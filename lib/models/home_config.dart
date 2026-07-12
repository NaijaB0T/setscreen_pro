class AppIconConfig {
  final int id; // Grid index
  final String name;
  final String iconType; // 'browser', 'mail', 'photos', 'camera', 'maps', 'settings', 'notes', 'chat' or a custom file path
  final bool isVisible;

  AppIconConfig({
    required this.id,
    required this.name,
    required this.iconType,
    required this.isVisible,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconType': iconType,
    'isVisible': isVisible,
  };

  factory AppIconConfig.fromJson(Map<String, dynamic> json) {
    return AppIconConfig(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      iconType: json['iconType'] as String? ?? 'settings',
      isVisible: json['isVisible'] as bool? ?? false,
    );
  }
}

class HomeConfig {
  final int gridColumns;
  final int gridRows;
  final String? wallpaperPath;
  final bool showStatusBar;
  final List<AppIconConfig> icons;

  HomeConfig({
    this.gridColumns = 4,
    this.gridRows = 6,
    this.wallpaperPath,
    this.showStatusBar = true,
    required this.icons,
  });

  Map<String, dynamic> toJson() => {
    'gridColumns': gridColumns,
    'gridRows': gridRows,
    'wallpaperPath': wallpaperPath,
    'showStatusBar': showStatusBar,
    'icons': icons.map((item) => item.toJson()).toList(),
  };

  factory HomeConfig.fromJson(Map<String, dynamic> json) {
    final list = json['icons'] as List? ?? [];
    return HomeConfig(
      gridColumns: json['gridColumns'] as int? ?? 4,
      gridRows: json['gridRows'] as int? ?? 6,
      wallpaperPath: json['wallpaperPath'] as String?,
      showStatusBar: json['showStatusBar'] as bool? ?? true,
      icons: list.map((item) => AppIconConfig.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}
