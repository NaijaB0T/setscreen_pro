import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_call_config.dart';
import 'video_call_screen.dart';

class VideoSetupScreen extends StatefulWidget {
  const VideoSetupScreen({super.key});

  @override
  State<VideoSetupScreen> createState() => _VideoSetupScreenState();
}

class _VideoSetupScreenState extends State<VideoSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  String? _avatarPath;
  String? _videoPath;
  bool _isIncoming = true;
  bool _isGreenScreenMode = false;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('saved_video_call_config');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final config = VideoCallConfig.fromJson(jsonDecode(jsonStr));
        setState(() {
          _nameController.text = config.callerName;
          _avatarPath = config.avatarPath;
          _videoPath = config.videoPath;
          _isIncoming = config.isIncoming;
          _isGreenScreenMode = config.isGreenScreenMode;
        });
      } catch (e) {
        debugPrint("Error loading video call config: $e");
        _loadDefaultValues();
      }
    } else {
      _loadDefaultValues();
    }
  }

  void _loadDefaultValues() {
    setState(() {
      _nameController.text = "Michael Naizu";
      _avatarPath = null;
      _videoPath = null;
      _isIncoming = true;
      _isGreenScreenMode = false;
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _avatarPath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking avatar: $e");
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

  Future<void> _startTake() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isGreenScreenMode && (_videoPath == null || _videoPath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a video file or enable Green Screen mode.")),
      );
      return;
    }

    final config = VideoCallConfig(
      callerName: _nameController.text.trim(),
      avatarPath: _avatarPath,
      videoPath: _videoPath,
      isIncoming: _isIncoming,
      isGreenScreenMode: _isGreenScreenMode,
    );

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_video_call_config', jsonEncode(config.toJson()));

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            config: null, // For backward compatibility
            videoCallConfig: config,
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
          primary: Colors.indigoAccent,
          secondary: Colors.indigo,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            "VIDEO CALL CONFIGURATION",
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
                // Background Mode selector
                const Text("BACKGROUND SIMULATION MODE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Center(
                    child: SegmentedButton<bool>(
                      segments: const <ButtonSegment<bool>>[
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Video Mode'),
                          icon: Icon(Icons.movie),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Chroma Mode'),
                          icon: Icon(Icons.aspect_ratio),
                        ),
                      ],
                      selected: <bool>{_isGreenScreenMode},
                      onSelectionChanged: (Set<bool> val) {
                        setState(() {
                          _isGreenScreenMode = val.first;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name Card
                const Text("CALLER IDENTITY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white10,
                              backgroundImage: _avatarPath != null && File(_avatarPath!).existsSync()
                                  ? FileImage(File(_avatarPath!))
                                  : null,
                              child: _avatarPath == null || !File(_avatarPath!).existsSync()
                                  ? const Icon(Icons.person, size: 40, color: Colors.white38)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.indigoAccent,
                                child: const Icon(Icons.edit, size: 11, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: const InputDecoration(
                            labelText: "Caller Name",
                            labelStyle: TextStyle(color: Colors.white38),
                            border: UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Caller name is required";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Video asset picker (hidden if chroma mode is selected)
                if (!_isGreenScreenMode) ...[
                  const Text("FACETIME INCOMING STREAM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _buildFrostedContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select a video file to play in the background as the incoming caller's feed.",
                          style: TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickVideo,
                              icon: const Icon(Icons.video_library),
                              label: const Text("Choose Video"),
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
                ],

                // Settings & Direction
                const Text("CALL DIRECTION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Incoming FaceTime Call", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("True: rings/accept controls; False: dial Outgoing connect", style: TextStyle(fontSize: 10, color: Colors.white38)),
                    value: _isIncoming,
                    onChanged: (val) {
                      setState(() {
                        _isIncoming = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // Start Take Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _startTake,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      "START TAKE",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
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
