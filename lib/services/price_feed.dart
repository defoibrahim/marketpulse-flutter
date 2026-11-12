import 'package:flutter/foundation.dart';

/// State of a live price connection.
enum ConnectionStatus { disconnected, connecting, connected, reconnecting }

/// A stream of live market updates, e.g. a WebSocket.
///
/// Messages look like
/// `{"type": "market_update", "data": {"symbol": "BTC/USD", "price": ...}}`.
abstract interface class PriceFeed {
  Stream<Map<String, dynamic>> get messages;

  ValueListenable<ConnectionStatus> get status;

  /// Starts (or keeps) the connection open, reconnecting after drops.
  void connect();

  /// Closes the connection and stops reconnecting.
  void disconnect();

  void dispose();
}
