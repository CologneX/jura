import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jura/config/api_config.dart';
import 'package:jura/config/storage_keys.dart';
import 'package:jura/models/auth.dart';
import 'package:jura/models/api_response.dart';
import 'package:jura/services/protected_api.dart';
import 'package:jura/services/user_service.dart';
import 'package:jura/main.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthService extends ChangeNotifier {
  late final ProtectedApiClient apiClient;

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  AuthService({http.Client? httpClient, FlutterSecureStorage? secureStorage})
    : _httpClient = httpClient ?? http.Client(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> init() async {
    try {
      final accessToken = await _secureStorage.read(key: storageKeyAccessToken);
      final refreshToken = await _secureStorage.read(key: storageKeyRefreshToken);

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

  Future<void> register({
    required String username,
    required String passcode,
  }) async {
    try {
      final body = json.encode({'username': username, 'passcode': passcode});

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
    required String username,
    required String passcode,
  }) async {
    try {
      final body = json.encode({'username': username, 'passcode': passcode});

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

      final apiResponse = ApiResponse<LoginResponse>.fromJson(
        json.decode(response.body),
        (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await apiResponse.data?.storeTokens();
        _status = AuthStatus.authenticated;
        notifyListeners();
        // Sync user data with UserService
        final userService = getIt<UserService>();
        await userService.setUser(apiResponse.data!.user);
      } else {
        throw Exception(apiResponse.message ?? 'Login failed');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: storageKeyAccessToken);
      await _secureStorage.delete(key: storageKeyRefreshToken);
      await _secureStorage.delete(key: storageKeyUserId);
      await _secureStorage.delete(key: storageKeyUsername);
      await _secureStorage.delete(key: storageKeyPrimaryCurrency);
      await _secureStorage.delete(key: storageKeyIsPremium);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      // Sync user data with UserService
      final userService = getIt<UserService>();
      await userService.clearUser();
    } catch (e) {
      log('Error during logout: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
}
