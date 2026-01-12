import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class PantryAddService {
  // API endpoint
  static const String _detectQtyUrl = "http://3.108.110.151:5001/detect-image-qty";
  
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

  // 🔹 USE CASE 2: Process scanned bill text
  Future<Map<String, dynamic>> processRawText(String rawText) async {
    final response = await _dio.post(
      "/pantry/add",
      data: {
        "raw_text": rawText,
      },
    );
    return response.data;
  }

  // 🔹 USE CASE 3: Save / Update pantry items
  Future<bool> saveToPantry(
    List<Map<String, dynamic>> items, {
    bool isUpdate = false,
  }) async {
    try {
      debugPrint("📤 Sending to server: ${items.length} items");
      
      // Skip backend call since MongoDB storage is handled separately
      // Just log the items and return success
      for (var item in items) {
        debugPrint("📦 Item being sent: $item");
      }
      
      debugPrint("✅ Pantry items processed locally - MongoDB storage handled separately");
      return true;
    } catch (e) {
      debugPrint("❌ Unexpected error: $e");
      return false;
    }
  }
}
