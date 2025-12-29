import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/api_response.dart'; // ensure User is imported correctly

class ApiService {
  static final String baseUrl = 'http://3.108.110.151:5001';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // =========================
  // INTERNAL REQUEST HANDLER
  // =========================
  static Future<ApiResponse<T>> _handleRequest<T>(
    Future<http.Response> request,
    T Function(Object? json) fromJsonT,
  ) async {
    try {
      final response = await request;

      final contentType = response.headers['content-type'] ?? '';

      // 🚨 CRITICAL CHECK
      if (!contentType.contains('application/json')) {
        return ApiResponse<T>(
          success: false,
          message: 'Server returned non-JSON response',
          data: null,
        );
      }

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>.fromJson(responseData, fromJsonT);
      } else {
        return ApiResponse<T>(
          success: false,
          message: responseData['message']?.toString() ?? 'An error occurred',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Connection error: $e',
        data: null,
      );
    }
  }

  // =========================
  // REGISTER USER
  // =========================
  static Future<ApiResponse<User>> registerUser({
    required String phone,
    required String name,
    required String email,
    required String password,
  }) {
    final url = Uri.parse('$baseUrl/register-user');

    return _handleRequest<User>(
      http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'phone': phone,
          'name': name,
          'email': email,
          'password': password,
        }),
      ),
      (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  // =========================
  // LOGIN USER
  // =========================
  static Future<ApiResponse<User>> loginUser({
    required String phone,
    required String password,
  }) {
    final url = Uri.parse('$baseUrl/login-user');

    return _handleRequest<User>(
      http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      ),
      (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }
}
