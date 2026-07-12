import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/tracking_marker_painter.dart';
import '../services/console_network_service.dart';

class GreenScreenScreen extends StatefulWidget {
  const GreenScreenScreen({super.key});

  @override
  State<GreenScreenScreen> createState() => _GreenScreenScreenState();
}

class _GreenScreenScreenState extends State<GreenScreenScreen> {
  // Screen state
  Color _chromaColor = const Color(0xFF00B140); // Default Chroma Green
  String _markerStyle = 'vfxTriangle'; // Default style
  Color _markerColor = Colors.black; // Default marker color
  bool _isLocked = false;
  bool _showConfigSheet = false;

  // Markers positions
  final List<Offset> _markerPositions = List.filled(5, Offset.zero);
  bool _isPositionsInitialized = false;

  StreamSubscription? _consoleSubscription;

  @override
  void initState() {
    super.initState();
    if (ConsoleServer.instance.isRunning) {
      _consoleSubscription = ConsoleServer.instance.commandStream.listen((cmd) {
        if (cmd['action'] == 'change_color') {
          _cycleColor();
        } else if (cmd['action'] == 'toggle_lock') {
          _toggleLock();
        }
      });
    }
  }

  @override
  void dispose() {
    _consoleSubscription?.cancel();
    super.dispose();
  }

  void _cycleColor() {
    if (mounted) {
      setState(() {
        if (_chromaColor == const Color(0xFF00B140)) {
          _chromaColor = const Color(0xFF0000FF);
        } else if (_chromaColor == const Color(0xFF0000FF)) {
          _chromaColor = const Color(0xFFFF00FF);
        } else {
          _chromaColor = const Color(0xFF00B140);
        }
      });
    }
  }

  void _toggleLock() {
    if (mounted) {
      setState(() {
        _isLocked = !_isLocked;
        if (_isLocked) {
          _showUnlockMessage();
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Screen Unlocked.")),
          );
        }
      });
    }
  }

  // Constants
  static const double markerSize = 60.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPositionsInitialized) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      // Initialize the 5 default positions (Top-Left, Top-Right, Bottom-Left, Bottom-Right, Center)
      _markerPositions[0] = const Offset(50, 100);                         // Top-Left
      _markerPositions[1] = Offset(width - markerSize - 50, 100);          // Top-Right
      _markerPositions[2] = Offset(50, height - markerSize - 160);         // Bottom-Left
      _markerPositions[3] = Offset(width - markerSize - 50, height - markerSize - 160); // Bottom-Right
      _markerPositions[4] = Offset(width / 2 - markerSize / 2, height / 2 - markerSize / 2 - 30); // Center
      _isPositionsInitialized = true;
    }
  }

  void _showUnlockMessage() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Screen Locked. Double-tap anywhere to unlock."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleDoubleTap() {
    if (_isLocked) {
      setState(() {
        _isLocked = false;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Screen Unlocked."),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildMarker(int index) {
    return Positioned(
      left: _markerPositions[index].dx,
      top: _markerPositions[index].dy,
      child: GestureDetector(
        onPanUpdate: _isLocked
            ? null
            : (details) {
                setState(() {
                  final newPos = _markerPositions[index] + details.delta;
                  // Screen boundary checks to keep markers inside viewport
                  final size = MediaQuery.of(context).size;
                  final x = newPos.dx.clamp(0.0, size.width - markerSize);
                  final y = newPos.dy.clamp(0.0, size.height - markerSize);
                  _markerPositions[index] = Offset(x, y);
                });
              },
        child: SizedBox(
          width: markerSize,
          height: markerSize,
          child: CustomPaint(
            painter: TrackingMarkerPainter(
              style: _markerStyle,
              color: _markerColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color, String label) {
    final isSelected = _chromaColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _chromaColor = color;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white24,
                width: isSelected ? 3.0 : 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMarkerStyleSelector(String style, String label) {
    final isSelected = _markerStyle == style;
    return GestureDetector(
      onTap: () {
        setState(() {
          _markerStyle = style;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white10 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.tealAccent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CustomPaint(
                painter: TrackingMarkerPainter(
                  style: style,
                  color: isSelected ? Colors.tealAccent : Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.tealAccent : Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerColorSelector(Color color, String label) {
    final isSelected = _markerColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _markerColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white10 : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.tealAccent : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30),
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.tealAccent : Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSheet() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: const Border(
            top: BorderSide(color: Colors.white12, width: 1),
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Chroma Color Title
            const Text(
              "CHROMA KEY COLOR",
              style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorDot(const Color(0xFF00B140), "Green"),
                _buildColorDot(const Color(0xFF0047BB), "Blue"),
                _buildColorDot(const Color(0xFFD10056), "Magenta"),
              ],
            ),
            const SizedBox(height: 24),

            // Marker Style Selector
            const Text(
              "TRACKING MARKER STYLE",
              style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMarkerStyleSelector('crosshair', 'Crosshair'),
                  _buildMarkerStyleSelector('x', 'Box X'),
                  _buildMarkerStyleSelector('circle', 'Concentric'),
                  _buildMarkerStyleSelector('vfxTriangle', 'VFX Triangle'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Marker Color Selector
            const Text(
              "MARKER COLOR",
              style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMarkerColorSelector(Colors.black, "Black"),
                  _buildMarkerColorSelector(Colors.white, "White"),
                  _buildMarkerColorSelector(const Color(0xFFFF9500), "Orange"),
                  _buildMarkerColorSelector(const Color(0xFFFFCC00), "Yellow"),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Done Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showConfigSheet = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("DONE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _chromaColor,
      body: GestureDetector(
        onDoubleTap: _handleDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // 1. Draggable Markers
            _buildMarker(0),
            _buildMarker(1),
            _buildMarker(2),
            _buildMarker(3),
            _buildMarker(4),

            // 2. Lock / Unlock Floating overlay button
            if (!_isLocked) ...[
              // Floating Lock Button (Top-Right)
              Positioned(
                top: 50,
                right: 20,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.lock_open),
                  onPressed: () {
                    setState(() {
                      _isLocked = true;
                      _showConfigSheet = false; // Hide config sheet when locking
                    });
                    _showUnlockMessage();
                  },
                ),
              ),
              // Floating Settings Trigger Button (Bottom-Right)
              if (!_showConfigSheet)
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.tealAccent,
                    child: const Icon(Icons.settings),
                    onPressed: () {
                      setState(() {
                        _showConfigSheet = true;
                      });
                    },
                  ),
                ),
              // Floating Back Button (Top-Left)
              Positioned(
                top: 50,
                left: 20,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],

            // 3. Frosted Configuration Sheet
            if (_showConfigSheet && !_isLocked)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildConfigSheet(),
              ),
          ],
        ),
      ),
    );
  }
}
