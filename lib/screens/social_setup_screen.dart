import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/social_config.dart';
import 'social_feed_screen.dart';

class SocialSetupScreen extends StatefulWidget {
  const SocialSetupScreen({super.key});

  @override
  State<SocialSetupScreen> createState() => _SocialSetupScreenState();
}

class _SocialSetupScreenState extends State<SocialSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  String _style = 'photoFeed';
  String? _wallpaperPath;
  String? _videoPath;
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _headlineController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('saved_social_config');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final config = SocialConfig.fromJson(jsonDecode(jsonStr));
        setState(() {
          _style = config.style;
          _wallpaperPath = config.wallpaperPath;
          _videoPath = config.videoPath;
          _queryController.text = config.customQuery;
          _headlineController.text = config.newsHeadline;
          _bodyController.text = config.newsBody;
        });
      } catch (e) {
        debugPrint("Error loading social config: $e");
        _loadDefaultValues();
      }
    } else {
      _loadDefaultValues();
    }
  }

  void _loadDefaultValues() {
    setState(() {
      _style = 'photoFeed';
      _wallpaperPath = null;
      _videoPath = null;
      _queryController.text = "SetScreen Pro prop simulator";
      _headlineController.text = "BREAKING NEWS";
      _bodyController.text = "This is a mock news body text that was remotely loaded or configured on set for screen compositing.";
    });
  }

  Future<void> _pickWallpaper() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _wallpaperPath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking wallpaper image: $e");
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
      debugPrint("Error picking feed video: $e");
    }
  }

  Future<void> _startTake() async {
    if (!_formKey.currentState!.validate()) return;

    if (_style == 'shortVideo' && (_videoPath == null || _videoPath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a video file for shortVideo template.")),
      );
      return;
    }

    final config = SocialConfig(
      style: _style,
      wallpaperPath: _wallpaperPath,
      videoPath: _videoPath,
      customQuery: _queryController.text.trim(),
      newsHeadline: _headlineController.text.trim(),
      newsBody: _bodyController.text.trim(),
    );

    // Save config
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_social_config', jsonEncode(config.toJson()));

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SocialFeedScreen(
            config: config,
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
          primary: Colors.pinkAccent,
          secondary: Colors.pink,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            "SOCIAL & BROWSER ENGINE CONFIG",
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
                // Style Selector dropdown
                const Text("SIMULATOR FEED TEMPLATE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Center(
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.grey[900],
                      initialValue: _style,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'photoFeed', child: Row(children: [Icon(Icons.photo_camera_back), SizedBox(width: 8), Text('Photo Feed (Instagram Style)')])),
                        DropdownMenuItem(value: 'shortVideo', child: Row(children: [Icon(Icons.movie_filter), SizedBox(width: 8), Text('Short Video (TikTok Style)')])),
                        DropdownMenuItem(value: 'microblog', child: Row(children: [Icon(Icons.chat_bubble), SizedBox(width: 8), Text('Microblog (Twitter/X Style)')])),
                        DropdownMenuItem(value: 'search', child: Row(children: [Icon(Icons.search), SizedBox(width: 8), Text('Web Search & News Editor')])),
                        DropdownMenuItem(value: 'navigation', child: Row(children: [Icon(Icons.navigation), SizedBox(width: 8), Text('Navigation Map & Route')])),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _style = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Video/Wallpaper Pickers based on selected style
                if (_style == 'shortVideo') ...[
                  const Text("LOCAL VIDEO FEED SOURCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _buildFrostedContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select a looping video file from device gallery to run as the main vertically swipeable TikTok feed.",
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
                                    ? "Selected: ${_videoPath!.split('/').last}"
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
                ] else if (_style == 'photoFeed' || _style == 'navigation') ...[
                  const Text("FEED WALLPAPER BACKDROP", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _buildFrostedContainer(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickWallpaper,
                              icon: const Icon(Icons.wallpaper),
                              label: const Text("Select Backdrop"),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _wallpaperPath != null
                                    ? "Selected: ${_wallpaperPath!.split('/').last}"
                                    : "No wallpaper selected (uses standard placeholder)",
                                style: const TextStyle(fontSize: 12, color: Colors.white38),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_wallpaperPath != null && File(_wallpaperPath!).existsSync()) ...[
                          const SizedBox(height: 12),
                          Container(
                            height: 120,
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                              image: DecorationImage(
                                image: FileImage(File(_wallpaperPath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Search Template Settings
                if (_style == 'search') ...[
                  const Text("AUTO-SEARCH & NEWS ARTICLE DETAILS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _buildFrostedContainer(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _queryController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Auto-Type Query",
                            labelStyle: TextStyle(color: Colors.white38),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _headlineController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "News Article Headline",
                            labelStyle: TextStyle(color: Colors.white38),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bodyController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: "Article Paragraph Text",
                            labelStyle: TextStyle(color: Colors.white38),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

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
                      backgroundColor: Colors.pinkAccent,
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
