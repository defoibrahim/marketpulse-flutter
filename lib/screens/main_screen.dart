import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'market_data_screen.dart';
import 'portfolio_screen.dart';
import 'analytics_screen.dart';
import '../providers/market_data_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/navigation_provider.dart';

import '../gen/assets.gen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const List<Widget> _screens = [
    MarketDataScreen(),
    AnalyticsScreen(),
    PortfolioScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, _) {
        final selectedIndex = navProvider.selectedIndex;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Assets.images.logo.image(
                  height: 32,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                const Text('MarketPulse'),
              ],
            ),
            elevation: 0,
            actions: [
              // Theme toggle button
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  final isDark = themeProvider.isDarkMode;
                  return IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: isDark ? Colors.amber : Colors.indigo,
                    ),
                    onPressed: themeProvider.toggleTheme,
                    tooltip:
                        isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  );
                },
              ),
              const SizedBox(width: 8),

              // Real-time toggle button (Visible only on Market Data tab)
              if (selectedIndex == 0)
                Consumer<MarketDataProvider>(
                  builder: (context, provider, child) {
                    final isLive = provider.isRealTimeEnabled;
                    return TextButton.icon(
                      onPressed: () {
                        if (isLive) {
                          provider.disableRealTimeUpdates();
                        } else {
                          provider.enableRealTimeUpdates();
                        }
                      },
                      icon: Icon(
                        isLive ? Icons.wifi : Icons.wifi_off,
                        color: isLive ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      label: Text(
                        isLive ? 'LIVE' : 'OFF',
                        style: TextStyle(
                          color: isLive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              if (selectedIndex == 0) const SizedBox(width: 8),
            ],
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: IndexedStack(
                index: selectedIndex,
                children: _screens,
              ),
            ),
          ),
          bottomNavigationBar: Container(
            color: Theme.of(context).cardColor,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                child: GNav(
                  gap: 8,
                  activeColor: Theme.of(context).colorScheme.primary,
                  iconSize: 24,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  duration: const Duration(milliseconds: 400),
                  tabBackgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  color: Colors.grey,
                  tabs: const [
                    GButton(
                      icon: Icons.candlestick_chart,
                      text: 'Market',
                    ),
                    GButton(
                      icon: Icons.bar_chart,
                      text: 'Analytics',
                    ),
                    GButton(
                      icon: Icons.pie_chart_outline,
                      text: 'Portfolio',
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onTabChange: (index) {
                    navProvider.setIndex(index);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
