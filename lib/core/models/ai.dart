import 'package:jura/core/models/transaction.dart';

class FunctionCall {
  // {
  //     "name": "generate_transaction_parameter",
  //     "args": {
  //         "limit": 50
  //     }
  // }

  final String name;
  final Map<String, dynamic> args;

  FunctionCall({required this.name, required this.args});

  Map<String, dynamic> toJson() => {'name': name, 'args': args};
}

class AIMessagePart {
  // {
  //     "text": "List my last 50 transactions"
  // }

  final String? text;
  final FunctionCall? functionCall;
  final dynamic functionResponse;

  AIMessagePart({this.text, this.functionCall, this.functionResponse});

  Map<String, dynamic> toJson() => {
    if (text != null) 'text': text,
    if (functionCall != null) 'function_call': functionCall!.toJson(),
    if (functionResponse != null) 'function_response': functionResponse,
  };
}

class AIMessage {
  // "parts": [
  //     {
  //         "text": "List my last 50 transactions"
  //     }
  // ],
  // "role": "user"

  final String role;
  final List<AIMessagePart> parts;

  AIMessage({required this.role, required this.parts});

  Map<String, dynamic> toJson() => {
    'role': role,
    'parts': parts.map((p) => p.toJson()).toList(),
  };
}

class AIResponse {
  final String message;
  final ListTransactionRequest? transactionSearchParameters;
  final List<AIMessage> history;
  AIResponse({
    required this.message,
    this.transactionSearchParameters,
    required this.history,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    ListTransactionRequest? params;
    if (json['transaction_search_parameters'] != null) {
      final paramsJson =
          json['transaction_search_parameters'] as Map<String, dynamic>;

      double? toDouble(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString());
      }

      DateTime? toDate(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        return DateTime.tryParse(value.toString());
      }

      params = ListTransactionRequest(
        type: paramsJson['type'],
        category: TransactionCategory.fromString(paramsJson['category']),
        notes: paramsJson['notes'] as String?,
        startDate: toDate(paramsJson['start_date']),
        endDate: toDate(paramsJson['end_date']),
        minAmount: toDouble(paramsJson['min_amount']),
        maxAmount: toDouble(paramsJson['max_amount']),
        limit: paramsJson['limit'] as int?,
        offset: paramsJson['offset'] as int?,
      );
    }

    final historyJson = json['history'] as List<dynamic>? ?? [];
    final history = historyJson.map((item) {
      final itemMap = item as Map<String, dynamic>;
      final partsJson = itemMap['parts'] as List<dynamic>? ?? [];
      final parts = partsJson.map((partItem) {
        final partMap = partItem as Map<String, dynamic>;
        FunctionCall? functionCall;
        if (partMap['function_call'] != null) {
          final fcMap = partMap['function_call'] as Map<String, dynamic>;
          functionCall = FunctionCall(
            name: fcMap['name'] as String,
            args: fcMap['args'] as Map<String, dynamic>,
          );
        }
        return AIMessagePart(
          text: partMap['text'] as String?,
          functionCall: functionCall,
          functionResponse: partMap['function_response'],
        );
      }).toList();
      return AIMessage(role: itemMap['role'] as String, parts: parts);
    }).toList();

    return AIResponse(
      message: json['message'] as String,
      transactionSearchParameters: params,
      history: history,
    );
  }
}
