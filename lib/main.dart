import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'screens/main_screen.dart';
import 'services/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(MarketPulseApp(preferences: preferences));
}

class MarketPulseApp extends StatelessWidget {
  const MarketPulseApp({super.key, this.preferences});

  /// Stores the theme choice; null keeps it in memory only.
  final SharedPreferences? preferences;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services: one instance each, owned and disposed by Provider.
        Provider<ApiService>(
          create: (_) => DioApiService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<PriceFeed>(
          create: (_) => WebSocketService(),
          dispose: (_, feed) => feed.dispose(),
        ),

        // State, built on the services above.
        ChangeNotifierProvider(create: (_) => ThemeProvider(preferences)),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
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
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
