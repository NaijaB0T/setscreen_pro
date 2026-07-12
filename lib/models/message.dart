enum MessageSender {
  sender,   // User (blue/green bubble on the right)
  receiver, // Opponent (gray bubble on the left)
}

class Message {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isTyped;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    required this.isTyped,
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
