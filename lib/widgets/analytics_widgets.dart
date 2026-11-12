import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_model.dart';
import '../utils/extensions.dart';
import 'chart_badge.dart';
import 'symbol_avatar.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;

  /// Icon colour; defaults to the theme's primary colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color ?? colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.trendData,
    required this.isPositive,
    this.overrideColor,
  });

  final TrendData trendData;
  final bool isPositive;
  final Color? overrideColor;

  @override
  Widget build(BuildContext context) {
    final market = context.marketColors;
    final color = overrideColor ?? (isPositive ? market.gain : market.loss);
    final theme = Theme.of(context);
    final spots = [
      for (var i = 0; i < trendData.data.length; i++)
        FlSpot(i.toDouble(), trendData.data[i].priceIndex),
    ];
    final summary = trendData.summary;

    return Semantics(
      label: 'Market trend over ${trendData.timeframe}: '
          '${summary.change.formatAsPercentage()}, '
          'volatility ${summary.volatility.toStringAsFixed(2)} percent',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.7,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: color,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => theme.cardColor,
                  getTooltipItems: (touchedSpots) => [
                    for (final spot in touchedSpots)
                      LineTooltipItem(
                        spot.y.toStringAsFixed(2),
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Percentage label for a pie slice. Slices under 4% are too thin for a
/// label (it would sit on the neighbours); the chart's semantics label still
/// lists every value.
String sliceTitle(double percent) =>
    percent < 4 ? '' : '${percent.toStringAsFixed(1)}%';

class DominancePieChart extends StatelessWidget {
  const DominancePieChart({super.key, required this.dominance});

  final MarketDominance dominance;

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('BTC', 'Bitcoin', dominance.btc, symbolColor('BTC')),
      ('ETH', 'Ethereum', dominance.eth, symbolColor('ETH')),
      ('Others', 'others', dominance.others, Colors.grey),
    ];
    final largest =
        sections.map((s) => s.$3).reduce((a, b) => a > b ? a : b);

    return Semantics(
      label: 'Market dominance: ${[
        for (final (_, name, value, _) in sections)
          '$name ${value.toStringAsFixed(1)} percent',
      ].join(', ')}',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.8,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: [
              for (final (label, _, value, color) in sections)
                PieChartSectionData(
                  color: color,
                  value: value,
                  title: sliceTitle(value),
                  titlePositionPercentageOffset: 0.4,
                  radius: value == largest ? 60 : 50,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: contrastingTextColor(color),
                  ),
                  badgeWidget: Skeleton.ignore(child: ChartBadge(label)),
                  badgePositionPercentageOffset: .98,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
