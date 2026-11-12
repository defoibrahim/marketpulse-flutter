import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/market_data_model.dart';
import '../providers/market_data_provider.dart';
import '../utils/extensions.dart';
import 'symbol_avatar.dart';

/// Search field and sort chips above the market list.
///
/// The screen owns [controller], so it can clear the search from elsewhere
/// (e.g. the "Clear search" button of the empty state).
class MarketFilterBar extends StatelessWidget {
  const MarketFilterBar({
    super.key,
    required this.controller,
    required this.provider,
  });

  final TextEditingController controller;
  final MarketDataProvider provider;

  void _clear(BuildContext context) {
    controller.clear();
    provider.setSearchQuery('');
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.outlineVariant),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search markets...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () => _clear(context),
                      ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: colors.outline, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final (option, label) in const [
                (SortOption.price, 'Price'),
                (SortOption.change, 'Change'),
                (SortOption.symbol, 'Symbol'),
              ]) ...[
                MarketSortChip(
                  label: label,
                  isSelected: provider.sortOption == option,
                  sortOrder: provider.sortOrder,
                  onTap: () => provider.setSortOption(option),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Sort chip: the selected one is filled and shows the sort direction.
class MarketSortChip extends StatelessWidget {
  const MarketSortChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.sortOrder,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final SortOrder sortOrder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isSelected ? colors.onPrimary : colors.onSurface;
    final ascending = sortOrder == SortOrder.ascending;

    return Semantics(
      selected: isSelected,
      label: isSelected
          ? 'Sort by $label, ${ascending ? 'ascending' : 'descending'}. '
              'Tap to reverse.'
          : 'Sort by $label',
      excludeSemantics: true,
      button: true,
      onTap: onTap,
      child: ActionChip(
        onPressed: onTap,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: foreground,
              ),
            ],
          ],
        ),
        backgroundColor:
            isSelected ? colors.primary : Theme.of(context).cardColor,
        side: BorderSide(
          color: isSelected ? colors.primary : colors.outlineVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

/// Full-page error with a retry button.
class MarketErrorView extends StatelessWidget {
  const MarketErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty list: either nothing loaded, or nothing matches the search.
class MarketEmptyView extends StatelessWidget {
  const MarketEmptyView({super.key, this.isFiltering = false, this.onClear});

  final bool isFiltering;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltering ? Icons.search_off : Icons.inbox_outlined,
            size: 64,
            color: muted,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltering ? 'No matches found' : 'No market data available',
            style: TextStyle(fontSize: 16, color: muted),
          ),
          if (isFiltering && onClear != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onClear, child: const Text('Clear Search')),
          ],
        ],
      ),
    );
  }
}

/// One market in the list.
class MarketDataListItem extends StatelessWidget {
  const MarketDataListItem({super.key, required this.data, this.onTap});

  final MarketData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final change = data.changePercent24h;
    final direction = change >= 0 ? 'up' : 'down';

    return Semantics(
      button: onTap != null,
      label: '${data.symbol}, ${data.price.formatAsCurrency()}, '
          '$direction ${change.abs().toStringAsFixed(2)} percent in 24 hours',
      excludeSemantics: true,
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SymbolAvatar(symbol: data.baseSymbol),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.price.formatAsCurrency(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ChangeBadge(changePercent: change),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Coloured 24h change with an arrow, so the direction isn't shown by colour
/// alone.
class ChangeBadge extends StatelessWidget {
  const ChangeBadge({super.key, required this.changePercent});

  final double changePercent;

  @override
  Widget build(BuildContext context) {
    final color = context.marketColors.forChange(changePercent);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            changePercent >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            changePercent.formatAsPercentage(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
