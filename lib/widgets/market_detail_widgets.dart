import 'package:flutter/material.dart';
import '../models/market_data_model.dart';
import '../utils/extensions.dart';
import 'symbol_avatar.dart';

class MarketDetailAppBar extends StatelessWidget {
  final MarketData data;

  const MarketDetailAppBar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SymbolAvatar(symbol: data.symbol, size: 24),
            const SizedBox(width: 8),
            Text(
              data.symbol,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class MainPriceDisplay extends StatelessWidget {
  final MarketData data;

  const MainPriceDisplay({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final color = data.isPositiveChange ? Colors.greenAccent : Colors.redAccent;

    return Center(
      child: Column(
        children: [
          Text(
            data.price.formatAsCurrency(),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  data.isPositiveChange
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  '${data.change24h.formatAsCurrency()} (${data.changePercent24h.formatAsPercentage()})',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MarketStatsGrid extends StatelessWidget {
  final MarketData data;

  const MarketStatsGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.1,
          children: [
            DetailStatTile(
              label: '24h High',
              value: data.high24h.formatAsCurrency(),
            ),
            DetailStatTile(
              label: '24h Low',
              value: data.low24h.formatAsCurrency(),
            ),
            DetailStatTile(
              label: 'Volume',
              value: data.volume.formatCompact(),
            ),
            DetailStatTile(
              label: 'Market Cap',
              value: data.marketCap.formatCompact(),
            ),
          ],
        ),
      ],
    );
  }
}

class DetailStatTile extends StatelessWidget {
  final String label;
  final String value;

  const DetailStatTile({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutSection extends StatelessWidget {
  final MarketData data;

  const AboutSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About ${data.baseSymbol}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          data.description.isNotEmpty
              ? data.description
              : 'No description available for this asset at the moment. Tracking ${data.symbol} market data in real-time.',
          style: TextStyle(
            color: Colors.grey.shade400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
