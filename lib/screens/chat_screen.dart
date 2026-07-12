import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';
import '../widgets/live_typing_keyboard.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatController _chatController;
  final ScrollController _scrollController = ScrollController();
  bool _isDarkMode = true; // Default to dark mode for screen insertion props

  @override
  void initState() {
    super.initState();
    _chatController = ChatController();
    _chatController.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _chatController.removeListener(_onControllerUpdate);
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    // Automatically scroll to the bottom on new message or typing indicator update
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
    // Set system status bar style based on theme
    SystemChrome.setSystemUIOverlayStyle(
      _isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Styling Colors
    final bgColor = _isDarkMode ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final headerBgColor = _isDarkMode ? const Color(0xFF161618) : const Color(0xFFF6F6F6);
    final dividerColor = _isDarkMode ? const Color(0xFF262629) : const Color(0xFFE5E5EA);
    final textColor = _isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final subtextColor = _isDarkMode ? Colors.white60 : Colors.black54;

    final userBubbleColor = _chatController.isGreenBubble
        ? const Color(0xFF34C759) // iOS Green
        : const Color(0xFF007AFF); // iOS Blue

    final opponentBubbleColor = _isDarkMode
        ? const Color(0xFF252528) // Dark Mode Opponent Bubble
        : const Color(0xFFE5E5EA); // Light Mode Opponent Bubble

    final opponentTextColor = _isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Mock iOS Status Bar for Authentic Look on Camera
            Container(
              color: headerBgColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time
                  Text(
                    "9:41",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  // Icons
                  Row(
                    children: [
                      Icon(Icons.signal_cellular_4_bar, size: 14, color: textColor),
                      const SizedBox(width: 4),
                      Text("5G", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(width: 4),
                      Icon(Icons.battery_5_bar, size: 16, color: textColor),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Chat Header / AppBar
            Container(
              color: headerBgColor,
              padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
              child: Row(
                children: [
                  // Left back chevron
                  Icon(Icons.arrow_back_ios_new, color: userBubbleColor, size: 20),
                  const SizedBox(width: 8),
                  
                  // Double tap title for instant theme switch, or click buttons
                  Expanded(
                    child: GestureDetector(
                      onDoubleTap: _toggleTheme,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Contact Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[400],
                            child: const Text(
                              "MN",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Name
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Michael Naizu",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 12, color: subtextColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Dev Tools / Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle bubble style (Blue vs Green)
                      IconButton(
                        icon: Icon(Icons.circle, color: userBubbleColor, size: 20),
                        onPressed: _chatController.toggleBubbleColor,
                        tooltip: "Toggle Blue/Green bubbles",
                      ),
                      // Reset Chat
                      IconButton(
                        icon: Icon(Icons.refresh, color: textColor, size: 20),
                        onPressed: _chatController.resetChat,
                        tooltip: "Reset Script",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Container(height: 1, color: dividerColor),

            // 3. Chat Messages Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                itemCount: _chatController.messages.length + (_chatController.isOpponentTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  // Typing indicator case
                  if (index == _chatController.messages.length) {
                    return TypingIndicator(isDarkMode: _isDarkMode);
                  }

                  final msg = _chatController.messages[index];
                  final isMe = msg.sender == MessageSender.sender;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? userBubbleColor : opponentBubbleColor,
                        borderRadius: isMe
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                                bottomRight: Radius.circular(4),
                              )
                            : const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                                bottomLeft: Radius.circular(4),
                                bottomRight: Radius.circular(18),
                              ),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : opponentTextColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: bgColor,
              child: Row(
                children: [
                  Icon(Icons.camera_alt, color: subtextColor, size: 28),
                  const SizedBox(width: 8),
                  Icon(Icons.card_giftcard, color: subtextColor, size: 28),
                  const SizedBox(width: 8),
                  
                  // Text field bubble simulation
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
                          _chatController.currentTypedText.isEmpty
                              ? "iMessage"
                              : _chatController.currentTypedText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _chatController.currentTypedText.isEmpty
                                ? (_isDarkMode ? Colors.white38 : Colors.black38)
                                : textColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Circular Send Arrow
                  GestureDetector(
                    onTap: () {
                      if (_chatController.isMessageFullyTyped) {
                        _chatController.sendMessage();
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _chatController.isMessageFullyTyped
                            ? userBubbleColor
                            : (_isDarkMode ? const Color(0xFF252528) : const Color(0xFFE5E5EA)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward,
                        color: _chatController.isMessageFullyTyped
                            ? Colors.white
                            : (_isDarkMode ? Colors.white38 : Colors.black38),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. iOS QWERTY Keyboard
            LiveTypingKeyboard(
              controller: _chatController,
              isDarkMode: _isDarkMode,
            ),
          ],
        ),
      ),
    );
  }
}
