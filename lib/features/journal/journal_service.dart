import 'package:jura/core/models/transaction.dart';
import 'package:jura/core/services/transaction_service.dart';

class JournalService {
  final TransactionService _transactionService;

  JournalService({required TransactionService transactionService})
    : _transactionService = transactionService;

  Future<TransactionResponse> getTransactions({
    ListTransactionRequest? filter,
  }) async {
    return await _transactionService.fetchTransactions(filter: filter);
  }

  Future<void> createTransaction(CreateTransaction transaction) async {
    await _transactionService.createTransaction(transaction);
  }
}
