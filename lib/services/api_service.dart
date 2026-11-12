import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../models/analytics_model.dart';
import '../models/market_data_model.dart';
import '../models/portfolio_model.dart';
import '../utils/constants.dart';

/// Either a [Failure] the UI can show, or the data.
typedef Result<T> = Either<Failure, T>;

/// Source of market, analytics and portfolio data.
///
/// Implementations never throw: every error comes back as a [Failure].
abstract interface class ApiService {
  Future<Result<List<MarketData>>> getMarketData();

  /// One market, e.g. `BTC/USD`.
  Future<Result<MarketData>> getMarketDataBySymbol(String symbol);

  Future<Result<AnalyticsOverview>> getAnalyticsOverview();

  Future<Result<TrendData>> getMarketTrends({String timeframe = '24h'});

  Future<Result<PortfolioOverview>> getPortfolioOverview();

  Future<Result<List<PortfolioHolding>>> getPortfolioHoldings();

  Future<Result<PortfolioPerformance>> getPortfolioPerformance({
    String timeframe = '24h',
  });

  void dispose();
}

/// [ApiService] backed by the REST API at [AppConstants.baseUrl].
///
/// Every response is expected to wrap its payload as `{ "data": ... }`.
class DioApiService implements ApiService {
  DioApiService({Dio? dio, String baseUrl = AppConstants.baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: const {'Accept': 'application/json'},
              ),
            ) {
    // Request and response logging is for development only: release builds
    // never print API traffic.
    if (kDebugMode && dio == null) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (line) => debugPrint(line.toString()),
        ),
      );
    }
  }

  final Dio _dio;

  @override
  Future<Result<List<MarketData>>> getMarketData() => _get(
        AppConstants.marketDataEndpoint,
        (data) => _list(data, MarketData.fromJson),
      );

  @override
  Future<Result<MarketData>> getMarketDataBySymbol(String symbol) => _get(
        '${AppConstants.marketDataEndpoint}/${Uri.encodeComponent(symbol)}',
        (data) => MarketData.fromJson(_map(data)),
      );

  @override
  Future<Result<AnalyticsOverview>> getAnalyticsOverview() => _get(
        '${AppConstants.analyticsEndpoint}/overview',
        (data) => AnalyticsOverview.fromJson(_map(data)),
      );

  @override
  Future<Result<TrendData>> getMarketTrends({String timeframe = '24h'}) =>
      _get(
        '${AppConstants.analyticsEndpoint}/trends',
        (data) => TrendData.fromJson(_map(data)),
        query: {'timeframe': timeframe},
      );

  @override
  Future<Result<PortfolioOverview>> getPortfolioOverview() => _get(
        AppConstants.portfolioEndpoint,
        (data) => PortfolioOverview.fromJson(_map(data)),
      );

  @override
  Future<Result<List<PortfolioHolding>>> getPortfolioHoldings() => _get(
        '${AppConstants.portfolioEndpoint}/holdings',
        (data) => _list(data, PortfolioHolding.fromJson),
      );

  @override
  Future<Result<PortfolioPerformance>> getPortfolioPerformance({
    String timeframe = '24h',
  }) =>
      _get(
        '${AppConstants.portfolioEndpoint}/performance',
        (data) => PortfolioPerformance.fromJson(_map(data)),
        query: {'timeframe': timeframe},
      );

  Future<Result<T>> _get<T>(
    String path,
    T Function(Object? data) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<Object?>(path, queryParameters: query);
      final body = response.data;
      if (body is! Map<String, dynamic> || !body.containsKey('data')) {
        throw const FormatException('Missing the "data" envelope');
      }
      return Right(parse(body['data']));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } on Object catch (e) {
      // A FormatException or TypeError from parsing. Keep the detail in the
      // debug log and show the user a plain message.
      debugPrint('ApiService: could not read the response of $path: $e');
      return const Left(ParseFailure());
    }
  }

  static Map<String, dynamic> _map(Object? data) {
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Expected a JSON object');
  }

  static List<T> _list<T>(
    Object? data,
    T Function(Map<String, dynamic> json) parse,
  ) {
    if (data is! List) throw const FormatException('Expected a JSON array');
    return [for (final item in data) parse(_map(item))];
  }

  static Failure _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkFailure(
          'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          "Couldn't open a secure connection to the server.",
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 404) {
          return const ServerFailure('That market could not be found.');
        }
        return ServerFailure(
          'The server returned an error${code == null ? '' : ' ($code)'}. '
          'Please try again.',
        );
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        debugPrint('ApiService: ${e.type.name}: ${e.message ?? e.error}');
        return const UnexpectedFailure();
    }
  }

  @override
  void dispose() => _dio.close();
}
