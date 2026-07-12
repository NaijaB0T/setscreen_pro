import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import '../models/project_config.dart';

class VideoCallScreen extends StatefulWidget {
  final ProjectConfig config;

  const VideoCallScreen({
    super.key,
    required this.config,
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

  // Controls State
  bool _isMuted = false;
  bool _isCameraOff = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _initializeCamera();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    final path = widget.config.videoCallerPath;
    if (path == null || path.isEmpty) {
      debugPrint("No video caller path specified.");
      return;
    }

    try {
      final file = File(path);
      if (await file.exists()) {
        _videoPlayerController = VideoPlayerController.file(file);
      } else {
        // Fallback to assets if file is not found
        debugPrint("File does not exist at $path. Falling back.");
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

      // Fallback to first camera if no front camera
      selectedCamera ??= _cameras.first;

      await _startCameraController(selectedCamera);
    } catch (e) {
      debugPrint("Error detecting cameras: $e");
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
        });
      }
    } catch (e) {
      debugPrint("Error initializing camera controller: $e");
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

    // Toggle direction flag
    nextCamera ??= _cameras.first;
    _isCameraFront = nextCamera.lensDirection == CameraLensDirection.front;

    await _startCameraController(nextCamera);
  }

  Widget _buildSelfPreview() {
    if (_isCameraOff) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white60, size: 28),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Render local camera output
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Video Feed (Incoming Stream)
          Positioned.fill(
            child: _isVideoInitialized && _videoPlayerController != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoPlayerController!.value.size.width,
                      height: _videoPlayerController!.value.size.height,
                      child: VideoPlayer(_videoPlayerController!),
                    ),
                  )
                : Container(
                    color: Colors.grey[950],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_call, size: 80, color: Colors.white24),
                          const SizedBox(height: 16),
                          Text(
                            "Connecting to ${widget.config.contactName}...",
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // 2. Picture-in-Picture (PIP) Window (Self Camera Feed)
          Positioned(
            top: 60,
            right: 20,
            width: 110,
            height: 150,
            child: Card(
              elevation: 8,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white24, width: 1),
              ),
              color: Colors.grey[900],
              clipBehavior: Clip.antiAlias,
              child: _buildSelfPreview(),
            ),
          ),

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
                  // Mute Mic Toggle
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.red : Colors.white,
                      size: 28,
                    ),
                    onPressed: () => setState(() => _isMuted = !_isMuted),
                  ),
                  
                  // Camera Off Toggle
                  IconButton(
                    icon: Icon(
                      _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      color: _isCameraOff ? Colors.red : Colors.white,
                      size: 28,
                    ),
                    onPressed: () => setState(() => _isCameraOff = !_isCameraOff),
                  ),

                  // Flip Camera
                  IconButton(
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _flipCamera,
                  ),

                  // End Call (Decline Red Button)
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
          
          // 4. Contact Name Tag (Top Left)
          Positioned(
            top: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.config.contactName,
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
        ],
      ),
    );
  }
}
