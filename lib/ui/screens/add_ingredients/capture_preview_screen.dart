import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import 'review_ingredients_screen.dart';
import '../../../data/services/scan_bill_service.dart';
import '../../../core/enums/scan_mode.dart';
import '../../../data/services/pantry_add_service.dart';
import '../pantry/review_items_screen.dart';



class CapturePreviewScreen extends StatefulWidget {
  final ScanMode mode;

  const CapturePreviewScreen({
    super.key,
    required this.mode,
  });

  @override
  State<CapturePreviewScreen> createState() => _CapturePreviewScreenState();
}

class _CapturePreviewScreenState extends State<CapturePreviewScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> _captureImage() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        return null;
      }
      return await _controller!.takePicture();
    } catch (e) {
      return null;
    }
  }

  Future<void> _initCamera() async {
    try {
      final List<CameraDescription> cams = await availableCameras();
      if (cams.isEmpty) return;
      final CameraController controller = CameraController(
        cams.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // If camera fails, we just keep a black background.
    }
  }

  Future<void> _openGallery() async {
  try {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;

    final scanResult =
        await ScanBillService().scanBill(file);

    if (widget.mode == ScanMode.cooking) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewIngredientsScreen(
            capturedImage: file,
            scanResult: scanResult,
          ),
        ),
      );
    } else {
      final rawText = scanResult["raw_text"];
      final pantryResult =
          await PantryAddService().processRawText(rawText);

      final items =
          pantryResult["ingredients_with_quantity"];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewItemsScreen(
            items: List<Map<String, dynamic>>.from(items),
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint("Gallery scan failed: $e");
  }
}


  @override
  void initState() {
    super.initState();
    print("🔥 SCANNER MODE = ${widget.mode}");
    _initFuture = _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initFuture,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return Stack(
              children: [
                /// Camera Preview or fallback
                Positioned.fill(
                  child: (_controller != null && _controller!.value.isInitialized)
                      ? CameraPreview(_controller!)
                      : Container(color: Colors.black),
                ),

                /// Fade to dark at bottom (overlay gradient)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                ),

                /// Scanning frame (rounded corners) - smaller so it doesn't touch bottom
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 90, 26, 180),
                    child: CustomPaint(painter: _ScannerFrame()),
                  ),
                ),

                /// Back Button
                Positioned(
                  top: 16,
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

                /// --- BOTTOM SHUTTER + TEXT ---
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40, left: 32, right: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// Controls Row (center shutter, gallery to the right)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(width: 56),

                            /// Capture button
                            GestureDetector(
                              onTap: () async {
  final XFile? image = await _captureImage();
  if (image == null || !mounted) return;

  final scanResult =
      await ScanBillService().scanBill(image);

  // 🔀 FLOW DECISION BASED ON MODE
  if (widget.mode == ScanMode.cooking) {
    // 🍳 COOKING FLOW
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewIngredientsScreen(
          capturedImage: image,
          scanResult: scanResult,
        ),
      ),
    );
  } else {
    // 🧺 PANTRY FLOW
    final rawText = scanResult["raw_text"];

    final pantryResult =
        await PantryAddService().processRawText(rawText);

    final items =
        pantryResult["ingredients_with_quantity"];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewItemsScreen(
          items: List<Map<String, dynamic>>.from(items),
        ),
      ),
    );
  }
},


                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 5),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 62,
                                    height: 62,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            /// Gallery button - outside frame, aligned to bottom-right
                            GestureDetector(
                              onTap: _openGallery,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black.withOpacity(0.12)),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.photo_library_rounded,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Top Button Component
class _TopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.12)),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: Colors.black87),
        onPressed: onTap,
      ),
    );
  }
}

/// Scanner Frame Painter
class _ScannerFrame extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double cornerSize = 24.0;
    final double cornerWidth = 3.0;
    final double cornerLength = cornerSize;

    // Draw left-top corner (L shape)
    canvas.drawLine(
      Offset(0, cornerLength),
      Offset.zero,
      paint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(cornerLength, 0),
      paint..strokeWidth = cornerWidth,
    );

    // Draw right-top corner (mirrored L shape)
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint..strokeWidth = cornerWidth,
    );

    // Draw left-bottom corner (upside-down L shape)
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint..strokeWidth = cornerWidth,
    );

    // Draw right-bottom corner (upside-down mirrored L shape)
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint..strokeWidth = cornerWidth,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}