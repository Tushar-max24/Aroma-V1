import 'package:flutter/material.dart';
import '../data/services/ingredient_image_service.dart';

class IngredientImagePreloader {
  static final Set<String> _preloadedIngredients = <String>{};
  static bool _isPreloading = false;

  /// Preload images for a list of ingredient names
  static Future<void> preloadIngredientImages(List<String> ingredientNames) async {
    if (_isPreloading) return;
    
    _isPreloading = true;
    
    try {
      // Filter out already preloaded ingredients
      final toPreload = ingredientNames
          .where((name) => !_preloadedIngredients.contains(name.toLowerCase()))
          .toList();
      
      if (toPreload.isEmpty) return;
      
      debugPrint('Preloading ${toPreload.length} ingredient images...');
      
      // Preload in batches to avoid overwhelming the API
      const batchSize = 3;
      for (int i = 0; i < toPreload.length; i += batchSize) {
        final batch = toPreload.skip(i).take(batchSize).toList();
        
        await Future.wait(
          batch.map((ingredientName) async {
            try {
              await IngredientImageService.getIngredientImage(ingredientName);
              _preloadedIngredients.add(ingredientName.toLowerCase());
              debugPrint('Preloaded: $ingredientName');
            } catch (e) {
              debugPrint('Failed to preload $ingredientName: $e');
            }
          }),
        );
        
        // Small delay between batches to avoid rate limiting
        if (i + batchSize < toPreload.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      debugPrint('Preloading completed. Total cached: ${_preloadedIngredients.length}');
    } finally {
      _isPreloading = false;
    }
  }

  /// Preload a single ingredient image
  static Future<void> preloadIngredientImage(String ingredientName) async {
    if (_preloadedIngredients.contains(ingredientName.toLowerCase())) {
      return;
    }
    
    try {
      await IngredientImageService.getIngredientImage(ingredientName);
      _preloadedIngredients.add(ingredientName.toLowerCase());
      debugPrint('Preloaded: $ingredientName');
    } catch (e) {
      debugPrint('Failed to preload $ingredientName: $e');
    }
  }

  /// Check if an ingredient has been preloaded
  static bool isPreloaded(String ingredientName) {
    return _preloadedIngredients.contains(ingredientName.toLowerCase());
  }

  /// Clear the preloaded ingredients tracker
  static void clearPreloadedTracker() {
    _preloadedIngredients.clear();
  }

  /// Get the count of preloaded ingredients
  static int get preloadedCount => _preloadedIngredients.length;

  /// Preload common ingredients that are frequently used
  static Future<void> preloadCommonIngredients() async {
    const commonIngredients = [
      'tomato', 'onion', 'potato', 'carrot', 'garlic', 'ginger',
      'chicken', 'beef', 'pork', 'fish', 'egg', 'milk',
      'rice', 'pasta', 'bread', 'flour', 'sugar', 'salt',
      'pepper', 'butter', 'oil', 'cheese', 'yogurt', 'cream',
      'apple', 'banana', 'orange', 'lemon', 'lime', 'strawberry',
      'broccoli', 'spinach', 'lettuce', 'cucumber', 'bell pepper',
      'beans', 'lentils', 'chickpeas', 'nuts', 'almonds', 'walnuts',
    ];
    
    await preloadIngredientImages(commonIngredients);
  }
}

/// A widget that automatically preloads ingredient images when mounted
class IngredientImagePreloaderWidget extends StatefulWidget {
  final List<String> ingredientNames;
  final Widget child;
  final bool preloadCommon;

  const IngredientImagePreloaderWidget({
    super.key,
    required this.ingredientNames,
    required this.child,
    this.preloadCommon = false,
  });

  @override
  State<IngredientImagePreloaderWidget> createState() => _IngredientImagePreloaderWidgetState();
}

class _IngredientImagePreloaderWidgetState extends State<IngredientImagePreloaderWidget> {
  @override
  void initState() {
    super.initState();
    _preloadImages();
  }

  Future<void> _preloadImages() async {
    // Don't block the UI
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.preloadCommon) {
        await IngredientImagePreloader.preloadCommonIngredients();
      }
      
      if (widget.ingredientNames.isNotEmpty) {
        await IngredientImagePreloader.preloadIngredientImages(widget.ingredientNames);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
