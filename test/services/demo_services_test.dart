import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/core/failure.dart';
import 'package:marketpulse/services/demo/demo_api_service.dart';
import 'package:marketpulse/services/demo/demo_price_feed.dart';
import 'package:marketpulse/services/price_feed.dart';

/// Serves assets straight from the repository.
class FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();
}

class MissingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => throw FlutterError('missing $key');

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      throw FlutterError('missing $key');
}

T right<T>(Either<Failure, T> result) =>
    result.fold((failure) => throw TestFailure(failure.message), (v) => v);

void main() {
  group('DemoApiService', () {
    final api = DemoApiService(bundle: FileBundle());

    test('serves every endpoint from the bundled data', () async {
      final markets = right(await api.getMarketData());
      expect(markets, hasLength(10));
      expect(markets.first.symbol, 'BTC/USD');

      final overview = right(await api.getAnalyticsOverview());
      expect(overview.topGainer.symbol, 'SOL/USD');

      for (final timeframe in ['1h', '4h', '24h', '7d', '30d']) {
        expect(right(await api.getMarketTrends(timeframe: timeframe)).timeframe,
            timeframe);
        expect(
          right(await api.getPortfolioPerformance(timeframe: timeframe))
              .timeframe,
          timeframe,
        );
      }

      final portfolio = right(await api.getPortfolioOverview());
      final holdings = right(await api.getPortfolioHoldings());
      expect(portfolio.totalHoldings, holdings.length);
      expect(
        holdings.fold<double>(0, (sum, h) => sum + h.value),
        closeTo(portfolio.totalValue, 0.05),
      );
    });

    test('finds a single market, or reports an unknown one', () async {
      expect(right(await api.getMarketDataBySymbol('SOL/USD')).price, 98.2);
      final missing = await api.getMarketDataBySymbol('NOPE/USD');
      expect(missing.isLeft(), isTrue);
    });

    test('an unreadable asset is a failure, not a crash', () async {
      final result = await DemoApiService(bundle: MissingBundle()).getMarketData();
      result.fold(
        (failure) => expect(failure, isA<ParseFailure>()),
        (_) => fail('expected a failure'),
      );
    });
  });

  group('DemoPriceFeed', () {
    test('ticks known markets once connected, and stops on disconnect', () {
      fakeAsync((async) {
        final feed = DemoPriceFeed(bundle: FileBundle());
        final messages = <Map<String, dynamic>>[];
        feed.messages.listen(messages.add);

        feed.connect();
        expect(feed.status.value, ConnectionStatus.connecting);
        async.flushMicrotasks();
        expect(feed.status.value, ConnectionStatus.connected);

        async.elapse(const Duration(seconds: 3));
        expect(messages, hasLength(3));
        for (final message in messages) {
          expect(message['type'], 'market_update');
          final data = message['data'] as Map<String, dynamic>;
          expect(data['symbol'], endsWith('/USD'));
          expect(data['price'], isA<double>());
          expect(DateTime.tryParse(data['timestamp'] as String), isNotNull);
        }

        feed.disconnect();
        async.elapse(const Duration(seconds: 3));
        expect(messages, hasLength(3));
        expect(feed.status.value, ConnectionStatus.disconnected);
        feed.dispose();
      });
    });

    test('a quick off-and-on toggle starts a single ticker', () {
      fakeAsync((async) {
        final feed = DemoPriceFeed(bundle: FileBundle());
        var count = 0;
        feed.messages.listen((_) => count++);

        feed.connect();
        feed.disconnect();
        feed.connect();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));

        expect(count, 2);
        feed.dispose();
      });
    });
  });
}
