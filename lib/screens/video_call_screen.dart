import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import '../models/project_config.dart';
import '../models/video_call_config.dart';

class VideoCallScreen extends StatefulWidget {
  final ProjectConfig? config;               // Old config parameter
  final VideoCallConfig? videoCallConfig;    // New Video Call Config

  const VideoCallScreen({
    super.key,
    this.config,
    this.videoCallConfig,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // Video Player (Incoming caller feed)
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;

  // Selfie Camera (PIP self feed)
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraFront = true;
  bool _isCameraPermissionDenied = false;

  // Controls State
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isLocked = false;

  // Picture in Picture drag position
  Offset _pipPosition = const Offset(20, 60); // Initial position relative to top-right
  bool _isPipPositionInitialized = false;

  // Consolidate configurations
  String get callerName => widget.videoCallConfig?.callerName ?? widget.config?.contactName ?? 'Michael Naizu';
  String? get avatarPath => widget.videoCallConfig?.avatarPath ?? widget.config?.avatarPath;
  String? get videoPath => widget.videoCallConfig?.videoPath ?? widget.config?.videoCallerPath;
  bool get isIncoming => widget.videoCallConfig?.isIncoming ?? widget.config?.isIncomingCall ?? true;
  bool get isGreenScreenMode => widget.videoCallConfig?.isGreenScreenMode ?? false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _initializeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPipPositionInitialized) {
      final size = MediaQuery.of(context).size;
      // Position PIP top right by default
      _pipPosition = Offset(size.width - 130 - 20, 60);
      _isPipPositionInitialized = true;
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    if (isGreenScreenMode) return;

    final path = videoPath;
    if (path == null || path.isEmpty) {
      debugPrint("No video path specified.");
      return;
    }

    try {
      final file = File(path);
      if (await file.exists()) {
        _videoPlayerController = VideoPlayerController.file(file);
      } else {
        debugPrint("Video file does not exist at $path.");
        return;
      }

      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(true);
      await _videoPlayerController!.play();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error initializing video player: $e");
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint("No cameras found.");
        return;
      }

      // Find front camera
      CameraDescription? selectedCamera;
      for (var camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          _isCameraFront = true;
          break;
        }
      }

      // Fallback
      selectedCamera ??= _cameras.first;

      await _startCameraController(selectedCamera);
    } catch (e) {
      debugPrint("Error detecting cameras: $e");
      if (mounted) {
        setState(() {
          _isCameraPermissionDenied = true;
        });
      }
    }
  }

  Future<void> _startCameraController(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraPermissionDenied = false;
        });
      }
    } catch (e) {
      debugPrint("Error initializing camera controller: $e");
      if (mounted) {
        setState(() {
          _isCameraPermissionDenied = true;
        });
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.isEmpty) return;

    CameraLensDirection targetDirection =
        _isCameraFront ? CameraLensDirection.back : CameraLensDirection.front;

    CameraDescription? nextCamera;
    for (var camera in _cameras) {
      if (camera.lensDirection == targetDirection) {
        nextCamera = camera;
        break;
      }
    }

    nextCamera ??= _cameras.first;
    _isCameraFront = nextCamera.lensDirection == CameraLensDirection.front;

    await _startCameraController(nextCamera);
  }

  void _handleLock() {
    setState(() {
      _isLocked = true;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("FaceTime Screen Locked. Double-tap the top area to unlock."),
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
          content: Text("FaceTime Screen Unlocked."),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildSelfPreview() {
    if (_isCameraOff) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white54, size: 28),
        ),
      );
    }

    if (_isCameraPermissionDenied || !_isCameraInitialized || _cameraController == null) {
      // Fallback: render avatar silhouette
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white10,
            backgroundImage: avatarPath != null && File(avatarPath!).existsSync()
                ? FileImage(File(avatarPath!))
                : null,
            child: avatarPath == null || !File(avatarPath!).existsSync()
                ? const Icon(Icons.person, color: Colors.white54, size: 28)
                : null,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildBackgroundFeed() {
    if (isGreenScreenMode) {
      // Full screen chroma green with tracking marks
      return Stack(
        children: [
          Container(
            color: const Color(0xFF00B140), // Chroma Green
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: GridTrackingPainter(),
            ),
          ),
        ],
      );
    }

    if (_isVideoInitialized && _videoPlayerController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoPlayerController!.value.size.width,
          height: _videoPlayerController!.value.size.height,
          child: VideoPlayer(_videoPlayerController!),
        ),
      );
    }

    // Default connecting overlay
    return Container(
      color: Colors.grey[950],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_call, size: 80, color: Colors.white12),
            const SizedBox(height: 16),
            Text(
              "Connecting to $callerName...",
              style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Video Feed (Incoming Stream or Green Screen)
          Positioned.fill(
            child: _buildBackgroundFeed(),
          ),

          // 2. Picture-in-Picture (PIP) Window (Self Camera Feed)
          Positioned(
            left: _pipPosition.dx,
            top: _pipPosition.dy,
            width: 130,
            height: 180,
            child: GestureDetector(
              onPanUpdate: _isLocked
                  ? null
                  : (details) {
                      setState(() {
                        final newPos = _pipPosition + details.delta;
                        // Boundary checks
                        final x = newPos.dx.clamp(0.0, size.width - 130);
                        final y = newPos.dy.clamp(0.0, size.height - 180);
                        _pipPosition = Offset(x, y);
                      });
                    },
              child: Card(
                elevation: 10,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white12, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildSelfPreview(),
              ),
            ),
          ),

          // HIDE Controls overlay and Status Bar when locked
          if (!_isLocked) ...[
            // 3. Floating HUD Controls (Bottom)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.red : Colors.white,
                        size: 28,
                      ),
                      onPressed: () => setState(() => _isMuted = !_isMuted),
                    ),
                    IconButton(
                      icon: Icon(
                        _isCameraOff ? Icons.videocam_off : Icons.videocam,
                        color: _isCameraOff ? Colors.red : Colors.white,
                        size: 28,
                      ),
                      onPressed: () => setState(() => _isCameraOff = !_isCameraOff),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _flipCamera,
                    ),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFFF3B30),
                      child: IconButton(
                        icon: const Icon(Icons.call_end, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Header metadata tag (Top Left) and Lock Button (Top Right)
            Positioned(
              top: 60,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "FaceTime...",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      shadows: [
                        Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Positioned(
              top: 60,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.lock_open, color: Colors.white, size: 26),
                onPressed: _handleLock,
              ),
            ),
          ] else ...[
            // 5. Unlock Double-tap zone (Top 90 pixels)
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

// Painter to render 4 corner tracking crosshairs for FaceTime Chroma mode
class GridTrackingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;
    const double crossSize = 16.0;
    const double offset = 50.0; // Distance from edges

    final List<Offset> centers = [
      const Offset(offset, offset),                    // Top-Left
      Offset(width - offset, offset),                 // Top-Right
      Offset(offset, height - offset),                // Bottom-Left
      Offset(width - offset, height - offset),        // Bottom-Right
    ];

    for (var center in centers) {
      canvas.drawLine(Offset(center.dx - crossSize, center.dy), Offset(center.dx + crossSize, center.dy), paint);
      canvas.drawLine(Offset(center.dx, center.dy - crossSize), Offset(center.dx, center.dy + crossSize), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
