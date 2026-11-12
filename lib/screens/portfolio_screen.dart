import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/portfolio_model.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/portfolio_widgets.dart';
import '../widgets/widgets.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<PortfolioProvider>();
      if (!provider.hasData && !provider.isLoading) provider.loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        final error = provider.error;
        if (error != null && !provider.hasData && !provider.isLoading) {
          return MarketErrorView(error: error, onRetry: provider.loadData);
        }

        final showSkeleton = !provider.hasData;
        final overview = provider.overview ?? PortfolioOverview.dummy;
        final holdings = showSkeleton
            ? PortfolioHolding.dummyList
            : provider.holdings ?? const <PortfolioHolding>[];
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
                          PortfolioSummaryCard(overview: overview),
                          const SizedBox(height: 24),
                          if (holdings.isNotEmpty) ...[
                            const Text('Asset Allocation', style: sectionTitle),
                            const SizedBox(height: 16),
                            AllocationPieChart(holdings: holdings),
                            const SizedBox(height: 24),
                          ],
                          const Text('Your Assets', style: sectionTitle),
                          const SizedBox(height: 16),
                          for (final holding in holdings)
                            AssetListTile(
                              key: ValueKey(holding.id),
                              holding: holding,
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
