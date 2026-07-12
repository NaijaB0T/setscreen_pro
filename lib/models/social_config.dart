class SocialConfig {
  final String style; // 'shortVideo', 'photoFeed', 'microblog', 'search', 'navigation'
  final List<String> mediaPaths; // Multi-media queue paths
  final String customQuery;
  final String newsHeadline;
  final String newsBody;

  SocialConfig({
    required this.style,
    required this.mediaPaths,
    required this.customQuery,
    required this.newsHeadline,
    required this.newsBody,
  });

  Map<String, dynamic> toJson() => {
    'style': style,
    'mediaPaths': mediaPaths,
    'customQuery': customQuery,
    'newsHeadline': newsHeadline,
    'newsBody': newsBody,
  };

  factory SocialConfig.fromJson(Map<String, dynamic> json) {
    final list = json['mediaPaths'] as List? ?? [];
    return SocialConfig(
      style: json['style'] as String? ?? 'photoFeed',
      mediaPaths: list.map((item) => item as String).toList(),
      customQuery: json['customQuery'] as String? ?? 'SetScreen Pro prop simulator',
      newsHeadline: json['newsHeadline'] as String? ?? 'BREAKING NEWS',
      newsBody: json['newsBody'] as String? ?? 'This is a mock news body text that was remotely loaded or configured on set for screen compositing.',
    );
  }
}
