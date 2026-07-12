class SocialPostItem {
  final String username;
  final String avatarLetter;
  final String? mediaPath; // Image or video file path
  final String caption;
  final int likes;
  final String postType;   // 'image', 'video', 'text'

  SocialPostItem({
    required this.username,
    required this.avatarLetter,
    this.mediaPath,
    required this.caption,
    required this.likes,
    required this.postType,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'avatarLetter': avatarLetter,
    'mediaPath': mediaPath,
    'caption': caption,
    'likes': likes,
    'postType': postType,
  };

  factory SocialPostItem.fromJson(Map<String, dynamic> json) {
    return SocialPostItem(
      username: json['username'] as String? ?? 'user_account',
      avatarLetter: json['avatarLetter'] as String? ?? 'U',
      mediaPath: json['mediaPath'] as String?,
      caption: json['caption'] as String? ?? '',
      likes: json['likes'] as int? ?? 120,
      postType: json['postType'] as String? ?? 'image',
    );
  }
}

class SearchResultItem {
  final String title;
  final String url;
  final String snippet;
  final String articleHeadline;
  final String articleBody;

  SearchResultItem({
    required this.title,
    required this.url,
    required this.snippet,
    required this.articleHeadline,
    required this.articleBody,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'snippet': snippet,
    'articleHeadline': articleHeadline,
    'articleBody': articleBody,
  };

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      title: json['title'] as String? ?? 'Mock Search Result Title',
      url: json['url'] as String? ?? 'www.mockwebsite.com',
      snippet: json['snippet'] as String? ?? 'This is a description snippet of the custom search result designed for film set playback.',
      articleHeadline: json['articleHeadline'] as String? ?? 'BREAKING NEWS HEADLINE',
      articleBody: json['articleBody'] as String? ?? 'This is the full body text of the selected editorial article.',
    );
  }
}

class SocialConfig {
  final String style; // 'shortVideo', 'photoFeed', 'microblog', 'search', 'navigation'
  final List<SocialPostItem> posts;
  final String searchLogoText;
  final String customQuery;
  final List<SearchResultItem> searchResults;

  SocialConfig({
    required this.style,
    required this.posts,
    required this.searchLogoText,
    required this.customQuery,
    required this.searchResults,
  });

  Map<String, dynamic> toJson() => {
    'style': style,
    'posts': posts.map((p) => p.toJson()).toList(),
    'searchLogoText': searchLogoText,
    'customQuery': customQuery,
    'searchResults': searchResults.map((r) => r.toJson()).toList(),
  };

  factory SocialConfig.fromJson(Map<String, dynamic> json) {
    final postsList = json['posts'] as List? ?? [];
    final resultsList = json['searchResults'] as List? ?? [];
    return SocialConfig(
      style: json['style'] as String? ?? 'photoFeed',
      posts: postsList.map((p) => SocialPostItem.fromJson(p as Map<String, dynamic>)).toList(),
      searchLogoText: json['searchLogoText'] as String? ?? 'Search',
      customQuery: json['customQuery'] as String? ?? 'SetScreen Pro prop simulator',
      searchResults: resultsList.map((r) => SearchResultItem.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }
}
