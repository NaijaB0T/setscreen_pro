class ScriptItem {
  final String text;
  final bool isUser; // true if the actor types it, false if it's automated opponent response

  ScriptItem({
    required this.text,
    required this.isUser,
  });
}
