import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/core/failure.dart';
import 'package:marketpulse/models/market_data_model.dart';
import 'package:marketpulse/providers/market_data_provider.dart';
import 'package:marketpulse/services/api_service.dart';
import 'package:marketpulse/services/price_feed.dart';
import 'package:mocktail/mocktail.dart';

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

  group('loading', () {
    test('starts empty', () {
      expect(provider.isLoading, isFalse);
      expect(provider.hasLoaded, isFalse);
      expect(provider.marketData, isEmpty);
      expect(provider.error, isNull);
      expect(provider.sortOption, SortOption.price);
    });

    test('a successful load stores the data', () async {
      await provider.loadMarketData();

      expect(provider.isLoading, isFalse);
      expect(provider.hasLoaded, isTrue);
      expect(provider.marketData, hasLength(3));
      expect(provider.error, isNull);
    });

    test('a failed first load sets the error', () async {
      when(() => api.getMarketData())
          .thenAnswer((_) async => const Left(ServerFailure('Down')));

      await provider.loadMarketData();

      expect(provider.hasData, isFalse);
      expect(provider.error, 'Down');
    });

    test('a failed refresh keeps the data and reports the error', () async {
      await provider.loadMarketData();
      when(() => api.getMarketData())
          .thenAnswer((_) async => const Left(NetworkFailure()));

      await provider.loadMarketData();

      expect(provider.marketData, hasLength(3));
      expect(provider.error, const NetworkFailure().message);
    });

    test('concurrent loads share one request', () async {
      final completer = Completer<Result<List<MarketData>>>();
      when(() => api.getMarketData()).thenAnswer((_) => completer.future);

      final first = provider.loadMarketData();
      final second = provider.loadMarketData();
      completer.complete(Right(sampleMarkets));
      await Future.wait([first, second]);

      verify(() => api.getMarketData()).called(1);
    });

    test('does not wait on an artificial delay', () {
      fakeAsync((async) {
        provider.loadMarketData();
        async.flushMicrotasks();
        expect(provider.hasLoaded, isTrue);
      });
    });
  });

  group('search and sort', () {
    setUp(() => provider.loadMarketData());

    test('filters by symbol, case-insensitively', () {
      provider.setSearchQuery('btc');
      expect(provider.marketData.map((m) => m.symbol), ['BTC/USD']);
      expect(provider.isFiltering, isTrue);
    });

    test('a search with no match leaves an empty view but keeps the data', () {
      provider.setSearchQuery('doge');
      expect(provider.marketData, isEmpty);
      expect(provider.hasData, isTrue);
      expect(provider.isFiltering, isTrue);
    });

    test('sorts by price descending, then toggles to ascending', () {
      expect(provider.marketData.map((m) => m.symbol),
          ['BTC/USD', 'ETH/USD', 'SOL/USD']);
      provider.setSortOption(SortOption.price);
      expect(provider.sortOrder, SortOrder.ascending);
      expect(provider.marketData.map((m) => m.symbol),
          ['SOL/USD', 'ETH/USD', 'BTC/USD']);
    });

    test('sorts by change', () {
      provider.setSortOption(SortOption.change);
      expect(provider.marketData.map((m) => m.symbol),
          ['SOL/USD', 'BTC/USD', 'ETH/USD']);
    });

    test('reuses the computed view until something changes', () {
      final first = provider.marketData;
      expect(identical(provider.marketData, first), isTrue);
      provider.setSearchQuery('e');
      expect(identical(provider.marketData, first), isFalse);
    });
  });

  group('live prices', () {
    test('applies ticks to the matching market', () {
      fakeAsync((async) {
        provider.loadMarketData();
        async.flushMicrotasks();
        provider.enableRealTimeUpdates();

        feed.tick('ETH/USD', 3100);
        async.elapse(const Duration(milliseconds: 150));

        expect(provider.getBySymbol('ETH/USD')!.price, 3100);
        expect(provider.connectionStatus, ConnectionStatus.connected);
      });
    });

    test('throttles a steady stream of ticks instead of starving the UI', () {
      fakeAsync((async) {
        provider.loadMarketData();
        async.flushMicrotasks();
        provider.enableRealTimeUpdates();
        var notifications = 0;
        provider.addListener(() => notifications++);

        // A tick every 20ms for one second: a debounce would never fire.
        for (var i = 0; i < 50; i++) {
          feed.tick('BTC/USD', 50000.0 + i);
          async.elapse(const Duration(milliseconds: 20));
        }
        async.elapse(const Duration(milliseconds: 100));

        expect(notifications, inInclusiveRange(9, 11));
        expect(provider.getBySymbol('BTC/USD')!.price, 50049);
      });
    });

    test('ignores ticks for unknown symbols and other message types', () {
      fakeAsync((async) {
        provider.loadMarketData();
        async.flushMicrotasks();
        provider.enableRealTimeUpdates();
        var notifications = 0;
        provider.addListener(() => notifications++);

        feed.tick('DOGE/USD', 1);
        async.elapse(const Duration(milliseconds: 200));

        expect(notifications, 0);
      });
    });

    test('reports the connection state only while enabled', () {
      provider.enableRealTimeUpdates();
      feed.setStatus(ConnectionStatus.reconnecting);
      expect(provider.connectionStatus, ConnectionStatus.reconnecting);

      provider.disableRealTimeUpdates();
      expect(provider.connectionStatus, ConnectionStatus.disconnected);
      expect(feed.disconnectCalls, 1);
    });

    test('pauses in the background and resumes in the foreground', () async {
      provider.enableRealTimeUpdates();
      expect(feed.connectCalls, 1);

      provider.pauseRealTime();
      expect(feed.disconnectCalls, 1);
      expect(provider.isRealTimeEnabled, isTrue);

      provider.resumeRealTime();
      expect(feed.connectCalls, 2);
      await untilCalled(() => api.getMarketData());
    });

    test('stays disconnected on resume if live prices are off', () {
      provider.pauseRealTime();
      provider.resumeRealTime();
      expect(feed.connectCalls, 0);
    });
  });

  group('single market refresh', () {
    test('updates one market without the list loading state', () async {
      await provider.loadMarketData();
      final updated = market('BTC/USD', price: 51000);
      when(() => api.getMarketDataBySymbol('BTC/USD'))
          .thenAnswer((_) async => Right(updated));
      final loadingStates = <bool>[];
      provider.addListener(() => loadingStates.add(provider.isLoading));

      await provider.refreshSymbol('BTC/USD');

      expect(provider.getBySymbol('BTC/USD')!.price, 51000);
      expect(loadingStates, everyElement(isFalse));
      verify(() => api.getMarketData()).called(1);
    });

    test('loads a market that is not in the list yet', () async {
      when(() => api.getMarketDataBySymbol('ADA/USD'))
          .thenAnswer((_) async => Right(market('ADA/USD', price: 0.52)));

      await provider.refreshSymbol('ADA/USD');

      expect(provider.getBySymbol('ADA/USD')!.price, 0.52);
    });

    test('keeps a per-market error', () async {
      when(() => api.getMarketDataBySymbol('ADA/USD'))
          .thenAnswer((_) async => const Left(ServerFailure('Not found')));

      await provider.refreshSymbol('ADA/USD');

      expect(provider.errorFor('ADA/USD'), 'Not found');
      expect(provider.error, isNull);
      expect(provider.isRefreshing('ADA/USD'), isFalse);
    });
  });
}
