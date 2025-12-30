import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PantryAddService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://3.108.110.151:5001",
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  // 🔹 USE CASE 1: Process scanned bill
  Future<Map<String, dynamic>> processRawText(String rawText) async {
    final response = await _dio.post(
      "/pantry/add",
      data: {
        "raw_text": rawText,
      },
    );
    return response.data;
  }

  // 🔹 USE CASE 2: Save / Update pantry items
  // In pantry_add_service.dart, update the saveToPantry method:
Future<bool> saveToPantry(
  List<Map<String, dynamic>> items, {
  bool isUpdate = false,
}) async {
  try {
    debugPrint("📤 Sending to server: ${items.length} items");
    
    final response = await _dio.post(
      "/pantry/add",
      data: {
        "ingredients_with_quantity": items.map((item) {
          debugPrint("📦 Item being sent: $item");
          return {
            'name': item['name']?.toString() ?? '',
            'quantity': (item['quantity'] as num?)?.toDouble() ?? 1.0,
            'unit': item['unit']?.toString() ?? 'pcs',
            'is_update': isUpdate,
          };
        }).toList(),
      },
    );

    debugPrint("✅ Server response: ${response.statusCode} - ${response.data}");
    return response.statusCode == 200;
  } on DioException catch (e) {
    debugPrint("❌ Dio error: ${e.message}");
    if (e.response != null) {
      debugPrint("❌ Response data: ${e.response?.data}");
      debugPrint("❌ Status code: ${e.response?.statusCode}");
    }
    return false;
  } catch (e) {
    debugPrint("❌ Unexpected error: $e");
    return false;
  }
}
}
