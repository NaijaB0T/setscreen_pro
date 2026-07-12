class CallConfig {
  final String firstName;
  final String lastName;
  final String? avatarPath;
  final String? posterPath;
  final bool isIncoming;
  final String layoutVersion; // 'ios13', 'ios17', 'ios26'
  final String ringtone;
  final double ringtoneVolume;

  CallConfig({
    required this.firstName,
    required this.lastName,
    this.avatarPath,
    this.posterPath,
    required this.isIncoming,
    required this.layoutVersion,
    required this.ringtone,
    required this.ringtoneVolume,
  });

  String get fullName => "$firstName $lastName".trim();

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'avatarPath': avatarPath,
    'posterPath': posterPath,
    'isIncoming': isIncoming,
    'layoutVersion': layoutVersion,
    'ringtone': ringtone,
    'ringtoneVolume': ringtoneVolume,
  };

  factory CallConfig.fromJson(Map<String, dynamic> json) {
    return CallConfig(
      firstName: json['firstName'] as String? ?? 'Michael',
      lastName: json['lastName'] as String? ?? 'Naizu',
      avatarPath: json['avatarPath'] as String?,
      posterPath: json['posterPath'] as String?,
      isIncoming: json['isIncoming'] as bool? ?? true,
      layoutVersion: json['layoutVersion'] as String? ?? 'ios13',
      ringtone: json['ringtone'] as String? ?? 'Marimba',
      ringtoneVolume: (json['ringtoneVolume'] as num? ?? 0.8).toDouble(),
    );
  }
}
