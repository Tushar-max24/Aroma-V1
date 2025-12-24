import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/enums/scan_mode.dart';
import '../../../widgets/primary_button.dart';
import 'review_ingredients_list_screen.dart';
import '../../../data/services/scan_bill_service.dart';

enum ReviewState { confirm, scanning, failed }

class ReviewIngredientsScreen extends StatefulWidget {
  final XFile? capturedImage;
  final Map<String, dynamic>? scanResult;
  final ScanMode mode;

  const ReviewIngredientsScreen({
    super.key,
    required this.capturedImage,
    this.scanResult,
    this.mode = ScanMode.cooking,
  });

  @override
  State<ReviewIngredientsScreen> createState() =>
      _ReviewIngredientsScreenState();
}

class _ReviewIngredientsScreenState extends State<ReviewIngredientsScreen> {
  ReviewState _state = ReviewState.confirm;

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case ReviewState.confirm:
  return _ConfirmPhotoView(
    capturedImage: widget.capturedImage,

    onLooksGood: () async {
      setState(() => _state = ReviewState.scanning);

      try {
        final result = await ScanBillService().scanBill(widget.capturedImage!);

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewIngredientsListScreen(scanResult: result),
          ),
        );
      } catch (e) {
        setState(() => _state = ReviewState.failed);
      }
    },

    onRetake: () => Navigator.pop(context),
  );


      case ReviewState.scanning:
        return _ScanningView(
          capturedImage: widget.capturedImage,
          onFail: () => setState(() => _state = ReviewState.failed),
        );

      case ReviewState.failed:
        return const _UploadFailedView();
    }
  }
}

///// 1️⃣ Confirm Screen UI
class _ConfirmPhotoView extends StatelessWidget {
  final XFile? capturedImage;
  final VoidCallback onLooksGood;
  final VoidCallback onRetake;

  const _ConfirmPhotoView({
    this.capturedImage,
    required this.onLooksGood,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 0.0; // Remove horizontal padding for full width
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button at the top
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Vertical rectangular image preview - more rectangular
            Expanded(
              flex: 4,  // Increased flex to make it take more vertical space
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: capturedImage != null
                      ? kIsWeb
                          ? Image.network(
                              capturedImage!.path,
                              fit: BoxFit.cover,
                              height: double.infinity,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  _plainFallbackImage(),
                            )
                          : Image.file(
                              File(capturedImage!.path),
                              fit: BoxFit.cover,
                              height: double.infinity,
                              width: double.infinity,
                            )
                      : _plainFallbackImage(),
                ),
              ),
            ),

            // Text content below the image
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Great! Is the photo clear enough to see the ingredients?",
                style: AppTypography.h3.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bottom action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 26),
                      onPressed: onRetake,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: onLooksGood,
                        child: const Text(
                          "Yes, Looks Good",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // plain fallback image (no AspectRatio) — used inside an outer AspectRatio/SizedBox
  Widget _plainFallbackImage() {
    return Image.asset(
      AssetPaths.vegBoard,
      fit: BoxFit.cover,
    );
  }
}

///// 2️⃣ Scanning UI
class _ScanningView extends StatelessWidget {
  final XFile? capturedImage;
  final VoidCallback onFail;

  const _ScanningView({
    this.capturedImage,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: capturedImage != null
                ? kIsWeb
                    ? Image.network(
                        capturedImage!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                      )
                    : Image.file(
                        File(capturedImage!.path),
                        fit: BoxFit.cover,
                      )
                : _buildFallbackImage(),
          ),
          
          // Back button at top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),
          
          // Headphone icon at top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.headphones, color: Colors.black, size: 24),
            ),
          ),

          // Center icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),

          // Scanner Frame Overlay
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 120, 40, 200),
              child: CustomPaint(painter: _ScanningFrame()),
            ),
          ),

          // Bottom text
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Just a few more seconds',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const Text(
                    'and your pantry will be up to date.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      AssetPaths.vegBoard,
      fit: BoxFit.cover,
    );
  }
}

///// 3️⃣ Failed UI Sheet
class _UploadFailedView extends StatelessWidget {
  const _UploadFailedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),

      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),

              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upload Failed!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Oops! Something went wrong.\nTry Uploading image again!",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Retry Upload",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
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
class _ScanningFrame extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 40.0;
    const stroke = 3.0;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw four L-shaped corners at the edges of the screen
    // Top-left
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}