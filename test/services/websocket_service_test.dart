import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/services/price_feed.dart';
import 'package:marketpulse/services/websocket_service.dart';

/// A socket the test opens, feeds and drops by hand.
class FakeConnection implements SocketConnection {
  final _controller = StreamController<dynamic>();
  final _ready = Completer<void>();
  bool closed = false;

  void open() => _ready.complete();
  void failHandshake(Object error) => _ready.completeError(error);
  void send(Map<String, dynamic> message) =>
      _controller.add(jsonEncode(message));
  void sendRaw(String message) => _controller.add(message);
  void drop() => _controller.close();

  @override
  Future<void> get ready => _ready.future;

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
  }
}

void main() {
  late List<FakeConnection> connections;
  late WebSocketService service;
  late List<Map<String, dynamic>> received;

  void start(FakeAsync async) {
    connections = [];
    received = [];
    service = WebSocketService(
      uri: Uri.parse('ws://test'),
      connector: (_) {
        final connection = FakeConnection();
        connections.add(connection);
        return connection;
      },
      backoff: (attempt) => Duration(seconds: 1 << attempt),
    );
    service.messages.listen(received.add);
  }

  test('reports connecting, then connected once the handshake succeeds', () {
    fakeAsync((async) {
      start(async);
      service.connect();
      expect(service.status.value, ConnectionStatus.connecting);

      connections.single.open();
      async.flushMicrotasks();

      expect(service.status.value, ConnectionStatus.connected);
      service.dispose();
    });
  });

  test('connect while connected does not open a second socket', () {
    fakeAsync((async) {
      start(async);
      service.connect();
      connections.single.open();
      async.flushMicrotasks();

      service.connect();

      expect(connections, hasLength(1));
      service.dispose();
    });
  });

  test('a late handshake failure from a replaced socket is ignored', () {
    fakeAsync((async) {
      start(async);
      // Toggle off and on before the first handshake finishes.
      service.connect();
      service.disconnect();
      service.connect();
      connections[1].open();
      async.flushMicrotasks();

      // The first socket only now reports that it failed.
      connections[0].failHandshake(Exception('refused'));
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 1));

      expect(connections, hasLength(2));
      expect(service.status.value, ConnectionStatus.connected);
      expect(connections[1].closed, isFalse);

      connections[1].send({'type': 'market_update'});
      async.flushMicrotasks();
      expect(received, hasLength(1));
      service.dispose();
    });
  });

  test('a handshake error reported twice schedules one reconnect', () {
    fakeAsync((async) {
      start(async);
      service.connect();
      // A failed handshake errors both the stream and `ready`.
      connections[0]._controller.addError(Exception('refused'));
      connections[0].failHandshake(Exception('refused'));
      async.flushMicrotasks();

      expect(service.status.value, ConnectionStatus.reconnecting);
      async.elapse(const Duration(seconds: 1));
      expect(connections, hasLength(2));
      async.elapse(const Duration(minutes: 1));
      expect(connections, hasLength(2));
      service.dispose();
    });
  });

  test('reconnects with exponential backoff after drops', () {
    fakeAsync((async) {
      start(async);
      service.connect();
      connections[0].open();
      async.flushMicrotasks();

      connections[0].drop();
      async.flushMicrotasks();
      expect(service.status.value, ConnectionStatus.reconnecting);
      async.elapse(const Duration(milliseconds: 999));
      expect(connections, hasLength(1));
      async.elapse(const Duration(milliseconds: 1));
      expect(connections, hasLength(2));

      // The second attempt fails too: the next wait doubles.
      connections[1].failHandshake(Exception('refused'));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1999));
      expect(connections, hasLength(2));
      async.elapse(const Duration(milliseconds: 1));
      expect(connections, hasLength(3));

      // A successful handshake resets the backoff.
      connections[2].open();
      async.flushMicrotasks();
      expect(service.status.value, ConnectionStatus.connected);
      connections[2].drop();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      expect(connections, hasLength(4));
      service.dispose();
    });
  });

  test('disconnect cancels a pending reconnect', () {
    fakeAsync((async) {
      start(async);
      service.connect();
      connections[0].open();
      async.flushMicrotasks();
      connections[0].drop();
      async.flushMicrotasks();

      service.disconnect();
      async.elapse(const Duration(minutes: 5));

      expect(connections, hasLength(1));
      expect(service.status.value, ConnectionStatus.disconnected);
      service.dispose();
    });
  });

  test('disconnect closes the socket', () {
    fakeAsync((async) {
      start(async);
      service.connect();
      connections[0].open();
      async.flushMicrotasks();

      service.disconnect();

      expect(connections[0].closed, isTrue);
      service.dispose();
    });
  });

  test('skips malformed messages and keeps the connection', () {
    fakeAsync((async) {
      start(async);
      service.connect();
      connections[0].open();
      async.flushMicrotasks();

      connections[0].sendRaw('not json');
      connections[0].send({'type': 'market_update'});
      async.flushMicrotasks();

      expect(received, [
        {'type': 'market_update'},
      ]);
      expect(service.status.value, ConnectionStatus.connected);
      service.dispose();
    });
  });

  test('dispose closes the message stream and stops reconnecting', () {
    fakeAsync((async) {
      start(async);
      var done = false;
      service.messages.listen(null, onDone: () => done = true);
      service.connect();
      connections[0].drop();
      async.flushMicrotasks();

      service.dispose();
      async.elapse(const Duration(minutes: 1));

      expect(done, isTrue);
      expect(connections, hasLength(1));
    });
  });
}
