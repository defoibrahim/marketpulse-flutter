import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/core/theme/app_theme.dart';
import 'package:marketpulse/models/analytics_model.dart';
import 'package:marketpulse/models/market_data_model.dart';
import 'package:marketpulse/providers/market_data_provider.dart';
import 'package:marketpulse/widgets/analytics_widgets.dart';
import 'package:marketpulse/widgets/widgets.dart';

import '../helpers/fakes.dart';

Widget wrap(Widget child, {double textScale = 1, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.dark,
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('a market row reads as one labelled button', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(wrap(
      MarketDataListItem(
        data: market('BTC/USD', price: 43250.2, changePercent: 2.5),
        onTap: () {},
      ),
    ));

    expect(
      find.bySemanticsLabel(r'BTC/USD, $43,250.20, up 2.50 percent in 24 hours'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('sort chips announce the selected order', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(wrap(
      MarketSortChip(
        label: 'Price',
        isSelected: true,
        sortOrder: SortOrder.descending,
        onTap: () {},
      ),
    ));

    expect(
      find.bySemanticsLabel('Sort by Price, descending. Tap to reverse.'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('charts describe their values', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(wrap(
      const DominancePieChart(
        dominance: MarketDominance(btc: 42.5, eth: 28.3, others: 29.2),
      ),
    ));

    expect(
      find.bySemanticsLabel(
        'Market dominance: Bitcoin 42.5 percent, Ethereum 28.3 percent, '
        'others 29.2 percent',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the detail layout grows with large text instead of overflowing',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final data = MarketData.dummy;

    await tester.pumpWidget(wrap(
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MainPriceDisplay(data: data),
          MarketStatsGrid(data: data),
          AboutSection(data: data),
        ],
      ),
      textScale: 2,
    ));

    expect(tester.takeException(), isNull);
  });

  test('gain and loss colours differ per theme', () {
    expect(AppTheme.light.extension<MarketColors>(), MarketColors.light);
    expect(AppTheme.dark.extension<MarketColors>(), MarketColors.dark);
    expect(MarketColors.light.forChange(-1), MarketColors.light.loss);
    expect(MarketColors.light.forChange(0), MarketColors.light.gain);
  });

  test('thin pie slices get no label of their own', () {
    expect(sliceTitle(1.1), '');
    expect(sliceTitle(4.4), '4.4%');
  });
}
