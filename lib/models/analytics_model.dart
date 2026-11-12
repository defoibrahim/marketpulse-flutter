import 'package:equatable/equatable.dart';

import 'json_readers.dart';

class AnalyticsOverview extends Equatable {
  final double totalMarketCap;
  final double totalVolume24h;
  final int activeMarkets;
  final MarketMover topGainer;
  final MarketMover topLoser;
  final MarketDominance dominance;
  final DateTime lastUpdated;

  const AnalyticsOverview({
    required this.totalMarketCap,
    required this.totalVolume24h,
    required this.activeMarkets,
    required this.topGainer,
    required this.topLoser,
    required this.dominance,
    required this.lastUpdated,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      totalMarketCap: readDouble(json, 'totalMarketCap'),
      totalVolume24h: readDouble(json, 'totalVolume24h'),
      activeMarkets: readInt(json, 'activeMarkets'),
      topGainer: MarketMover.fromJson(readMap(json, 'topGainer')),
      topLoser: MarketMover.fromJson(readMap(json, 'topLoser')),
      dominance: MarketDominance.fromJson(readMap(json, 'marketDominance')),
      lastUpdated: readDate(json, 'lastUpdated'),
    );
  }

  @override
  List<Object?> get props => [
        totalMarketCap,
        totalVolume24h,
        activeMarkets,
        topGainer,
        topLoser,
        dominance,
        lastUpdated
      ];

  static AnalyticsOverview get dummy => AnalyticsOverview(
        totalMarketCap: 2000000000000,
        totalVolume24h: 100000000,
        activeMarkets: 5000,
        topGainer: const MarketMover(symbol: 'BTC', change: 5.5, price: 50000),
        topLoser: const MarketMover(symbol: 'ETH', change: -3.2, price: 3000),
        dominance: const MarketDominance(btc: 45, eth: 20, others: 35),
        lastUpdated: DateTime.now(),
      );
}

class MarketMover extends Equatable {
  final String symbol;
  final double change;
  final double price;

  const MarketMover({
    required this.symbol,
    required this.change,
    required this.price,
  });

  factory MarketMover.fromJson(Map<String, dynamic> json) {
    return MarketMover(
      symbol: readString(json, 'symbol'),
      change: readDouble(json, 'change'),
      price: readDouble(json, 'price'),
    );
  }

  @override
  List<Object?> get props => [symbol, change, price];
}

class MarketDominance extends Equatable {
  final double btc;
  final double eth;
  final double others;

  const MarketDominance({
    required this.btc,
    required this.eth,
    required this.others,
  });

  factory MarketDominance.fromJson(Map<String, dynamic> json) {
    return MarketDominance(
      btc: readDouble(json, 'btc'),
      eth: readDouble(json, 'eth'),
      others: readDouble(json, 'others'),
    );
  }

  @override
  List<Object?> get props => [btc, eth, others];
}

class TrendData extends Equatable {
  final String timeframe;
  final List<MarketTrend> data;
  final TrendSummary summary;

  const TrendData({
    required this.timeframe,
    required this.data,
    required this.summary,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      timeframe: readString(json, 'timeframe'),
      data: readList(json, 'data').map(MarketTrend.fromJson).toList(),
      summary: TrendSummary.fromJson(readMap(json, 'summary')),
    );
  }

  @override
  List<Object?> get props => [timeframe, data, summary];

  static TrendData get dummy => TrendData(
        timeframe: '24h',
        data: List.generate(
          20,
          (index) => MarketTrend(
            timestamp: DateTime.now().subtract(Duration(hours: index)),
            marketCap: 2000000000000,
            volume: 100000000,
            priceIndex: 100.0,
          ),
        ),
        summary: const TrendSummary(change: 2.5, volatility: 3.0),
      );
}

class MarketTrend extends Equatable {
  final DateTime timestamp;
  final double marketCap;
  final double volume;
  final double priceIndex;

  const MarketTrend({
    required this.timestamp,
    required this.marketCap,
    required this.volume,
    required this.priceIndex,
  });

  factory MarketTrend.fromJson(Map<String, dynamic> json) {
    return MarketTrend(
      timestamp: readDate(json, 'timestamp'),
      marketCap: readDouble(json, 'marketCap'),
      volume: readDouble(json, 'volume'),
      priceIndex: readDouble(json, 'priceIndex'),
    );
  }

  @override
  List<Object?> get props => [timestamp, marketCap, volume, priceIndex];
}

class TrendSummary extends Equatable {
  final double change;
  final double volatility;

  const TrendSummary({
    required this.change,
    required this.volatility,
  });

  factory TrendSummary.fromJson(Map<String, dynamic> json) {
    return TrendSummary(
      change: readDouble(json, 'change'),
      volatility: readDouble(json, 'volatility'),
    );
  }

  @override
  List<Object?> get props => [change, volatility];
}
