import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:marketpulse/providers/market_data_provider.dart';
import 'package:marketpulse/services/api_service.dart';
import 'package:marketpulse/services/websocket_service.dart';
import 'package:marketpulse/models/market_data_model.dart';
import 'package:marketpulse/core/failure.dart';

// Mocks
class MockApiService extends Mock implements ApiService {}

class MockWebSocketService extends Mock implements WebSocketService {}

void main() {
  late MarketDataProvider provider;
  late MockApiService mockApiService;
  late MockWebSocketService mockWebSocketService;

  setUp(() {
    mockApiService = MockApiService();
    mockWebSocketService = MockWebSocketService();
    provider = MarketDataProvider(
      apiService: mockApiService,
      wsService: mockWebSocketService,
    );
  });

  // Sample Data
  final dummyMarketData = [
    MarketData(
      symbol: 'BTC/USD',
      description: 'Bitcoin',
      price: 50000.0,
      change24h: 1000.0,
      changePercent24h: 2.0,
      volume: 1000000.0,
      high24h: 51000.0,
      low24h: 49000.0,
      marketCap: 1000000000.0,
      lastUpdated: DateTime.now(),
    ),
    MarketData(
      symbol: 'ETH/USD',
      description: 'Ethereum',
      price: 3000.0,
      change24h: -150.0,
      changePercent24h: -5.0,
      volume: 500000.0,
      high24h: 3100.0,
      low24h: 2900.0,
      marketCap: 500000000.0,
      lastUpdated: DateTime.now(),
    ),
    MarketData(
      symbol: 'SOL/USD',
      description: 'Solana',
      price: 100.0,
      change24h: 10.0,
      changePercent24h: 10.0,
      volume: 200000.0,
      high24h: 110.0,
      low24h: 90.0,
      marketCap: 100000000.0,
      lastUpdated: DateTime.now(),
    ),
  ];

  group('MarketDataProvider Tests', () {
    test('Initial state is correct', () {
      expect(provider.isLoading, false);
      expect(provider.marketData, isEmpty);
      expect(provider.error, null);
      expect(provider.searchQuery, '');
      expect(provider.sortOption, SortOption.price);
    });

    test('loadMarketData success updates state correctly', () async {
      // Arrange
      when(() => mockApiService.getMarketData())
          .thenAnswer((_) async => Right(dummyMarketData));

      // Act
      final future = provider.loadMarketData();

      // Assert Loading State (Sync check might be tricky with async method, usually checking listener count or flags)
      // Since `loadMarketData` is async, testing immediate isLoading=true requires a synchronous verification pattern or checking notification flow.
      // For simplicity in this unit test, we await completion.

      await future;

      // Assert Final State
      expect(provider.isLoading, false);
      expect(provider.marketData, equals(dummyMarketData));
      expect(provider.error, null);
      verify(() => mockApiService.getMarketData()).called(1);
    });

    test('loadMarketData failure updates error state', () async {
      // Arrange
      const errorMessage = 'Network Error';
      when(() => mockApiService.getMarketData())
          .thenAnswer((_) async => const Left(ServerFailure(errorMessage)));

      // Act
      await provider.loadMarketData();

      // Assert
      expect(provider.isLoading, false);
      expect(provider.marketData, isEmpty);
      expect(provider.error, errorMessage);
    });

    test('Search filters list by symbol correctly', () async {
      // Arrange
      // Inject data directly or mock load
      // We can mock the private _marketData by loading it first
      when(() => mockApiService.getMarketData())
          .thenAnswer((_) async => Right(dummyMarketData));
      await provider.loadMarketData();

      // Act
      provider.setSearchQuery('BTC');

      // Assert
      expect(provider.marketData.length, 1);
      expect(provider.marketData.first.symbol, 'BTC/USD');

      // Act 2 - Search 'Bitcoin' (Description search should fail as we removed it)
      provider.setSearchQuery('Bitcoin');
      expect(provider.marketData, isEmpty); // Description search removed
    });

    test('Search is case-insensitive', () async {
      when(() => mockApiService.getMarketData())
          .thenAnswer((_) async => Right(dummyMarketData));
      await provider.loadMarketData();

      provider.setSearchQuery('btc');
      expect(provider.marketData.length, 1);
      expect(provider.marketData.first.symbol, 'BTC/USD');
    });

    test('Sort by Price works (Descending by default, then toggle)', () async {
      when(() => mockApiService.getMarketData())
          .thenAnswer((_) async => Right(dummyMarketData));
      await provider.loadMarketData();

      // Default is price descending
      // BTC (50000), ETH (3000), SOL (100)
      expect(provider.marketData[0].symbol, 'BTC/USD');
      expect(provider.marketData[1].symbol, 'ETH/USD');
      expect(provider.marketData[2].symbol, 'SOL/USD');

      // Toggle to Ascending
      provider.setSortOption(SortOption.price); // Same option -> toggle
      expect(provider.sortOrder, SortOrder.ascending);

      // SOL (100), ETH (3000), BTC (50000)
      expect(provider.marketData[0].symbol, 'SOL/USD');
      expect(provider.marketData[1].symbol, 'ETH/USD');
      expect(provider.marketData[2].symbol, 'BTC/USD');
    });

    test('Sort by Change works', () async {
      when(() => mockApiService.getMarketData())
          .thenAnswer((_) async => Right(dummyMarketData));
      await provider.loadMarketData();

      // Set Sort to Change (Default Descending)
      // BTC (+2%), SOL (+10%), ETH (-5%)
      // Descending Order: SOL (10%), BTC (2%), ETH (-5%)
      provider.setSortOption(SortOption.change);

      expect(provider.marketData[0].symbol, 'SOL/USD');
      expect(provider.marketData[1].symbol, 'BTC/USD');
      expect(provider.marketData[2].symbol, 'ETH/USD');
    });
  });
}
