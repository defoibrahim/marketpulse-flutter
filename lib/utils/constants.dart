/// App-wide constants.
class AppConstants {
  AppConstants._();

  /// REST API base URL. Override at build time, for example on the Android
  /// emulator: `--dart-define=API_BASE_URL=http://10.0.2.2:3000/api`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  /// WebSocket URL for live prices: `--dart-define=WS_URL=ws://10.0.2.2:3000`.
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:3000',
  );

  /// Run on the bundled demo data with simulated live prices and no server:
  /// `--dart-define=DEMO=true`.
  static const bool demoMode = bool.fromEnvironment('DEMO');

  // API endpoints
  static const String marketDataEndpoint = '/market-data';
  static const String analyticsEndpoint = '/analytics';
  static const String portfolioEndpoint = '/portfolio';

  // Timeframes
  static const List<String> timeframes = ['1h', '4h', '24h', '7d', '30d'];
}
