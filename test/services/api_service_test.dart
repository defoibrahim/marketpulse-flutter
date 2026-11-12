import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/core/failure.dart';
import 'package:marketpulse/services/api_service.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object body, {int status = 200}) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

const btc = {
  'symbol': 'BTC/USD',
  'description': 'Bitcoin',
  'price': 43250.2,
  'change24h': 1055.0,
  'changePercent24h': 2.5,
  'volume': 1.25e9,
  'high24h': 44500,
  'low24h': 42000,
  'marketCap': 8.5e11,
  'lastUpdated': '2026-01-16T12:00:00Z',
};

void main() {
  late FakeAdapter adapter;

  DioApiService serviceWith(
      Future<ResponseBody> Function(RequestOptions) handler) {
    adapter = FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api'))
      ..httpClientAdapter = adapter;
    return DioApiService(dio: dio);
  }

  test('parses the data envelope', () async {
    final api = serviceWith((_) async => jsonBody({
          'data': [btc],
        }));

    final result = await api.getMarketData();

    expect(result.isRight(), isTrue);
    result.fold((_) {}, (data) => expect(data.single.symbol, 'BTC/USD'));
    expect(adapter.requests.single.uri.path, '/api/market-data');
  });

  test('encodes the symbol into a single path segment', () async {
    final api = serviceWith((_) async => jsonBody({'data': btc}));

    await api.getMarketDataBySymbol('BTC/USD');

    expect(adapter.requests.single.uri.path, '/api/market-data/BTC%2FUSD');
  });

  test('sends the timeframe as a query parameter', () async {
    final api = serviceWith((_) async => jsonBody({
          'data': {
            'timeframe': '7d',
            'data': <Object>[],
            'summary': {'change': 1, 'volatility': 2},
          },
        }));

    await api.getMarketTrends(timeframe: '7d');

    expect(adapter.requests.single.uri.queryParameters, {'timeframe': '7d'});
  });

  test('a missing envelope is a parse failure with a friendly message',
      () async {
    final api = serviceWith((_) async => jsonBody([btc]));

    final result = await api.getMarketData();

    result.fold(
      (failure) {
        expect(failure, isA<ParseFailure>());
        expect(failure.message, const ParseFailure().message);
      },
      (_) => fail('expected a failure'),
    );
  });

  test('a malformed item is a parse failure, not a crash', () async {
    final api = serviceWith((_) async => jsonBody({
          'data': [
            {...btc, 'price': null},
          ],
        }));

    final result = await api.getMarketData();

    result.fold(
      (failure) => expect(failure, isA<ParseFailure>()),
      (_) => fail('expected a failure'),
    );
  });

  test('an error status is a server failure', () async {
    final api = serviceWith((_) async => jsonBody({'error': 'boom'}, status: 500));

    final result = await api.getPortfolioOverview();

    result.fold(
      (failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, contains('500'));
      },
      (_) => fail('expected a failure'),
    );
  });

  test('an unreachable server is a network failure', () async {
    final api = serviceWith((options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'refused',
        ));

    final result = await api.getAnalyticsOverview();

    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected a failure'),
    );
  });

  test('timeouts, including slow response decoding, are network failures',
      () async {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
    ]) {
      final api = serviceWith(
        (options) async => throw DioException(requestOptions: options, type: type),
      );

      final result = await api.getMarketData();

      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>(), reason: '$type'),
        (_) => fail('expected a failure for $type'),
      );
    }
  });
}
