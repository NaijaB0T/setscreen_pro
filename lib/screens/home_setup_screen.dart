import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_config.dart';
import 'home_designer_screen.dart';

class HomeSetupScreen extends StatefulWidget {
  const HomeSetupScreen({super.key});

  @override
  State<HomeSetupScreen> createState() => _HomeSetupScreenState();
}

class _HomeSetupScreenState extends State<HomeSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  int _gridColumns = 4;
  int _gridRows = 6;
  String? _wallpaperPath;
  bool _showStatusBar = true;
  List<AppIconConfig> _savedIcons = [];

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('saved_home_config');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final config = HomeConfig.fromJson(jsonDecode(jsonStr));
        setState(() {
          _gridColumns = config.gridColumns;
          _gridRows = config.gridRows;
          _wallpaperPath = config.wallpaperPath;
          _showStatusBar = config.showStatusBar;
          _savedIcons = config.icons;
        });
      } catch (e) {
        debugPrint("Error loading home screen config: $e");
      }
    }
  }

  Future<void> _pickWallpaper() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _wallpaperPath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking wallpaper: $e");
    }
  }

  Future<void> _startDesigner() async {
    if (!_formKey.currentState!.validate()) return;

    final totalSlots = _gridColumns * _gridRows;
    final List<AppIconConfig> icons = [];

    // Map existing icons or generate default templates
    final Map<int, AppIconConfig> existingMap = {
      for (var icon in _savedIcons) icon.id: icon
    };

    final List<String> defaultTypes = [
      'browser', 'chat', 'camera', 'photos', 
      'mail', 'maps', 'notes', 'settings'
    ];

    for (int i = 0; i < totalSlots; i++) {
      if (existingMap.containsKey(i)) {
        icons.add(existingMap[i]!);
      } else {
        // Generate default icons for the first few slots, leave rest invisible
        final isDefaultVisible = i < 8;
        final name = isDefaultVisible 
            ? defaultTypes[i].toUpperCase() 
            : "APP ${i + 1}";
        icons.add(AppIconConfig(
          id: i,
          name: name,
          iconType: isDefaultVisible ? defaultTypes[i] : 'settings',
          isVisible: isDefaultVisible,
        ));
      }
    }

    final config = HomeConfig(
      gridColumns: _gridColumns,
      gridRows: _gridRows,
      wallpaperPath: _wallpaperPath,
      showStatusBar: _showStatusBar,
      icons: icons,
    );

    // Save configuration
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_home_config', jsonEncode(config.toJson()));

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HomeDesignerScreen(
            config: config,
          ),
        ),
      );
    }
  }

  Widget _buildFrostedContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.pinkAccent,
          secondary: Colors.pink,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            "HOME SCREEN CONFIGURATION",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          centerTitle: true,
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallpaper backdrop picker
                const Text("WALLPAPER BACKDROP", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickWallpaper,
                            icon: const Icon(Icons.wallpaper),
                            label: const Text("Choose Image"),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _wallpaperPath != null
                                  ? "Selected: ${_wallpaperPath!.split('/').last}"
                                  : "No wallpaper selected (uses standard iOS default)",
                              style: const TextStyle(fontSize: 12, color: Colors.white38),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_wallpaperPath != null && File(_wallpaperPath!).existsSync()) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 120,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                            image: DecorationImage(
                              image: FileImage(File(_wallpaperPath!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Grid settings selectors
                const Text("GRID ARRANGEMENT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Columns", style: TextStyle(fontSize: 14)),
                          Text("$_gridColumns columns", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                        ],
                      ),
                      Slider(
                        value: _gridColumns.toDouble(),
                        min: 3,
                        max: 6,
                        divisions: 3,
                        activeColor: Colors.pinkAccent,
                        onChanged: (val) {
                          setState(() {
                            _gridColumns = val.toInt();
                          });
                        },
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Rows", style: TextStyle(fontSize: 14)),
                          Text("$_gridRows rows", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                        ],
                      ),
                      Slider(
                        value: _gridRows.toDouble(),
                        min: 4,
                        max: 8,
                        divisions: 4,
                        activeColor: Colors.pinkAccent,
                        onChanged: (val) {
                          setState(() {
                            _gridRows = val.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Look and Options
                const Text("SIMULATOR DISPLAY OPTIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Show iOS Status Bar", style: TextStyle(fontSize: 14)),
                    value: _showStatusBar,
                    onChanged: (val) {
                      setState(() {
                        _showStatusBar = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // Open Designer Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _startDesigner,
                    icon: const Icon(Icons.grid_view),
                    label: const Text(
                      "OPEN DESIGNER",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
