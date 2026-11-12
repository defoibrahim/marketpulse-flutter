import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/market_data_model.dart';
import '../utils/extensions.dart';

class MainPriceDisplay extends StatelessWidget {
  const MainPriceDisplay({super.key, required this.data});

  final MarketData data;

  @override
  Widget build(BuildContext context) {
    final color = context.marketColors.forChange(data.change24h);
    final direction = data.change24h >= 0 ? 'up' : 'down';

    return Semantics(
      label: '${data.symbol} ${data.price.formatAsCurrency()}, $direction '
          '${data.change24h.abs().formatAsCurrency()}, '
          '${data.changePercent24h.formatAsPercentage()} in 24 hours',
      excludeSemantics: true,
      child: Center(
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.price.formatAsCurrency(),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    data.change24h >= 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${data.change24h.formatAsSignedCurrency()} '
                      '(${data.changePercent24h.formatAsPercentage()})',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketStatsGrid extends StatelessWidget {
  const MarketStatsGrid({super.key, required this.data});

  final MarketData data;

  @override
  Widget build(BuildContext context) {
    // Rows of equal-height tiles instead of a fixed-aspect grid, so the
    // tiles grow with the text size instead of clipping it.
    Widget row(Widget left, Widget right) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Statistics',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        row(
          DetailStatTile(
            label: '24h High',
            value: data.high24h.formatAsCurrency(),
          ),
          DetailStatTile(
            label: '24h Low',
            value: data.low24h.formatAsCurrency(),
          ),
        ),
        const SizedBox(height: 16),
        row(
          DetailStatTile(label: 'Volume', value: data.volume.formatCompact()),
          DetailStatTile(
            label: 'Market Cap',
            value: data.marketCap.formatCompact(),
          ),
        ),
      ],
    );
  }
}

class DetailStatTile extends StatelessWidget {
  const DetailStatTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.data});

  final MarketData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About ${data.baseSymbol}',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          data.description.isNotEmpty
              ? data.description
              : 'No description is available for ${data.symbol} yet.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
