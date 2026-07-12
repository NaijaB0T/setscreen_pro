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
          if (WebSocketTransformer.isUpgradeRequest(request)) {
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
            request.response.statusCode = HttpStatus.badRequest;
            request.response.close();
          }
        } else if (request.uri.path == '/' && request.method == 'GET') {
          request.response
            ..headers.contentType = ContentType.html
            ..write(_htmlControlPanel)
            ..close();
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

  static const String _htmlControlPanel = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SetScreen Pro Web Control Panel</title>
  <style>
    body {
      background-color: #000000;
      color: #ffffff;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      margin: 0;
      padding: 20px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      box-sizing: border-box;
    }
    .container {
      width: 100%;
      max-width: 480px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 20px;
      padding: 24px;
      box-sizing: border-box;
      box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
    }
    .header {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 100%;
      margin-bottom: 8px;
      position: relative;
    }
    .nav-back-btn {
      position: absolute;
      left: 0;
      padding: 6px 12px;
      font-size: 12px;
      font-weight: 600;
      border-radius: 8px;
      background: rgba(255, 255, 255, 0.1);
      border: 1px solid rgba(255, 255, 255, 0.15);
      color: #ffffff;
      cursor: pointer;
      display: none;
      outline: none;
    }
    .nav-back-btn:active {
      background: rgba(255, 255, 255, 0.2);
    }
    h1 {
      font-size: 18px;
      font-weight: 900;
      text-align: center;
      margin-top: 0;
      margin-bottom: 0;
      letter-spacing: 1.5px;
      text-transform: uppercase;
      background: linear-gradient(45deg, #ff007a, #007aff);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      padding: 8px 0;
    }
    .status {
      text-align: center;
      font-size: 12px;
      color: #888888;
      margin-bottom: 24px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background-color: #ff3b30;
    }
    .status-dot.connected {
      background-color: #34c759;
      box-shadow: 0 0 8px #34c759;
    }
    .section-title {
      font-size: 11px;
      font-weight: 800;
      color: #888888;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 16px;
      text-align: center;
    }
    .info-text {
      font-size: 13px;
      color: #bbbbbb;
      line-height: 1.6;
      text-align: center;
      background: rgba(255, 255, 255, 0.03);
      padding: 16px;
      border-radius: 12px;
      border: 1px solid rgba(255, 255, 255, 0.05);
    }
    .grid {
      display: grid;
      grid-template-columns: 1fr;
      gap: 16px;
    }
    button {
      background: rgba(255, 255, 255, 0.08);
      color: #ffffff;
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 12px;
      padding: 16px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      outline: none;
    }
    button:active {
      transform: scale(0.98);
      background: rgba(255, 255, 255, 0.15);
    }
    button.primary {
      background: #007aff;
      border-color: #007aff;
    }
    button.primary:active {
      background: #0056b3;
    }
    button.success {
      background: #34c759;
      border-color: #34c759;
    }
    button.success:active {
      background: #248a3d;
    }
    button.accent {
      background: #ff2d55;
      border-color: #ff2d55;
    }
    button.accent:active {
      background: #c3002f;
    }
    button.warning {
      background: #ff9500;
      border-color: #ff9500;
    }
    button.warning:active {
      background: #b36b00;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <button id="back-btn" class="nav-back-btn" onclick="showView('main')">← Back</button>
      <h1 id="title">SetScreen Pro Web Console</h1>
    </div>
    <div class="status">
      <div id="dot" class="status-dot"></div>
      <span id="state">Connecting to actor device...</span>
    </div>

    <!-- MAIN VIEW (NAVIGATION) -->
    <div id="main-view" class="view-panel">
      <div class="section-title">📺 Remote Screen Navigation</div>
      <div class="grid">
        <button class="menu-btn primary" onclick="navigateToScreen('green_screen')">🟢 Green Screen Viewport</button>
        <button class="menu-btn primary" onclick="navigateToScreen('messages')">💬 Messages Viewport</button>
        <button class="menu-btn primary" onclick="navigateToScreen('call')">📞 Audio Call Viewport</button>
        <button class="menu-btn" onclick="navigateToScreen('video_call')">📹 Video Call Setup</button>
        <button class="menu-btn" onclick="navigateToScreen('playback')">📺 Screen Playback Setup</button>
        <button class="menu-btn" onclick="navigateToScreen('notifications')">🔔 Notifications Setup</button>
        <button class="menu-btn" onclick="navigateToScreen('home_screen')">📱 Home Layout Setup</button>
        <button class="menu-btn" onclick="navigateToScreen('social_web')">🌐 Social & Web Viewport</button>
      </div>
    </div>

    <!-- GREEN SCREEN CONTROLS -->
    <div id="green_screen-view" class="view-panel" style="display: none;">
      <div class="section-title">🟢 Green Screen Controls</div>
      <div class="grid">
        <button class="action-btn warning" onclick="sendCommand('change_color')">🎨 Cycle Chroma Colors</button>
        <button class="action-btn primary" onclick="sendCommand('toggle_lock')">🔒 Toggle Viewport Lock</button>
      </div>
    </div>

    <!-- MESSAGES CONTROLS -->
    <div id="messages-view" class="view-panel" style="display: none;">
      <div class="section-title">💬 Messages Controls</div>
      <div class="grid">
        <button class="action-btn primary" onclick="sendCommand('trigger_key')">⌨️ Type Next Key</button>
        <button class="action-btn warning" onclick="sendCommand('trigger_opponent')">🗣️ Progress Dialog</button>
      </div>
    </div>

    <!-- CALL CONTROLS -->
    <div id="call-view" class="view-panel" style="display: none;">
      <div class="section-title">📞 Audio Call Controls</div>
      <div class="grid">
        <button class="action-btn success" onclick="sendCommand('force_ring')">🔔 Force Call Ring</button>
        <button class="action-btn accent" onclick="sendCommand('disconnect')">📴 Force Disconnect</button>
      </div>
    </div>

    <!-- SOCIAL & WEB CONTROLS -->
    <div id="social_web-view" class="view-panel" style="display: none;">
      <div class="section-title">🌐 Social & Web Controls</div>
      <div class="grid">
        <button class="action-btn primary" onclick="sendCommand('scroll_next')">📜 Scroll Next Page / Feed</button>
        <button class="action-btn warning" onclick="sendCommand('trigger_search')">🔍 Trigger Web Search</button>
      </div>
    </div>

    <!-- GENERIC SETUP VIEW -->
    <div id="generic-setup-view" class="view-panel" style="display: none;">
      <div class="section-title">⚙️ Setup Dashboard Screen</div>
      <div class="info-text">
        This screen serves as a configuration dashboard on the actor's device.<br/><br/>
        Configure the options locally on their device, then tap <strong>Start Take</strong> to open the live simulation viewport.
      </div>
    </div>
  </div>

  <script>
    let ws;
    const dot = document.getElementById('dot');
    const state = document.getElementById('state');

    function connect() {
      const proto = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const wsUrl = proto + '//' + window.location.host + '/ws';
      ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        dot.className = 'status-dot connected';
        state.innerText = 'Connected to actor device';
      };

      ws.onclose = () => {
        dot.className = 'status-dot';
        state.innerText = 'Disconnected. Reconnecting...';
        setTimeout(connect, 2000);
      };
    }

    function sendCommand(action, data = {}) {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ action, ...data }));
      }
    }

    function navigate(route) {
      sendCommand('navigate', { data: { route } });
    }

    function navigateToScreen(route) {
      navigate(route);
      
      // Determine which sub-view to display based on the route
      if (route === 'green_screen') {
        showView('green_screen');
      } else if (route === 'messages') {
        showView('messages');
      } else if (route === 'call') {
        showView('call');
      } else if (route === 'social_web') {
        showView('social_web');
      } else if (route === 'home') {
        showView('main');
      } else {
        showView('generic-setup');
      }
    }

    function showView(viewId) {
      // Hide all panels
      const panels = document.querySelectorAll('.view-panel');
      panels.forEach(p => p.style.display = 'none');

      // Show requested panel
      if (viewId === 'main') {
        document.getElementById('main-view').style.display = 'block';
        document.getElementById('back-btn').style.display = 'none';
        document.getElementById('title').innerText = 'SetScreen Pro Web Console';
      } else {
        const targetView = document.getElementById(viewId + '-view');
        if (targetView) {
          targetView.style.display = 'block';
        }
        document.getElementById('back-btn').style.display = 'block';
        
        // Format title
        const formattedTitle = viewId.replace('_', ' ').replace('-', ' ').toUpperCase() + ' PANEL';
        document.getElementById('title').innerText = formattedTitle;
      }
    }

    connect();
  </script>
</body>
</html>
''';
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
