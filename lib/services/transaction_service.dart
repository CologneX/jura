import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:jura/config/api_config.dart';
import 'package:jura/services/protected_api.dart';
import 'package:jura/models/transaction.dart';
import 'package:jura/models/api_response.dart';

class TransactionService {
  final ProtectedApiClient _apiClient = GetIt.instance<ProtectedApiClient>();

  Future<TransactionResponse> fetchTransactions({
    ListTransactionRequest? filter,
  }) async {
    try {
      final request = filter ?? ListTransactionRequest();
      final url = '${ApiConfig.baseUrl}/transactions${request.queryString}';

      final response = await _apiClient
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
            json.decode(response.body) as Map<String, dynamic>;

        final apiResponse = ApiResponse<TransactionResponse>.fromJson(
          jsonResponse,
          (data) => TransactionResponse.fromJson(data as Map<String, dynamic>),
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
          throw Exception(
            'Failed to load transactions: ${response.statusCode}',
          );
        }
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  Future<Transaction> createTransaction(
    CreateTransaction createTransaction,
  ) async {
    try {
      final body = json.encode(createTransaction.toJson());
      final response = await _apiClient
          .post(Uri.parse('${ApiConfig.baseUrl}/transactions'), body: body)
          .timeout(
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
          throw Exception(
            apiResponse.message ?? 'Failed to create transaction',
          );
        }
      } else {
        try {
          final errorResponse = ErrorResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );
          throw Exception(errorResponse.displayMessage);
        } catch (e) {
          throw Exception(
            'Failed to create transaction: ${response.statusCode}',
          );
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
        'notes': notes,
        'payment_method': paymentMethod,
      });
      final response = await _apiClient
          .put(
            Uri.parse('${ApiConfig.baseUrl}/transactions/$transactionId'),
            body: body,
          )
          .timeout(
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
          throw Exception(
            apiResponse.message ?? 'Failed to update transaction',
          );
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
      final response = await _apiClient
          .delete(Uri.parse('${ApiConfig.baseUrl}/transactions/$transactionId'))
          .timeout(
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

  Future<String> processTranscriptGemini(String transcript) async {
    try {
      final body = json.encode({'prompt': transcript});
      final response = await _apiClient
          .post(
            Uri.parse('${ApiConfig.baseUrl}/transactions/ai/process'),
            body: body,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception('Request timeout'),
          );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
            json.decode(response.body) as Map<String, dynamic>;

        // display the data
        final apiResponse = ApiResponse<String>.fromJson(
          jsonResponse,
          (data) => data as String,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(
            apiResponse.message ?? 'Failed to process transcript',
          );
        }
      } else {
        try {
          final errorResponse = ErrorResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );
          throw Exception(errorResponse.displayMessage);
        } catch (e) {
          throw Exception(
            'Failed to process transcript: ${response.statusCode}',
          );
        }
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw Exception('Error processing transcript: $e');
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => message;
}
