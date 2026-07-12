import 'script_item.dart';

enum MessageSender {
  sender,   // User (right side)
  receiver, // Opponent (left side)
}

class Message {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isTyped;
  final MessageType type;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    required this.isTyped,
    this.type = MessageType.text,
  });

  bool get isUser => sender == MessageSender.sender;
}

class ScriptMessage {
  final String text;
  final MessageSender sender;
  final Duration typingDelay;

  ScriptMessage({
    required this.text,
    required this.sender,
    this.typingDelay = const Duration(seconds: 2),
  });
}
