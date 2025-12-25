import 'package:jura/core/models/ai.dart';
import 'package:jura/core/models/transaction.dart';
import 'package:jura/core/services/transaction_service.dart';

class ChatService {
  final TransactionService _transactionService;

  ChatService({required TransactionService transactionService})
    : _transactionService = transactionService;

  Future<AIResponse> processConversation(
    String message,
    List<Map<String, dynamic>> history,
  ) async {
    try {
      return await _transactionService.processConversation(message, history);
    } catch (e) {
      throw Exception('Failed to process conversation: $e');
    }
  }

  Future<TransactionResponse> fetchTransactions({
    ListTransactionRequest? filter,
  }) async {
    try {
      return await _transactionService.fetchTransactions(filter: filter);
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }
}
