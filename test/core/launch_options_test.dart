import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/core/launch_options.dart';

void main() {
  test('reads the tab, theme and symbol from the query', () {
    final options = LaunchOptions.fromUri(
      Uri.parse('https://demo.test/?tab=analytics&theme=light&symbol=BTC%2FUSD'),
    );
    expect(options.tab, 1);
    expect(options.themeMode, ThemeMode.light);
    expect(options.symbol, 'BTC/USD');
  });

  test('falls back to the defaults for missing or unknown values', () {
    final options =
        LaunchOptions.fromUri(Uri.parse('https://demo.test/?tab=x&theme=y'));
    expect(options.tab, 0);
    expect(options.themeMode, isNull);
    expect(options.symbol, isNull);
  });
}
