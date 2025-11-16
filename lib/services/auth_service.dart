import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jura/models/auth.dart';
import 'package:jura/models/api_response.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:8080/api/v1';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  AuthService({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Map<String, String> _getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: accessToken),
        _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      ]);
    } catch (e) {
      throw Exception('Failed to save tokens: $e');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e) {
      print('Error retrieving access token: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      print('Error retrieving refresh token: $e');
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final body = json.encode({
        'name': name,
        'email': email,
        'password': password,
      });

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/users/register'),
        headers: _getHeaders(),
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
            json.decode(response.body) as Map<String, dynamic>;

        final apiResponse = ApiResponse<AuthResponse>.fromJson(
          jsonResponse,
          (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          await _saveTokens(
            accessToken: apiResponse.data!.accessToken,
            refreshToken: apiResponse.data!.refreshToken,
          );
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message ?? 'Registration failed');
        }
      } else {
        try {
          final errorResponse = ErrorResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );
          throw Exception(errorResponse.displayMessage);
        } catch (e) {
          throw Exception('Registration failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Error during registration: $e');
    }
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final body = json.encode({
        'email': email,
        'password': password,
      });

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/users/login'),
        headers: _getHeaders(),
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
            json.decode(response.body) as Map<String, dynamic>;

        final apiResponse = ApiResponse<LoginResponse>.fromJson(
          jsonResponse,
          (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          await _saveTokens(
            accessToken: apiResponse.data!.accessToken,
            refreshToken: apiResponse.data!.refreshToken,
          );
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message ?? 'Login failed');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Invalid email or password');
      } else {
        try {
          final errorResponse = ErrorResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );
          throw Exception(errorResponse.displayMessage);
        } catch (e) {
          throw Exception('Login failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  Future<void> logout() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
      ]);
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<void> clearTokens() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      print('Error clearing tokens: $e');
    }
  }
}
