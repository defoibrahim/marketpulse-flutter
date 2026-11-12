import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/utils/extensions.dart';

void main() {
  group('formatAsCurrency', () {
    test('uses two decimals from one dollar up', () {
      expect(43250.2.formatAsCurrency(), r'$43,250.20');
      expect(98.2.formatAsCurrency(), r'$98.20');
      expect(1.formatAsCurrency(), r'$1.00');
    });

    test('uses four decimals below one dollar', () {
      expect(0.5199.formatAsCurrency(), r'$0.5199');
      expect(0.0823.formatAsCurrency(), r'$0.0823');
    });

    test('formats negative values by magnitude, not as small numbers', () {
      expect((-1.2).formatAsCurrency(), r'-$1.20');
      expect((-2500).formatAsCurrency(), r'-$2,500.00');
      expect((-0.0092).formatAsCurrency(), r'-$0.0092');
    });

    test('formats zero with two decimals', () {
      expect(0.formatAsCurrency(), r'$0.00');
    });
  });

  test('formatAsSignedCurrency adds a plus sign to gains only', () {
    expect(804.formatAsSignedCurrency(), r'+$804.00');
    expect((-32.21).formatAsSignedCurrency(), r'-$32.21');
    expect(0.formatAsSignedCurrency(), r'$0.00');
  });

  test('formatAsPercentage always shows the sign', () {
    expect(2.5.formatAsPercentage(), '+2.50%');
    expect((-1.2).formatAsPercentage(), '-1.20%');
    expect(0.formatAsPercentage(), '+0.00%');
    expect(1234.5.formatAsPercentage(), '+1,234.50%');
  });

  group('formatCompact', () {
    test('abbreviates large values', () {
      expect(2.5e12.formatCompact(), r'$2.50T');
      expect(8.5e10.formatCompact(), r'$85.00B');
      expect(1.25e9.formatCompact(), r'$1.25B');
      expect(4.5e6.formatCompact(), r'$4.50M');
      expect(1500.formatCompact(), r'$1.50K');
    });

    test('keeps the sign of negative values', () {
      expect((-1.25e6).formatCompact(), r'-$1.25M');
    });

    test('falls back to currency below a thousand', () {
      expect(950.formatCompact(), r'$950.00');
      expect(0.0823.formatCompact(), r'$0.0823');
      expect((-12.5).formatCompact(), r'-$12.50');
    });
  });

  test('formatQuantity drops trailing zeros', () {
    expect(0.5.formatQuantity(), '0.5');
    expect(4000.formatQuantity(), '4,000');
    expect(5.0.formatQuantity(), '5');
    expect(0.00012345.formatQuantity(), '0.00012345');
  });
}
