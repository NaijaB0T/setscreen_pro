class PlaybackConfig {
  final String videoPath;
  final double playbackSpeed;
  final bool muteAudio;
  final bool hideStatusBar;
  final bool useVolumeTrigger;

  PlaybackConfig({
    required this.videoPath,
    required this.playbackSpeed,
    required this.muteAudio,
    required this.hideStatusBar,
    required this.useVolumeTrigger,
  });

  Map<String, dynamic> toJson() => {
    'videoPath': videoPath,
    'playbackSpeed': playbackSpeed,
    'muteAudio': muteAudio,
    'hideStatusBar': hideStatusBar,
    'useVolumeTrigger': useVolumeTrigger,
  };

  factory PlaybackConfig.fromJson(Map<String, dynamic> json) {
    return PlaybackConfig(
      videoPath: json['videoPath'] as String? ?? '',
      playbackSpeed: (json['playbackSpeed'] as num? ?? 1.0).toDouble(),
      muteAudio: json['muteAudio'] as bool? ?? false,
      hideStatusBar: json['hideStatusBar'] as bool? ?? false,
      useVolumeTrigger: json['useVolumeTrigger'] as bool? ?? false,
    );
  }
}
