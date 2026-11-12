import 'package:flutter/material.dart';
import '../models/market_data_model.dart';
import '../utils/extensions.dart';
import 'symbol_avatar.dart';
import '../providers/market_data_provider.dart';

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

/// Single Sort Chip
class MarketSortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final SortOrder sortOrder;
  final VoidCallback onTap;

  const MarketSortChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.sortOrder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionChip(
      onPressed: onTap,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              sortOrder == SortOrder.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
              color: Colors.white,
            ),
          ],
        ],
      ),
      backgroundColor: isSelected ? theme.primaryColor : theme.cardColor,
      side: BorderSide(
        color: isSelected
            ? Colors.grey.withValues(alpha: 0.4)
            : theme.dividerColor.withValues(alpha: 0.1),
        width: isSelected ? 1.5 : 1.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

/// Error state view
class MarketErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const MarketErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
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

/// Empty state view
class MarketEmptyView extends StatelessWidget {
  final bool isFiltering;
  final VoidCallback? onClear;

  const MarketEmptyView({super.key, this.isFiltering = false, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltering ? 'No matches found' : 'No market data available',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          if (isFiltering && onClear != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClear,
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Market Data List Item
class MarketDataListItem extends StatelessWidget {
  final MarketData data;
  final VoidCallback? onTap;

  const MarketDataListItem({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = data.isPositiveChange;
    final changeColor = isPositive ? Colors.green : Colors.red;
    final changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Symbol Avatar
              SymbolAvatar(symbol: data.baseSymbol),
              const SizedBox(width: 16),

              // Symbol and Price
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

              // Change Badge
              _ChangeBadge(
                changePercent: data.changePercent24h,
                isPositive: isPositive,
                color: changeColor,
                icon: changeIcon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge showing percentage change with color
class _ChangeBadge extends StatelessWidget {
  final double changePercent;
  final bool isPositive;
  final Color color;
  final IconData icon;

  const _ChangeBadge({
    required this.changePercent,
    required this.isPositive,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.25)
            : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
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
