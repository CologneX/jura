import 'package:flutter/material.dart';
import 'package:jura/models/transaction.dart';
import 'package:jura/services/transaction_service.dart';

class TransactionState extends ChangeNotifier {
  final TransactionService _transactionService;

  List<Transaction> _transactions = [];
  double _totalExpenses = 0.0;
  double _totalIncome = 0.0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String? _nextCursor;
  ListTransactionRequest? _currentFilter;

  TransactionState(this._transactionService);

  // Getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasError => _error != null;
  String? get nextCursor => _nextCursor;
  bool get hasMoreData => _nextCursor != null;
  ListTransactionRequest? get currentFilter => _currentFilter;

  double get totalExpenses => _totalExpenses;
  double get totalIncome => _totalIncome;

  Future<void> fetchTransactions({ListTransactionRequest? filter}) async {
    _isLoading = true;
    _error = null;
    _nextCursor = null;
    _transactions = [];
    _currentFilter = filter;
    notifyListeners();

    try {
      final response = await _transactionService.fetchTransactions(
        filter: filter,
      );
      _transactions = response.transactions;
      _nextCursor = response.nextCursor;
      _totalIncome = response.incomeSummary;
      _totalExpenses = response.expenseSummary;
      _error = null;
    } on UnauthorizedException catch (e) {
      _error = e.toString();
      _transactions = [];
      _nextCursor = null;
    } catch (e) {
      _error = e.toString();
      _transactions = [];
      _nextCursor = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreTransactions() async {
    if (_isLoadingMore || !hasMoreData) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final filterWithCursor = _currentFilter != null
          ? ListTransactionRequest(
              type: _currentFilter!.type,
              category: _currentFilter!.category,
              startDate: _currentFilter!.startDate,
              endDate: _currentFilter!.endDate,
              minAmount: _currentFilter!.minAmount,
              maxAmount: _currentFilter!.maxAmount,
              cursor: _nextCursor,
            )
          : ListTransactionRequest(cursor: _nextCursor);

      final response = await _transactionService.fetchTransactions(
        filter: filterWithCursor,
      );
      _transactions.addAll(response.transactions);
      _nextCursor = response.nextCursor;
      _error = null;
    } on UnauthorizedException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> createTransaction(CreateTransaction createTransaction) async {
    try {
      final transaction = await _transactionService.createTransaction(
        createTransaction,
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
