import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jura/core/utils/api_config.dart';
import 'package:jura/core/models/api_response.dart';

class RegisterService {
  final http.Client _httpClient;

  RegisterService({required http.Client httpClient}) : _httpClient = httpClient;

  Map<String, String> _getHeaders() {
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
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
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
