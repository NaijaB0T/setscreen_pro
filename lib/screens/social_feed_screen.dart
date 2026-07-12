import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/social_config.dart';
import '../services/console_network_service.dart';

class SocialFeedScreen extends StatefulWidget {
  final SocialConfig config;

  const SocialFeedScreen({
    super.key,
    required this.config,
  });

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> with SingleTickerProviderStateMixin {
  // Navigation stream subscription for Director Remote Console
  StreamSubscription? _consoleSubscription;

  // Video controller for shortVideo (TikTok style)
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  int _currentVideoIndex = 0;

  // Search template auto-typing states
  bool _isTyping = false;
  String _typedQuery = "";
  bool _isSearching = false;
  bool _showSearchResults = false;
  SearchResultItem? _selectedArticle;
  Timer? _typingTimer;

  // Navigation map arrow progress animation
  late AnimationController _mapAnimationController;
  double _navigationProgress = 0.0;

  // Scroll controllers for feeds
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  // Safety Lock State
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _initializeFirstVideo();

    // Map arrow animation controller setup
    _mapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addListener(() {
        setState(() {
          _navigationProgress = _mapAnimationController.value;
        });
      });
    if (widget.config.style == 'navigation') {
      _mapAnimationController.repeat();
    }

    // Connect remote console stream
    if (ConsoleServer.instance.isRunning) {
      _consoleSubscription = ConsoleServer.instance.commandStream.listen((cmd) {
        if (cmd['action'] == 'scroll_next') {
          _scrollNextFeed();
        } else if (cmd['action'] == 'trigger_search') {
          _triggerSearchTyping();
        }
      });
    }
  }

  @override
  void dispose() {
    _consoleSubscription?.cancel();
    _videoPlayerController?.dispose();
    _typingTimer?.cancel();
    _mapAnimationController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeFirstVideo() {
    if (widget.config.style == 'shortVideo' && widget.config.posts.isNotEmpty) {
      _loadVideoForIndex(0);
    }
  }

  Future<void> _loadVideoForIndex(int index) async {
    final validPosts = widget.config.posts.where((p) => p.postType == 'video').toList();
    if (validPosts.isEmpty) return;

    final post = validPosts[index % validPosts.length];
    final path = post.mediaPath;

    // Dispose old controller first
    if (_videoPlayerController != null) {
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }

    if (path != null && path.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final controller = VideoPlayerController.file(file);
          _videoPlayerController = controller;
          await controller.initialize();
          await controller.setLooping(true);
          await controller.play();
          if (mounted && _videoPlayerController == controller) {
            setState(() {
              _isVideoInitialized = true;
              _currentVideoIndex = index;
            });
          }
        }
      } catch (e) {
        debugPrint("Error loading video at index $index: $e");
      }
    }
  }

  void _scrollNextFeed() {
    if (!mounted) return;
    if (widget.config.style == 'shortVideo') {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } else if (widget.config.style == 'photoFeed' || widget.config.style == 'microblog') {
      if (_scrollController.hasClients) {
        final currentOffset = _scrollController.offset;
        _scrollController.animateTo(
          currentOffset + 300,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _triggerSearchTyping() {
    if (_isTyping || _isSearching || _showSearchResults || _selectedArticle != null || widget.config.style != 'search') return;

    setState(() {
      _isTyping = true;
      _typedQuery = "";
    });

    int charIndex = 0;
    final query = widget.config.customQuery;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (charIndex < query.length) {
        if (mounted) {
          setState(() {
            _typedQuery += query[charIndex];
          });
        }
        charIndex++;
      } else {
        _typingTimer?.cancel();
        _runSearchLookup();
      }
    });
  }

  Future<void> _runSearchLookup() async {
    if (mounted) {
      setState(() {
        _isTyping = false;
        _isSearching = true;
      });
    }

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _isSearching = false;
        _showSearchResults = true;
      });
    }
  }

  void _handleLock() {
    setState(() {
      _isLocked = true;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Simulation View Locked. Double-tap top area to exit."),
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
          content: Text("Simulation View Unlocked."),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  // --- SUB-TEMPLATES ---

  // 1. TikTok style short video page layout
  Widget _buildShortVideoView() {
    final validPosts = widget.config.posts.where((p) => p.postType == 'video').toList();
    if (validPosts.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text("No video posts in queue. Please add video posts in setup.", style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: _isLocked ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      onPageChanged: (index) {
        _loadVideoForIndex(index);
      },
      itemCount: validPosts.length,
      itemBuilder: (context, index) {
        final post = validPosts[index];
        final isCurrentIndexLoaded = _isVideoInitialized && _currentVideoIndex == index && _videoPlayerController != null;
        final hasVideo = post.mediaPath != null && post.mediaPath!.isNotEmpty && File(post.mediaPath!).existsSync();

        return Stack(
          children: [
            // Video Loop background or fallback
            Positioned.fill(
              child: hasVideo && isCurrentIndexLoaded
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoPlayerController!.value.size.width,
                        height: _videoPlayerController!.value.size.height,
                        child: VideoPlayer(_videoPlayerController!),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE91E63),
                            Color(0xFF9C27B0),
                            Color(0xFF1E1E24),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_fill, size: 72, color: Colors.white54),
                            const SizedBox(height: 12),
                            Text("@${post.username}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text("Simulated Video Feed Fallback", style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
            ),
            
            // Vignette overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black38,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
              ),
            ),

            // Right side overlay options (Heart, comment, share)
            Positioned(
              right: 16,
              bottom: 120,
              child: Column(
                children: [
                  _buildTikTokIcon(Icons.favorite, "${post.likes}"),
                  _buildTikTokIcon(Icons.chat_bubble, "${(post.likes * 0.12).toInt()}"),
                  _buildTikTokIcon(Icons.reply, "Share"),
                ],
              ),
            ),

            // Bottom Caption metadata
            Positioned(
              left: 16,
              bottom: 40,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "@${post.username}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.caption,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTikTokIcon(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // 2. Instagram style photo feed
  Widget _buildPhotoFeedView() {
    final validPosts = widget.config.posts.where((p) => p.postType == 'image' || p.postType == 'text').toList();
    if (validPosts.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text("No photo posts in queue. Please add posts in setup.", style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: ListView.builder(
        controller: _scrollController,
        physics: _isLocked ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
        itemCount: 20,
        itemBuilder: (context, index) {
          final post = validPosts[index % validPosts.length];
          final mediaPath = post.mediaPath;
          final hasMedia = mediaPath != null && mediaPath.isNotEmpty && File(mediaPath).existsSync();

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Profile)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        child: Text(post.avatarLetter, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Text(post.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      const Icon(Icons.more_horiz),
                    ],
                  ),
                ),
                // Card Media Box
                if (post.postType == 'image') ...[
                  AspectRatio(
                    aspectRatio: 1,
                    child: hasMedia
                        ? Image.file(File(mediaPath), fit: BoxFit.cover)
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF13101C), Color(0xFF2C243B)],
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.image, size: 50, color: Colors.white24),
                                  const SizedBox(height: 8),
                                  Text("@${post.username}", style: const TextStyle(color: Colors.white30, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                  ),
                ] else ...[
                  // Text only post representation in feed
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: Colors.white.withValues(alpha: 0.02),
                    child: Text(
                      post.caption,
                      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white70),
                    ),
                  ),
                ],
                // Footer details
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.favorite_border, size: 28),
                      SizedBox(width: 16),
                      Icon(Icons.chat_bubble_outline, size: 26),
                      SizedBox(width: 16),
                      Icon(Icons.send_outlined, size: 26),
                      Spacer(),
                      Icon(Icons.bookmark_border, size: 28),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${post.likes} likes", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (post.postType == 'image')
                        Text("${post.username} ${post.caption}", style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 3. Twitter/X style microblog feed
  Widget _buildMicroblogView() {
    if (widget.config.posts.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text("No microblog posts in queue. Please add posts in setup.", style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: ListView.builder(
        controller: _scrollController,
        physics: _isLocked ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
        itemCount: 15,
        itemBuilder: (context, index) {
          final post = widget.config.posts[index % widget.config.posts.length];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white10,
                  child: Text(post.avatarLetter),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(post.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 6),
                          Text("@${post.username.toLowerCase()}", style: const TextStyle(color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.caption,
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [const Icon(Icons.mode_comment_outlined, size: 16, color: Colors.white38), const SizedBox(width: 4), Text("${(post.likes * 0.08).toInt()}", style: const TextStyle(color: Colors.white38, fontSize: 11))]),
                          Row(children: [const Icon(Icons.autorenew_outlined, size: 18, color: Colors.white38), const SizedBox(width: 4), Text("${(post.likes * 0.04).toInt()}", style: const TextStyle(color: Colors.white38, fontSize: 11))]),
                          Row(children: [const Icon(Icons.favorite_border, size: 16, color: Colors.white38), const SizedBox(width: 4), Text("${post.likes}", style: const TextStyle(color: Colors.white38, fontSize: 11))]),
                          const Icon(Icons.share_outlined, size: 16, color: Colors.white38),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 4. Web Search engine & custom results list & news views
  Widget _buildSearchView() {
    if (_selectedArticle != null) {
      // News Article View (editorial layout)
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedArticle!.articleHeadline,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black, height: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                "SOURCE: ${_selectedArticle!.url.toUpperCase()} • 2 MIN READ",
                style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const Divider(color: Colors.black12, height: 24, thickness: 1),
              Text(
                _selectedArticle!.articleBody,
                style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.6, fontFamily: "serif"),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedArticle = null;
                  });
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text("Back to Search Results", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              ),
            ],
          ),
        ),
      );
    }

    if (_showSearchResults) {
      // Mock Google Search Results list
      return Container(
        color: const ui.Color(0xFF202124),
        padding: const EdgeInsets.only(top: 80, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.config.searchLogoText,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const ui.Color(0xFF303134),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.config.customQuery,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.close, size: 16, color: Colors.white38),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.config.searchResults.length,
                itemBuilder: (context, index) {
                  final result = widget.config.searchResults[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.url,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedArticle = result;
                            });
                          },
                          child: Text(
                            result.title,
                            style: const TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.snippet,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // Google-style Search Box Landing page
    return Container(
      color: const ui.Color(0xFF202124),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom Configured Logo
          Text(
            widget.config.searchLogoText,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5),
          ),
          const SizedBox(height: 32),

          // Search input box
          GestureDetector(
            onTap: _triggerSearchTyping,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const ui.Color(0xFF303134),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _typedQuery.isEmpty ? "Search query..." : _typedQuery,
                      style: TextStyle(color: _typedQuery.isEmpty ? Colors.white30 : Colors.white, fontSize: 16),
                    ),
                  ),
                  if (_isSearching)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                    )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Tap search box to initiate auto-typing",
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 5. Navigation routing maps
  Widget _buildNavigationView() {
    return Stack(
      children: [
        // Map texture background representation
        Positioned.fill(
          child: Container(
            color: const ui.Color(0xFF1E1E24), // Dark map base
          ),
        ),
        // Draw path and arrow pointer
        Positioned.fill(
          child: CustomPaint(
            painter: MapNavigationPainter(progress: _navigationProgress),
          ),
        ),
        
        // Navigation Instructions overlay
        Positioned(
          top: 80,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  child: Icon(Icons.turn_right),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("In 500 feet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Turn right onto Main Street", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockStatusBar() {
    final useDarkText = widget.config.style == 'search' && _selectedArticle != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: useDarkText ? Colors.white : Colors.black.withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("9:41", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: useDarkText ? Colors.black : Colors.white)),
          Row(
            children: [
              Icon(Icons.signal_cellular_4_bar, size: 14, color: useDarkText ? Colors.black : Colors.white),
              const SizedBox(width: 4),
              Icon(Icons.wifi, size: 14, color: useDarkText ? Colors.black : Colors.white),
              const SizedBox(width: 4),
              Icon(Icons.battery_full, size: 16, color: useDarkText ? Colors.black : Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget feedWidget;
    switch (widget.config.style) {
      case 'shortVideo':
        feedWidget = _buildShortVideoView();
        break;
      case 'photoFeed':
        feedWidget = _buildPhotoFeedView();
        break;
      case 'microblog':
        feedWidget = _buildMicroblogView();
        break;
      case 'search':
        feedWidget = _buildSearchView();
        break;
      case 'navigation':
        feedWidget = _buildNavigationView();
        break;
      default:
        feedWidget = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Template Viewport Content
          Positioned.fill(
            child: feedWidget,
          ),

          // HIDE status bar and buttons when safety locked
          if (!_isLocked) ...[
            // Status bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: _buildMockStatusBar()),
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
            // 2. Invisible Unlock double tap zone (Top 90 pixels)
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

// Custom Painter to render GPS Route Navigation path and grid road layout
class MapNavigationPainter extends CustomPainter {
  final double progress;

  MapNavigationPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw secondary road grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 14.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, height * 0.45), Offset(width, height * 0.4), gridPaint);
    canvas.drawLine(Offset(0, height * 0.7), Offset(width, height * 0.8), gridPaint);
    canvas.drawLine(Offset(width * 0.25, 0), Offset(width * 0.35, height), gridPaint);

    // Highlight navigation path
    final routePaint = Paint()
      ..color = const Color(0xFF007AFF) // iOS Blue
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(80, height - 120);
    path.quadraticBezierTo(width * 0.4, height * 0.75, width * 0.5, height * 0.5);
    path.quadraticBezierTo(width * 0.6, height * 0.25, width - 80, 160);

    canvas.drawPath(path, routePaint);

    // Compute pointer along path
    final pathMetrics = path.computeMetrics();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final distance = metric.length * progress;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        final position = tangent.position;
        
        // Draw pulse circle
        final pulsePaint = Paint()..color = const Color(0xFF007AFF).withValues(alpha: 0.3);
        canvas.drawCircle(position, 20, pulsePaint);

        // Outer white border
        final borderPaint = Paint()..color = Colors.white;
        canvas.drawCircle(position, 9, borderPaint);

        // Core blue circle
        final corePaint = Paint()..color = const Color(0xFF007AFF);
        canvas.drawCircle(position, 6, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapNavigationPainter oldDelegate) => oldDelegate.progress != progress;
}
