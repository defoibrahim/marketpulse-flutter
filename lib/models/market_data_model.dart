import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'json_readers.dart';

/// Model representing market data for a crypto symbol
/// Maps to: GET /api/market-data response
class MarketData extends Equatable {
  final String symbol;
  final String description;
  final double price;
  final double change24h;
  final double changePercent24h;
  final double volume;
  final double high24h;
  final double low24h;
  final double marketCap;
  final DateTime lastUpdated;

  const MarketData({
    required this.symbol,
    required this.description,
    required this.price,
    required this.change24h,
    required this.changePercent24h,
    required this.volume,
    required this.high24h,
    required this.low24h,
    required this.marketCap,
    required this.lastUpdated,
  });

  /// Parses one item of `GET /market-data`. Throws [FormatException] when a
  /// required field is missing or malformed.
  factory MarketData.fromJson(Map<String, dynamic> json) {
    final description = json['description'];
    return MarketData(
      symbol: readString(json, 'symbol'),
      description: description is String ? description : '',
      price: readDouble(json, 'price'),
      change24h: readDouble(json, 'change24h'),
      changePercent24h: readDouble(json, 'changePercent24h'),
      volume: readDouble(json, 'volume'),
      high24h: readDouble(json, 'high24h'),
      low24h: readDouble(json, 'low24h'),
      marketCap: readDouble(json, 'marketCap'),
      lastUpdated: readDate(json, 'lastUpdated'),
    );
  }

  /// Applies a partial live update (a WebSocket `market_update` payload).
  /// Fields that are absent or invalid keep their current value, and the 24h
  /// high and low stretch to include the new price.
  factory MarketData.updateFromJson(
      MarketData existing, Map<String, dynamic> json) {
    final price = readDoubleOrNull(json, 'price');
    final timestamp = json['timestamp'];
    return existing.copyWith(
      price: price,
      change24h: readDoubleOrNull(json, 'change24h'),
      changePercent24h: readDoubleOrNull(json, 'changePercent24h'),
      volume: readDoubleOrNull(json, 'volume'),
      high24h: price == null ? null : math.max(existing.high24h, price),
      low24h: price == null ? null : math.min(existing.low24h, price),
      lastUpdated: timestamp is String ? DateTime.tryParse(timestamp) : null,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'description': description,
      'price': price,
      'change24h': change24h,
      'changePercent24h': changePercent24h,
      'volume': volume,
      'high24h': high24h,
      'low24h': low24h,
      'marketCap': marketCap,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Helper getter: Check if change is positive
  bool get isPositiveChange => change24h >= 0;

  /// Helper getter: Get base symbol (e.g., "BTC" from "BTC/USD")
  String get baseSymbol => symbol.split('/').first;

  /// Helper getter: Get quote symbol (e.g., "USD" from "BTC/USD")
  String get quoteSymbol => symbol.split('/').last;

  /// Creates a copy of this MarketData with updated fields
  MarketData copyWith({
    String? symbol,
    String? description,
    double? price,
    double? change24h,
    double? changePercent24h,
    double? volume,
    double? high24h,
    double? low24h,
    double? marketCap,
    DateTime? lastUpdated,
  }) {
    return MarketData(
      symbol: symbol ?? this.symbol,
      description: description ?? this.description,
      price: price ?? this.price,
      change24h: change24h ?? this.change24h,
      changePercent24h: changePercent24h ?? this.changePercent24h,
      volume: volume ?? this.volume,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      marketCap: marketCap ?? this.marketCap,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'MarketData(symbol: $symbol, price: $price, change24h: $change24h%)';
  }

  @override
  List<Object?> get props => [
        symbol,
        description,
        price,
        change24h,
        changePercent24h,
        volume,
        high24h,
        low24h,
        marketCap,
        lastUpdated,
      ];

  static MarketData get dummy => MarketData(
        symbol: 'BTC/USD',
        description: 'Bitcoin',
        price: 43250.50,
        change24h: 2.50,
        changePercent24h: 2.50,
        volume: 1250000000,
        high24h: 44500,
        low24h: 42000,
        marketCap: 850000000000,
        lastUpdated: DateTime.now(),
      );

  /// Create dummy data with a specific symbol (for detail screen skeleton)
  static MarketData dummyFor(String symbol) => MarketData(
        symbol: symbol,
        description: symbol.split('/').first,
        price: 43250.50,
        change24h: 2.50,
        changePercent24h: 2.50,
        volume: 1250000000,
        high24h: 44500,
        low24h: 42000,
        marketCap: 850000000000,
        lastUpdated: DateTime.now(),
      );

  static List<MarketData> get dummyList => [
        dummy,
        MarketData(
          symbol: 'ETH/USD',
          description: 'Ethereum',
          price: 2650.75,
          change24h: -1.20,
          changePercent24h: -1.20,
          volume: 850000000,
          high24h: 2750,
          low24h: 2600,
          marketCap: 320000000000,
          lastUpdated: DateTime.now(),
        ),
        MarketData(
          symbol: 'SOL/USD',
          description: 'Solana',
          price: 98.25,
          change24h: 5.30,
          changePercent24h: 5.30,
          volume: 450000000,
          high24h: 102,
          low24h: 92,
          marketCap: 45000000000,
          lastUpdated: DateTime.now(),
        ),
        MarketData(
          symbol: 'ADA/USD',
          description: 'Cardano',
          price: 0.52,
          change24h: 1.80,
          changePercent24h: 1.80,
          volume: 120000000,
          high24h: 0.54,
          low24h: 0.50,
          marketCap: 18000000000,
          lastUpdated: DateTime.now(),
        ),
        MarketData(
          symbol: 'DOT/USD',
          description: 'Polkadot',
          price: 7.85,
          change24h: -0.50,
          changePercent24h: -0.50,
          volume: 95000000,
          high24h: 8.10,
          low24h: 7.60,
          marketCap: 9500000000,
          lastUpdated: DateTime.now(),
        ),
      ];
}
