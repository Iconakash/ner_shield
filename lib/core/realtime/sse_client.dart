import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

@immutable
class RealtimeEvent {
  const RealtimeEvent({
    required this.kind,
    required this.id,
    required this.data,
    required this.receivedAt,
  });
  final String kind;
  final String id;
  final Map<String, dynamic>? data;
  final DateTime receivedAt;
}

class SseClient {
  SseClient({
    required String baseUrl,
    required this.accessTokenProvider,
    String path = '/api/v1/realtime/stream',
    this.heartbeatTimeout = const Duration(seconds: 45),
  })  : _url = Uri.parse('$baseUrl$path');

  final Uri _url;
  final Future<String?> Function() accessTokenProvider;
  final Duration heartbeatTimeout;

  final StreamController<RealtimeEvent> _controller =
      StreamController<RealtimeEvent>.broadcast();
  http.Client? _client;
  StreamSubscription<String>? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _attempt = 0;
  final bool _disposed = false;
  bool _stopRequested = false;

  Stream<RealtimeEvent> get stream => _controller.stream;
  bool get isConnected => _subscription != null;

  Future<void> connect() async {
    if (_disposed || _stopRequested) return;
    if (_subscription != null) return;
    final token = await accessTokenProvider();
    if (token == null || token.isEmpty) {
      _scheduleReconnect();
      return;
    }
    try {
      _client = http.Client();
      final req = http.Request('GET', _url)
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Cache-Control'] = 'no-cache'
        ..headers['Authorization'] = 'Bearer $token';
      final res = await _client!.send(req);
      if (res.statusCode != 200) {
        _closeTransport();
        _scheduleReconnect();
        return;
      }
      _attempt = 0;
      _armHeartbeat();
      _subscription = res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_onLine, onError: (_) {
        _closeTransport();
        _scheduleReconnect();
      }, onDone: () {
        _closeTransport();
        _scheduleReconnect();
      });
    } catch (_) {
      _closeTransport();
      _scheduleReconnect();
    }
  }

  Future<void> stop() async {
    _stopRequested = true;
    _closeTransport();
    await _controller.close();
  }

  Future<void> reconnectNow() async {
    _closeTransport();
    _attempt = 0;
    await connect();
  }

  void _onLine(String line) {
    _armHeartbeat();
    if (line.isEmpty) {
      _flushFrame();
      return;
    }
    if (line.startsWith(':')) return;
    final sep = line.indexOf(':');
    if (sep < 0) return;
    final field = line.substring(0, sep);
    var value = line.substring(sep + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    if (field == 'event') {
      _bufferKind = value;
    } else if (field == 'id') {
      _bufferId = value;
    } else if (field == 'data') {
      _bufferDataLines.add(value);
    }
  }

  String? _bufferKind;
  String? _bufferId;
  final List<String> _bufferDataLines = [];

  void _flushFrame() {
    final kind = _bufferKind;
    final id = _bufferId;
    if (kind == null && id == null && _bufferDataLines.isEmpty) return;
    final joined = _bufferDataLines.join('\n');
    Map<String, dynamic>? parsed;
    if (joined.isNotEmpty) {
      try {
        final v = jsonDecode(joined);
        if (v is Map<String, dynamic>) parsed = v;
      } catch (_) {}
    }
    if ((kind != null || id != null) && !_controller.isClosed) {
      _controller.add(RealtimeEvent(
        kind: kind ?? 'message',
        id: id ?? '',
        data: parsed,
        receivedAt: DateTime.now(),
      ));
    }
    _bufferKind = null;
    _bufferId = null;
    _bufferDataLines.clear();
  }

  void _armHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer(heartbeatTimeout, () {
      _closeTransport();
      _scheduleReconnect();
    });
  }

  void _closeTransport() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _client?.close();
    } catch (_) {}
    _client = null;
  }

  void _scheduleReconnect() {
    if (_disposed || _stopRequested) return;
    _reconnectTimer?.cancel();
    _attempt = (_attempt + 1).clamp(1, 6);
    final base = (1 << (_attempt - 1)).clamp(1, 60);
    final jitterMs = (base * 250) ~/ 4;
    final delay = Duration(seconds: base, milliseconds: jitterMs);
    _reconnectTimer = Timer(delay, connect);
  }
}
