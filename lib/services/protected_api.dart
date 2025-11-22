import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jura/config/api_config.dart';
import 'package:jura/models/api_response.dart';
import 'package:jura/models/auth.dart';

/// A small protected API client which automatically:
/// - attaches `Authorization: Bearer {access_token}` to requests
/// - on 401 attempts to refresh tokens via `POST /api/v1/refresh-token` with
///   `Cookie: refresh_token={refresh}` header (refresh from secure storage)
/// - if refresh succeeds, stores new tokens and retries the original request
/// - if refresh fails (401), clears tokens and navigates to login page
class ProtectedApiClient {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final http.Client _inner;
  final FlutterSecureStorage _secureStorage;

  final VoidCallback onSessionExpired;

  ProtectedApiClient({
    required this.onSessionExpired,
    http.Client? inner,
    FlutterSecureStorage? storage,
  }) : _inner = inner ?? http.Client(),
       _secureStorage = storage ?? const FlutterSecureStorage();

  Future<Map<String, String>> _defaultHeaders({
    Map<String, String>? extra,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (extra != null) headers.addAll(extra);
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (!headers.containsKey('Content-Type')) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    return await _performRequest(
      () async =>
          await _inner.get(uri, headers: await _defaultHeaders(extra: headers)),
    );
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final bodyStr = body is String
        ? body
        : (body != null ? json.encode(body) : null);
    return await _performRequest(
      () async => await _inner.post(
        uri,
        headers: await _defaultHeaders(extra: headers),
        body: bodyStr,
      ),
    );
  }

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final bodyStr = body is String
        ? body
        : (body != null ? json.encode(body) : null);
    return await _performRequest(
      () async => await _inner.put(
        uri,
        headers: await _defaultHeaders(extra: headers),
        body: bodyStr,
      ),
    );
  }

  Future<http.Response> delete(Uri uri, {Map<String, String>? headers}) async {
    return await _performRequest(
      () async => await _inner.delete(
        uri,
        headers: await _defaultHeaders(extra: headers),
      ),
    );
  }

  // navigate to login page
  void _navigateToLogin() {
    onSessionExpired();
  }

  Future<bool> _refreshTokens() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) return false;
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/refresh-token');
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Cookie': 'refresh_token=$refreshToken',
      };
      final resp = await _inner
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        final Map<String, dynamic> jsonResp =
            json.decode(resp.body) as Map<String, dynamic>;
        final apiResp = ApiResponse<LoginResponse>.fromJson(
          jsonResp,
          (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
        );
        if (apiResp.success && apiResp.data != null) {
          final access = apiResp.data!.accessToken;
          final refresh = apiResp.data!.refreshToken;
          await Future.wait([
            _secureStorage.write(key: _accessTokenKey, value: access),
            _secureStorage.write(key: _refreshTokenKey, value: refresh),
          ]);
          return true;
        }
        return false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _clearTokens() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
      ]);
    } catch (_) {}
  }

  Future<http.Response> _performRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    http.Response response;
    try {
      response = await requestFn();
    } catch (e) {
      rethrow;
    }

    if (response.statusCode != 401) return response;

    // Got 401 - attempt refresh
    final refreshed = await _refreshTokens();
    if (!refreshed) {
      // refresh failed - navigate to login
      await _clearTokens();
      _navigateToLogin();
      return response; // original 401
    }

    // refresh succeeded - retry the original request once
    try {
      response = await requestFn();
      if (response.statusCode == 401) {
        // still unauthorized -> clear tokens and navigate
        await _clearTokens();
        _navigateToLogin();
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
