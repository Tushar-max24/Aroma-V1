import 'dart:io';
import 'package:flutter/foundation.dart';
import 'lib/data/services/ingredient_image_db_service.dart';
import 'lib/data/services/ingredient_image_service.dart';

Future<void> main() async {
  if (kDebugMode) {
    print('🔍 Testing cache debug...');
    
    // Test ingredients from the logs
    final testIngredients = [
      'large eggs',
      'milk', 
      'cottage cheese',
      'natural yogurt',
      'cherry tomatoes',
      'bananas',
      'aubergine',
      'cheese crackers',
      'chocolate cookies',
      'canned tuna',
      'chicken breast'
    ];
    
    for (final ingredient in testIngredients) {
      print('\n--- Testing: $ingredient ---');
      
      // Check database
      final dbImage = await IngredientImageDBService.getCachedImage(ingredient);
      if (dbImage != null) {
        print('✅ Found in DB: ${dbImage.localPath}');
        
        // Check file existence
        final file = File(dbImage.localPath);
        final exists = await file.exists();
        print('📁 File exists: $exists');
        
        if (exists) {
          final size = await file.length();
          print('📏 File size: $size bytes');
        } else {
          print('❌ File does not exist - this is the problem!');
        }
      } else {
        print('❌ Not found in DB');
      }
    }
  }
}
