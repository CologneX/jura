import 'package:intl/intl.dart';

/// Formats numeric amounts as currency strings using `intl`.
///
/// Usage:
/// ```dart
/// formatCurrency(12.5); // -> $12.50 (depending on locale)
/// formatCurrency(12.5, currencyCode: 'EUR'); // -> €12.50
/// ```
String formatCurrency(num? amount, {String? locale, String? currencyCode}) {
  if (amount == null) return '';
  try {
    // Determine whether the amount has fractional digits (considering floating point precision)
    final doubleValue = amount.toDouble();
    final isWhole = (doubleValue - doubleValue.truncate()).abs() < 0.0000001;
    final decimalDigits = isWhole ? 0 : 2;

    if (currencyCode != null && currencyCode.isNotEmpty) {
      final simple = NumberFormat.simpleCurrency(name: currencyCode);
      final symbol = simple.currencySymbol;
      final fmt = NumberFormat.currency(
        locale: locale,
        name: currencyCode,
        symbol: symbol,
        decimalDigits: decimalDigits,
      );
      return fmt.format(amount);
    }

    // Use locale-default currency symbol when currencyCode is not provided
    final fmt = NumberFormat.currency(
      locale: locale,
      decimalDigits: decimalDigits,
    );

    return fmt.format(amount);
  } catch (e) {
    // Fallback: omit decimals for whole numbers
    final doubleValue = amount.toDouble();
    final isWhole = (doubleValue - doubleValue.truncate()).abs() < 0.0000001;
    return isWhole ? doubleValue.toStringAsFixed(0) : doubleValue.toStringAsFixed(2);
  }
}
