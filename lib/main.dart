import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'screens/main_screen.dart';
import 'services/services.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MarketPulseApp());
}

class MarketPulseApp extends StatelessWidget {
  const MarketPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Provide services FIRST (singleton instances)
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<WebSocketService>(
          create: (_) => WebSocketService(),
          dispose: (_, service) => service.dispose(),
        ),

        // 2. Provide ViewModels/Connectors dealing with state
        // They depend on the services above
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (context) => MarketDataProvider(
            apiService: context.read<ApiService>(),
            wsService: context.read<WebSocketService>(),
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

            // Dynamic Theme Mode
            themeMode: themeProvider.themeMode,

            // Light Theme
            theme: AppTheme.light,

            // Dark Theme
            darkTheme: AppTheme.dark,

            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
