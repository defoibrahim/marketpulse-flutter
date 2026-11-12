import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/json_readers.dart';
import '../price_feed.dart';
import 'demo_data.dart';

/// [PriceFeed] that simulates live prices from the bundled demo data: every
/// [interval] one market moves by up to 0.2%, in the same message format as
/// the WebSocket feed.
class DemoPriceFeed implements PriceFeed {
  DemoPriceFeed({
    AssetBundle? bundle,
    this.interval = const Duration(seconds: 1),
    Random? random,
  })  : _bundle = bundle ?? rootBundle,
        _random = random ?? Random();

  final AssetBundle _bundle;
  final Duration interval;
  final Random _random;

  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _status = ValueNotifier(ConnectionStatus.disconnected);
  List<_Market>? _markets;
  Timer? _timer;
  bool _wanted = false;
  bool _disposed = false;

  @override
  Stream<Map<String, dynamic>> get messages => _messages.stream;

  @override
  ValueListenable<ConnectionStatus> get status => _status;

  @override
  void connect() {
    if (_disposed || _timer != null) return;
    _wanted = true;
    _status.value = ConnectionStatus.connecting;
    _loadMarkets().then((markets) {
      // Disconnected meanwhile, or another connect already started ticking.
      if (!_wanted || _disposed || _timer != null) return;
      _status.value = ConnectionStatus.connected;
      _timer = Timer.periodic(interval, (_) => _tick(markets));
    }, onError: (Object error) {
      debugPrint('DemoPriceFeed: $error');
      if (!_disposed) _status.value = ConnectionStatus.disconnected;
    });
  }

  Future<List<_Market>> _loadMarkets() async {
    final cached = _markets;
    if (cached != null) return cached;
    final data = await DemoData.load(_bundle);
    return _markets = [
      for (final json in readList(data, 'marketData'))
        _Market(
          symbol: readString(json, 'symbol'),
          price: readDouble(json, 'price'),
          open: readDouble(json, 'price') - readDouble(json, 'change24h'),
          volume: readDouble(json, 'volume'),
        ),
    ];
  }

  void _tick(List<_Market> markets) {
    if (markets.isEmpty || _messages.isClosed) return;
    final market = markets[_random.nextInt(markets.length)];
    market.price *= 1 + (_random.nextDouble() - 0.5) * 0.004;
    market.volume *= 1 + _random.nextDouble() * 0.0005;
    final change = market.price - market.open;
    _messages.add({
      'type': 'market_update',
      'data': {
        'symbol': market.symbol,
        'price': market.price,
        'change24h': change,
        'changePercent24h': change / market.open * 100,
        'volume': market.volume,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    });
  }

  @override
  void disconnect() {
    _wanted = false;
    _timer?.cancel();
    _timer = null;
    if (!_disposed) _status.value = ConnectionStatus.disconnected;
  }

  @override
  void dispose() {
    if (_disposed) return;
    disconnect();
    _disposed = true;
    _messages.close();
    _status.dispose();
  }
}

class _Market {
  _Market({
    required this.symbol,
    required this.price,
    required this.open,
    required this.volume,
  });

  final String symbol;
  double price;
  final double open;
  double volume;
}
