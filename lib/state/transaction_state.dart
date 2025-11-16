import 'package:flutter/material.dart';
import 'package:jura/models/transaction.dart';
import 'package:jura/services/transaction_service.dart';

class TransactionState extends ChangeNotifier {
  final TransactionService _transactionService;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  TransactionState(this._transactionService);

  // Getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  // Sorted getters
  List<Transaction> get transactionsSortedByDate {
    final sorted = [..._transactions];
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  double get totalExpenses {
    return _transactions
        .where((t) => t.type.toLowerCase() == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalIncome {
    return _transactions
        .where((t) => t.type.toLowerCase() == 'income')
        .fold(0, (sum, t) => sum + t.amount);
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _transactionService.fetchTransactions();
      _error = null;
    } on UnauthorizedException catch (e) {
      _error = e.toString();
      _transactions = [];
    } catch (e) {
      _error = e.toString();
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTransaction({
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
      final transaction = await _transactionService.createTransaction(
        type: type,
        amount: amount,
        currency: currency,
        date: date,
        category: category,
        subcategory: subcategory,
        notes: notes,
        paymentMethod: paymentMethod,
      );
      _transactions.add(transaction);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTransaction({
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
      final updatedTransaction = await _transactionService.updateTransaction(
        transactionId: transactionId,
        type: type,
        amount: amount,
        currency: currency,
        date: date,
        category: category,
        subcategory: subcategory,
        notes: notes,
        paymentMethod: paymentMethod,
      );
      
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _transactionService.deleteTransaction(transactionId);
      _transactions.removeWhere((t) => t.id == transactionId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
