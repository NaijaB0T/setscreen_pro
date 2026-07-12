import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/script_item.dart';

class ChatController extends ChangeNotifier {
  final List<ScriptItem> _script = [];
  final List<Message> _visibleMessages = [];
  
  int _currentScriptIndex = 0;
  String _currentTypedText = "";
  int _characterIndex = 0;
  bool _isOpponentTyping = false;
  
  // Customization (Prop Tools)
  bool _isGreenBubble = false;

  ChatController({List<ScriptItem>? customScript}) {
    if (customScript != null && customScript.isNotEmpty) {
      _script.addAll(customScript);
    } else {
      _loadDefaultScript();
    }
    // Start the script flow
    _checkNextScriptStep();
  }

  // Getters
  List<Message> get visibleMessages => List.unmodifiable(_visibleMessages);
  List<Message> get messages => visibleMessages; // For backwards compatibility
  String get currentTypedText => _currentTypedText;
  bool get isOpponentTyping => _isOpponentTyping;
  bool get isGreenBubble => _isGreenBubble;
  int get currentScriptIndex => _currentScriptIndex;
  
  // Check if user has finished typing the current script message
  bool get isMessageFullyTyped {
    if (_currentScriptIndex >= _script.length) return false;
    final currentScriptMsg = _script[_currentScriptIndex];
    if (!currentScriptMsg.isUser) return false;
    return _characterIndex >= currentScriptMsg.text.length && _currentTypedText.isNotEmpty;
  }

  // Toggle between iOS Blue and iOS Green bubbles
  void toggleBubbleColor() {
    _isGreenBubble = !_isGreenBubble;
    notifyListeners();
  }

  void _loadDefaultScript() {
    _script.addAll([
      ScriptItem(
        text: "Can't believe he did that.",
        isUser: true,
      ),
      ScriptItem(
        text: "Right?",
        isUser: false,
      ),
      ScriptItem(
        text: "Mike send me over your script",
        isUser: true,
      ),
      ScriptItem(
        text: "I thought you said it was finished?",
        isUser: false,
      ),
      ScriptItem(
        text: "It is, I just need to double-check the final scene structure.",
        isUser: true,
      ),
      ScriptItem(
        text: "Alright, sending it now.",
        isUser: false,
      ),
    ]);
  }

  // Intercept key tap and type the next character from the current script message
  void typeNextCharacter() {
    if (_currentScriptIndex >= _script.length) return;
    
    final currentScriptMsg = _script[_currentScriptIndex];
    if (!currentScriptMsg.isUser) return;

    final targetText = currentScriptMsg.text;
    if (_characterIndex < targetText.length) {
      _currentTypedText += targetText[_characterIndex];
      _characterIndex++;
      notifyListeners();
    }
  }

  // Send the message once fully spelled out
  void sendMessage() {
    if (!isMessageFullyTyped) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _currentTypedText,
      sender: MessageSender.sender,
      timestamp: DateTime.now(),
      isTyped: true,
    );

    _visibleMessages.add(newMessage);
    _currentTypedText = "";
    _characterIndex = 0;
    _currentScriptIndex++;
    
    notifyListeners();
    
    // Check if the next step is an opponent message
    _checkNextScriptStep();
  }

  // Reset the chat to restart the script
  void resetChat() {
    _visibleMessages.clear();
    _currentTypedText = "";
    _characterIndex = 0;
    _currentScriptIndex = 0;
    _isOpponentTyping = false;
    notifyListeners();
    _checkNextScriptStep();
  }

  void _checkNextScriptStep() {
    if (_currentScriptIndex >= _script.length) return;

    final nextScriptMsg = _script[_currentScriptIndex];
    if (!nextScriptMsg.isUser) {
      _simulateOpponentTyping(nextScriptMsg);
    }
  }

  Future<void> _simulateOpponentTyping(ScriptItem scriptMsg) async {
    _isOpponentTyping = true;
    notifyListeners();

    // 2-second typing delay to simulate realistic opponent responses
    await Future.delayed(const Duration(seconds: 2));

    // Make sure we haven't reset the chat while waiting
    if (_currentScriptIndex < _script.length && _script[_currentScriptIndex] == scriptMsg) {
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: scriptMsg.text,
        sender: MessageSender.receiver,
        timestamp: DateTime.now(),
        isTyped: false,
      );

      _visibleMessages.add(newMessage);
      _isOpponentTyping = false;
      _currentScriptIndex++;
      notifyListeners();

      // Check if the next step is also an opponent message
      _checkNextScriptStep();
    }
  }
}
