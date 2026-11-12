import 'package:intl/intl.dart';

final _currency2 =
    NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);
final _currency4 =
    NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 4);
final _percent = NumberFormat('+#,##0.00;-#,##0.00', 'en_US');
final _quantity = NumberFormat('#,##0.########', 'en_US');

/// Number formatting used across the app (US dollars, en_US separators).
extension NumberFormatting on num {
  /// `$43,250.20`, `-$1.20`, and four decimals below one dollar: `$0.5199`.
  String formatAsCurrency() {
    final value = toDouble();
    final magnitude = value.abs();
    final format = magnitude > 0 && magnitude < 1 ? _currency4 : _currency2;
    return format.format(value);
  }

  /// Like [formatAsCurrency] with an explicit sign: `+$804.00`, `-$32.21`.
  String formatAsSignedCurrency() =>
      this > 0 ? '+${formatAsCurrency()}' : formatAsCurrency();

  /// `+2.50%`, `-1.20%`, `+0.00%`.
  String formatAsPercentage() => '${_percent.format(this)}%';

  /// `$2.50T`, `$85.00B`, `-$1.25M`, `$950.00`, `$0.0823`.
  String formatCompact() {
    final value = toDouble();
    final magnitude = value.abs();
    final sign = value < 0 ? '-' : '';
    for (final (threshold, suffix) in const [
      (1e12, 'T'),
      (1e9, 'B'),
      (1e6, 'M'),
      (1e3, 'K'),
    ]) {
      if (magnitude >= threshold) {
        return '$sign\$${(magnitude / threshold).toStringAsFixed(2)}$suffix';
      }
    }
    return formatAsCurrency();
  }

  /// Coin amounts without trailing zeros: `0.5`, `4,000`, `0.00012345`.
  String formatQuantity() => _quantity.format(this);
}
