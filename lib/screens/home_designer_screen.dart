import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_config.dart';

class HomeDesignerScreen extends StatefulWidget {
  final HomeConfig config;

  const HomeDesignerScreen({
    super.key,
    required this.config,
  });

  @override
  State<HomeDesignerScreen> createState() => _HomeDesignerScreenState();
}

class _HomeDesignerScreenState extends State<HomeDesignerScreen> {
  late HomeConfig _currentConfig;
  final GlobalKey _repaintKey = GlobalKey();
  bool _isExporting = false;

  final Map<String, IconData> _vectorIcons = {
    'browser': Icons.language,
    'mail': Icons.mail,
    'photos': Icons.photo_library,
    'camera': Icons.camera_alt,
    'maps': Icons.map,
    'settings': Icons.settings,
    'notes': Icons.note_alt,
    'chat': Icons.chat,
  };

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.config;
  }

  void _showAppEditorDialog(int index) {
    final iconConfig = _currentConfig.icons[index];
    final labelController = TextEditingController(text: iconConfig.name);
    String selectedIconType = iconConfig.iconType;
    bool isVisible = iconConfig.isVisible;
    String? localIconPath = selectedIconType.contains('/') ? selectedIconType : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white10),
              ),
              title: Text("Edit Grid Icon ${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text label
                    TextFormField(
                      controller: labelController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "App Label",
                        labelStyle: TextStyle(color: Colors.white38),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Visibility Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Show Icon", style: TextStyle(fontSize: 14)),
                      value: isVisible,
                      onChanged: (val) {
                        setDialogState(() {
                          isVisible = val;
                        });
                      },
                    ),
                    const Divider(color: Colors.white10, height: 24),

                    // Vector Icon choices
                    const Text("SELECT VECTOR ICON", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _vectorIcons.keys.map((String key) {
                        final isSel = selectedIconType == key;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIconType = key;
                              localIconPath = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.pinkAccent.withValues(alpha: 0.2) : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? Colors.pinkAccent : Colors.transparent),
                            ),
                            child: Icon(_vectorIcons[key], color: isSel ? Colors.pinkAccent : Colors.white70, size: 24),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Custom photo picker
                    const Text("OR SELECT CUSTOM IMAGE", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            try {
                              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setDialogState(() {
                                  localIconPath = pickedFile.path;
                                  selectedIconType = pickedFile.path; // Store path
                                });
                              }
                            } catch (e) {
                              debugPrint("Error picking custom app icon image: $e");
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text("Upload Icon"),
                        ),
                        const SizedBox(width: 12),
                        if (localIconPath != null)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              image: DecorationImage(
                                image: FileImage(File(localIconPath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    // Update current icons config
                    final updatedIcon = AppIconConfig(
                      id: index,
                      name: labelController.text.trim().isEmpty ? "APP" : labelController.text.trim(),
                      iconType: selectedIconType,
                      isVisible: isVisible,
                    );
                    setState(() {
                      _currentConfig.icons[index] = updatedIcon;
                    });
                    _saveConfigToStorage();
                    Navigator.of(context).pop();
                  },
                  child: const Text("SAVE", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveConfigToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_home_config', jsonEncode(_currentConfig.toJson()));
  }

  Future<void> _exportPng() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Find RenderRepaintBoundary
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Convert boundary to ui.Image (pixel ratio 3.0 for crisp high-res)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save bytes to temp directory using path_provider
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/setscreen_home.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Open System Share Sheet using share_plus
      await SharePlus.instance.share(
        ShareParams(
          text: 'SetScreen Pro - Exported Home Layout',
          files: [XFile(filePath)],
        ),
      );
    } catch (e) {
      debugPrint("Error exporting home screen PNG: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Widget _buildWallpaper() {
    final hasWallpaper = _currentConfig.wallpaperPath != null &&
        _currentConfig.wallpaperPath!.isNotEmpty &&
        File(_currentConfig.wallpaperPath!).existsSync();

    if (hasWallpaper) {
      return Image.file(
        File(_currentConfig.wallpaperPath!),
        fit: BoxFit.cover,
      );
    }

    // Default premium lock screen abstract dark gradient
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0F1A),
            Color(0xFF231E35),
            Color(0xFF0A0B12),
          ],
        ),
      ),
    );
  }

  Widget _buildMockStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: Colors.black.withValues(alpha: 0.15),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("9:41", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          Row(
            children: [
              Icon(Icons.signal_cellular_4_bar, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Icon(Icons.wifi, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Icon(Icons.battery_full, size: 16, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppTile(AppIconConfig iconConfig) {
    if (!iconConfig.isVisible) {
      // Invisible grid tile placeholder (still clickable in design mode)
      return Opacity(
        opacity: 0.25,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white38),
          ),
        ),
      );
    }

    final isCustom = iconConfig.iconType.contains('/');
    Widget iconWidget;

    if (isCustom) {
      iconWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          image: DecorationImage(
            image: FileImage(File(iconConfig.iconType)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      final iconData = _vectorIcons[iconConfig.iconType] ?? Icons.settings;
      iconWidget = Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Center(
          child: Icon(iconData, color: Colors.white, size: 28),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: iconWidget,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          iconConfig.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Repaint Boundary that captures the home screen layout
            Positioned.fill(
              bottom: 80, // Leave room for bottom control bar
              child: RepaintBoundary(
                key: _repaintKey,
                child: Stack(
                  children: [
                    // Wallpaper
                    Positioned.fill(
                      child: _buildWallpaper(),
                    ),
                    
                    // Status bar
                    if (_currentConfig.showStatusBar)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(child: _buildMockStatusBar()),
                      ),

                    // Grid View area
                    Positioned.fill(
                      top: _currentConfig.showStatusBar ? 80 : 40,
                      bottom: 40,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _currentConfig.gridColumns,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _currentConfig.gridColumns * _currentConfig.gridRows,
                          itemBuilder: (context, index) {
                            final iconConfig = _currentConfig.icons[index];
                            return GestureDetector(
                              onTap: () => _showAppEditorDialog(index),
                              child: _buildAppTile(iconConfig),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom control bar (Floating HUD)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        
                        // Main Title label
                        const Text(
                          "DESIGN MODE",
                          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.pinkAccent, fontSize: 13, letterSpacing: 1.5),
                        ),
                        
                        // Export PNG Button
                        _isExporting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent),
                              )
                            : IconButton(
                                icon: const Icon(Icons.share, color: Colors.pinkAccent),
                                onPressed: _exportPng,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
