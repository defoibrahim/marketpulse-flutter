import 'package:flutter/material.dart';

/// Brand colour of a crypto asset, e.g. `BTC` or `BTC/USD`. One source for
/// avatars and charts.
Color symbolColor(String symbol) {
  switch (symbol.split('/').first.toUpperCase()) {
    case 'BTC':
      return const Color(0xFFF7931A); // Bitcoin orange
    case 'ETH':
      return const Color(0xFF627EEA); // Ethereum blue
    case 'SOL':
      return const Color(0xFF00FFA3); // Solana green
    case 'ADA':
      return const Color(0xFF0033AD); // Cardano blue
    case 'DOT':
      return const Color(0xFFE6007A); // Polkadot pink
    case 'XRP':
      return const Color(0xFF23292F); // XRP dark
    case 'DOGE':
      return const Color(0xFFC3A634); // Dogecoin gold
    case 'AVAX':
      return const Color(0xFFE84142); // Avalanche red
    case 'MATIC':
      return const Color(0xFF8247E5); // Polygon purple
    case 'LINK':
      return const Color(0xFF2A5ADA); // Chainlink blue
    default:
      return Colors.blueGrey;
  }
}

/// Black or white, whichever reads better on [background].
Color contrastingTextColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;

/// Coloured circle with the asset's ticker. Decorative: the row that shows it
/// already says the symbol, so screen readers skip it.
class SymbolAvatar extends StatelessWidget {
  const SymbolAvatar({super.key, required this.symbol, this.size = 40});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ticker = symbol.split('/').first;
    final background = symbolColor(ticker);
    final foreground = contrastingTextColor(background);

    return ExcludeSemantics(
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: background,
        child: Text(
          ticker.length > 3 ? ticker.substring(0, 3) : ticker,
          maxLines: 1,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}
