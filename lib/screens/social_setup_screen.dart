import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  List<SocialPostItem> _customPosts = [];
  String _searchLogoText = "Search";
  final TextEditingController _queryController = TextEditingController();
  List<SearchResultItem> _customResults = [];

  bool _isDownloadingSample = false;
  String _downloadStatus = "";

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('saved_social_config_v2');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final config = SocialConfig.fromJson(jsonDecode(jsonStr));
        setState(() {
          _style = config.style;
          _customPosts = config.posts;
          _searchLogoText = config.searchLogoText;
          _queryController.text = config.customQuery;
          _customResults = config.searchResults;
        });
      } catch (e) {
        debugPrint("Error loading social config v2: $e");
        _loadDefaultValues();
      }
    } else {
      _loadDefaultValues();
    }
  }

  void _loadDefaultValues() {
    setState(() {
      _style = 'photoFeed';
      _customPosts = [
        SocialPostItem(username: "director_cut", avatarLetter: "D", caption: "Action! Capturing beautiful frames on set today.", likes: 980, postType: "image"),
        SocialPostItem(username: "scenic_views", avatarLetter: "S", caption: "Sunset glow behind the main stage layout.", likes: 450, postType: "image"),
        SocialPostItem(username: "actor_life", avatarLetter: "A", caption: "Reading screenplays between takes. #props", likes: 1250, postType: "text"),
      ];
      _searchLogoText = "Google";
      _queryController.text = "How to run a wireless master console";
      _customResults = [
        SearchResultItem(
          title: "SetScreen Pro Remote Control Guide",
          url: "https://guide.setscreenpro.com/wireless",
          snippet: "Learn how to use offline local WebSockets on port 4040 to trigger screen composites and notifications in real-time.",
          articleHeadline: "DIRECTOR REMOTE CONSOLE DOCUMENTATION",
          articleBody: "By binding a ConsoleServer instance locally, sets can coordinate up to 10 devices at once. WebSockets transmit JSON commands instantaneously over Wi-Fi without needing internet access.",
        ),
        SearchResultItem(
          title: "Breaking News: Live Production VFX",
          url: "https://news.cinematoday.com/vfx",
          snippet: "Advanced chroma key markers and interactive mock browsers replace old green screens in modern TV studios.",
          articleHeadline: "THE RISE OF DIGITAL PROP SIMULATORS",
          articleBody: "Actors perform better when responding to real-time visual triggers, such as typing search keys or incoming calls, compared to blank green screens. SetScreen Pro bridges this gap.",
        ),
      ];
    });
  }

  Future<void> _downloadSampleVideoForPost(int index) async {
    setState(() {
      _isDownloadingSample = true;
      _downloadStatus = "Downloading sample video (1.8MB)...";
    });
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sample_prop_video.mp4');
      if (!await file.exists()) {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'
        ));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        await file.writeAsBytes(bytes);
      }
      setState(() {
        final p = _customPosts[index];
        _customPosts[index] = SocialPostItem(
          username: p.username,
          avatarLetter: p.avatarLetter,
          caption: p.caption,
          likes: p.likes,
          postType: p.postType,
          mediaPath: file.path,
        );
        _downloadStatus = "Sample video loaded successfully!";
      });
    } catch (e) {
      setState(() {
        _downloadStatus = "Download failed. Offline fallback will be used.";
      });
      debugPrint("Error downloading sample video: $e");
    } finally {
      setState(() {
        _isDownloadingSample = false;
      });
    }
  }

  Future<void> _pickMediaForPost(int index, bool isVideo) async {
    final picker = ImagePicker();
    try {
      XFile? file;
      if (isVideo) {
        file = await picker.pickVideo(source: ImageSource.gallery);
      } else {
        file = await picker.pickImage(source: ImageSource.gallery);
      }
      if (file != null) {
        setState(() {
          final p = _customPosts[index];
          _customPosts[index] = SocialPostItem(
            username: p.username,
            avatarLetter: p.avatarLetter,
            caption: p.caption,
            likes: p.likes,
            postType: p.postType,
            mediaPath: file!.path,
          );
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void _addMockPost() {
    setState(() {
      _customPosts.add(SocialPostItem(
        username: "new_profile",
        avatarLetter: "N",
        caption: "Editable custom caption goes here.",
        likes: 100,
        postType: _style == 'shortVideo' ? 'video' : 'image',
      ));
    });
  }

  void _removePost(int index) {
    setState(() {
      _customPosts.removeAt(index);
    });
  }

  void _addSearchResult() {
    setState(() {
      _customResults.add(SearchResultItem(
        title: "New Search Headline",
        url: "www.newurl.com",
        snippet: "This is a search snippet that appears in the list.",
        articleHeadline: "NEWS ARTICLE TITLE",
        articleBody: "News article body content goes here.",
      ));
    });
  }

  void _removeSearchResult(int index) {
    setState(() {
      _customResults.removeAt(index);
    });
  }

  Future<void> _startTake() async {
    if (!_formKey.currentState!.validate()) return;

    final config = SocialConfig(
      style: _style,
      posts: _customPosts,
      searchLogoText: _searchLogoText,
      customQuery: _queryController.text.trim(),
      searchResults: _customResults,
    );

    // Save config
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_social_config_v2', jsonEncode(config.toJson()));

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

  // Dialog/Form to Edit a post item
  void _editPostDialog(int index) {
    final p = _customPosts[index];
    final usernameController = TextEditingController(text: p.username);
    final avatarController = TextEditingController(text: p.avatarLetter);
    final captionController = TextEditingController(text: p.caption);
    final likesController = TextEditingController(text: p.likes.toString());
    String type = p.postType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[950],
              title: const Text("Edit Post Content", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: "Username"),
                      style: const TextStyle(color: Colors.white),
                    ),
                    TextField(
                      controller: avatarController,
                      maxLength: 1,
                      decoration: const InputDecoration(labelText: "Avatar Letter"),
                      style: const TextStyle(color: Colors.white),
                    ),
                    TextField(
                      controller: captionController,
                      decoration: const InputDecoration(labelText: "Caption"),
                      style: const TextStyle(color: Colors.white),
                    ),
                    TextField(
                      controller: likesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Likes Count"),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      dropdownColor: Colors.grey[900],
                      value: type,
                      items: const [
                        DropdownMenuItem(value: "image", child: Text("Image Post")),
                        DropdownMenuItem(value: "video", child: Text("Video Post")),
                        DropdownMenuItem(value: "text", child: Text("Text Only")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            type = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _customPosts[index] = SocialPostItem(
                        username: usernameController.text.trim(),
                        avatarLetter: avatarController.text.trim().toUpperCase(),
                        caption: captionController.text.trim(),
                        likes: int.tryParse(likesController.text) ?? 0,
                        postType: type,
                        mediaPath: p.mediaPath,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog/Form to Edit a Search Result Item
  void _editSearchResultDialog(int index) {
    final r = _customResults[index];
    final titleController = TextEditingController(text: r.title);
    final urlController = TextEditingController(text: r.url);
    final snippetController = TextEditingController(text: r.snippet);
    final headlineController = TextEditingController(text: r.articleHeadline);
    final bodyController = TextEditingController(text: r.articleBody);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[950],
          title: const Text("Edit Search Result & Article", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Result Title"),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: "Display URL"),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: snippetController,
                  decoration: const InputDecoration(labelText: "Snippet Description"),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                TextField(
                  controller: headlineController,
                  decoration: const InputDecoration(labelText: "Linked Article Headline"),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: "Article Paragraph Body"),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _customResults[index] = SearchResultItem(
                    title: titleController.text.trim(),
                    url: urlController.text.trim(),
                    snippet: snippetController.text.trim(),
                    articleHeadline: headlineController.text.trim(),
                    articleBody: bodyController.text.trim(),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
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
                // Downloading Status feedback
                if (_isDownloadingSample || _downloadStatus.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        if (_isDownloadingSample)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _downloadStatus,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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

                // Feed Posts customization (Instagram / TikTok / Twitter)
                if (_style == 'photoFeed' || _style == 'shortVideo' || _style == 'microblog') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MANAGE POSTS QUEUE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                      TextButton.icon(
                        onPressed: _addMockPost,
                        icon: const Icon(Icons.add, size: 16, color: Colors.pinkAccent),
                        label: const Text("Add Post", style: TextStyle(color: Colors.pinkAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _customPosts.length,
                    itemBuilder: (context, index) {
                      final p = _customPosts[index];
                      final hasMedia = p.mediaPath != null && p.mediaPath!.isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              child: Text(p.avatarLetter),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("@${p.username}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.caption,
                                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${p.likes} likes • Type: ${p.postType} ${hasMedia ? '(Media Loaded)' : ''}",
                                    style: const TextStyle(fontSize: 10, color: Colors.white30),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Media upload indicators
                            if (p.postType != 'text') ...[
                              IconButton(
                                icon: const Icon(Icons.video_library, size: 18),
                                tooltip: "Load Video",
                                onPressed: () => _pickMediaForPost(index, true),
                              ),
                              IconButton(
                                icon: const Icon(Icons.photo_library, size: 18),
                                tooltip: "Load Photo",
                                onPressed: () => _pickMediaForPost(index, false),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cloud_download, size: 18),
                                tooltip: "Get Sample Video",
                                onPressed: () => _downloadSampleVideoForPost(index),
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                              onPressed: () => _editPostDialog(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                              onPressed: () => _removePost(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Search Template Customization
                if (_style == 'search') ...[
                  const Text("SEARCH BRANDING & AUTO-QUERY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _buildFrostedContainer(
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: _searchLogoText,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Search Logo Name",
                            labelStyle: TextStyle(color: Colors.white38),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchLogoText = val.trim();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _queryController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Auto-Type Query",
                            labelStyle: TextStyle(color: Colors.white38),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MANAGE MOCK SEARCH RESULTS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                      TextButton.icon(
                        onPressed: _addSearchResult,
                        icon: const Icon(Icons.add, size: 16, color: Colors.pinkAccent),
                        label: const Text("Add Result", style: TextStyle(color: Colors.pinkAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _customResults.length,
                    itemBuilder: (context, index) {
                      final r = _customResults[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link, color: Colors.blueAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                                  Text(r.url, style: const TextStyle(fontSize: 10, color: Colors.green)),
                                  Text(
                                    r.snippet,
                                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                              onPressed: () => _editSearchResultDialog(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                              onPressed: () => _removeSearchResult(index),
                            ),
                          ],
                        ),
                      );
                    },
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
