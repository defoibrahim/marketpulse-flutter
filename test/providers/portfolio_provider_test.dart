import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/core/failure.dart';
import 'package:marketpulse/models/portfolio_model.dart';
import 'package:marketpulse/providers/portfolio_provider.dart';
import 'package:marketpulse/services/api_service.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';

PortfolioPerformance performance(String timeframe) => PortfolioPerformance(
      timeframe: timeframe,
      data: [
        PerformancePoint(
          timestamp: DateTime.utc(2026, 1, 16),
          value: 100,
          pnl: 1,
          pnlPercent: 1,
        ),
      ],
      summary: const PerformanceSummary(
        startValue: 99,
        endValue: 100,
        totalReturn: 1,
      ),
    );

void main() {
  late MockApiService api;
  late PortfolioProvider provider;
  final overview = PortfolioOverview.dummy;
  final holdings = PortfolioHolding.dummyList;

  setUp(() {
    api = MockApiService();
    provider = PortfolioProvider(api);
    when(() => api.getPortfolioOverview())
        .thenAnswer((_) async => Right(overview));
    when(() => api.getPortfolioHoldings())
        .thenAnswer((_) async => Right(holdings));
    when(() => api.getPortfolioPerformance(
            timeframe: any(named: 'timeframe')))
        .thenAnswer((invocation) async => Right(
            performance(invocation.namedArguments[#timeframe] as String)));
  });

  tearDown(() => provider.dispose());

  test('loads overview, holdings and performance together', () async {
    await provider.loadData();

    expect(provider.overview, overview);
    expect(provider.holdings, holdings);
    expect(provider.performance!.timeframe, '24h');
    expect(provider.isLoading, isFalse);
  });

  test('a failed holdings request keeps the rest and reports it', () async {
    when(() => api.getPortfolioHoldings())
        .thenAnswer((_) async => const Left(ServerFailure('Holdings down')));

    await provider.loadData();

    expect(provider.overview, overview);
    expect(provider.holdings, isNull);
    expect(provider.error, 'Holdings down');
  });

  test('a slow older timeframe response does not overwrite a newer one',
      () async {
    await provider.loadData();
    final slow = Completer<Result<PortfolioPerformance>>();
    final fast = Completer<Result<PortfolioPerformance>>();
    when(() => api.getPortfolioPerformance(timeframe: '1h'))
        .thenAnswer((_) => slow.future);
    when(() => api.getPortfolioPerformance(timeframe: '7d'))
        .thenAnswer((_) => fast.future);

    final first = provider.setTimeframe('1h');
    final second = provider.setTimeframe('7d');
    fast.complete(Right(performance('7d')));
    await second;
    slow.complete(Right(performance('1h')));
    await first;

    expect(provider.performance!.timeframe, '7d');
    expect(provider.isLoadingPerformance, isFalse);
  });

  test('a new timeframe clears the previous error', () async {
    when(() => api.getPortfolioOverview())
        .thenAnswer((_) async => const Left(NetworkFailure()));
    await provider.loadData();
    expect(provider.error, isNotNull);

    await provider.setTimeframe('7d');

    expect(provider.error, isNull);
  });
}
