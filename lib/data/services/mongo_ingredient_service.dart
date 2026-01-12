import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MongoIngredientService {
  static String _baseUrl = "http://172.16.1.119:3000"; // Temporary hardcoded IP
  static String _localBaseUrl = "http://172.16.1.119:3000"; // Temporary hardcoded IP
  static const String _collectionName = "ingredients";

  /// Test connection to MongoDB server (tries external then local)
  static Future<bool> testConnection() async {
    debugPrint("🔄 Testing MongoDB connection to $_baseUrl...");
    try {
      // Try external IP first
      final url = Uri.parse("$_baseUrl/api/health");
      final response = await http.get(url).timeout(Duration(seconds: 5));
      
      debugPrint("📌 External Health Check Response: ${response.statusCode}");
      debugPrint("📌 External Health Check Body: ${response.body}");
      
      if (response.statusCode == 200) {
        debugPrint("✅ External MongoDB connection successful!");
        return true;
      }
    } catch (e) {
      debugPrint("⚠️ External connection failed: $e");
      
      // Fallback to localhost
      debugPrint("🔄 Trying fallback to localhost...");
      try {
        final localUrl = Uri.parse("$_localBaseUrl/api/health");
        final localResponse = await http.get(localUrl).timeout(Duration(seconds: 5));
        
        debugPrint("📌 Local Health Check Response: ${localResponse.statusCode}");
        debugPrint("📌 Local Health Check Body: ${localResponse.body}");
        
        if (localResponse.statusCode == 200) {
          debugPrint("✅ Local MongoDB connection successful!");
          return true;
        } else {
          debugPrint("❌ Local MongoDB connection failed with status: ${localResponse.statusCode}");
          return false;
        }
      } catch (localError) {
        debugPrint("❌ Local connection also failed: $localError");
        return false;
      }
    }
    return false;
  }

  /// Get the appropriate base URL (external if available, otherwise local)
  static Future<String> _getBaseUrl() async {
    try {
      final url = Uri.parse("$_baseUrl/api/health");
      final response = await http.get(url).timeout(Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        return _baseUrl;
      }
    } catch (e) {
      // External not available, use local
    }
    
    return _localBaseUrl;
  }

  /// Store extracted ingredients from scan bill API to MongoDB
  static Future<bool> storeExtractedIngredients(List<Map<String, dynamic>> ingredients) async {
    try {
      bool allSuccess = true;
      
      for (var ingredient in ingredients) {
        final success = await storeSingleIngredient(ingredient);
        if (!success) {
          allSuccess = false;
          print("❌ Failed to store ingredient: ${ingredient['name']}");
        }
      }
      
      return allSuccess;
    } catch (e) {
      print("❌ Error storing ingredients to MongoDB: $e");
      return false;
    }
  }

  /// Get ingredient by name from MongoDB
  static Future<Map<String, dynamic>?> getIngredientByName(String name) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/ingredients/name/$name");
      
      final response = await http.get(url);

      print("📌 MongoDB Get Response: ${response.statusCode}");
      print("📌 MongoDB Get Body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result; // Return the ingredient directly
      } else if (response.statusCode == 404) {
        print("ℹ️ Ingredient not found: $name");
        return null;
      } else {
        print("❌ Failed to fetch ingredient: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching ingredient from MongoDB: $e");
      return null;
    }
  }

  /// Store single ingredient to MongoDB
  static Future<bool> storeSingleIngredient(Map<String, dynamic> ingredient) async {
    try {
      debugPrint("🔄 Storing single ingredient: $ingredient");
      
      // Check if ingredient already exists
      final existing = await getIngredientByName(ingredient['name']);
      if (existing != null) {
        debugPrint("ℹ️ Ingredient already exists: ${ingredient['name']}");
        return true;
      }

      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/ingredients");
      
      // Match the server's expected format: name, image_url, common_units, nutrition_per_100g
      final payload = {
        'name': ingredient['name'],
        'image_url': ingredient['image_url'] ?? '',
        'common_units': ingredient['common_units'] ?? ["g", "pcs"],
        'nutrition_per_100g': ingredient['nutrition_per_100g'] ?? {
          "calories": 0,
          "protein": 0,
          "carbs": 0,
          "fats": 0,
          "fiber": 0,
          "sugar": 0
        }
      };
      
      debugPrint("📦 Sending payload to MongoDB: $payload");
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint("📌 MongoDB Store Single Response: ${response.statusCode}");
      debugPrint("📌 MongoDB Store Single Body: ${response.body}");

      if (response.statusCode == 201) {
        debugPrint("✅ Successfully stored ingredient: ${ingredient['name']}");
        return true;
      } else if (response.statusCode == 400) {
        debugPrint("⚠️ Ingredient already exists: ${ingredient['name']}");
        return true; // Treat as success since it already exists
      } else {
        debugPrint("❌ Failed to store ingredient: ${response.statusCode}");
        debugPrint("❌ Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error storing single ingredient to MongoDB: $e");
      return false;
    }
  }

  /// Convert scan bill ingredient to MongoDB format
  static Map<String, dynamic> convertToMongoFormat(Map<String, dynamic> scanIngredient, {String source = "scan_bill"}) {
    debugPrint("🔄 Converting scan ingredient: $scanIngredient");
    debugPrint("📊 Source: $source");
    
    // Handle different field names from scan API
    final name = scanIngredient["item"]?.toString() ?? 
                 scanIngredient["name"]?.toString() ?? 
                 "Unknown";
                 
    final imageUrl = scanIngredient["imageURL"]?.toString() ?? 
                     scanIngredient["image_url"]?.toString() ?? "";
    
    // Determine common units based on metrics/unit field
    String metrics = scanIngredient["metrics"]?.toString() ?? 
                    scanIngredient["unit"]?.toString() ?? 
                    "pcs";
    
    debugPrint("📊 Converting: name='$name', imageUrl='$imageUrl', metrics='$metrics'");
    
    List<String> commonUnits = ["pcs", "g", "kg"];
    
    if (metrics.contains("g") || metrics.contains("gram")) {
      commonUnits = ["g", "kg", "oz"];
    } else if (metrics.contains("pcs") || metrics.contains("piece")) {
      commonUnits = ["pcs", "dozen"];
    } else if (metrics.contains("can")) {
      commonUnits = ["can", "g", "oz"];
    } else if (metrics.contains("lb") || metrics.contains("pound")) {
      commonUnits = ["lb", "g", "kg"];
    }

    // Extract nutrition data from macros if available
    Map<String, dynamic> macros = scanIngredient["macros"] ?? {};
    debugPrint("📊 Macros data: $macros");
    
    final mongoIngredient = {
      "name": name.trim(),
      "category": _inferCategory(name),
      "image_url": imageUrl,
      "common_units": commonUnits,
      "nutrition_per_100g": {
        "calories": _extractNumericValue(macros["calories_kcal"] ?? 0),
        "protein": _extractNumericValue(macros["protein_g"] ?? 0),
        "carbs": _extractNumericValue(macros["carbohydrates_g"] ?? 0),
        "fats": _extractNumericValue(macros["fat_g"] ?? 0),
        "fiber": _extractNumericValue(macros["fiber_g"] ?? 0),
        "sugar": _extractNumericValue(macros["sugar_g"] ?? 0)
      },
      "source": source,
      "created_at": DateTime.now().toIso8601String(),
    };
    
    debugPrint("✅ Converted to MongoDB format: $mongoIngredient");
    return mongoIngredient;
  }

  /// Extract numeric value from dynamic input
  static double _extractNumericValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  /// Infer category from ingredient name
  static String _inferCategory(String name) {
    final lowerName = name.toLowerCase();
    
    if (lowerName.contains('chicken') || lowerName.contains('beef') || 
        lowerName.contains('pork') || lowerName.contains('fish') || 
        lowerName.contains('tuna') || lowerName.contains('meat')) {
      return "Protein";
    } else if (lowerName.contains('apple') || lowerName.contains('banana') || 
               lowerName.contains('orange') || lowerName.contains('fruit')) {
      return "Fruit";
    } else if (lowerName.contains('carrot') || lowerName.contains('broccoli') || 
               lowerName.contains('lettuce') || lowerName.contains('tomato') ||
               lowerName.contains('pumpkin') || lowerName.contains('fennel') ||
               lowerName.contains('cabbage') || lowerName.contains('pepper')) {
      return "Vegetable";
    } else if (lowerName.contains('milk') || lowerName.contains('cheese') || 
               lowerName.contains('yogurt') || lowerName.contains('dairy')) {
      return "Dairy";
    } else if (lowerName.contains('bread') || lowerName.contains('rice') || 
               lowerName.contains('pasta') || lowerName.contains('flour')) {
      return "Grain";
    } else {
      return "Other";
    }
  }

  /// Store ingredients from scan bill results
  static Future<bool> storeScanBillIngredients(List<Map<String, dynamic>> scanResults, {String source = "scan_bill"}) async {
    try {
      debugPrint("🔄 Starting to store ${scanResults.length} ingredients to MongoDB with source: $source...");
      
      final mongoIngredients = scanResults.map((ingredient) => 
        convertToMongoFormat(ingredient, source: source)
      ).toList();

      debugPrint("📋 Converted ingredients to MongoDB format:");
      for (var ingredient in mongoIngredients) {
        debugPrint("  - ${ingredient['name']} (${ingredient['category']}) - source: ${ingredient['source']}");
      }

      debugPrint("📦 Calling storeExtractedIngredients...");
      final result = await storeExtractedIngredients(mongoIngredients);
      debugPrint("📊 StoreExtractedIngredients result: $result");
      
      return result;
    } catch (e) {
      debugPrint("❌ Error processing scan bill ingredients: $e");
      return false;
    }
  }
}
