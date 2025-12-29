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
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (imageUrl.startsWith('http')) {
      // 🌐 Network image (cached)
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (BuildContext context, String url) =>
            placeholder ??
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (BuildContext context, String url, dynamic error) {
          return errorBuilder?.call(context, error, null) ?? 
                 errorWidget ?? 
                 Container(color: Colors.grey.shade300);
        },
      );
    } else if (!kIsWeb && File(imageUrl).existsSync()) {
      // 📂 Local file (camera / gallery)
      image = Image.file(
        File(imageUrl),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          return errorBuilder?.call(context, error, stackTrace) ?? 
                 errorWidget ?? 
                 Container(color: Colors.grey.shade300);
        },
      );
    } else {
      // 🧯 Fallback
      return errorBuilder?.call(context, Exception('Image not found'), null) ?? 
             errorWidget ?? 
             Container(color: Colors.grey.shade300);
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
