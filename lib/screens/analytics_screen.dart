import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_model.dart';
import '../providers/analytics_provider.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../widgets/analytics_widgets.dart';
import '../widgets/widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AnalyticsProvider>();
      if (!provider.hasData && !provider.isLoading) provider.loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, _) {
        final error = provider.error;
        if (error != null && !provider.hasData && !provider.isLoading) {
          return MarketErrorView(error: error, onRetry: provider.loadData);
        }

        // The page skeleton only covers the first load. Changing the
        // timeframe only puts the trend chart into its loading state.
        final showSkeleton = !provider.hasData;
        final overview = provider.overview ?? AnalyticsOverview.dummy;
        final trends = provider.trendData;
        final trendsLoading =
            showSkeleton || provider.isLoadingTrends || trends == null;
        final shownTrends = trends ?? TrendData.dummy;
        const sectionTitle =
            TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

        return Column(
          children: [
            AppLinearProgress(isLoading: provider.isLoading),
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.loadData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (error != null && provider.hasData) ...[
                      ErrorBanner(
                        message: error,
                        onRetry: provider.loadData,
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Skeletonizer(
                      enabled: showSkeleton,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: StatCard(
                                  label: 'Market Cap',
                                  value: overview.totalMarketCap.formatCompact(),
                                  icon: Icons.pie_chart,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StatCard(
                                  label: '24h Volume',
                                  value: overview.totalVolume24h.formatCompact(),
                                  icon: Icons.bar_chart,
                                  color: Colors.blue.shade400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Market Dominance', style: sectionTitle),
                          const SizedBox(height: 16),
                          DominancePieChart(dominance: overview.dominance),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text('Market Trends', style: sectionTitle),
                        ),
                        DropdownButton<String>(
                          value: provider.selectedTimeframe,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final timeframe in AppConstants.timeframes)
                              DropdownMenuItem(
                                value: timeframe,
                                child: Text(timeframe),
                              ),
                          ],
                          onChanged: showSkeleton
                              ? null
                              : (value) {
                                  if (value != null) {
                                    provider.setTimeframe(value);
                                  }
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Skeletonizer(
                      enabled: trendsLoading,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Volatility: ${shownTrends.summary.volatility.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TrendLineChart(
                            trendData: shownTrends,
                            isPositive: shownTrends.summary.change >= 0,
                            overrideColor: trendsLoading ? Colors.grey : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Skeletonizer(
                      enabled: showSkeleton,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Top Movers (24h)', style: sectionTitle),
                          const SizedBox(height: 16),
                          _MoverTile(
                            title: 'Top Gainer',
                            mover: overview.topGainer,
                            isGainer: true,
                          ),
                          const SizedBox(height: 8),
                          _MoverTile(
                            title: 'Top Loser',
                            mover: overview.topLoser,
                            isGainer: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MoverTile extends StatelessWidget {
  const _MoverTile({
    required this.title,
    required this.mover,
    required this.isGainer,
  });

  final String title;
  final MarketMover mover;
  final bool isGainer;

  @override
  Widget build(BuildContext context) {
    final color = context.marketColors.forChange(mover.change);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: MergeSemantics(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: isDark ? 0.2 : 0.12),
            child: Icon(
              isGainer ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
            ),
          ),
          title: Text(title),
          subtitle: Text(mover.symbol),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mover.price.formatAsCurrency(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                mover.change.formatAsPercentage(),
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
