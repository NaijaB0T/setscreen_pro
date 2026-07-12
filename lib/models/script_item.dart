enum MessageType {
  text,
  photo,
  map,
  audio,
}

class ScriptItem {
  final String text;
  final bool isUser; // true if the actor types it, false if it's automated opponent response
  final MessageType type;

  ScriptItem({
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'type': type.name,
  };

  factory ScriptItem.fromJson(Map<String, dynamic> json) {
    MessageType parsedType = MessageType.text;
    final typeName = json['type'] as String?;
    if (typeName != null) {
      try {
        parsedType = MessageType.values.byName(typeName);
      } catch (_) {}
    }
    return ScriptItem(
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? true,
      type: parsedType,
    );
  }
}
