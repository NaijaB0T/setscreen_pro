class NotificationItem {
  final String id;
  final String appName;
  final String senderName;
  final String? senderAvatarPath;
  final String messageBody;
  final double triggerDelay; // in seconds
  final double displayDuration; // in seconds

  NotificationItem({
    required this.id,
    required this.appName,
    required this.senderName,
    this.senderAvatarPath,
    required this.messageBody,
    required this.triggerDelay,
    required this.displayDuration,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'appName': appName,
    'senderName': senderName,
    'senderAvatarPath': senderAvatarPath,
    'messageBody': messageBody,
    'triggerDelay': triggerDelay,
    'displayDuration': displayDuration,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      appName: json['appName'] as String? ?? 'iMessage',
      senderName: json['senderName'] as String? ?? 'Sender',
      senderAvatarPath: json['senderAvatarPath'] as String?,
      messageBody: json['messageBody'] as String? ?? '',
      triggerDelay: (json['triggerDelay'] as num? ?? 0.0).toDouble(),
      displayDuration: (json['displayDuration'] as num? ?? 5.0).toDouble(),
    );
  }
}

class NotificationConfig {
  final String style; // 'lockScreen', 'banner'
  final String? wallpaperPath;
  final List<NotificationItem> queue;

  NotificationConfig({
    required this.style,
    this.wallpaperPath,
    required this.queue,
  });

  Map<String, dynamic> toJson() => {
    'style': style,
    'wallpaperPath': wallpaperPath,
    'queue': queue.map((item) => item.toJson()).toList(),
  };

  factory NotificationConfig.fromJson(Map<String, dynamic> json) {
    final list = json['queue'] as List? ?? [];
    return NotificationConfig(
      style: json['style'] as String? ?? 'lockScreen',
      wallpaperPath: json['wallpaperPath'] as String?,
      queue: list.map((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}
