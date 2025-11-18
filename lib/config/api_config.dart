import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static late String _baseUrl;

  /// Initialize the API configuration by loading the base URL from environment variables
  static void initialize() {
    final endpoint = dotenv.env['ENDPOINT_URL'];
    if (endpoint == null || endpoint.isEmpty) {
      throw Exception('ENDPOINT_URL not found in .env file');
    }
    _baseUrl = '$endpoint/api/v1';
  }

  /// Get the base URL for API requests
  static String get baseUrl => _baseUrl;
}
