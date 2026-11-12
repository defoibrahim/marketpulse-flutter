import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/launch_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'screens/main_screen.dart';
import 'services/demo/demo_api_service.dart';
import 'services/demo/demo_price_feed.dart';
import 'services/services.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    MarketPulseApp(
      preferences: preferences,
      demoMode: AppConstants.demoMode,
      // Demo web builds can open a given screen from the URL (screenshots).
      launch: AppConstants.demoMode
          ? LaunchOptions.fromUri(Uri.base)
          : const LaunchOptions(),
    ),
  );
}

class MarketPulseApp extends StatelessWidget {
  const MarketPulseApp({
    super.key,
    this.preferences,
    this.demoMode = false,
    this.launch = const LaunchOptions(),
  });

  /// Stores the theme choice; null keeps it in memory only.
  final SharedPreferences? preferences;

  /// Serve the bundled demo data and simulated live prices instead of
  /// calling a server (`--dart-define=DEMO=true`).
  final bool demoMode;

  final LaunchOptions launch;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services: one instance each, owned and disposed by Provider.
        Provider<ApiService>(
          create: (_) => demoMode ? DemoApiService() : DioApiService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<PriceFeed>(
          create: (_) => demoMode ? DemoPriceFeed() : WebSocketService(),
          dispose: (_, feed) => feed.dispose(),
        ),

        // State, built on the services above.
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(preferences, launch.themeMode),
        ),
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(initialIndex: launch.tab),
        ),
        ChangeNotifierProvider(
          create: (context) => MarketDataProvider(
            apiService: context.read<ApiService>(),
            priceFeed: context.read<PriceFeed>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AnalyticsProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => PortfolioProvider(context.read<ApiService>()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MarketPulse',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: MainScreen(initialSymbol: launch.symbol),
          );
        },
      ),
    );
  }
}
