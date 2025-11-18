import 'package:jura/utils/formatters.dart';

/// Request payload for creating a new transaction
class CreateTransaction {
  final String type;
  final double amount;
  final String currency;
  final DateTime date;
  final String? category;
  final String? subcategory;
  final String notes;
  final String paymentMethod;

  CreateTransaction({
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    this.category,
    this.subcategory,
    required this.notes,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'amount': amount,
    'currency': currency,
    'date': date.toIso8601String(),
    'category': category,
    'subcategory': subcategory,
    'notes': notes,
    'payment_method': paymentMethod,
  };

  @override
  String toString() {
    return 'CreateTransaction{type: $type, amount: $amount, currency: $currency, date: $date, category: $category, subcategory: $subcategory, notes: $notes, paymentMethod: $paymentMethod}';
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
  final String? subcategory;
  final String notes;
  final String paymentMethod;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    this.category,
    this.subcategory,
    required this.notes,
    required this.paymentMethod,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      notes: json['notes'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'cash',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
    'currency': currency,
    'date': date.toIso8601String(),
    'category': category,
    'subcategory': subcategory,
    'notes': notes,
    'payment_method': paymentMethod,
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
    return 'Transaction{id: $id, type: $type, amount: $amount, currency: $currency, date: $date, category: $category, subcategory: $subcategory, notes: $notes, paymentMethod: $paymentMethod}';
  }
}
