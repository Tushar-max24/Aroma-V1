import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'pantry_review_items_screen.dart';
import '../../../data/services/pantry_add_service.dart';

enum ReviewState { confirm, scanning, failed }

class PantryReviewIngredientsScreen extends StatefulWidget {
  final XFile? capturedImage;
  final List<Map<String, dynamic>>? items;

  const PantryReviewIngredientsScreen({
    super.key,
    this.capturedImage,
    this.items,
  });

  @override
  State<PantryReviewIngredientsScreen> createState() =>
      _PantryReviewIngredientsScreenState();
}

class _PantryReviewIngredientsScreenState
    extends State<PantryReviewIngredientsScreen> {
  ReviewState _state = ReviewState.confirm;
  final PantryAddService _pantryService = PantryAddService();

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case ReviewState.confirm:
        return _ConfirmPhotoView(
          imagePath: widget.capturedImage?.path ?? '',
          onConfirm: _processImage,
          onRetake: () => Navigator.pop(context),
        );
      case ReviewState.scanning:
        return _ScanningView(
          onCancel: () => Navigator.pop(context),
        );
      case ReviewState.failed:
        return _UploadFailedView(
          onRetry: () => setState(() => _state = ReviewState.confirm),
          onCancel: () => Navigator.pop(context),
        );
    }
  }

  Future<void> _processImage() async {
    if (!mounted) return;

    setState(() => _state = ReviewState.scanning);

    try {
      final imageBytes = widget.capturedImage != null 
          ? await widget.capturedImage!.readAsBytes()
          : null;

      final result = await _pantryService.processRawText(
        imageBytes != null ? String.fromCharCodes(imageBytes) : '',
      );

      if (!mounted) return;

      final items =
          result["ingredients_with_quantity"] as List<dynamic>? ?? [];

      if (items.isEmpty) {
        setState(() => _state = ReviewState.failed);
        return;
      }

      final addedItems = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantryReviewItemsScreen(
            items: List<Map<String, dynamic>>.from(items),
          ),
        ),
      );

      if (!mounted) return;

      if (addedItems != null) {
        Navigator.pop(context, addedItems);
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error processing image: $e');
      if (mounted) {
        setState(() => _state = ReviewState.failed);
      }
    }
  }
}

/* ---------------- UI SUB WIDGETS ---------------- */

class _ConfirmPhotoView extends StatelessWidget {
  final String imagePath;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  const _ConfirmPhotoView({
    required this.imagePath,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Photo')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                PrimaryButton(text: 'Looks Good', onPressed: onConfirm),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRetake,
                  child: const Text('Retake'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningView extends StatelessWidget {
  final VoidCallback onCancel;

  const _ScanningView({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanning Receipt')),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _UploadFailedView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _UploadFailedView({
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Failed')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 72, color: Colors.red),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}
