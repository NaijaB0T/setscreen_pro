class VideoCallConfig {
  final String callerName;
  final String? avatarPath;
  final String? videoPath;
  final bool isIncoming;
  final bool isGreenScreenMode;

  VideoCallConfig({
    required this.callerName,
    this.avatarPath,
    this.videoPath,
    required this.isIncoming,
    required this.isGreenScreenMode,
  });

  Map<String, dynamic> toJson() => {
    'callerName': callerName,
    'avatarPath': avatarPath,
    'videoPath': videoPath,
    'isIncoming': isIncoming,
    'isGreenScreenMode': isGreenScreenMode,
  };

  factory VideoCallConfig.fromJson(Map<String, dynamic> json) {
    return VideoCallConfig(
      callerName: json['callerName'] as String? ?? 'Michael Naizu',
      avatarPath: json['avatarPath'] as String?,
      videoPath: json['videoPath'] as String?,
      isIncoming: json['isIncoming'] as bool? ?? true,
      isGreenScreenMode: json['isGreenScreenMode'] as bool? ?? false,
    );
  }
}
