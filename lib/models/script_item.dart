class ScriptItem {
  final String text;
  final bool isUser; // true if the actor types it, false if it's automated opponent response

  ScriptItem({
    required this.text,
    required this.isUser,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
  };

  factory ScriptItem.fromJson(Map<String, dynamic> json) => ScriptItem(
    text: json['text'] as String,
    isUser: json['isUser'] as bool,
  );
}
