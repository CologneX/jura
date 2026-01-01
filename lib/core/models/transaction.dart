import 'package:jura/core/utils/formatters.dart';
// Category = // "Food", "Transport", "Entertainment", "Shopping", "Bills", "Other"

// Make Category enum
enum TransactionCategory {
  food,
  transport,
  entertainment,
  shopping,
  bills,
  other;

  /// Parse a string to TransactionCategory enum
  static TransactionCategory? fromString(String? value) {
    if (value == null) return null;
    final lowerValue = value.toLowerCase();
    return TransactionCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == lowerValue,
      orElse: () => TransactionCategory.other,
    );
  }
}

/// Filter request for listing transactions
class ListTransactionRequest {
  final String? type;
  final TransactionCategory? category;
  final String? notes;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? cursor;
  final int? limit;
  final int? offset;

  ListTransactionRequest({
    this.type,
    this.category,
    this.notes,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.cursor,
    this.limit,
    this.offset,
  });

  ListTransactionRequest copyWith({
    String? type,
    TransactionCategory? category,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? cursor,
    int? limit,
    int? offset,
  }) {
    return ListTransactionRequest(
      type: type ?? this.type,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      cursor: cursor ?? this.cursor,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (type != null) params['type'] = type;
    if (category != null) params['category'] = category!.name;
    if (notes != null) params['notes'] = notes;
    if (startDate != null) {
      params['start_date'] = startDate!.toUtc().toIso8601String();
    }
    if (endDate != null) {
      params['end_date'] = endDate!.toUtc().toIso8601String();
    }
    if (minAmount != null) params['min_amount'] = minAmount;
    if (maxAmount != null) params['max_amount'] = maxAmount;
    if (cursor != null) params['cursor'] = cursor;
    if (limit != null) params['limit'] = limit;
    if (offset != null) params['offset'] = offset;

    return params;
  }

  String get queryString {
    final params = toQueryParams();
    if (params.isEmpty) return '';

    final entries = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
    return entries.isNotEmpty ? '?$entries' : '';
  }
}

/// Request payload for creating a new transaction
class CreateTransaction {
  final String type;
  final double amount;
  final DateTime date;
  final String? category;
  final String currency;
  final String notes;
  final String paymentMethod;

  CreateTransaction({
    required this.type,
    required this.amount,
    required this.date,
    required this.currency,
    this.category,
    required this.notes,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'amount': amount,
    'date': date.toUtc().toIso8601String(),
    'category': category,
    'currency': currency,
    'notes': notes,
    'payment_method': paymentMethod,
  };

  @override
  String toString() {
    return 'CreateTransaction{type: $type, amount: $amount, date: $date, category: $category, notes: $notes, paymentMethod: $paymentMethod}';
  }
}

/// Response from the transaction endpoint
class Transaction {
  final String id;
  final String type;
  final double amount;
  final String currency;
  final DateTime date;
  final String category;
  final String notes;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    required this.notes,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: (json['amount']).toDouble(),
      currency: json['currency'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      notes: json['notes'] ?? '',
      paymentMethod: json['payment_method'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get formattedAmount => formatCurrency(amount, currencyCode: currency);
  String get formattedDate => _formatDate(date);
  String get displayType => type.toUpperCase();

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  String toString() {
    return 'Transaction{id: $id, type: $type, amount: $amount, currency: $currency, date: $date, category: $category, notes: $notes, paymentMethod: $paymentMethod, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}

/// Paginated response for transactions
class TransactionResponse {
  final List<Transaction> transactions;
  final double incomeSummary;
  final double expenseSummary;
  final String currency;
  final String? nextCursor;

  TransactionResponse({
    required this.transactions,
    required this.incomeSummary,
    required this.expenseSummary,
    required this.currency,
    this.nextCursor,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    final transactionsList = (json['transactions'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((t) => Transaction.fromJson(t))
        .toList();

    return TransactionResponse(
      transactions: transactionsList,
      incomeSummary: json['income_summary'].toDouble(),
      expenseSummary: json['expense_summary'].toDouble(),
      currency: json['currency'],
      nextCursor: json['next_cursor'] as String?,
    );
  }

  bool get hasMoreData => nextCursor != null;
}
