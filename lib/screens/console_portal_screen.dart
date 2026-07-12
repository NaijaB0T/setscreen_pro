import 'dart:async';
import 'package:flutter/material.dart';
import '../services/console_network_service.dart';
import 'green_screen_screen.dart';
import 'setup_screen.dart';
import 'call_setup_screen.dart';
import 'video_setup_screen.dart';
import 'playback_setup_screen.dart';
import 'notification_setup_screen.dart';
import 'home_setup_screen.dart';

class ConsolePortalScreen extends StatefulWidget {
  const ConsolePortalScreen({super.key});

  @override
  State<ConsolePortalScreen> createState() => _ConsolePortalScreenState();
}

class _ConsolePortalScreenState extends State<ConsolePortalScreen> {
  // Receiver Server Mode states
  bool _isServerRunning = false;
  String _localIp = "Resolving...";
  StreamSubscription? _serverSubscription;

  // Director Client Mode states
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.");
  final ConsoleClient _client = ConsoleClient();
  bool _isConnected = false;
  StreamSubscription? _clientSubscription;

  @override
  void initState() {
    super.initState();
    _resolveIp();
    _isServerRunning = ConsoleServer.instance.isRunning;
    if (_isServerRunning) {
      _listenToServerCommands();
    }
  }

  @override
  void dispose() {
    _serverSubscription?.cancel();
    _clientSubscription?.cancel();
    _client.disconnect();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _resolveIp() async {
    final ip = await getLocalIpAddress();
    if (mounted) {
      setState(() {
        _localIp = ip;
        // Pre-populate client input with subnet if resolved to help connection
        if (ip != '127.0.0.1' && _ipController.text == "192.168.1.") {
          final parts = ip.split('.');
          if (parts.length == 4) {
            _ipController.text = "${parts[0]}.${parts[1]}.${parts[2]}.";
          }
        }
      });
    }
  }

  // --- SERVER / RECEIVER METHODS ---
  void _listenToServerCommands() {
    _serverSubscription?.cancel();
    _serverSubscription = ConsoleServer.instance.commandStream.listen((cmd) {
      if (cmd['action'] == 'navigate') {
        final route = cmd['route'] as String?;
        if (route != null) {
          _navigateLocal(route);
        }
      }
    });
  }

  void _navigateLocal(String route) {
    if (!mounted) return;

    // Return to root portal home first
    Navigator.of(context).popUntil((route) => route.isFirst);

    Widget target;
    switch (route) {
      case 'green_screen':
        target = const GreenScreenScreen();
        break;
      case 'messages':
        target = const SetupScreen();
        break;
      case 'call':
        target = const CallSetupScreen();
        break;
      case 'video_call':
        target = const VideoSetupScreen();
        break;
      case 'playback':
        target = const PlaybackSetupScreen();
        break;
      case 'notifications':
        target = const NotificationSetupScreen();
        break;
      case 'home_screen':
        target = const HomeSetupScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => target),
    );
  }

  Future<void> _toggleServer(bool start) async {
    if (start) {
      await ConsoleServer.instance.start();
      if (!mounted) return;
      setState(() {
        _isServerRunning = true;
      });
      _listenToServerCommands();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Console Server active. Listening on port 4040.")),
      );
    } else {
      _serverSubscription?.cancel();
      await ConsoleServer.instance.stop();
      if (!mounted) return;
      setState(() {
        _isServerRunning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Console Server stopped.")),
      );
    }
  }

  // --- CLIENT / DIRECTOR METHODS ---
  Future<void> _connectToActor() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid IP address.")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Connecting to $ip...")),
    );

    final ok = await _client.connect(ip);
    if (mounted) {
      if (ok) {
        setState(() {
          _isConnected = true;
        });
        _clientSubscription = _client.connectionStream.listen((connected) {
          setState(() {
            _isConnected = connected;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connection failed. Check IP & client server status.")),
        );
      }
    }
  }

  void _sendDirectorCommand(String action, [Map<String, dynamic>? data]) {
    _client.sendCommand(action, data ?? {});
  }

  // --- BUILD WIDGETS ---
  Widget _buildFrostedContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }

  Widget _buildDirectorDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "DIRECTOR DASHBOARD",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.amberAccent),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _client.disconnect();
                setState(() {
                  _isConnected = false;
                });
              },
              icon: const Icon(Icons.link_off, size: 16),
              label: const Text("Disconnect", style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFrostedContainer(
          child: Row(
            children: [
              const Icon(Icons.wifi_tethering, color: Colors.amberAccent),
              const SizedBox(width: 12),
              Text(
                "Connected to Actor: ${_ipController.text}",
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Global Route Commands
        const Text("GLOBAL SCENE NAVIGATION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildFrostedContainer(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildControlBtn("Green Screen", () => _sendDirectorCommand("navigate", {"route": "green_screen"})),
              _buildControlBtn("Messages Setup", () => _sendDirectorCommand("navigate", {"route": "messages"})),
              _buildControlBtn("Prop Call Setup", () => _sendDirectorCommand("navigate", {"route": "call"})),
              _buildControlBtn("Video Call Setup", () => _sendDirectorCommand("navigate", {"route": "video_call"})),
              _buildControlBtn("Playback Setup", () => _sendDirectorCommand("navigate", {"route": "playback"})),
              _buildControlBtn("Notifications Setup", () => _sendDirectorCommand("navigate", {"route": "notifications"})),
              _buildControlBtn("Home Layout Setup", () => _sendDirectorCommand("navigate", {"route": "home_screen"})),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Message control options
        const Text("PROP MESSAGES SIMULATION CONTROL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildFrostedContainer(
          child: Row(
            children: [
              Expanded(
                child: _buildControlBtn(
                  "Force Keyboard Tap", 
                  () => _sendDirectorCommand("trigger_key"),
                  Colors.tealAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlBtn(
                  "Progress Opponent Dialog", 
                  () => _sendDirectorCommand("trigger_opponent"),
                  Colors.tealAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Calls control options
        const Text("PROP CALLS SIMULATION CONTROL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildFrostedContainer(
          child: Row(
            children: [
              Expanded(
                child: _buildControlBtn(
                  "Trigger Ringtone / Ringing", 
                  () => _sendDirectorCommand("force_ring"),
                  Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlBtn(
                  "Force Disconnect", 
                  () => _sendDirectorCommand("disconnect"),
                  Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Green Screen / VFX Control
        const Text("GREEN SCREEN COMPOSITING CONTROL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildFrostedContainer(
          child: Row(
            children: [
              Expanded(
                child: _buildControlBtn(
                  "Cycle Chroma Colors", 
                  () => _sendDirectorCommand("change_color"),
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlBtn(
                  "Toggle Viewport Lock", 
                  () => _sendDirectorCommand("toggle_lock"),
                  Colors.greenAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Alerts / Notifications
        const Text("PROP NOTIFICATIONS CONTROL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildFrostedContainer(
          child: SizedBox(
            width: double.infinity,
            child: _buildControlBtn(
              "Instantly Drop Queue Notification", 
              () => _sendDirectorCommand("drop_notification"),
              Colors.purpleAccent,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildControlBtn(String text, VoidCallback onPressed, [Color? color, Color? textColor]) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.white10,
        foregroundColor: textColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amberAccent,
          secondary: Colors.amber,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            "DIRECTOR REMOTE CONSOLE",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          centerTitle: true,
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: _isConnected
              ? _buildDirectorDashboard()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receiver Mode Setup card
                    const Text("ACTOR DEVICE RECEIVER ROLE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    _buildFrostedContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Turn this on if this device is the actor's prop. It will receive navigation and simulation cues wirelessly.",
                            style: TextStyle(fontSize: 11, color: Colors.white38),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Local IP: $_localIp",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Switch(
                                value: _isServerRunning,
                                onChanged: _toggleServer,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Director Master setup card
                    const Text("DIRECTOR REMOTE CONTROLLER ROLE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    _buildFrostedContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Enter the IP address shown on the Actor's screen to link up and issue real-time commands.",
                            style: TextStyle(fontSize: 11, color: Colors.white38),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ipController,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: const InputDecoration(
                              labelText: "Actor Device IP",
                              labelStyle: TextStyle(color: Colors.white38),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _connectToActor,
                              icon: const Icon(Icons.link),
                              label: const Text(
                                "CONNECT TO ACTOR",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amberAccent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
        ),
      ),
    );
  }
}
