import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playback_config.dart';
import 'playback_screen.dart';

class PlaybackSetupScreen extends StatefulWidget {
  const PlaybackSetupScreen({super.key});

  @override
  State<PlaybackSetupScreen> createState() => _PlaybackSetupScreenState();
}

class _PlaybackSetupScreenState extends State<PlaybackSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _videoPath;
  double _playbackSpeed = 1.0;
  bool _muteAudio = false;
  bool _hideStatusBar = false;
  bool _useVolumeTrigger = false;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('saved_playback_config');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final config = PlaybackConfig.fromJson(jsonDecode(jsonStr));
        setState(() {
          _videoPath = config.videoPath;
          _playbackSpeed = config.playbackSpeed;
          _muteAudio = config.muteAudio;
          _hideStatusBar = config.hideStatusBar;
          _useVolumeTrigger = config.useVolumeTrigger;
        });
      } catch (e) {
        debugPrint("Error loading playback config: $e");
      }
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _videoPath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
    }
  }

  Future<void> _startPlayback() async {
    if (_videoPath == null || _videoPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a video file to play.")),
      );
      return;
    }

    final config = PlaybackConfig(
      videoPath: _videoPath!,
      playbackSpeed: _playbackSpeed,
      muteAudio: _muteAudio,
      hideStatusBar: _hideStatusBar,
      useVolumeTrigger: _useVolumeTrigger,
    );

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_playback_config', jsonEncode(config.toJson()));

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PlaybackScreen(
            playbackConfig: config,
          ),
        ),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.orangeAccent,
          secondary: Colors.orange,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            "SCREEN PLAYBACK CONFIG",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          centerTitle: true,
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Selector
                const Text("SCREEN RECORDING ASSET", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Choose a pre-recorded screen capture video to play back full-screen.",
                        style: TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickVideo,
                            icon: const Icon(Icons.video_library),
                            label: const Text("Select Video"),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _videoPath != null
                                  ? "Selected: ${File(_videoPath!).path.split('/').last}"
                                  : "No video selected",
                              style: const TextStyle(fontSize: 12, color: Colors.white38),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Playback Speed Selector
                const Text("PLAYBACK SPEED", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Center(
                    child: SegmentedButton<double>(
                      segments: const <ButtonSegment<double>>[
                        ButtonSegment<double>(
                          value: 0.5,
                          label: Text('0.5x'),
                        ),
                        ButtonSegment<double>(
                          value: 1.0,
                          label: Text('1.0x'),
                        ),
                        ButtonSegment<double>(
                          value: 1.5,
                          label: Text('1.5x'),
                        ),
                        ButtonSegment<double>(
                          value: 2.0,
                          label: Text('2.0x'),
                        ),
                      ],
                      selected: <double>{_playbackSpeed},
                      onSelectionChanged: (Set<double> val) {
                        setState(() {
                          _playbackSpeed = val.first;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Player settings toggles
                const Text("SCREEN PLAYBACK OPTIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Mute Audio", style: TextStyle(fontSize: 14)),
                        subtitle: const Text("True: sets playback volume to zero", style: TextStyle(fontSize: 10, color: Colors.white38)),
                        value: _muteAudio,
                        onChanged: (val) {
                          setState(() {
                            _muteAudio = val;
                          });
                        },
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Hide Top Status Bar", style: TextStyle(fontSize: 14)),
                        value: _hideStatusBar,
                        onChanged: (val) {
                          setState(() {
                            _hideStatusBar = val;
                          });
                        },
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Volume-Button Trigger", style: TextStyle(fontSize: 14)),
                        subtitle: const Text("Tapping volume key plays/pauses playback", style: TextStyle(fontSize: 10, color: Colors.white38)),
                        value: _useVolumeTrigger,
                        onChanged: (val) {
                          setState(() {
                            _useVolumeTrigger = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Play Fullscreen Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _startPlayback,
                    icon: const Icon(Icons.fullscreen),
                    label: const Text(
                      "PLAY FULLSCREEN",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
