import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class PantryAddService {
  // API endpoints
  static const String _baseUrl = "http://3.108.110.151:5001";
  static const String _addPantryUrl = "$_baseUrl/pantry/add";
  static const String _detectQtyUrl = "$_baseUrl/detect-image-qty";
  
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _detectQtyUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  // 🔹 USE CASE 1: Scan pantry image for ingredient detection
  Future<Map<String, dynamic>> scanPantryImage(XFile image) async {
    try {
      debugPrint("📤 Scanning pantry image: ${image.path}");
      
      // Direct API call - no enrichment for speed
      final detectResponse = await _detectIngredientsAndQuantity(image);
      
      debugPrint("✅ Pantry scan successful: ${detectResponse}");
      return detectResponse;
    } catch (e) {
      debugPrint("❌ Pantry scan failed: $e");
      throw Exception("Failed to scan pantry image: $e");
    }
  }

  Future<Map<String, dynamic>> _detectIngredientsAndQuantity(XFile image) async {
    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: 'pantry_image.jpg'),
    });
    
    final response = await _dio.post(
      "",
      data: formData,
    );
    
    debugPrint("📌 DETECT-QTY API RESPONSE: ${response.data}");
    return response.data;
  }

  // 🔹 USE CASE 2: Process scanned bill text (same as add)
  Future<Map<String, dynamic>> processRawText(String rawText) async {
    return await addPantryItemsFromText(rawText);
  }

  // 🔹 USE CASE 3: Add pantry items using the correct API format
  Future<Map<String, dynamic>> addPantryItemsFromText(String rawText) async {
    try {
      debugPrint("📤 Adding pantry items from text...");
      
      final addPantryDio = Dio();
      final response = await addPantryDio.post(
        _addPantryUrl,
        data: {
          "raw_text": rawText,
        },
      );
      
      debugPrint("✅ Pantry items added: ${response.data}");
      return response.data;
    } catch (e) {
      debugPrint("❌ Error adding pantry items: $e");
      rethrow;
    }
  }

  // 🔹 USE CASE 4: Add individual pantry items (for scanned items)
  Future<Map<String, dynamic>> addIndividualPantryItems(List<Map<String, dynamic>> items) async {
    try {
      debugPrint("📤 Adding ${items.length} individual pantry items...");
      
      // Convert items to the format expected by the API
      final ingredientsWithQuantity = items.map((item) => {
        "item": item['name']?.toString() ?? '',
        "price": item['price']?.toDouble() ?? 0.0,
        "quantity": item['quantity']?.toInt() ?? 1,
      }).toList();
      
      // Create the request body in the correct format
      final requestBody = {
        "ingredients_with_quantity": ingredientsWithQuantity,
        "message": "Food items extracted successfully",
        "raw_text": jsonEncode({
          "ingredients_with_quantity": ingredientsWithQuantity,
          "message": "Extracted food items from scan",
          "status": true,
        }),
        "status": true,
      };
      
      debugPrint("📦 Request body: $requestBody");
      
      final addPantryDio = Dio();
      final response = await addPantryDio.post(
        _addPantryUrl,
        data: requestBody,
      );
      
      debugPrint("✅ Individual pantry items added: ${response.data}");
      return response.data;
    } catch (e) {
      debugPrint("❌ Error adding individual pantry items: $e");
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<bool> saveToPantry(
    List<Map<String, dynamic>> items, {
    bool isUpdate = false,
  }) async {
    try {
      final result = await addIndividualPantryItems(items);
      return result['status'] == true;
    } catch (e) {
      debugPrint("❌ Error in saveToPantry: $e");
      return false;
    }
  }
}
