import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ScanBillService {
  // API endpoint
  static const String _detectQtyUrl = "http://3.108.110.151:5001/detect-image-qty";

  Future<dynamic> scanBill(XFile image) async {
    final startTime = DateTime.now();
    print("🚀 [ScanBillService] Starting scan at: ${startTime.millisecondsSinceEpoch}");
    
    try {
      // Direct API call - no enrichment for speed
      final detectResponse = await _detectIngredientsAndQuantity(image);
      
      final endTime = DateTime.now();
      print("✅ [ScanBillService] Scan completed at: ${endTime.millisecondsSinceEpoch}");
      print("⏱️ [ScanBillService] Total scan time: ${endTime.difference(startTime).inMilliseconds}ms");
      
      return detectResponse;
    } catch (e) {
      final endTime = DateTime.now();
      print("❌ [ScanBillService] Scan failed at: ${endTime.millisecondsSinceEpoch}");
      print("⏱️ [ScanBillService] Failed after: ${endTime.difference(startTime).inMilliseconds}ms");
      throw Exception("Scan failed: $e");
    }
  }

  Future<Map<String, dynamic>> _detectIngredientsAndQuantity(XFile image) async {
    final apiStartTime = DateTime.now();
    print("🌐 [API] Starting request to: $_detectQtyUrl at: ${apiStartTime.millisecondsSinceEpoch}");
    
    var request = http.MultipartRequest("POST", Uri.parse(_detectQtyUrl));
    request.files.add(await http.MultipartFile.fromPath("image", image.path));

    var response = await request.send();
    var body = await response.stream.bytesToString();

    final apiEndTime = DateTime.now();
    print("📌 DETECT-QTY API RESPONSE received at: ${apiEndTime.millisecondsSinceEpoch}");
    print("⏱️ [API] API call time: ${apiEndTime.difference(apiStartTime).inMilliseconds}ms");
    print(body);

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(body);
      print("✅ [API] JSON parsed successfully");
      
      // Add image URLs to ingredients for instant display
      if (parsedData is Map && parsedData.containsKey("ingredients_with_quantity")) {
        final ingredients = parsedData["ingredients_with_quantity"] as List;
        final enrichedIngredients = <Map<String, dynamic>>[];
        
        for (var ingredient in ingredients) {
          if (ingredient is Map) {
            final itemName = ingredient["item"]?.toString() ?? "";
            if (itemName.isNotEmpty) {
              // Get image URL for this ingredient
              final imageUrl = await _getImageUrlForIngredient(itemName);
              
              // Create enriched ingredient with image URL
              final enrichedIngredient = Map<String, dynamic>.from(ingredient);
              if (imageUrl != null && imageUrl.isNotEmpty) {
                enrichedIngredient["image_url"] = imageUrl;
                print("🖼️ [API] Added image URL for $itemName: $imageUrl");
              }
              enrichedIngredients.add(enrichedIngredient.cast<String, dynamic>());
            } else {
                enrichedIngredients.add(Map<String, dynamic>.from(ingredient.cast<dynamic, dynamic>()));
            }
          }
        }
        
        // Update the parsed data with enriched ingredients
        parsedData["ingredients_with_quantity"] = enrichedIngredients;
        print("✅ [API] Enriched ${enrichedIngredients.length} ingredients with image URLs");
      }
      
      return parsedData;
    } else {
      throw Exception("Ingredient detection failed: ${response.statusCode} → $body");
    }
  }
  
  // Helper method to get image URL for an ingredient
  Future<String> _getImageUrlForIngredient(String itemName) async {
    try {
      const String metricsUrl = "http://3.108.110.151:5001/metrices";
      
      var request = http.MultipartRequest("POST", Uri.parse(metricsUrl));
      request.fields['item'] = itemName;

      var response = await request.send();
      var body = await response.stream.bytesToString();

      // Even if status is 400, the response body might contain the image URL
      if (response.statusCode == 200 || response.statusCode == 400) {
        try {
          final decodedBody = jsonDecode(body);
          if (decodedBody is Map) {
            final imageUrl = decodedBody["image_url"]?.toString() ?? decodedBody["imageURL"]?.toString() ?? "";
            return imageUrl;
          }
        } catch (e) {
          // If JSON parsing fails, try to extract image_url with regex
          final regex = RegExp(r'"image_url":\s*"([^"]+)"');
          final match = regex.firstMatch(body);
          if (match != null) {
            return match.group(1) ?? "";
          }
        }
      }
    } catch (e) {
      print("⚠️ [API] Failed to get image URL for $itemName: $e");
    }
    
    return "";
  }
}
