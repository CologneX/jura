import 'package:flutter/foundation.dart';
import 'package:jura/core/models/transaction.dart';
import 'package:jura/core/services/user_service.dart';
import 'journal_service.dart';

/// Journal States
abstract class JournalState {
  const JournalState();
}

class JournalInitial extends JournalState {}

class JournalLoading extends JournalState {}

class JournalLoaded extends JournalState {
  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpenses;
  final String currency;
  final String? nextCursor;
  final ListTransactionRequest? currentFilter;

  const JournalLoaded({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpenses,
    required this.currency,
    this.nextCursor,
    this.currentFilter,
  });

  bool get hasMoreData => nextCursor != null;
}

class JournalLoadingMore extends JournalState {
  final List<Transaction> existingTransactions;
  final double totalIncome;
  final double totalExpenses;
  final String currency;

  const JournalLoadingMore({
    required this.existingTransactions,
    required this.totalIncome,
    required this.totalExpenses,
    required this.currency,
  });
}

class JournalError extends JournalState {
  final String message;

  const JournalError({required this.message});
}

class JournalViewModel extends ChangeNotifier {
  final JournalService _service;
  final UserService _userService;

  JournalViewModel(this._service, this._userService);

  JournalState _state = JournalInitial();
  JournalState get state => _state;

  void _updateState(JournalState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadTransactions({ListTransactionRequest? filter}) async {
    _updateState(JournalLoading());

    try {
      final user = _userService.currentUser;
      if (user == null) {
        _updateState(const JournalError(message: 'User not found'));
        return;
      }

      final response = await _service.getTransactions(filter: filter);

      _updateState(
        JournalLoaded(
          transactions: response.transactions,
          totalIncome: response.incomeSummary,
          totalExpenses: response.expenseSummary,
          currency: user.primaryCurrency,
          nextCursor: response.nextCursor,
          currentFilter: filter,
        ),
      );
    } catch (e) {
      _updateState(JournalError(message: e.toString()));
    }
  }

  Future<void> loadMoreTransactions() async {
    final currentState = _state;
    if (currentState is! JournalLoaded || !currentState.hasMoreData) {
      return;
    }

    _updateState(
      JournalLoadingMore(
        existingTransactions: currentState.transactions,
        totalIncome: currentState.totalIncome,
        totalExpenses: currentState.totalExpenses,
        currency: currentState.currency,
      ),
    );

    try {
      // Create a new filter with the cursor, preserving existing filter criteria
      final filter = ListTransactionRequest(
        type: currentState.currentFilter?.type,
        category: currentState.currentFilter?.category,
        notes: currentState.currentFilter?.notes,
        startDate: currentState.currentFilter?.startDate,
        endDate: currentState.currentFilter?.endDate,
        minAmount: currentState.currentFilter?.minAmount,
        maxAmount: currentState.currentFilter?.maxAmount,
        cursor: currentState.nextCursor,
        limit: currentState.currentFilter?.limit,
        offset: currentState.currentFilter?.offset,
      );

      final response = await _service.getTransactions(filter: filter);

      final allTransactions = [
        ...currentState.transactions,
        ...response.transactions,
      ];

      _updateState(
        JournalLoaded(
          transactions: allTransactions,
          totalIncome: response.incomeSummary,
          totalExpenses: response.expenseSummary,
          currency: currentState.currency,
          nextCursor: response.nextCursor,
          currentFilter: currentState.currentFilter,
        ),
      );
    } catch (e) {
      _updateState(JournalError(message: e.toString()));
    }
  }

  Future<void> createTransaction(CreateTransaction transaction) async {
    final previousState = _state;
    final filter = previousState is JournalLoaded
        ? previousState.currentFilter
        : null;
    try {
      await _service.createTransaction(transaction);
      await _reloadTransactionsAfterMutation(filter: filter);
    } catch (e) {
      // Keep the current journal content as-is and let the caller decide how to
      // surface the error (e.g. showAppToast in the bottom sheet).
      _state = previousState;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _reloadTransactionsAfterMutation({
    ListTransactionRequest? filter,
  }) async {
    final user = _userService.currentUser;
    if (user == null) {
      throw Exception('User not found');
    }

    final response = await _service.getTransactions(filter: filter);

    _updateState(
      JournalLoaded(
        transactions: response.transactions,
        totalIncome: response.incomeSummary,
        totalExpenses: response.expenseSummary,
        currency: user.primaryCurrency,
        nextCursor: response.nextCursor,
        currentFilter: filter,
      ),
    );
  }

  Future<void> refresh() async {
    final currentState = _state;
    if (currentState is JournalLoaded) {
      await loadTransactions(filter: currentState.currentFilter);
    } else {
      await loadTransactions();
    }
  }
}
