import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/market_data_provider.dart';
import '../services/price_feed.dart';

/// App-bar switch for live prices that also shows the connection state:
/// grey when off, amber while connecting, green once the socket is open.
class LiveToggle extends StatelessWidget {
  const LiveToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketDataProvider>();
    final enabled = provider.isRealTimeEnabled;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final gain = context.marketColors.gain;
    final (Color color, IconData icon, String tooltip) =
        switch (provider.connectionStatus) {
      _ when !enabled => (
          muted,
          Icons.wifi_off,
          'Live prices are off. Tap to turn them on.',
        ),
      ConnectionStatus.connected => (
          gain,
          Icons.wifi,
          'Live prices are on. Tap to turn them off.',
        ),
      ConnectionStatus.connecting || ConnectionStatus.reconnecting => (
          Colors.amber.shade700,
          Icons.sync,
          'Connecting to live prices. Tap to turn them off.',
        ),
      ConnectionStatus.disconnected => (
          Colors.amber.shade700,
          Icons.sync_problem,
          'Live prices are not connected. Tap to turn them off.',
        ),
    };

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: 'Live prices',
        toggled: enabled,
        child: TextButton.icon(
          onPressed: enabled
              ? provider.disableRealTimeUpdates
              : provider.enableRealTimeUpdates,
          icon: Icon(icon, color: color, size: 20),
          label: Text(
            enabled ? 'LIVE' : 'OFF',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
