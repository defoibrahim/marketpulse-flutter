import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

import '../gen/assets.gen.dart';
import '../providers/market_data_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/widgets.dart';
import 'analytics_screen.dart';
import 'market_data_screen.dart';
import 'market_detail_screen.dart';
import 'portfolio_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialSymbol});

  /// A market whose detail screen opens on start (demo launch options).
  final String? initialSymbol;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const List<Widget> _screens = [
    MarketDataScreen(),
    AnalyticsScreen(),
    PortfolioScreen(),
  ];

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Close the live-price socket while the app is in the background and
    // reopen it when it comes back.
    _lifecycle = AppLifecycleListener(
      onHide: () {
        if (mounted) context.read<MarketDataProvider>().pauseRealTime();
      },
      onShow: () {
        if (mounted) context.read<MarketDataProvider>().resumeRealTime();
      },
    );
    final symbol = widget.initialSymbol;
    if (symbol != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MarketDetailScreen(symbol: symbol),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final selectedIndex = navProvider.selectedIndex;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Assets.images.logo.image(
              height: 32,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 12),
            const Text('MarketPulse'),
          ],
        ),
        elevation: 0,
        actions: [
          Builder(
            builder: (context) {
              final brightness = Theme.of(context).brightness;
              final isDark = brightness == Brightness.dark;
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: isDark ? Colors.amber : Colors.indigo,
                ),
                onPressed: () =>
                    context.read<ThemeProvider>().toggle(brightness),
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              );
            },
          ),
          const SizedBox(width: 8),
          // Live prices only apply to the market tab.
          if (selectedIndex == 0) ...[
            const LiveToggle(),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: IndexedStack(index: selectedIndex, children: _screens),
        ),
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).cardColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: GNav(
              gap: 8,
              activeColor: colors.primary,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: colors.primary.withValues(alpha: 0.1),
              color: Colors.grey,
              tabs: const [
                GButton(icon: Icons.candlestick_chart, text: 'Market'),
                GButton(icon: Icons.bar_chart, text: 'Analytics'),
                GButton(icon: Icons.pie_chart_outline, text: 'Portfolio'),
              ],
              selectedIndex: selectedIndex,
              onTabChange: navProvider.setIndex,
            ),
          ),
        ),
      ),
    );
  }
}
