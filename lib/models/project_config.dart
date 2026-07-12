import 'script_item.dart';

enum SceneType {
  text,
  audioCall,
  videoCall,
}

enum PlatformStyle {
  ios,
  android,
  generic,
}

class ProjectConfig {
  final String contactName;
  final String? avatarPath;
  final int opponentTypingDelay;
  final bool initialUseGreenBubbles;
  final bool initialUseDarkMode;
  final List<ScriptItem> script;
  final SceneType sceneType;
  final bool isIncomingCall;
  final String? videoCallerPath;
  final PlatformStyle platformStyle;

  ProjectConfig({
    required this.contactName,
    this.avatarPath,
    required this.opponentTypingDelay,
    required this.initialUseGreenBubbles,
    required this.initialUseDarkMode,
    required this.script,
    required this.sceneType,
    this.isIncomingCall = true,
    this.videoCallerPath,
    this.platformStyle = PlatformStyle.ios,
  });

  Map<String, dynamic> toJson() => {
    'contactName': contactName,
    'avatarPath': avatarPath,
    'opponentTypingDelay': opponentTypingDelay,
    'initialUseGreenBubbles': initialUseGreenBubbles,
    'initialUseDarkMode': initialUseDarkMode,
    'script': script.map((item) => item.toJson()).toList(),
    'sceneType': sceneType.name,
    'isIncomingCall': isIncomingCall,
    'videoCallerPath': videoCallerPath,
    'platformStyle': platformStyle.name,
  };

  factory ProjectConfig.fromJson(Map<String, dynamic> json) {
    final scriptList = json['script'] as List? ?? [];
    
    // Parse sceneType safely
    SceneType parsedSceneType = SceneType.text;
    final sceneTypeName = json['sceneType'] as String?;
    if (sceneTypeName != null) {
      try {
        parsedSceneType = SceneType.values.byName(sceneTypeName);
      } catch (_) {}
    }

    // Parse platformStyle safely
    PlatformStyle parsedPlatformStyle = PlatformStyle.ios;
    final platformStyleName = json['platformStyle'] as String?;
    if (platformStyleName != null) {
      try {
        parsedPlatformStyle = PlatformStyle.values.byName(platformStyleName);
      } catch (_) {}
    }

    return ProjectConfig(
      contactName: json['contactName'] as String? ?? 'Michael Naizu',
      avatarPath: json['avatarPath'] as String?,
      opponentTypingDelay: json['opponentTypingDelay'] as int? ?? 2,
      initialUseGreenBubbles: json['initialUseGreenBubbles'] as bool? ?? false,
      initialUseDarkMode: json['initialUseDarkMode'] as bool? ?? true,
      script: scriptList
          .map((item) => ScriptItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      sceneType: parsedSceneType,
      isIncomingCall: json['isIncomingCall'] as bool? ?? true,
      videoCallerPath: json['videoCallerPath'] as String?,
      platformStyle: parsedPlatformStyle,
    );
  }
}
