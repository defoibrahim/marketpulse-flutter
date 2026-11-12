import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../core/theme/app_theme.dart';
import '../models/portfolio_model.dart';
import '../utils/extensions.dart';
import 'analytics_widgets.dart' show sliceTitle;
import 'chart_badge.dart';
import 'symbol_avatar.dart';

class PortfolioSummaryCard extends StatelessWidget {
  const PortfolioSummaryCard({super.key, required this.overview});

  final PortfolioOverview overview;

  @override
  Widget build(BuildContext context) {
    final isGain = overview.totalPnl >= 0;
    final change = '${overview.totalPnl.formatAsSignedCurrency()} '
        '(${overview.totalPnlPercent.formatAsPercentage()})';

    return Semantics(
      label: 'Total balance ${overview.totalValue.formatAsCurrency()}, '
          '${isGain ? 'up' : 'down'} $change',
      excludeSemantics: true,
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppTheme.brandGradient,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  overview.totalValue.formatAsCurrency(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGain ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        change,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssetListTile extends StatelessWidget {
  const AssetListTile({super.key, required this.holding});

  final PortfolioHolding holding;

  @override
  Widget build(BuildContext context) {
    final ticker = holding.symbol.split('/').first;
    final color = context.marketColors.forChange(holding.pnl);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: MergeSemantics(
        child: ListTile(
          leading: SymbolAvatar(symbol: ticker),
          title: Text(
            holding.symbol,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${holding.quantity.formatQuantity()} $ticker'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                holding.value.formatAsCurrency(),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                holding.pnlPercent.formatAsPercentage(),
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AllocationPieChart extends StatelessWidget {
  const AllocationPieChart({super.key, required this.holdings});

  final List<PortfolioHolding> holdings;

  @override
  Widget build(BuildContext context) {
    if (holdings.isEmpty) return const SizedBox.shrink();

    // The four largest holdings, then everything else as "others".
    final sorted = List.of(holdings)
      ..sort((a, b) => b.allocation.compareTo(a.allocation));
    final top = sorted.take(4).toList();
    final others =
        sorted.skip(4).fold(0.0, (sum, item) => sum + item.allocation);
    String ticker(PortfolioHolding h) => h.symbol.split('/').first;

    return Semantics(
      label: 'Asset allocation: ${[
        for (final h in top) '${ticker(h)} ${h.allocation.toStringAsFixed(1)} percent',
        if (others > 0) 'others ${others.toStringAsFixed(1)} percent',
      ].join(', ')}',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.8,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: [
              for (final h in top)
                PieChartSectionData(
                  color: symbolColor(h.symbol),
                  value: h.allocation,
                  title: sliceTitle(h.allocation),
                  titlePositionPercentageOffset: 0.4,
                  radius: 60,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: contrastingTextColor(symbolColor(h.symbol)),
                  ),
                  badgeWidget: Skeleton.ignore(child: ChartBadge(ticker(h))),
                  badgePositionPercentageOffset: .98,
                ),
              if (others > 0)
                PieChartSectionData(
                  color: Colors.grey,
                  value: others,
                  title: sliceTitle(others),
                  titlePositionPercentageOffset: 0.4,
                  radius: 50,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: contrastingTextColor(Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
