class SocialConfig {
  final String style; // 'shortVideo', 'photoFeed', 'microblog', 'search', 'navigation'
  final String? wallpaperPath; // Image path for photoFeed/navigation backgrounds
  final String? videoPath;     // Video path for shortVideo
  final String customQuery;
  final String newsHeadline;
  final String newsBody;

  SocialConfig({
    required this.style,
    this.wallpaperPath,
    this.videoPath,
    required this.customQuery,
    required this.newsHeadline,
    required this.newsBody,
  });

  Map<String, dynamic> toJson() => {
    'style': style,
    'wallpaperPath': wallpaperPath,
    'videoPath': videoPath,
    'customQuery': customQuery,
    'newsHeadline': newsHeadline,
    'newsBody': newsBody,
  };

  factory SocialConfig.fromJson(Map<String, dynamic> json) {
    return SocialConfig(
      style: json['style'] as String? ?? 'photoFeed',
      wallpaperPath: json['wallpaperPath'] as String?,
      videoPath: json['videoPath'] as String?,
      customQuery: json['customQuery'] as String? ?? 'SetScreen Pro prop simulator',
      newsHeadline: json['newsHeadline'] as String? ?? 'BREAKING NEWS',
      newsBody: json['newsBody'] as String? ?? 'This is a mock news body text that was remotely loaded or configured on set for screen compositing.',
    );
  }
}
