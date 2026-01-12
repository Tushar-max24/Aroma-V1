import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (imageUrl.startsWith('http')) {
      // 🌐 Network image (cached)
      debugPrint('🖼️ Loading network image: $imageUrl');
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) =>
            placeholder ??
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, __, stackTrace) {
          debugPrint('❌ Failed to load network image: $imageUrl');
          debugPrint('❌ Error: $stackTrace');
          return errorWidget ?? Container(color: Colors.grey.shade300);
        },
      );
    } else if (!kIsWeb && File(imageUrl).existsSync()) {
      // 📂 Local file (camera / gallery)
      debugPrint('🖼️ Loading local file: $imageUrl');
      image = Image.file(
        File(imageUrl),
        fit: fit,
        width: width,
        height: height,
      );
    } else {
      // 🧯 Fallback
      debugPrint('🖼️ Using fallback placeholder for: $imageUrl');
      image = errorWidget ?? Container(color: Colors.grey.shade300);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}
