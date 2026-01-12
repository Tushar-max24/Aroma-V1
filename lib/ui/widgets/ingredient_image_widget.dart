import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/services/enhanced_ingredient_image_service.dart';

class IngredientImageWidget extends StatefulWidget {
  final String ingredientName;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final String? imageUrl; // Add imageUrl parameter

  const IngredientImageWidget({
    super.key,
    required this.ingredientName,
    this.width = 56,
    this.height = 56,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.onTap,
    this.imageUrl, // Add to constructor
  });

  @override
  State<IngredientImageWidget> createState() => _IngredientImageWidgetState();
}

class _IngredientImageWidgetState extends State<IngredientImageWidget> {
  String? _imagePath;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final imagePath = await EnhancedIngredientImageService.getIngredientImage(
        widget.ingredientName, 
        imageUrl: widget.imageUrl, // Use the imageUrl parameter
      );
      if (mounted) {
        setState(() {
          _imagePath = imagePath;
          _isLoading = false;
          _hasError = imagePath == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ?? 
      Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            Icons.restaurant,
            size: widget.width * 0.4,
            color: Colors.grey.shade400,
          ),
        ),
      );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
      Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            Icons.broken_image,
            size: widget.width * 0.4,
            color: Colors.grey.shade400,
          ),
        ),
      );
  }

  Widget _buildImage() {
    if (_imagePath != null) {
      // Check if it's a network URL
      if (_imagePath!.startsWith('http://') || _imagePath!.startsWith('https://')) {
        return ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          child: Image.network(
            _imagePath!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
              );
            },
          ),
        );
      } else {
        // Handle as local file
        final file = File(_imagePath!);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            child: Image.file(
              file,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorWidget();
              },
            ),
          );
        }
      }
    }
    return _buildErrorWidget();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = _buildPlaceholder();
    } else if (_hasError) {
      content = _buildErrorWidget();
    } else {
      content = _buildImage();
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: content,
      );
    }

    return content;
  }
}

// A simpler version for list items
class IngredientImageThumbnail extends StatelessWidget {
  final String ingredientName;
  final double size;
  final VoidCallback? onTap;
  final String? imageUrl; // Add imageUrl parameter

  const IngredientImageThumbnail({
    super.key,
    required this.ingredientName,
    this.size = 56,
    this.onTap,
    this.imageUrl, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    return IngredientImageWidget(
      ingredientName: ingredientName,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      imageUrl: imageUrl, // Pass imageUrl to the widget
    );
  }
}

// A hero version for detailed views
class IngredientImageHero extends StatelessWidget {
  final String ingredientName;
  final double width;
  final double height;
  final String? heroTag;

  const IngredientImageHero({
    super.key,
    required this.ingredientName,
    this.width = 200,
    this.height = 200,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final tag = heroTag ?? 'ingredient_image_$ingredientName';
    
    return Hero(
      tag: tag,
      child: IngredientImageWidget(
        ingredientName: ingredientName,
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
