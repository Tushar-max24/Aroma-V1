// Update the imports at the top
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'capture_preview_screen.dart';
import 'review_ingredients_screen.dart';
import '../../../core/enums/scan_mode.dart';
import '../pantry/review_items_screen.dart';
import '../../../data/services/scan_bill_service.dart';
import '../../../data/services/pantry_add_service.dart';

class IngredientEntryScreen extends StatelessWidget {
  final ScanMode mode;
  
  const IngredientEntryScreen({
    super.key,
    required this.mode,
  });

  Future<void> _handleGallerySelection(BuildContext context) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    maxHeight: 1600,
    imageQuality: 85,
  );
  
  if (image == null || !context.mounted) return;

  if (mode == ScanMode.cooking) {
    // Navigate directly to ReviewIngredientsScreen without scanning first
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReviewIngredientsScreen(
            capturedImage: image,
            mode: mode,
            // Don't pass scanResult yet, it will be loaded when confirmed
          ),
        ),
      );
    }
  } else {
    // For pantry, we'll still scan immediately since that was the original behavior
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final scanResult = await ScanBillService().scanBill(image);
      final items = scanResult["ingredients_with_quantity"];

      if (context.mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReviewItemsScreen(
              items: List<Map<String, dynamic>>.from(items),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error processing pantry items: $e");
      if (context.mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process image. Please try again.')),
        );
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: Stack(
        children: [
          /// --- Background ---
          Positioned.fill(
            child: Container(color: Colors.grey.shade300),
          ),

          /// --- Close Button ---
          Align(
            alignment: const Alignment(0, 0.2),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),

          /// --- Bottom Sheet ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 42),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Title
                    Text(
                      mode == ScanMode.cooking 
                          ? 'Start Adding Ingredients' 
                          : 'Add Items to Pantry',
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 26),

                    /// --- Action Icons ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _OptionCard(
                          label: 'Search',
                          icon: Icons.search_rounded,
                          onTap: () {
                            // TODO: Implement search functionality
                          },
                        ),
                        _OptionCard(
                          label: 'Camera',
                          icon: Icons.camera_alt_rounded,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => CapturePreviewScreen(
                                mode: mode,
                              ),
                            ));
                          },
                        ),
                        _OptionCard(
                          label: 'Gallery',
                          icon: Icons.photo_library_rounded,
                          onTap: () => _handleGallerySelection(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep the existing _OptionCard widget

/// -------- Option Cards --------
class _OptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              size: 34,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.body2.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}