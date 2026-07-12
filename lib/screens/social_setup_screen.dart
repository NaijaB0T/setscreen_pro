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
  List<String> _mediaPaths = [];
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
          _mediaPaths = config.mediaPaths;
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
      _mediaPaths = [];
      _queryController.text = "SetScreen Pro prop simulator";
      _headlineController.text = "BREAKING NEWS";
      _bodyController.text = "This is a mock news body text that was remotely loaded or configured on set for screen compositing.";
    });
  }

  Future<void> _pickMultiPhotos() async {
    final picker = ImagePicker();
    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _mediaPaths.addAll(pickedFiles.map((file) => file.path));
        });
      }
    } catch (e) {
      debugPrint("Error picking multi photos: $e");
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _mediaPaths.add(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
    }
  }

  void _removeMediaItem(int index) {
    setState(() {
      _mediaPaths.removeAt(index);
    });
  }

  Future<void> _startTake() async {
    if (!_formKey.currentState!.validate()) return;

    if ((_style == 'shortVideo' || _style == 'photoFeed') && _mediaPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one media file for this feed.")),
      );
      return;
    }

    final config = SocialConfig(
      style: _style,
      mediaPaths: _mediaPaths,
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

  Widget _buildMediaThumbnailTray() {
    if (_mediaPaths.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text("No media added to queue", style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
      );
    }

    final isVideo = _style == 'shortVideo';

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mediaPaths.length,
        itemBuilder: (context, index) {
          final path = _mediaPaths[index];
          final file = File(path);
          final exists = file.existsSync();

          return Stack(
            children: [
              Container(
                width: 80,
                height: 100,
                margin: const EdgeInsets.only(right: 12, top: 8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                clipBehavior: Clip.antiAlias,
                child: exists
                    ? (isVideo
                        ? const Center(child: Icon(Icons.movie, color: Colors.white54, size: 28))
                        : Image.file(file, fit: BoxFit.cover))
                    : const Center(child: Icon(Icons.broken_image, color: Colors.redAccent)),
              ),
              Positioned(
                top: 0,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeMediaItem(index),
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.close, size: 10, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
                            // Clear media queue when switching styles to prevent mismatches
                            _mediaPaths = [];
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Multi-media queue widgets
                if (_style == 'photoFeed' || _style == 'shortVideo') ...[
                  Text(
                    _style == 'photoFeed' ? "PHOTO FEED QUEUE SOURCE" : "VIDEO FEED QUEUE SOURCE",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  _buildFrostedContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _style == 'photoFeed'
                              ? "Select multiple images from the device gallery. The simulator will display them sequentially as the actor scrolls."
                              : "Add multiple looping video files. The simulator will load them for the feed in sequence.",
                          style: const TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _style == 'photoFeed' ? _pickMultiPhotos : _pickVideo,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(_style == 'photoFeed' ? "Choose Feed Photos" : "Add Video"),
                        ),
                        const SizedBox(height: 16),
                        _buildMediaThumbnailTray(),
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
