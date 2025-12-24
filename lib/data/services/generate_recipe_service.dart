// lib/data/services/generate_recipe_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GenerateRecipeService {
  final String recipeUrl =
      "http://3.108.110.151:5001/generate-recipes-ingredient"; // API #2
  final String imageUrl =
      "http://3.108.110.151:5001/generate-dish-image"; // API #3

  Future<dynamic> generateRecipes(
      List<String> ingredients, Map<String, dynamic> preferences) async {
    final url = Uri.parse(recipeUrl);

    final body = jsonEncode({
      "ingredients": ingredients,
      "preferences": preferences,
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    // debug logs
    print("📌 Recipe API Status: ${response.statusCode}");
    print("📌 Recipe API Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Recipe Generation Failed: ${response.statusCode} → ${response.body}");
    }
  }

  /// Generate dish image; returns either a remote image URL (String) or Uint8List (decoded base64)
  Future<dynamic> generateDishImage(String dishName) async {
    final url = Uri.parse(imageUrl);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"dish_name": dishName}),
    );

    print("📌 Image API Status: ${response.statusCode}");
    print("📌 Image API Response: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded.containsKey("image_url")) {
        return decoded["image_url"].toString();
      } else if (decoded is Map && decoded.containsKey("image_base64")) {
        final base64Str = decoded["image_base64"].toString();
        return base64Decode(base64Str);
      } else {
        // If backend returns the raw URL string, return it directly
        if (response.body.isNotEmpty && response.body.startsWith("http")) {
          return response.body.trim();
        }
        throw Exception("Unexpected image response: ${response.body}");
      }
    } else {
      throw Exception("Image generation failed: ${response.statusCode} → ${response.body}");
    }
  }
}
