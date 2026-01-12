import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ingredient_image_cache_service.dart';
import 'ingredient_image_db_service.dart';
import '../models/ingredient_image_model.dart';

class IngredientImageService {
  static bool _isInitialized = false;
  static const String _fallbackImagePath = 'assets/images/pantry/temp_pantry.png';
  static String get _baseUrl => dotenv.env['MONGO_EXTERNAL_API_URL'] ?? "http://3.108.110.151:5001";

  /// Normalize ingredient name for consistent database storage and lookup
  static String _normalizeIngredientName(String ingredientName) {
    return ingredientName.toLowerCase().trim();
  }

  static Future<void> initialize() async {
    if (!_isInitialized) {
      await IngredientImageCacheService.initialize();
      await IngredientImageDBService.initialize();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Ingredient Image Service initialized with DB support (Backend Images Only)');
      }
    }
  }

  static Future<String?> getIngredientImage(String ingredientName, {String? imageUrl}) async {
    await initialize();
    
    final normalizedName = _normalizeIngredientName(ingredientName);
    
    if (kDebugMode) {
      print('🔍 Getting ingredient image for: "$ingredientName" -> normalized: "$normalizedName"');
      print('🔍 Original ingredient name length: ${ingredientName.length}');
      print('🔍 Normalized ingredient name length: ${normalizedName.length}');
    }
    
    try {
      // 1. First, check local database
      final dbImage = await IngredientImageDBService.getCachedImage(normalizedName);
      if (dbImage != null) {
        // Check if local file still exists
        final file = File(dbImage.localPath);
        if (await file.exists()) {
          final fileSize = await file.length();
          if (kDebugMode) {
            print('✅ Using DB cached image for: $ingredientName (normalized: $normalizedName)');
            print('📁 File path: ${dbImage.localPath}');
            print('📏 File size: $fileSize bytes');
          }
          return dbImage.localPath;
        } else {
          // File doesn't exist, remove from database
          if (kDebugMode) {
            print('🗑️ Cached file missing, removing from DB: ${dbImage.localPath}');
          }
          await IngredientImageDBService.removeCachedImage(normalizedName);
        }
      }

      // 2. Check SharedPreferences cache (for backward compatibility)
      final cachedImage = await IngredientImageCacheService.getCachedImage(normalizedName);
      if (cachedImage != null) {
        // Check if local file still exists
        final file = File(cachedImage.localPath);
        if (await file.exists()) {
          final fileSize = await file.length();
          if (kDebugMode) {
            print('✅ Using SharedPreferences cached image for: $ingredientName (normalized: $normalizedName)');
            print('📁 File path: ${cachedImage.localPath}');
            print('📏 File size: $fileSize bytes');
          }
          // Migrate to database
          await IngredientImageDBService.cacheImage(cachedImage);
          return cachedImage.localPath;
        } else {
          // File doesn't exist, remove from cache
          if (kDebugMode) {
            print('🗑️ Cached file missing, removing from SharedPreferences: ${cachedImage.localPath}');
          }
          await IngredientImageCacheService.removeCachedImage(normalizedName);
        }
      }

      // 3. Use provided imageURL if available, otherwise use backend image URL
      String? workingUrl;
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        if (kDebugMode) {
          print('🔄 Using provided imageURL for: $ingredientName (normalized: $normalizedName)');
          print('🌐 Provided imageURL: $imageUrl');
        }
        
        workingUrl = imageUrl;
      } else {
        // Try multiple backend URL formats
        final possibleUrls = [
          '$_baseUrl/v2/images/${normalizedName.replaceAll(' ', '_')}.png',
          '$_baseUrl/v2/images/${normalizedName.replaceAll(' ', '')}.png',
          '$_baseUrl/v2/images/${normalizedName}.png',
          '$_baseUrl/ingredient_images/${normalizedName.replaceAll(' ', '_')}.png',
          '$_baseUrl/ingredient_images/${normalizedName}.png',
        ];
        
        for (final url in possibleUrls) {
          if (kDebugMode) {
            print('🌐 Trying backend URL: "$url" (length: ${url.length})');
          }
          
          // Use the first URL and let image widget handle 404s
          workingUrl = url;
          break;
        }
      }
      
      if (workingUrl == null) {
        if (kDebugMode) {
          print('❌ No backend URL available for: $ingredientName, using fallback');
        }
        return _fallbackImagePath;
      }
      
      if (kDebugMode) {
        print('🌐 Final backend URL: "$workingUrl" (length: ${workingUrl?.length})');
      }
      
      if (workingUrl == null) {
        if (kDebugMode) {
          print('❌ No backend URL available for: $ingredientName, using fallback');
        }
        return _fallbackImagePath;
      }
      
      if (kDebugMode) {
        print('🌐 Using backend URL: $workingUrl');
      }

      // 4. Cache the backend image URL
      final imageModel = IngredientImageModel(
        id: '${normalizedName}_${DateTime.now().millisecondsSinceEpoch}',
        ingredientName: normalizedName,
        localPath: workingUrl, // Use backend URL as path
        imageUrl: workingUrl,
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
      );

      await IngredientImageDBService.cacheImage(imageModel);
      await IngredientImageCacheService.cacheImage(
        normalizedName,
        workingUrl,
        workingUrl,
      );

      if (kDebugMode) {
        print('✅ Successfully cached backend image for: $ingredientName (normalized: $normalizedName)');
        print('🌐 Backend URL: $workingUrl');
      }

      return workingUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting ingredient image: $e, using fallback');
      }
      return _fallbackImagePath;
    }
  }

  static Future<String?> _saveImageLocally(String ingredientName, Uint8List imageData) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'ingredient_images'));
      
      // Create directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Create a safe filename with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = ingredientName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      
      final fileName = '${safeName}_$timestamp.png';
      final filePath = path.join(imagesDir.path, fileName);
      
      // Write the image data
      final file = File(filePath);
      await file.writeAsBytes(imageData);
      
      if (kDebugMode) {
        print('✅ Image saved locally: $filePath');
      }
      
      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving image locally: $e');
      }
      return null;
    }
  }

  static Future<void> clearCache() async {
    await initialize();
    
    try {
      // Clear database cache
      final cachedImages = await IngredientImageDBService.getAllCachedImages();
      for (final image in cachedImages) {
        final file = File(image.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await IngredientImageDBService.clearOldCache(maxAge: Duration.zero);
      
      // Clear SharedPreferences cache
      await IngredientImageCacheService.clearCache();
      
      if (kDebugMode) {
        print('✅ All image cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing cache: $e');
      }
    }
  }

  static Future<int> getCacheSize() async {
    await initialize();
    return await IngredientImageDBService.getCacheSize();
  }

  static Future<List<IngredientImageModel>> getAllCachedImages() async {
    await initialize();
    return await IngredientImageDBService.getAllCachedImages();
  }

  static Future<void> removeCachedImage(String ingredientName) async {
    await initialize();
    
    try {
      // Remove from database
      final dbImage = await IngredientImageDBService.getCachedImage(ingredientName);
      if (dbImage != null) {
        final file = File(dbImage.localPath);
        if (await file.exists()) {
          await file.delete();
        }
        await IngredientImageDBService.removeCachedImage(ingredientName);
      }
      
      // Remove from SharedPreferences cache
      await IngredientImageCacheService.removeCachedImage(ingredientName);
      
      if (kDebugMode) {
        print('✅ Removed cached image for: $ingredientName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing cached image: $e');
      }
    }
  }

  static Future<void> preloadImages(List<String> ingredientNames) async {
    await initialize();
    
    for (final ingredientName in ingredientNames) {
      try {
        // Check if already cached in database
        final cached = await IngredientImageDBService.getCachedImage(ingredientName);
        if (cached != null) {
          final file = File(cached.localPath);
          if (await file.exists()) {
            continue; // Skip if already cached and file exists
          }
        }
        
        // Generate and cache new image
        await getIngredientImage(ingredientName);
      } catch (e) {
        if (kDebugMode) {
          print('Error preloading image for $ingredientName: $e');
        }
      }
    }
  }
}
