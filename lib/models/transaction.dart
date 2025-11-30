import 'package:jura/utils/formatters.dart';

/// Filter request for listing transactions
class ListTransactionRequest {
  final String? type;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? cursor;

  ListTransactionRequest({
    this.type,
    this.category,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.cursor,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (type != null) params['type'] = type;
    if (category != null) params['category'] = category;
    // Dates are converted to RFC3339/ISO8601 format for backend compatibility
    if (startDate != null) params['start_date'] = startDate!.toIso8601String();
    if (endDate != null) params['end_date'] = endDate!.toIso8601String();
    if (minAmount != null) params['min_amount'] = minAmount;
    if (maxAmount != null) params['max_amount'] = maxAmount;
    if (cursor != null) params['cursor'] = cursor;

    return params;
  }

  String get queryString {
    final params = toQueryParams();
    if (params.isEmpty) return '';

    // URL-encode each parameter to safely transmit dates and other values
    final entries = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
    return entries.isNotEmpty ? '?$entries' : '';
  }

  @override
  String toString() {
    return 'ListTransactionRequest{type: $type, category: $category, startDate: $startDate, endDate: $endDate, minAmount: $minAmount, maxAmount: $maxAmount, cursor: $cursor}';
  }
}

/// Request payload for creating a new transaction
class CreateTransaction {
  final String type;
  final double amount;
  final String currency;
  final DateTime date;
  final String? category;
  final String notes;
  final String paymentMethod;

  CreateTransaction({
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    this.category,
    required this.notes,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'amount': amount,
    'currency': currency,
    'date': date.toIso8601String(),
    'category': category,
    'notes': notes,
    'payment_method': paymentMethod,
  };

  @override
  String toString() {
    return 'CreateTransaction{type: $type, amount: $amount, currency: $currency, date: $date, category: $category, notes: $notes, paymentMethod: $paymentMethod}';
  }
}

/// Response from the transaction endpoint

class Transaction {
  final String id;
  final String type;
  final double amount;
  final String currency;
  final DateTime date;
  final String? category;
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
    this.category,
    required this.notes,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String?,
      notes: json['notes'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
    'currency': currency,
    'date': date.toIso8601String(),
    'category': category,
    'notes': notes,
    'payment_method': paymentMethod,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

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
  final String? nextCursor;

  TransactionResponse({
    required this.transactions,
    required this.incomeSummary,
    required this.expenseSummary,
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
      nextCursor: json['next_cursor'] as String?,
    );
  }

  bool get hasMoreData => nextCursor != null;
}
