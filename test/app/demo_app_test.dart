import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/core/launch_options.dart';
import 'package:marketpulse/main.dart';

void main() {
  testWidgets('demo mode runs the whole app on bundled data', (tester) async {
    await tester.pumpWidget(const MarketPulseApp(demoMode: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MarketPulse'), findsOneWidget);
    expect(find.text('BTC/USD'), findsWidgets);

    // Live prices: the simulated feed connects without a server.
    await tester.tap(find.text('OFF'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('LIVE'), findsOneWidget);

    // Switch it off again so no ticker outlives the test.
    await tester.tap(find.text('LIVE'));
    await tester.pump();
    expect(find.text('OFF'), findsOneWidget);
  });

  testWidgets('launch options open a tab, theme and market', (tester) async {
    await tester.pumpWidget(const MarketPulseApp(
      demoMode: true,
      launch: LaunchOptions(themeMode: ThemeMode.light, symbol: 'ETH/USD'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('About ETH'), findsOneWidget);
    final context = tester.element(find.text('About ETH'));
    expect(Theme.of(context).brightness, Brightness.light);
  });
}
