import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConsoleServer {
  ConsoleServer._privateConstructor();
  static final ConsoleServer instance = ConsoleServer._privateConstructor();

  HttpServer? _server;
  final List<WebSocket> _sockets = [];
  final StreamController<Map<String, dynamic>> _commandController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get commandStream => _commandController.stream;
  bool get isRunning => _server != null;

  Future<void> start() async {
    if (isRunning) return;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 4040);
      _server!.listen((HttpRequest request) {
        if (request.uri.path == '/ws') {
          WebSocketTransformer.upgrade(request).then((WebSocket socket) {
            _sockets.add(socket);
            socket.listen((message) {
              try {
                final Map<String, dynamic> data = jsonDecode(message as String);
                _commandController.add(data);
              } catch (e) {
                debugPrint("Error parsing message: $e");
              }
            }, onDone: () {
              _sockets.remove(socket);
            }, onError: (err) {
              _sockets.remove(socket);
            });
          });
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.close();
        }
      });
      debugPrint("Console server started on port 4040");
    } catch (e) {
      debugPrint("Error starting console server: $e");
      _server = null;
    }
  }

  Future<void> stop() async {
    for (var socket in _sockets) {
      try {
        await socket.close();
      } catch (_) {}
    }
    _sockets.clear();
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    debugPrint("Console server stopped");
  }
}

class ConsoleClient {
  WebSocket? _socket;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _socket != null && _socket!.readyState == WebSocket.open;

  Future<bool> connect(String ip) async {
    await disconnect();
    try {
      final targetUrl = 'ws://$ip:4040/ws';
      debugPrint("Connecting to console receiver: $targetUrl");
      _socket = await WebSocket.connect(targetUrl).timeout(const Duration(seconds: 5));
      _connectionController.add(true);

      _socket!.listen(
        (msg) {
          // Client only sends commands in this workflow, but we listen for completeness
        },
        onDone: () {
          _socket = null;
          _connectionController.add(false);
        },
        onError: (err) {
          _socket = null;
          _connectionController.add(false);
        },
      );
      return true;
    } catch (e) {
      debugPrint("Connection failed: $e");
      _socket = null;
      _connectionController.add(false);
      return false;
    }
  }

  void sendCommand(String action, Map<String, dynamic> data) {
    if (!isConnected) {
      debugPrint("Cannot send command, client not connected.");
      return;
    }
    final Map<String, dynamic> payload = {
      'action': action,
      ...data,
    };
    try {
      _socket!.add(jsonEncode(payload));
      debugPrint("Sent command: $payload");
    } catch (e) {
      debugPrint("Error sending command: $e");
    }
  }

  Future<void> disconnect() async {
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    _connectionController.add(false);
  }
}

Future<String> getLocalIpAddress() async {
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (!addr.isLoopback) {
          return addr.address;
        }
      }
    }
  } catch (e) {
    debugPrint("Error resolving local IP: $e");
  }
  return '127.0.0.1';
}
