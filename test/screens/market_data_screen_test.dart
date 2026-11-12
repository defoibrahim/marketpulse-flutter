import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/core/failure.dart';
import 'package:marketpulse/providers/market_data_provider.dart';
import 'package:marketpulse/screens/market_data_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../helpers/fakes.dart';

void main() {
  late MockApiService api;
  late FakePriceFeed feed;
  late MarketDataProvider provider;

  setUp(() {
    api = MockApiService();
    feed = FakePriceFeed();
    provider = MarketDataProvider(apiService: api, priceFeed: feed);
    when(() => api.getMarketData())
        .thenAnswer((_) async => Right(sampleMarkets));
  });

  tearDown(() {
    provider.dispose();
    feed.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: MarketDataScreen())),
      ),
    );
    // First frame, then the post-frame load and its result.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the loaded markets', (tester) async {
    await pumpScreen(tester);

    expect(find.text('BTC/USD'), findsOneWidget);
    expect(find.text('SOL/USD'), findsOneWidget);
  });

  testWidgets('a search with no match shows the empty state', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'doge');
    await tester.pump();

    expect(find.text('No matches found'), findsOneWidget);
    expect(find.text('BTC/USD'), findsNothing);

    await tester.tap(find.text('Clear Search'));
    await tester.pump();

    expect(find.text('No matches found'), findsNothing);
    expect(find.text('BTC/USD'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('a failed refresh keeps the list and shows a banner',
      (tester) async {
    await pumpScreen(tester);
    when(() => api.getMarketData())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await provider.loadMarketData();
    await tester.pump();

    expect(find.text('BTC/USD'), findsOneWidget);
    expect(find.textContaining("Can't reach the server"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a failed first load shows the full error view',
      (tester) async {
    when(() => api.getMarketData())
        .thenAnswer((_) async => const Left(ServerFailure('Server down.')));

    await pumpScreen(tester);

    expect(find.text('Server down.'), findsOneWidget);
    expect(find.text('BTC/USD'), findsNothing);
  });
}
