import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:marketpulse/models/analytics_model.dart';
import 'package:marketpulse/models/market_data_model.dart';
import 'package:marketpulse/services/api_service.dart';
import 'package:marketpulse/services/price_feed.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

/// In-memory [PriceFeed] whose connection succeeds immediately.
class FakePriceFeed implements PriceFeed {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final _status = ValueNotifier(ConnectionStatus.disconnected);
  int connectCalls = 0;
  int disconnectCalls = 0;

  @override
  Stream<Map<String, dynamic>> get messages => _controller.stream;

  @override
  ValueListenable<ConnectionStatus> get status => _status;

  @override
  void connect() {
    connectCalls++;
    _status.value = ConnectionStatus.connected;
  }

  @override
  void disconnect() {
    disconnectCalls++;
    _status.value = ConnectionStatus.disconnected;
  }

  void setStatus(ConnectionStatus status) => _status.value = status;

  void tick(String symbol, double price) => _controller.add({
        'type': 'market_update',
        'data': {'symbol': symbol, 'price': price},
      });

  @override
  void dispose() {
    _controller.close();
    _status.dispose();
  }
}

MarketData market(
  String symbol, {
  double price = 100,
  double changePercent = 1,
}) =>
    MarketData(
      symbol: symbol,
      description: symbol,
      price: price,
      change24h: price * changePercent / 100,
      changePercent24h: changePercent,
      volume: 1000000,
      high24h: price * 1.05,
      low24h: price * 0.95,
      marketCap: price * 1000000,
      lastUpdated: DateTime.utc(2026, 1, 16),
    );

final sampleMarkets = [
  market('BTC/USD', price: 50000, changePercent: 2),
  market('ETH/USD', price: 3000, changePercent: -5),
  market('SOL/USD', price: 100, changePercent: 10),
];

TrendData trend(String timeframe, {double change = 1}) => TrendData(
      timeframe: timeframe,
      data: [
        MarketTrend(
          timestamp: DateTime.utc(2026, 1, 16),
          marketCap: 1,
          volume: 1,
          priceIndex: 100,
        ),
      ],
      summary: TrendSummary(change: change, volatility: 1),
    );

final sampleOverview = AnalyticsOverview(
  totalMarketCap: 2.5e12,
  totalVolume24h: 8.5e10,
  activeMarkets: 10,
  topGainer: const MarketMover(symbol: 'SOL/USD', change: 5.3, price: 98.2),
  topLoser: const MarketMover(symbol: 'ETH/USD', change: -1.2, price: 2651.97),
  dominance: const MarketDominance(btc: 42.5, eth: 28.3, others: 29.2),
  lastUpdated: DateTime.utc(2026, 1, 16),
);
