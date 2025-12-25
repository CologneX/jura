import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jura/core/utils/api_config.dart';
import 'package:jura/core/utils/storage_keys.dart';
import 'package:jura/core/models/user.dart';
import 'package:jura/core/models/api_response.dart';

class LoginService {
  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  LoginService({
    required http.Client httpClient,
    required FlutterSecureStorage secureStorage,
  }) : _httpClient = httpClient,
       _secureStorage = secureStorage;

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

  Future<LoginResponse> login({
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
            json.decode(response.body) as Map<String, dynamic>;

        final apiResponse = ApiResponse<LoginResponse>.fromJson(
          jsonResponse,
          (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          final loginResponse = apiResponse.data!;

          // Store tokens in secure storage
          await _storeTokens(loginResponse);

          return loginResponse;
        } else {
          throw Exception(apiResponse.message ?? 'Login failed');
        }
      } else {
        final errorResponse = ErrorResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
        throw Exception(errorResponse.displayMessage);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _storeTokens(LoginResponse loginResponse) async {
    await _secureStorage.write(
      key: storageKeyAccessToken,
      value: loginResponse.accessToken,
    );
    await _secureStorage.write(
      key: storageKeyRefreshToken,
      value: loginResponse.refreshToken,
    );
    await _secureStorage.write(
      key: storageKeyUserId,
      value: loginResponse.user.id,
    );
    await _secureStorage.write(
      key: storageKeyUsername,
      value: loginResponse.user.username,
    );
    await _secureStorage.write(
      key: storageKeyPrimaryCurrency,
      value: loginResponse.user.primaryCurrency,
    );
    await _secureStorage.write(
      key: storageKeyIsPremium,
      value: loginResponse.user.isPremium.toString(),
    );
  }
}
