import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiImageService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _modelName = 'gemini-2.5-flash-image';
  // Only API key from environment
  
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(seconds: 2); // Rate limiting

  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('Gemini Image Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize Gemini Image Service: $e');
      }
      rethrow;
    }
  }

  static Future<void> _waitForRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        if (kDebugMode) {
          print('Rate limiting: waiting ${waitTime.inMilliseconds}ms');
        }
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  static Future<Uint8List?> generateIngredientImage(String ingredientName) async {
    try {
      // Apply rate limiting
      await _waitForRateLimit();
      
      final url = '$_baseUrl/models/$_modelName:generateContent?key=${dotenv.env['GEMINI_API_KEY'] ?? ''}';
      
      final prompt = '''
Generate a high-quality, realistic, appetizing image of the ingredient: "$ingredientName". 

Requirements:
- Make it look like a professional food photography shot
- Use natural lighting
- Show the ingredient in its fresh, natural state
- Clean, simple background (white or light gray)
- High resolution, detailed
- Make it look delicious and appealing
- No watermarks or text
- Focus solely on the ingredient itself

Return only the image without any additional elements.
''';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 1,
            'maxOutputTokens': 8192,
          }
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Extract the base64 image data from Gemini response
        if (responseData['candidates'] != null && 
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final parts = responseData['candidates'][0]['content']['parts'];
          for (final part in parts) {
            if (part['inlineData'] != null && 
                part['inlineData']['data'] != null) {
              
              final base64Data = part['inlineData']['data'] as String;
              return base64.decode(base64Data);
            }
          }
        }
        
        if (kDebugMode) {
          print('No image data found in Gemini response');
          print('Response: $responseData');
        }
        return null;
      } else {
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating ingredient image: $e');
      }
      rethrow;
    }
  }

  static Future<String?> generateImageFromText(String ingredientName) async {
    try {
      final imageData = await generateIngredientImage(ingredientName);
      if (imageData != null) {
        // For now, return a placeholder URL. In a real implementation,
        // you would save this image to local storage or a cloud service
        return 'data:image/png;base64,${base64.encode(imageData)}';
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error in generateImageFromText: $e');
      }
      return null;
    }
  }
}
