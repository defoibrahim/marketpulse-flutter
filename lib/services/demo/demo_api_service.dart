import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/failure.dart';
import '../../models/analytics_model.dart';
import '../../models/json_readers.dart';
import '../../models/market_data_model.dart';
import '../../models/portfolio_model.dart';
import '../api_service.dart';
import 'demo_data.dart';

/// [ApiService] that serves the bundled demo data, for running the app with
/// no server: `flutter run --dart-define=DEMO=true`.
class DemoApiService implements ApiService {
  DemoApiService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Future<Map<String, dynamic>>? _data;

  Future<Result<T>> _read<T>(T Function(Map<String, dynamic> data) parse) async {
    try {
      final data = await (_data ??= DemoData.load(_bundle));
      return Right(parse(data));
    } on Object catch (e) {
      debugPrint('DemoApiService: could not read the demo data: $e');
      return const Left(ParseFailure('The bundled demo data could not be read.'));
    }
  }

  static Map<String, dynamic> _byTimeframe(
    Map<String, dynamic> data,
    String key,
    String timeframe,
  ) =>
      readMap(readMap(data, key), timeframe);

  @override
  Future<Result<List<MarketData>>> getMarketData() => _read(
        (data) => readList(data, 'marketData').map(MarketData.fromJson).toList(),
      );

  @override
  Future<Result<MarketData>> getMarketDataBySymbol(String symbol) async {
    final result = await getMarketData();
    return result.fold<Result<MarketData>>(
      (failure) => Left(failure),
      (markets) {
        for (final market in markets) {
          if (market.symbol == symbol) return Right(market);
        }
        return const Left(ServerFailure('That market could not be found.'));
      },
    );
  }

  @override
  Future<Result<AnalyticsOverview>> getAnalyticsOverview() => _read(
        (data) => AnalyticsOverview.fromJson(readMap(data, 'analyticsOverview')),
      );

  @override
  Future<Result<TrendData>> getMarketTrends({String timeframe = '24h'}) =>
      _read((data) =>
          TrendData.fromJson(_byTimeframe(data, 'trends', timeframe)));

  @override
  Future<Result<PortfolioOverview>> getPortfolioOverview() => _read(
        (data) => PortfolioOverview.fromJson(readMap(data, 'portfolio')),
      );

  @override
  Future<Result<List<PortfolioHolding>>> getPortfolioHoldings() => _read(
        (data) =>
            readList(data, 'holdings').map(PortfolioHolding.fromJson).toList(),
      );

  @override
  Future<Result<PortfolioPerformance>> getPortfolioPerformance({
    String timeframe = '24h',
  }) =>
      _read((data) => PortfolioPerformance.fromJson(
          _byTimeframe(data, 'performance', timeframe)));

  @override
  void dispose() {}
}
