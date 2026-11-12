import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/market_data_model.dart';
import '../providers/market_data_provider.dart';
import '../widgets/widgets.dart';

class MarketDetailScreen extends StatefulWidget {
  const MarketDetailScreen({super.key, required this.symbol});

  final String symbol;

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Opened without the list loaded (e.g. a deep link): fetch this market.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MarketDataProvider>();
      if (provider.getBySymbol(widget.symbol) == null) {
        provider.refreshSymbol(widget.symbol);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketDataProvider>(
      builder: (context, provider, _) {
        final symbol = widget.symbol;
        final data = provider.getBySymbol(symbol);
        final refreshing = provider.isRefreshing(symbol);
        final error = provider.errorFor(symbol);
        Future<void> refresh() => provider.refreshSymbol(symbol);

        if (data == null && error != null && !refreshing) {
          return Scaffold(
            appBar: AppBar(title: Text(symbol)),
            body: MarketErrorView(error: error, onRetry: refresh),
          );
        }

        final display = data ?? MarketData.dummyFor(symbol);
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SymbolAvatar(symbol: display.baseSymbol, size: 24),
                const SizedBox(width: 8),
                Text(display.symbol),
              ],
            ),
          ),
          body: Column(
            children: [
              AppLinearProgress(isLoading: refreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refresh,
                  child: Skeletonizer(
                    enabled: data == null,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (error != null && data != null) ...[
                          ErrorBanner(
                            message: error,
                            onRetry: refresh,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 16),
                        ],
                        MainPriceDisplay(data: display),
                        const SizedBox(height: 32),
                        MarketStatsGrid(data: display),
                        const SizedBox(height: 32),
                        AboutSection(data: display),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
