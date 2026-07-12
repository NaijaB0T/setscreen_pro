import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/notification_config.dart';

class NotificationScreen extends StatefulWidget {
  final NotificationConfig config;

  const NotificationScreen({
    super.key,
    required this.config,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Sound Player
  late AudioPlayer _audioPlayer;

  // Timeline / stopwatch
  Timer? _stopwatchTimer;
  double _elapsedTime = 0.0; // in seconds

  // Lists of active/triggered notifications
  final List<NotificationItem> _triggeredQueue = [];
  final List<String> _removedIds = []; // tracked for banner dismissal

  // Safety Lock State
  bool _isLocked = false;

  // Clock state
  late Timer _clockTimer;
  String _timeString = "";
  String _dateString = "";

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) => _updateClock());
    
    _startAnimationEngine();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _stopwatchTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    final hours = now.hour.toString().padLeft(2, '0');
    final minutes = now.minute.toString().padLeft(2, '0');
    
    // Format Date: e.g. "Wednesday, September 10"
    final List<String> weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    final List<String> months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    
    if (mounted) {
      setState(() {
        _timeString = "$hours:$minutes";
        _dateString = "${weekdays[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}";
      });
    }
  }

  void _startAnimationEngine() {
    _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime += 0.1;
        });
        _checkTriggers();
      }
    });
  }

  Future<void> _playAlertChime() async {
    try {
      // Clean short alert chime
      await _audioPlayer.play(UrlSource("https://actions.google.com/sounds/v1/alarms/beep_short.ogg"), volume: 0.8);
    } catch (e) {
      debugPrint("Error playing chime: $e");
    }
  }

  void _checkTriggers() {
    for (var item in widget.config.queue) {
      // Check if item should trigger and hasn't been triggered yet
      if (_elapsedTime >= item.triggerDelay && !_triggeredQueue.any((x) => x.id == item.id)) {
        setState(() {
          _triggeredQueue.add(item);
        });
        _playAlertChime();

        // If it's a Top Banner alert, auto-dismiss after displayDuration
        if (widget.config.style == 'banner') {
          Future.delayed(Duration(milliseconds: (item.displayDuration * 1000).toInt()), () {
            if (mounted) {
              setState(() {
                _removedIds.add(item.id);
              });
            }
          });
        }
      }
    }
  }

  void _handleLock() {
    setState(() {
      _isLocked = true;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Notification Locked. Double-tap the top area to exit."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleUnlock() {
    if (_isLocked) {
      setState(() {
        _isLocked = false;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Notification Unlocked."),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildWallpaper() {
    final hasWallpaper = widget.config.wallpaperPath != null &&
        widget.config.wallpaperPath!.isNotEmpty &&
        File(widget.config.wallpaperPath!).existsSync();

    if (hasWallpaper) {
      return Image.file(
        File(widget.config.wallpaperPath!),
        fit: BoxFit.cover,
      );
    }

    // Default premium lock screen abstract dark gradient
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF13101C),
            Color(0xFF2C243B),
            Color(0xFF121422),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerBackground() {
    return Stack(
      children: [
        // Wallpaper
        Positioned.fill(child: _buildWallpaper()),
        
        // Mock home screen grid overlay
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMockAppIcon(Icons.message, "Messages", Colors.green),
                _buildMockAppIcon(Icons.phone, "Phone", Colors.blue),
                _buildMockAppIcon(Icons.camera_alt, "Camera", Colors.grey),
                _buildMockAppIcon(Icons.photo, "Photos", Colors.purple),
                _buildMockAppIcon(Icons.map, "Maps", Colors.teal),
                _buildMockAppIcon(Icons.music_note, "Music", Colors.orange),
                _buildMockAppIcon(Icons.web, "Browser", Colors.blueGrey),
                _buildMockAppIcon(Icons.settings, "Settings", Colors.grey[700]!),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockAppIcon(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLockScreenHeader(Color textColor) {
    return Column(
      children: [
        const SizedBox(height: 50),
        // Lock Icon at the top
        Icon(Icons.lock, color: textColor.withValues(alpha: 0.6), size: 22),
        const SizedBox(height: 12),
        // Date
        Text(
          _dateString,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: textColor.withValues(alpha: 0.8),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        // Time
        Text(
          _timeString,
          style: TextStyle(
            fontSize: 82,
            fontWeight: FontWeight.w200,
            color: textColor,
            letterSpacing: -2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("9:41", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          Row(
            children: [
              Icon(Icons.signal_cellular_4_bar, size: 14, color: textColor),
              const SizedBox(width: 4),
              Icon(Icons.wifi, size: 14, color: textColor),
              const SizedBox(width: 4),
              Icon(Icons.battery_full, size: 16, color: textColor),
            ],
          ),
        ],
      ),
    );
  }

  // Visual card builder for notification
  Widget _buildNotificationCard(NotificationItem item, bool isBannerStyle) {
    final cardBgColor = Colors.black.withValues(alpha: isBannerStyle ? 0.85 : 0.45);
    final borderCol = Colors.white.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular App icon mockup
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purple.withValues(alpha: 0.2),
                child: Text(
                  item.appName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.appName.toUpperCase(),
                          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const Text(
                          "now",
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.senderName,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.messageBody,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Main UI components
  Widget _buildLockScreenAlerts() {
    // Show triggered alerts stacked upwards from the bottom (standard list view is perfect)
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      top: 300, // Offset beneath date/clock
      child: ListView.builder(
        reverse: true, // Newest alerts stack at the bottom
        physics: const BouncingScrollPhysics(),
        itemCount: _triggeredQueue.length,
        itemBuilder: (context, index) {
          // Render newer items from the end of the triggered queue
          final item = _triggeredQueue[_triggeredQueue.length - 1 - index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1.0 - value) * 20),
                  child: child,
                ),
              );
            },
            child: _buildNotificationCard(item, false),
          );
        },
      ),
    );
  }

  Widget _buildBannerOverlay() {
    // Get the most recently triggered notification that has NOT been removed yet
    final activeBanners = _triggeredQueue.where((x) => !_removedIds.contains(x.id)).toList();
    if (activeBanners.isEmpty) return const SizedBox.shrink();

    final item = activeBanners.last; // Display latest banner

    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (value.clamp(0.0, 1.0) - 1.0) * 80),
              child: child,
            ),
          );
        },
        child: _buildNotificationCard(item, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLockStyle = widget.config.style == 'lockScreen';
    const textColor = Colors.white;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Wallpaper background
          Positioned.fill(
            child: isLockStyle ? _buildWallpaper() : _buildBannerBackground(),
          ),

          // 2. Lock screen overlays (Clock, shortcuts)
          if (isLockStyle) ...[
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: _buildLockScreenHeader(textColor),
            ),
            
            // Bottom Shortcut icons (flashlight & camera)
            Positioned(
              bottom: 40,
              left: 40,
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                child: const Icon(Icons.flashlight_on),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 40,
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ],

          // 3. Notification Alerts Rendering
          if (isLockStyle)
            _buildLockScreenAlerts()
          else
            _buildBannerOverlay(),

          // HIDE Developer Toolbar and status bar when locked
          if (!_isLocked) ...[
            // Status bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildStatusBar(textColor),
            ),
            // Floating Lock Button (Top-Right)
            Positioned(
              top: 50,
              right: 20,
              child: FloatingActionButton.small(
                heroTag: null,
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                onPressed: _handleLock,
                child: const Icon(Icons.lock_open),
              ),
            ),
            // Floating Back Button (Top-Left)
            Positioned(
              top: 50,
              left: 20,
              child: FloatingActionButton.small(
                heroTag: null,
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ] else ...[
            // 4. Double tap top zone (Top 90 pixels)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 90,
              child: GestureDetector(
                onDoubleTap: _handleUnlock,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
