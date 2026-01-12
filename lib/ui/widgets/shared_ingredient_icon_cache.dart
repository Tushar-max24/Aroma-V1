import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../../data/services/enhanced_ingredient_image_service.dart';
import '../../../core/utils/item_image_resolver.dart';

class SharedIngredientIconCache extends StatefulWidget {
  final dynamic icon;
  final String ingredientName;
  final double? size;
  final List<Map<String, dynamic>>? allIngredients;

  const SharedIngredientIconCache({
    super.key,
    required this.icon,
    required this.ingredientName,
    this.size = 30,
    this.allIngredients,
  });

  // Static method to clear the shared cache if needed
  static void clearSharedCache() {
    if (kDebugMode) {
      print('🗑️ SharedIngredientIconCache: Clearing all cached futures');
    }
    _SharedIngredientIconCacheState._imageCache.clear();
    _SharedIngredientIconCacheState._cacheKeys.clear();
  }
  
  // Static method to get cache status for debugging
  static Map<String, dynamic> getCacheStatus() {
    return {
      'cachedItems': _SharedIngredientIconCacheState._cacheKeys.length,
      'cacheKeys': _SharedIngredientIconCacheState._cacheKeys.toList(),
    };
  }

  @override
  State<SharedIngredientIconCache> createState() => _SharedIngredientIconCacheState();
}

class _SharedIngredientIconCacheState extends State<SharedIngredientIconCache> {
  static final Map<String, Future<String?>> _imageCache = {};
  static final Set<String> _cacheKeys = {}; // Track cache keys for debugging

  Future<String?> _getImageFuture(String ingredientName) {
    final normalizedName = ingredientName.toLowerCase().trim();
    
    // Check if already cached
    if (_imageCache.containsKey(normalizedName)) {
      if (kDebugMode) {
        print('🎯 SharedIngredientIconCache: Using cached future for: "$normalizedName" (Cache keys: ${_cacheKeys.length})');
      }
      return _imageCache[normalizedName]!;
    }
    
    // Try to find imageUrl from allIngredients list with multiple field support
    String? imageUrl;
    if (widget.allIngredients != null) {
      for (final allIng in widget.allIngredients!) {
        final allName = (allIng['item'] ?? allIng['name'] ?? '').toString().toLowerCase().trim();
        final currentName = ingredientName.toLowerCase().trim();
        
        // Enhanced matching logic for better ingredient name resolution
        if (allName == currentName || 
            allName.contains(currentName) || 
            currentName.contains(allName) ||
            _isIngredientMatch(allName, currentName)) {
          // Extract imageUrl from multiple possible fields for S3 URL support
          imageUrl = allIng['image_url']?.toString() ?? 
                     allIng['imageUrl']?.toString() ?? 
                     allIng['image']?.toString() ?? '';
          if (kDebugMode) {
            print('🔍 SharedIngredientIconCache: Found imageUrl for "$ingredientName" ($allName == $currentName): $imageUrl');
          }
          break;
        }
      }
    }
    
    // If widget.icon is a URL and we didn't find imageUrl in allIngredients, use it directly
    if ((imageUrl == null || imageUrl.isEmpty) && 
        widget.icon is String && 
        widget.icon.isNotEmpty && 
        (widget.icon.startsWith('http://') || widget.icon.startsWith('https://'))) {
      imageUrl = widget.icon.toString();
      if (kDebugMode) {
        print('🔍 SharedIngredientIconCache: Using widget.icon as imageUrl: $imageUrl');
      }
    }
    
    // Create new future and cache it
    if (kDebugMode) {
      print('🔄 SharedIngredientIconCache: Creating new future for: "$normalizedName" with imageUrl: $imageUrl');
    }
    
    final future = EnhancedIngredientImageService.getIngredientImage(normalizedName, imageUrl: imageUrl);
    _imageCache[normalizedName] = future;
    _cacheKeys.add(normalizedName);
    
    return future;
  }
  
  // Enhanced ingredient matching helper
  static bool _isIngredientMatch(String allName, String currentName) {
    // Handle common variations and plural forms
    final allWords = allName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final currentWords = currentName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    // Check if all words from allName are in currentName
    int matchCount = 0;
    for (final allWord in allWords) {
      if (currentWords.any((currentWord) => 
          currentWord.contains(allWord) || allWord.contains(currentWord))) {
        matchCount++;
      }
    }
    
    // Consider it a match if at least 50% of words match
    return matchCount >= (allWords.length / 2).ceil();
  }

  @override
  Widget build(BuildContext context) {
    // If we have an emoji (not a regular ingredient name), use it directly
    if (widget.icon is String && 
        widget.icon.isNotEmpty && 
        widget.icon.length <= 2 && 
        !widget.icon.startsWith('assets/')) {
      return Text(
        widget.icon,
        style: TextStyle(fontSize: widget.size),
      );
    }
    
    // Try to find matching ingredient in allIngredients list for better name matching
    String searchName = widget.ingredientName.toLowerCase().trim();
    if (widget.allIngredients != null) {
      for (final allIng in widget.allIngredients!) {
        final allName = (allIng['item'] ?? allIng['name'] ?? '').toString().toLowerCase().trim();
        final currentName = widget.ingredientName.toLowerCase().trim();
        if (allName.contains(currentName) || currentName.contains(allName)) {
          searchName = allIng['item'] ?? allIng['name'] ?? widget.ingredientName;
          if (kDebugMode) {
            print('🔍 SharedIngredientIconCache: Found better match: "$searchName"');
          }
          break;
        }
      }
    }
    
    // Use shared cache with FutureBuilder
    return FutureBuilder<String?>(
      future: _getImageFuture(searchName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          final imagePath = snapshot.data!;
          if (kDebugMode) {
            print('🔍 SharedIngredientIconCache: Found image path: $imagePath');
          }
          
          if (imagePath.startsWith('assets/')) {
            return Image.asset(
              imagePath,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildEmojiIcon(widget.ingredientName),
            );
          } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
            // For network URLs (S3), use Image.network directly
            return Image.network(
              imagePath,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildEmojiIcon(widget.ingredientName),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                );
              },
            );
          } else {
            // For local file paths, check if file exists first
            final file = File(imagePath);
            if (file.existsSync()) {
              if (kDebugMode) {
                final fileSize = file.lengthSync();
                print('🔍 SharedIngredientIconCache: File exists, size: $fileSize bytes');
              }
              return Image.file(
                file,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildEmojiIcon(widget.ingredientName),
              );
            } else {
              // File doesn't exist, fallback to emoji
              if (kDebugMode) {
                print('🔍 SharedIngredientIconCache: File does not exist: $imagePath');
              }
              return _buildEmojiIcon(widget.ingredientName);
            }
          }
        }
        
        // If no data or error, fallback to emoji
        return _buildEmojiIcon(widget.ingredientName);
      },
    );
  }

  Widget _buildEmojiIcon(String ingredientName) {
    return Text(
      ItemImageResolver.getEmojiForIngredient(ingredientName),
      style: TextStyle(fontSize: widget.size),
    );
  }
}
