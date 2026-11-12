import 'package:flutter/material.dart';

/// Start-up options read from the page URL of a demo web build, so the
/// screenshot workflow can open any screen directly:
/// `?tab=analytics&theme=light&symbol=BTC%2FUSD`.
@immutable
class LaunchOptions {
  const LaunchOptions({this.tab = 0, this.themeMode, this.symbol});

  /// From [uri]'s query: `tab` (market, analytics or portfolio), `theme`
  /// (light or dark) and `symbol` (a market to open, e.g. `BTC/USD`).
  /// Unknown values are ignored.
  factory LaunchOptions.fromUri(Uri uri) {
    final query = uri.queryParameters;
    const tabs = ['market', 'analytics', 'portfolio'];
    final tab = tabs.indexOf(query['tab'] ?? '');
    final symbol = query['symbol'];
    return LaunchOptions(
      tab: tab < 0 ? 0 : tab,
      themeMode: switch (query['theme']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => null,
      },
      symbol: symbol == null || symbol.isEmpty ? null : symbol,
    );
  }

  final int tab;
  final ThemeMode? themeMode;
  final String? symbol;
}
