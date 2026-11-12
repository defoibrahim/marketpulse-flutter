import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/core/failure.dart';
import 'package:marketpulse/models/analytics_model.dart';
import 'package:marketpulse/providers/analytics_provider.dart';
import 'package:marketpulse/services/api_service.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';

void main() {
  late MockApiService api;
  late AnalyticsProvider provider;

  setUp(() {
    api = MockApiService();
    provider = AnalyticsProvider(api);
    when(() => api.getAnalyticsOverview())
        .thenAnswer((_) async => Right(sampleOverview));
    when(() => api.getMarketTrends(timeframe: any(named: 'timeframe')))
        .thenAnswer((invocation) async => Right(
            trend(invocation.namedArguments[#timeframe] as String)));
  });

  tearDown(() => provider.dispose());

  test('loads the overview and the selected trend', () async {
    await provider.loadData();

    expect(provider.overview, sampleOverview);
    expect(provider.trendData!.timeframe, '24h');
    expect(provider.isLoading, isFalse);
    expect(provider.error, isNull);
  });

  test('a failed refresh keeps the last data', () async {
    await provider.loadData();
    when(() => api.getAnalyticsOverview())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await provider.loadData();

    expect(provider.overview, sampleOverview);
    expect(provider.hasData, isTrue);
    expect(provider.error, const NetworkFailure().message);
  });

  test('a slow older timeframe response does not overwrite a newer one',
      () async {
    await provider.loadData();
    final slow = Completer<Result<TrendData>>();
    final fast = Completer<Result<TrendData>>();
    when(() => api.getMarketTrends(timeframe: '1h'))
        .thenAnswer((_) => slow.future);
    when(() => api.getMarketTrends(timeframe: '7d'))
        .thenAnswer((_) => fast.future);

    final first = provider.setTimeframe('1h');
    final second = provider.setTimeframe('7d');
    fast.complete(Right(trend('7d')));
    await second;
    slow.complete(Right(trend('1h')));
    await first;

    expect(provider.selectedTimeframe, '7d');
    expect(provider.trendData!.timeframe, '7d');
    expect(provider.isLoadingTrends, isFalse);
  });

  test('changing the timeframe only loads the trend', () async {
    await provider.loadData();
    final pending = Completer<Result<TrendData>>();
    when(() => api.getMarketTrends(timeframe: '30d'))
        .thenAnswer((_) => pending.future);

    final change = provider.setTimeframe('30d');

    expect(provider.isLoadingTrends, isTrue);
    expect(provider.isLoadingOverview, isFalse);
    expect(provider.hasData, isTrue);
    pending.complete(Right(trend('30d')));
    await change;
    verify(() => api.getAnalyticsOverview()).called(1);
  });

  test('selecting the current timeframe does nothing', () async {
    await provider.loadData();
    await provider.setTimeframe('24h');
    verify(() => api.getMarketTrends(timeframe: '24h')).called(1);
  });
}
