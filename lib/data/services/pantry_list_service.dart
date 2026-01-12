import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PantryListService {
  // Updated to use the new API endpoint
  static const String _baseUrl = 'http://3.108.110.151:5001/pantry/list'; // Updated to new API

  /// Fetch all pantry items from remote server
  Future<List<Map<String, dynamic>>> fetchPantryItems() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded['status'] == true && decoded['data'] != null) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load pantry list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Remote pantry fetch failed: $e");
      // Fallback to local storage if remote fails
      return await _fetchPantryFromLocal();
    }
  }

  /// Fallback method to get pantry items from local SharedPreferences
  Future<List<Map<String, dynamic>>> _fetchPantryFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pantry_data');
      
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      debugPrint("❌ Local pantry fetch failed: $e");
      return [];
    }
  }
}
