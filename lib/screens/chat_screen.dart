import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/console_network_service.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';
import '../models/script_item.dart';
import '../models/project_config.dart';
import '../widgets/live_typing_keyboard.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final ProjectConfig config;

  const ChatScreen({
    super.key,
    required this.config,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatController _chatController;
  final ScrollController _scrollController = ScrollController();
  late bool _isDarkMode;
  bool _isLocked = false;

  StreamSubscription? _consoleSubscription;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController(config: widget.config);
    _isDarkMode = widget.config.initialUseDarkMode;
    _chatController.addListener(_onControllerUpdate);

    if (ConsoleServer.instance.isRunning) {
      _consoleSubscription = ConsoleServer.instance.commandStream.listen((cmd) {
        if (cmd['action'] == 'trigger_key') {
          if (mounted) {
            setState(() {
              if (_chatController.isMessageFullyTyped) {
                _chatController.sendMessage();
              } else {
                _chatController.typeNextCharacter();
              }
            });
          }
        } else if (cmd['action'] == 'trigger_opponent') {
          _chatController.triggerOpponentProgress();
        }
      });
    }
  }

  @override
  void dispose() {
    _consoleSubscription?.cancel();
    _chatController.removeListener(_onControllerUpdate);
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
    setState(() {});
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    SystemChrome.setSystemUIOverlayStyle(
      _isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  void _handleLock() {
    setState(() {
      _isLocked = true;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Chat Lock Active. Double-tap the top header area to unlock."),
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
          content: Text("Chat Unlocked."),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "U";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // Media render helpers
  Widget _buildPhotoAttachment(bool isMe) {
    final themeColor = isMe ? Colors.white.withValues(alpha: 0.15) : Colors.black12;
    final iconColor = isMe ? Colors.white70 : Colors.grey[400];
    return Container(
      width: 200,
      height: 140,
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 36, color: iconColor),
            const SizedBox(height: 8),
            Text(
              "Attachment: Photo",
              style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapAttachment(bool isMe) {
    return Container(
      width: 220,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: MapPainter(),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.redAccent, size: 28),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 2, spreadRadius: 1)],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.my_location, color: Colors.blueAccent, size: 12),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Shared Location",
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioAttachment(bool isMe) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(Icons.play_arrow_rounded, color: isMe ? Colors.white : Colors.tealAccent, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(15, (index) {
                      final heights = [12.0, 6.0, 18.0, 14.0, 8.0, 20.0, 10.0, 16.0, 6.0, 12.0, 18.0, 8.0, 14.0, 10.0, 4.0];
                      return Container(
                        width: 3,
                        height: heights[index],
                        decoration: BoxDecoration(
                          color: isMe ? Colors.white70 : Colors.tealAccent.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("0:14", style: TextStyle(color: isMe ? Colors.white54 : Colors.white38, fontSize: 10)),
                    Text("Voice Memo", style: TextStyle(color: isMe ? Colors.white54 : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build platform specific components
  Widget _buildStatusBar(Color textColor, PlatformStyle style) {
    if (style == PlatformStyle.ios) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("9:41", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
          Row(
            children: [
              Icon(Icons.signal_cellular_4_bar, size: 14, color: textColor),
              const SizedBox(width: 4),
              Text("5G", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(width: 4),
              Icon(Icons.battery_full, size: 16, color: textColor),
            ],
          ),
        ],
      );
    } else if (style == PlatformStyle.android) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text("09:41", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
              const SizedBox(width: 6),
              Icon(Icons.message, size: 12, color: textColor.withValues(alpha: 0.7)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.wifi, size: 14, color: textColor),
              const SizedBox(width: 4),
              Icon(Icons.signal_cellular_alt, size: 14, color: textColor),
              const SizedBox(width: 4),
              Icon(Icons.battery_std, size: 14, color: textColor),
              const SizedBox(width: 2),
              Text("100%", style: TextStyle(fontSize: 11, color: textColor)),
            ],
          ),
        ],
      );
    } else {
      // Generic (Neutral/Unbranded)
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.greenAccent),
                const SizedBox(width: 6),
                Text(
                  "SECURE PROP FEED",
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.5), letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildAppBar(Color textColor, Color subtextColor, Color userBubbleColor, PlatformStyle style) {
    if (style == PlatformStyle.ios) {
      return Row(
        children: [
          // iOS Back
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios_new, color: userBubbleColor, size: 20),
                const SizedBox(width: 4),
                Text("Setup", style: TextStyle(color: userBubbleColor, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onDoubleTap: _toggleTheme,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[400],
                    backgroundImage: widget.config.avatarPath != null && widget.config.avatarPath!.isNotEmpty && File(widget.config.avatarPath!).existsSync()
                        ? FileImage(File(widget.config.avatarPath!))
                        : null,
                    child: widget.config.avatarPath == null || widget.config.avatarPath!.isEmpty || !File(widget.config.avatarPath!).existsSync()
                        ? Text(_getInitials(widget.config.contactName), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.config.contactName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textColor)),
                      Icon(Icons.chevron_right, size: 10, color: subtextColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.lock, size: 18),
            color: subtextColor,
            onPressed: _handleLock,
          ),
        ],
      );
    } else if (style == PlatformStyle.android) {
      return Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[500],
            backgroundImage: widget.config.avatarPath != null && widget.config.avatarPath!.isNotEmpty && File(widget.config.avatarPath!).existsSync()
                ? FileImage(File(widget.config.avatarPath!))
                : null,
            child: widget.config.avatarPath == null || widget.config.avatarPath!.isEmpty || !File(widget.config.avatarPath!).existsSync()
                ? Text(_getInitials(widget.config.contactName), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.config.contactName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                Text("Online", style: TextStyle(fontSize: 11, color: Colors.greenAccent[400])),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: textColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.lock, color: subtextColor, size: 20),
            onPressed: _handleLock,
          ),
        ],
      );
    } else {
      // Generic Style
      return Row(
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: textColor.withValues(alpha: 0.6), size: 16),
            label: Text("EXIT", style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.config.contactName.toUpperCase(),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, size: 20),
            color: subtextColor,
            onPressed: _handleLock,
          ),
        ],
      );
    }
  }

  Widget _buildMessageContent(Message msg, bool isMe) {
    switch (msg.type) {
      case MessageType.photo:
        return _buildPhotoAttachment(isMe);
      case MessageType.map:
        return _buildMapAttachment(isMe);
      case MessageType.audio:
        return _buildAudioAttachment(isMe);
      case MessageType.text:
        return Text(
          msg.text,
          style: TextStyle(
            color: isMe ? Colors.white : (_isDarkMode ? Colors.white : Colors.black87),
            fontSize: 15,
          ),
        );
    }
  }

  Widget _buildInputBar(Color bgColor, Color textColor, Color subtextColor, Color userBubbleColor, PlatformStyle style) {
    if (style == PlatformStyle.ios) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: bgColor,
        child: Row(
          children: [
            Icon(Icons.camera_alt, color: subtextColor, size: 26),
            const SizedBox(width: 10),
            Icon(Icons.card_giftcard, color: subtextColor, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _chatController.currentTypedText.isEmpty ? "iMessage" : _chatController.currentTypedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _chatController.currentTypedText.isEmpty
                          ? (_isDarkMode ? Colors.white38 : Colors.black38)
                          : textColor,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                if (_chatController.isMessageFullyTyped) {
                  _chatController.sendMessage();
                }
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _chatController.isMessageFullyTyped
                      ? userBubbleColor
                      : (_isDarkMode ? const Color(0xFF252528) : const Color(0xFFE5E5EA)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward,
                  color: _chatController.isMessageFullyTyped ? Colors.white : (_isDarkMode ? Colors.white38 : Colors.black38),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (style == PlatformStyle.android) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: bgColor,
        child: Row(
          children: [
            Icon(Icons.add, color: textColor.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF202124) : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _chatController.currentTypedText.isEmpty ? "Text message" : _chatController.currentTypedText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _chatController.currentTypedText.isEmpty ? Colors.white38 : textColor,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(Icons.emoji_emotions_outlined, color: textColor.withValues(alpha: 0.6)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (_chatController.isMessageFullyTyped) {
                  _chatController.sendMessage();
                }
              },
              child: CircleAvatar(
                radius: 22,
                backgroundColor: _chatController.isMessageFullyTyped ? Colors.tealAccent : Colors.white10,
                child: Icon(
                  Icons.send,
                  color: _chatController.isMessageFullyTyped ? Colors.black : Colors.white38,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Generic Style
      return Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF121212),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _chatController.currentTypedText.isEmpty ? "Type..." : _chatController.currentTypedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _chatController.currentTypedText.isEmpty ? Colors.white30 : textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: () {
                  if (_chatController.isMessageFullyTyped) {
                    _chatController.sendMessage();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _chatController.isMessageFullyTyped ? Colors.tealAccent : Colors.white10,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  "SEND",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _chatController.isMessageFullyTyped ? Colors.black : Colors.white38,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.config.platformStyle;
    
    // Style settings mapping
    final isGeneric = style == PlatformStyle.generic;
    final isAndroid = style == PlatformStyle.android;

    final bgColor = _isDarkMode ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final headerBgColor = _isDarkMode 
        ? (isGeneric ? const Color(0xFF121212) : const Color(0xFF161618)) 
        : const Color(0xFFF6F6F6);
    final dividerColor = _isDarkMode ? const Color(0xFF262629) : const Color(0xFFE5E5EA);
    final textColor = _isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final subtextColor = _isDarkMode ? Colors.white38 : Colors.black38;

    // Bubbles Styles
    Color userBubbleColor;
    Color opponentBubbleColor;
    BorderRadius userBorderRadius;
    BorderRadius opponentBorderRadius;

    if (isAndroid) {
      userBubbleColor = const Color(0xFF007BFF); // Google Messages Light Blue
      opponentBubbleColor = _isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF1F3F4);
      userBorderRadius = BorderRadius.circular(20);
      opponentBorderRadius = BorderRadius.circular(20);
    } else if (isGeneric) {
      userBubbleColor = const Color(0xFF2E2E32); // Charcoal
      opponentBubbleColor = const Color(0xFF1C1C1E); // Off charcoal
      userBorderRadius = BorderRadius.circular(8);
      opponentBorderRadius = BorderRadius.circular(8);
    } else {
      // iOS Style
      userBubbleColor = _chatController.isGreenBubble ? const Color(0xFF34C759) : const Color(0xFF007AFF);
      opponentBubbleColor = _isDarkMode ? const Color(0xFF252528) : const Color(0xFFE5E5EA);
      userBorderRadius = const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(4),
      );
      opponentBorderRadius = const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(18),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Safe unlocking area
            if (_isLocked)
              GestureDetector(
                onDoubleTap: _handleUnlock,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 90, // Match height of status bar + app bar
                  color: Colors.transparent,
                ),
              )
            else ...[
              // 1. Platform Status Bar
              Container(
                color: headerBgColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildStatusBar(textColor, style),
              ),

              // 2. Chat Header / AppBar
              Container(
                color: headerBgColor,
                padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
                child: _buildAppBar(textColor, subtextColor, userBubbleColor, style),
              ),
              
              Container(height: 1, color: dividerColor),
            ],

            // 3. Chat Messages Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: _isLocked ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                itemCount: _chatController.messages.length + (_chatController.isOpponentTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _chatController.messages.length) {
                    return TypingIndicator(isDarkMode: _isDarkMode);
                  }

                  final msg = _chatController.messages[index];
                  final isMe = msg.sender == MessageSender.sender;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: msg.type == MessageType.text
                          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                          : EdgeInsets.zero, // Padding built inside attachments
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: msg.type == MessageType.text
                          ? BoxDecoration(
                              color: isMe ? userBubbleColor : opponentBubbleColor,
                              borderRadius: isMe ? userBorderRadius : opponentBorderRadius,
                            )
                          : null,
                      child: _buildMessageContent(msg, isMe),
                    ),
                  );
                },
              ),
            ),

            // HIDE Input Bar & Keyboard when safety-locked
            if (!_isLocked) ...[
              // 4. Input Area
              _buildInputBar(bgColor, textColor, subtextColor, userBubbleColor, style),

              // 5. iOS/Universal QWERTY Keyboard
              LiveTypingKeyboard(
                controller: _chatController,
                isDarkMode: _isDarkMode,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Custom Map Vector Grid Painter for Shared Location representation
class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
      
    // Crisscrossing road grid lines
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.25), paint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.8), paint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.45, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.6, size.height), paint);
    
    // Draw minor road details
    final minorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
      
    canvas.drawLine(Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.55), minorPaint);
    canvas.drawLine(Offset(size.width * 0.15, 0), Offset(size.width * 0.15, size.height), minorPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
