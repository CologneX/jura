import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:jura/models/transaction.dart';

class GeminiService {
  final Gemini _gemini = Gemini.instance;

  /// Parses transcribed text using Gemini API and returns a CreateTransaction object
  Future<CreateTransaction> parseTranscriptToTransaction(
    String transcript,
  ) async {
    if (transcript.isEmpty) {
      throw Exception('Transcript cannot be empty');
    }

    try {
      final prompt =
          '''You are an expert transaction parser. Your sole function is to extract structured financial data from the provided raw text transcript. Your output MUST be a single, valid JSON object that strictly adheres to the provided template. Do not include any text before or after the JSON.

Input Text: "$transcript"

Output Template:
{
  "type": "<string: transaction type, e.g., 'expense' or 'income'>",
  "amount": "<float: monetary value (e.g., 3.00)>",
  "currency": "<string: 3-letter currency code (e.g., 'USD')>",
  "category": "<string: high-level category>",
  "subcategory": "<string: specific subcategory, omit if not present>",
  "date": "<string: RFC3339 datetime, omit if not present>",
  "notes": "<string: detailed description, omit if not present>",
  "payment_method": "<string: method of payment, e.g., 'cash' or 'card', omit if not present>",
}

Return ONLY a valid JSON object matching this template. Ensure:
1. "id" is a valid UUID (or leave as placeholder)
2. "type" is either 'expense' or 'income'
3. "amount" is a positive number (float)
4. "currency" is a 3-letter code (default to 'USD' if not specified)
5. "date" is in RFC3339 format (e.g., 2023-10-05T14:48:00Z) or omitted
6. "category" should be one of: Food, Transport, Entertainment, Shopping, Bills, Other
8. All required fields must be present in the JSON

Return ONLY the JSON object, no additional text.''';

      final response = await _gemini.prompt(
        parts: [Part.text(prompt)],
        // model: 'gemini-flash',
        generationConfig: GenerationConfig(
          temperature: 0.2,
          maxOutputTokens: 800,
        ),
      );

      final responseText = response?.output;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('No response from Gemini API');
      }

      // Extract JSON from response (Gemini might include extra text)
      final jsonString = _extractJsonFromResponse(responseText);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate and create Transaction object
      final transaction = _parseJsonToTransaction(jsonData);

      print(transaction);

      return transaction;
    } catch (e) {
      throw Exception('Failed to parse transcript: $e');
    }
  }

  /// Extracts JSON from response text, handling cases where Gemini adds extra text
  String _extractJsonFromResponse(String response) {
    final trimmed = response.trim();

    // Try to find JSON object boundaries
    final startIndex = trimmed.indexOf('{');
    final endIndex = trimmed.lastIndexOf('}');

    if (startIndex == -1 || endIndex == -1 || startIndex > endIndex) {
      throw Exception('No valid JSON found in response');
    }

    return trimmed.substring(startIndex, endIndex + 1);
  }

  /// Parses JSON into a CreateTransaction object with validation
  CreateTransaction _parseJsonToTransaction(Map<String, dynamic> json) {
    try {
      // Validate type
      final type = (json['type'] as String?)?.toLowerCase() ?? 'expense';
      if (type != 'expense' && type != 'income') {
        throw Exception('Invalid transaction type: $type');
      }

      // Validate and parse amount
      final amountRaw = json['amount'];
      final amount = _parseAmount(amountRaw);
      if (amount <= 0) {
        throw Exception('Amount must be positive');
      }

      // Validate currency
      final currency = (json['currency'] as String?)?.toUpperCase() ?? 'USD';
      if (currency.length != 3) {
        throw Exception('Invalid currency code: $currency');
      }

      // Parse date - use current time if not provided, ensure RFC3339 format
      final date = json.containsKey('date') && json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now();

      // Parse optional fields
      final category = (json['category'] as String?) ?? 'Other';
      final subcategory = (json['subcategory'] as String?);
      final notes = (json['notes'] as String?) ?? '';
      final paymentMethod = (json['payment_method'] as String?) ?? 'cash';

      return CreateTransaction(
        type: type,
        amount: amount,
        currency: currency,
        category: category,
        subcategory: subcategory,
        date: date.toUtc(),
        notes: notes,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      throw Exception('Failed to parse transaction data: $e');
    }
  }

  /// Safely parse amount from various formats
  double _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        throw Exception('Cannot parse amount: $value');
      }
    }
    throw Exception('Invalid amount type: ${value.runtimeType}');
  }
}
