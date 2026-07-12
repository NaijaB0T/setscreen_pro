import 'script_item.dart';

class ProjectConfig {
  final String contactName;
  final String? avatarPath;
  final int opponentTypingDelay;
  final bool initialUseGreenBubbles;
  final bool initialUseDarkMode;
  final List<ScriptItem> script;

  ProjectConfig({
    required this.contactName,
    this.avatarPath,
    required this.opponentTypingDelay,
    required this.initialUseGreenBubbles,
    required this.initialUseDarkMode,
    required this.script,
  });

  Map<String, dynamic> toJson() => {
    'contactName': contactName,
    'avatarPath': avatarPath,
    'opponentTypingDelay': opponentTypingDelay,
    'initialUseGreenBubbles': initialUseGreenBubbles,
    'initialUseDarkMode': initialUseDarkMode,
    'script': script.map((item) => item.toJson()).toList(),
  };

  factory ProjectConfig.fromJson(Map<String, dynamic> json) {
    final scriptList = json['script'] as List? ?? [];
    return ProjectConfig(
      contactName: json['contactName'] as String? ?? 'Michael Naizu',
      avatarPath: json['avatarPath'] as String?,
      opponentTypingDelay: json['opponentTypingDelay'] as int? ?? 2,
      initialUseGreenBubbles: json['initialUseGreenBubbles'] as bool? ?? false,
      initialUseDarkMode: json['initialUseDarkMode'] as bool? ?? true,
      script: scriptList
          .map((item) => ScriptItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
