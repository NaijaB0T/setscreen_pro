import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/script_item.dart';
import '../models/project_config.dart';

class ChatController extends ChangeNotifier {
  final ProjectConfig config;
  final List<ScriptItem> _script = [];
  final List<Message> _visibleMessages = [];
  
  int _currentScriptIndex = 0;
  String _currentTypedText = "";
  int _characterIndex = 0;
  bool _isOpponentTyping = false;
  
  // Customization (Prop Tools toggled at runtime)
  late bool _isGreenBubble;

  ChatController({required this.config}) {
    _script.addAll(config.script);
    _isGreenBubble = config.initialUseGreenBubbles;
    
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
    
    if (currentScriptMsg.type != MessageType.text) {
      return _characterIndex > 0;
    }
    return _characterIndex >= currentScriptMsg.text.length && _currentTypedText.isNotEmpty;
  }

  // Toggle between iOS Blue and iOS Green bubbles
  void toggleBubbleColor() {
    _isGreenBubble = !_isGreenBubble;
    notifyListeners();
  }

  // Intercept key tap and type the next character from the current script message
  void typeNextCharacter() {
    if (_currentScriptIndex >= _script.length) return;
    
    final currentScriptMsg = _script[_currentScriptIndex];
    if (!currentScriptMsg.isUser) return;

    if (currentScriptMsg.type != MessageType.text) {
      if (_characterIndex == 0) {
        _currentTypedText = "[Attachment: ${currentScriptMsg.type.name.toUpperCase()}]";
        _characterIndex = 1;
        notifyListeners();
      }
      return;
    }

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

    final currentScriptMsg = _script[_currentScriptIndex];
    
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: currentScriptMsg.type == MessageType.text ? _currentTypedText : "",
      sender: MessageSender.sender,
      timestamp: DateTime.now(),
      isTyped: true,
      type: currentScriptMsg.type,
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

    // Custom delay from config
    await Future.delayed(Duration(seconds: config.opponentTypingDelay));

    // Make sure we haven't reset the chat while waiting
    if (_currentScriptIndex < _script.length && _script[_currentScriptIndex] == scriptMsg) {
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: scriptMsg.type == MessageType.text ? scriptMsg.text : "",
        sender: MessageSender.receiver,
        timestamp: DateTime.now(),
        isTyped: false,
        type: scriptMsg.type,
      );

      _visibleMessages.add(newMessage);
      _isOpponentTyping = false;
      _currentScriptIndex++;
      notifyListeners();

      // Check if the next step is also an opponent message
      _checkNextScriptStep();
    }
  }

  void triggerOpponentProgress() {
    _checkNextScriptStep();
  }
}
