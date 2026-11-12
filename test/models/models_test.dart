import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/models/analytics_model.dart';
import 'package:marketpulse/models/market_data_model.dart';
import 'package:marketpulse/models/portfolio_model.dart';

import '../helpers/fakes.dart';

void main() {
  group('MarketData', () {
    final json = <String, dynamic>{
      'symbol': 'BTC/USD',
      'description': 'Bitcoin',
      'price': 43250.2,
      'change24h': 1055,
      'changePercent24h': '2.5',
      'volume': 1.25e9,
      'high24h': 44500,
      'low24h': 42000,
      'marketCap': 8.5e11,
      'lastUpdated': '2026-01-16T12:00:00Z',
    };

    test('parses numbers sent as ints, doubles or strings', () {
      final data = MarketData.fromJson(json);

      expect(data.price, 43250.2);
      expect(data.change24h, 1055.0);
      expect(data.changePercent24h, 2.5);
      expect(data.baseSymbol, 'BTC');
      expect(data.quoteSymbol, 'USD');
      expect(data.lastUpdated, DateTime.utc(2026, 1, 16, 12));
    });

    test('a missing description becomes empty', () {
      final data = MarketData.fromJson({...json}..remove('description'));
      expect(data.description, '');
    });

    test('a missing or malformed field throws a FormatException', () {
      expect(
        () => MarketData.fromJson({...json}..remove('price')),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('price'))),
      );
      expect(
        () => MarketData.fromJson({...json, 'lastUpdated': 'yesterday'}),
        throwsFormatException,
      );
    });

    test('a live update changes only the fields it carries', () {
      final base = market('BTC/USD', price: 100);
      final updated = MarketData.updateFromJson(base, const {
        'symbol': 'BTC/USD',
        'price': '110',
        'volume': 'not a number',
        'timestamp': 42,
      });

      expect(updated.price, 110);
      expect(updated.volume, base.volume);
      expect(updated.lastUpdated, base.lastUpdated);
      expect(updated.changePercent24h, base.changePercent24h);
    });

    test('a live update stretches the 24h range', () {
      final base = market('BTC/USD', price: 100);
      expect(
        MarketData.updateFromJson(base, const {'price': 200}).high24h,
        200,
      );
      expect(MarketData.updateFromJson(base, const {'price': 50}).low24h, 50);
      expect(
        MarketData.updateFromJson(base, const {'price': 101}).high24h,
        base.high24h,
      );
    });
  });

  group('AnalyticsOverview', () {
    test('parses nested movers and dominance', () {
      final overview = AnalyticsOverview.fromJson(const {
        'totalMarketCap': 2.5e12,
        'totalVolume24h': 8.5e10,
        'activeMarkets': 10,
        'topGainer': {'symbol': 'SOL/USD', 'change': 5.3, 'price': 98.2},
        'topLoser': {'symbol': 'ETH/USD', 'change': -1.2, 'price': 2651.97},
        'marketDominance': {'btc': 42.5, 'eth': 28.3, 'others': 29.2},
        'lastUpdated': '2026-01-16T12:00:00Z',
      });

      expect(overview.topLoser.change, -1.2);
      expect(overview.dominance.others, 29.2);
    });

    test('a missing nested object throws a FormatException', () {
      expect(
        () => AnalyticsOverview.fromJson(const {
          'totalMarketCap': 1,
          'totalVolume24h': 1,
          'activeMarkets': 1,
          'lastUpdated': '2026-01-16T12:00:00Z',
        }),
        throwsFormatException,
      );
    });
  });

  group('Portfolio', () {
    final holdingJson = <String, dynamic>{
      'id': '1',
      'symbol': 'BTC/USD',
      'quantity': '0.5',
      'averagePrice': 40000,
      'currentPrice': 43250.2,
      'value': 21625.1,
      'pnl': 1625.1,
      'pnlPercent': 8.13,
      'allocation': 45.2,
      'lastUpdated': '2026-01-16T12:00:00Z',
    };

    test('parses string quantities', () {
      expect(PortfolioHolding.fromJson(holdingJson).quantity, 0.5);
    });

    test('a non-numeric value throws instead of silently becoming 0', () {
      expect(
        () => PortfolioHolding.fromJson({...holdingJson, 'value': 'n/a'}),
        throwsFormatException,
      );
    });

    test('equality covers every field', () {
      final a = PortfolioHolding.fromJson(holdingJson);
      final b = PortfolioHolding.fromJson({...holdingJson, 'currentPrice': 1});
      final c = PortfolioHolding.fromJson({...holdingJson, 'allocation': 1});
      expect(a, PortfolioHolding.fromJson(holdingJson));
      expect(a, isNot(b));
      expect(a, isNot(c));
    });

    test('parses performance points', () {
      final performance = PortfolioPerformance.fromJson(const {
        'timeframe': '7d',
        'data': [
          {
            'timestamp': '2026-01-16T12:00:00Z',
            'value': 100,
            'pnl': 1,
            'pnlPercent': 1,
          },
        ],
        'summary': {'startValue': 99, 'endValue': 100, 'totalReturn': 1},
      });
      expect(performance.data.single.value, 100);
      expect(performance.summary.totalReturn, 1);
    });
  });
}
