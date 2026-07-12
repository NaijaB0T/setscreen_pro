import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/playback_config.dart';

class PlaybackScreen extends StatefulWidget {
  final PlaybackConfig playbackConfig;

  const PlaybackScreen({
    super.key,
    required this.playbackConfig,
  });

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLocked = false;
  
  // FocusNode to intercept hardware keys (volume buttons)
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    
    // Hide status bar dynamically if configured
    if (widget.playbackConfig.hideStatusBar) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    // Restore system UI on dispose
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    final file = File(widget.playbackConfig.videoPath);
    if (!await file.exists()) {
      debugPrint("Playback video file does not exist.");
      return;
    }

    _controller = VideoPlayerController.file(file);

    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setPlaybackSpeed(widget.playbackConfig.playbackSpeed);
      await _controller!.setVolume(widget.playbackConfig.muteAudio ? 0.0 : 1.0);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // Request keyboard focus immediately to catch volume button keys
        _focusNode.requestFocus();
      }
    } catch (e) {
      debugPrint("Error initializing video playback: $e");
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _handleLock() {
    setState(() {
      _isLocked = true;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Screen Playback Locked. Double-tap the top area to exit."),
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
          content: Text("Screen Playback Unlocked."),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      // Pop back to setup screen if unlocked and double-tapped
      Navigator.of(context).pop();
    }
  }

  Widget _buildPlaybackFeed() {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        // Intercept volume buttons if configured
        if (widget.playbackConfig.useVolumeTrigger && event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp ||
              event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
            _togglePlayPause();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Full-screen Video feed
            Positioned.fill(
              child: _buildPlaybackFeed(),
            ),

            // 2. Gesture Interceptor Overlay
            // Completely transparent, catches all taps/swipes to prevent pausing/changing state during filming
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Do nothing (block action)
                },
                onDoubleTap: () {
                  // Do nothing (block action)
                },
                onPanUpdate: (details) {
                  // Do nothing (block action)
                },
                child: const SizedBox.shrink(),
              ),
            ),

            // 3. Safety Lock Button & Unlock/Exit Double-tap Zone
            if (!_isLocked) ...[
              // Floating Lock Button (Top-Right)
              Positioned(
                top: 50,
                right: 20,
                child: FloatingActionButton.small(
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
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back),
                ),
              ),
            ],

            // Invisible Double-Tap Exit Trigger Zone (Top 90 pixels of screen)
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
        ),
      ),
    );
  }
}
