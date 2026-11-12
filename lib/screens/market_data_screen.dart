import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/market_data_model.dart';
import '../providers/market_data_provider.dart';
import '../widgets/widgets.dart';
import 'market_detail_screen.dart';

class MarketDataScreen extends StatefulWidget {
  const MarketDataScreen({super.key});

  @override
  State<MarketDataScreen> createState() => _MarketDataScreenState();
}

class _MarketDataScreenState extends State<MarketDataScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<MarketDataProvider>();
    _searchController.text = provider.searchQuery;
    // Load after the first frame: notifying listeners during build throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !provider.hasLoaded && !provider.isLoading) {
        provider.loadMarketData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch(MarketDataProvider provider) {
    _searchController.clear();
    provider.setSearchQuery('');
  }

  void _openDetail(BuildContext context, MarketData data) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MarketDetailScreen(symbol: data.symbol),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketDataProvider>(
      builder: (context, provider, _) {
        final error = provider.error;
        // Skeleton until the first successful load; later refreshes keep
        // the current list on screen.
        final showSkeleton =
            !provider.hasData && !provider.hasLoaded && error == null;
        final items = showSkeleton ? MarketData.dummyList : provider.marketData;

        return Column(
          children: [
            AppLinearProgress(isLoading: provider.isLoading),
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.loadMarketData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Sizes itself to the filter bar, so larger text sizes
                    // don't clip it.
                    PinnedHeaderSliver(
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: MarketFilterBar(
                          controller: _searchController,
                          provider: provider,
                        ),
                      ),
                    ),
                    if (error != null && provider.hasData)
                      SliverToBoxAdapter(
                        child: ErrorBanner(
                          message: error,
                          onRetry: provider.loadMarketData,
                        ),
                      ),
                    if (error != null && !provider.hasData)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: MarketErrorView(
                          error: error,
                          onRetry: provider.loadMarketData,
                        ),
                      )
                    else if (items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: MarketEmptyView(
                          isFiltering: provider.isFiltering,
                          onClear: () => _clearSearch(provider),
                        ),
                      )
                    else
                      SliverSkeletonizer(
                        enabled: showSkeleton,
                        child: SliverPadding(
                          padding: const EdgeInsets.only(bottom: 16),
                          sliver: SliverList.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final data = items[index];
                              return MarketDataListItem(
                                key: ValueKey(data.symbol),
                                data: data,
                                onTap: showSkeleton
                                    ? null
                                    : () => _openDetail(context, data),
                              );
                            },
                          ),
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
