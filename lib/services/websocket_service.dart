import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/constants.dart';
import 'price_feed.dart';

/// One socket connection. An interface so tests can drive the service
/// without a server.
abstract interface class SocketConnection {
  /// Completes when the handshake succeeds, or fails if it doesn't.
  Future<void> get ready;

  Stream<dynamic> get stream;

  Future<void> close();
}

typedef SocketConnector = SocketConnection Function(Uri uri);

class _ChannelConnection implements SocketConnection {
  _ChannelConnection(Uri uri) : _channel = WebSocketChannel.connect(uri);

  final WebSocketChannel _channel;

  @override
  Future<void> get ready => _channel.ready;

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}

/// [PriceFeed] over a WebSocket, with reconnects and exponential backoff.
///
/// Each connection gets a generation number. Callbacks from a socket that has
/// already been replaced or closed carry an old generation and are ignored,
/// so a late `onDone` or handshake error can never tear down a newer socket
/// or start a duplicate one.
class WebSocketService implements PriceFeed {
  WebSocketService({
    Uri? uri,
    SocketConnector? connector,
    Duration Function(int attempt)? backoff,
  })  : _uri = uri ?? Uri.parse(AppConstants.wsUrl),
        _connector = connector ?? _ChannelConnection.new,
        _backoff = backoff ?? defaultBackoff;

  final Uri _uri;
  final SocketConnector _connector;
  final Duration Function(int attempt) _backoff;

  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _status = ValueNotifier(ConnectionStatus.disconnected);

  SocketConnection? _connection;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  int _generation = 0;
  int _attempt = 0;
  bool _wanted = false;
  bool _disposed = false;

  static final _random = Random();

  /// 1s, 2s, 4s ... capped at 30s, plus up to 20% jitter so many clients
  /// don't reconnect in lockstep after a server restart.
  static Duration defaultBackoff(int attempt) {
    final base = min(1000 * pow(2, min(attempt, 5)).toInt(), 30000);
    final jitter = (_random.nextDouble() * 0.2 * base).round();
    return Duration(milliseconds: base + jitter);
  }

  @override
  Stream<Map<String, dynamic>> get messages => _messages.stream;

  @override
  ValueListenable<ConnectionStatus> get status => _status;

  @override
  void connect() {
    if (_disposed) return;
    _wanted = true;
    // Already connected, connecting, or waiting to reconnect.
    if (_connection != null || _reconnectTimer != null) return;
    _open();
  }

  void _open() {
    final generation = ++_generation;
    _status.value = _attempt == 0
        ? ConnectionStatus.connecting
        : ConnectionStatus.reconnecting;

    final SocketConnection connection;
    try {
      connection = _connector(_uri);
    } on Object catch (error) {
      _handleClosed(generation, error);
      return;
    }
    _connection = connection;
    _subscription = connection.stream.listen(
      (message) {
        if (generation == _generation) _handleMessage(message);
      },
      onError: (Object error) => _handleClosed(generation, error),
      onDone: () => _handleClosed(generation, null),
    );
    connection.ready.then(
      (_) {
        if (generation != _generation) return;
        _attempt = 0;
        _status.value = ConnectionStatus.connected;
      },
      onError: (Object error) => _handleClosed(generation, error),
    );
  }

  void _handleMessage(dynamic message) {
    if (message is! String) return;
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic> && !_messages.isClosed) {
        _messages.add(decoded);
      }
    } on FormatException catch (e) {
      debugPrint('WebSocket: ignoring a malformed message: $e');
    }
  }

  void _handleClosed(int generation, Object? error) {
    // A stale callback from a socket we already replaced or closed.
    if (generation != _generation) return;
    // Invalidate any other callback from this socket (a handshake error is
    // usually reported both on the stream and on `ready`).
    _generation++;
    if (error != null) debugPrint('WebSocket: connection lost: $error');
    _teardown();
    if (!_wanted || _disposed) {
      if (!_disposed) _status.value = ConnectionStatus.disconnected;
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    final delay = _backoff(_attempt);
    _attempt++;
    _status.value = ConnectionStatus.reconnecting;
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_wanted && !_disposed) _open();
    });
  }

  void _teardown() {
    final subscription = _subscription;
    final connection = _connection;
    _subscription = null;
    _connection = null;
    subscription?.cancel();
    connection?.close().catchError((Object error) {
      debugPrint('WebSocket: error while closing: $error');
    });
  }

  @override
  void disconnect() {
    _wanted = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _generation++;
    _attempt = 0;
    _teardown();
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
