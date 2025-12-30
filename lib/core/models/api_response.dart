class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? token;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.token,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      token: json['token'] as String?,
    );
  }
}

// In api_response.dart
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? token;
  final String? password;  // Add this line

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.token,
    this.password,  // Add this to the constructor
  });

  // Add fromJson and toJson methods if they don't exist
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      token: json['token'],
      password: json['password'],  // Add this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'token': token,
      'password': password,  // Add this line
    };
  }
}