import 'dart:convert';
import 'package:jura/services/protected_api.dart';
import 'package:jura/models/transaction.dart';
import 'package:jura/models/api_response.dart';

class TransactionService {
  static const String _baseUrl = 'http://localhost:8080/api/v1';
  
  final ProtectedApiClient _apiClient;

  TransactionService({
    ProtectedApiClient? apiClient,
  }) : _apiClient = apiClient ?? ProtectedApiClient();

  // ProtectedApiClient attaches tokens and handles refresh.

  Future<List<Transaction>> fetchTransactions() async {
    try {
      final response = await _apiClient.get(
        Uri.parse('$_baseUrl/transactions'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = 
            json.decode(response.body) as Map<String, dynamic>;
        
        final apiResponse = ApiResponse<List<Transaction>>.fromJson(
          jsonResponse,
          (data) {
            if (data is List) {
              return data
                  .cast<Map<String, dynamic>>()
                  .map((json) => Transaction.fromJson(json))
                  .toList();
            }
            throw Exception('Invalid data format');
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message ?? 'Failed to load transactions');
        }
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized');
      } else if (response.statusCode == 403) {
        throw UnauthorizedException('Access denied');
      } else {
        try {
          final errorResponse = ErrorResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );
          throw Exception(errorResponse.displayMessage);
        } catch (e) {
          throw Exception('Failed to load transactions: ${response.statusCode}');
        }
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  Future<Transaction> createTransaction({
    required String type,
    required double amount,
    required String currency,
    required DateTime date,
    String? category,
    String? subcategory,
    String notes = '',
    String paymentMethod = 'cash',
  }) async {
    try {
      final body = json.encode({
        'type': type,
        'amount': amount,
        'currency': currency,
        'date': date.toIso8601String(),
        'category': category,
        'subcategory': subcategory,
        'notes': notes,
        'payment_method': paymentMethod,
      });
      final response = await _apiClient.post(
        Uri.parse('$_baseUrl/transactions'),
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
            json.decode(response.body) as Map<String, dynamic>;

        final apiResponse = ApiResponse<Transaction>.fromJson(
          jsonResponse,
          (data) => Transaction.fromJson(data as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message ?? 'Failed to create transaction');
        }
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized');
      } else {
        try {
          final errorResponse = ErrorResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );
          throw Exception(errorResponse.displayMessage);
        } catch (e) {
          throw Exception('Failed to create transaction: ${response.statusCode}');
        }
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw Exception('Error creating transaction: $e');
    }
  }

  Future<Transaction> updateTransaction({
    required String transactionId,
    required String type,
    required double amount,
    required String currency,
    required DateTime date,
    String? category,
    String? subcategory,
    String notes = '',
    String paymentMethod = 'cash',
  }) async {
    try {
      final body = json.encode({
        'type': type,
        'amount': amount,
        'currency': currency,
        'date': date.toIso8601String(),
        'category': category,
        'subcategory': subcategory,
        'notes': notes,
        'payment_method': paymentMethod,
      });
      final response = await _apiClient.put(
        Uri.parse('$_baseUrl/transactions/$transactionId'),
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
            json.decode(response.body) as Map<String, dynamic>;

        final apiResponse = ApiResponse<Transaction>.fromJson(
          jsonResponse,
          (data) => Transaction.fromJson(data as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message ?? 'Failed to update transaction');
        }
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized');
      } else {
        throw Exception('Failed to update transaction: ${response.statusCode}');
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw Exception('Error updating transaction: $e');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      final response = await _apiClient.delete(
        Uri.parse('$_baseUrl/transactions/$transactionId'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        if (response.statusCode == 401) {
          throw UnauthorizedException('Unauthorized');
        }
        throw Exception('Failed to delete transaction: ${response.statusCode}');
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw Exception('Error deleting transaction: $e');
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  
  @override
  String toString() => message;
}
