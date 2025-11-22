import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jura/config/api_config.dart';
import 'package:jura/models/auth.dart';
import 'package:jura/models/api_response.dart';
import 'package:jura/services/protected_api.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthService extends ChangeNotifier {
  late final ProtectedApiClient apiClient; 
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  AuthService({http.Client? httpClient, FlutterSecureStorage? secureStorage})
    : _httpClient = httpClient ?? http.Client(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> init() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      if (accessToken != null && refreshToken != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      // Fallback on storage read error
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

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

  Future<void> register({
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

      final response = await _httpClient
          .post(
            Uri.parse('${ApiConfig.baseUrl}/users/register'),
            headers: _getHeaders(),
            body: body,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );
      if (response.statusCode != 201) {
        final errorResponse = ErrorResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
        throw Exception(errorResponse.displayMessage);
      }
      
      // Redirect to login with prefilled email could be handled here if needed
      // context.go('/login?email=$email');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final body = json.encode({'email': email, 'password': password});

      final response = await _httpClient
          .post(
            Uri.parse('${ApiConfig.baseUrl}/users/login'),
            headers: _getHeaders(),
            body: body,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode != 200) {
        final errorResponse = ErrorResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
        throw Exception(errorResponse.displayMessage);
      }

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
        _status = AuthStatus.authenticated;
        notifyListeners();
      } else {
        throw Exception(apiResponse.message ?? 'Login failed');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      _secureStorage.deleteAll();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      log('Error during logout: $e');
    }
  }
}
