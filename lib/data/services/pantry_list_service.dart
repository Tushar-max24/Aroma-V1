import 'dart:convert';
import 'package:http/http.dart' as http;

class PantryListService {
  static const String _baseUrl =
      'http://3.108.110.151:5001/pantry/list';

  /// Fetch all pantry items
  Future<List<Map<String, dynamic>>> fetchPantryItems() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded['status'] == true &&
            decoded['data'] != null) {
          // return only the list of items
          return List<Map<String, dynamic>>.from(
            decoded['data'],
          );
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Failed to load pantry list: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
