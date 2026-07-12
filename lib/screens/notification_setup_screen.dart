import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_config.dart';
import 'notification_screen.dart';

class NotificationSetupScreen extends StatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  State<NotificationSetupScreen> createState() => _NotificationSetupScreenState();
}

class _NotificationSetupScreenState extends State<NotificationSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  String _style = 'lockScreen'; // 'lockScreen', 'banner'
  String? _wallpaperPath;
  List<NotificationItem> _queue = [];

  final List<String> _appNames = ['iMessage', 'Instagram', 'WhatsApp', 'Mail', 'Calendar'];

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('saved_notification_config');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final config = NotificationConfig.fromJson(jsonDecode(jsonStr));
        setState(() {
          _style = config.style;
          _wallpaperPath = config.wallpaperPath;
          _queue = config.queue;
        });
      } catch (e) {
        debugPrint("Error loading notification config: $e");
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

  void _showAddNotificationDialog() {
    final nameController = TextEditingController();
    final bodyController = TextEditingController();
    String appName = 'iMessage';
    double delay = 2.0;
    double duration = 5.0;

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
              title: const Text("Add Notification Alert", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.grey[900],
                        initialValue: appName,
                        decoration: const InputDecoration(
                          labelText: "App Icon / Channel",
                          labelStyle: TextStyle(color: Colors.white38),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        items: _appNames.map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              appName = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Sender Name",
                          labelStyle: TextStyle(color: Colors.white38),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bodyController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Message Text",
                          labelStyle: TextStyle(color: Colors.white38),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Trigger Delay", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text("${delay.toStringAsFixed(1)}s", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Slider(
                        value: delay,
                        min: 0,
                        max: 30,
                        divisions: 30,
                        activeColor: Colors.orangeAccent,
                        onChanged: (val) {
                          setDialogState(() {
                            delay = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Display Duration", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text("${duration.toStringAsFixed(1)}s", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Slider(
                        value: duration,
                        min: 2,
                        max: 10,
                        divisions: 8,
                        activeColor: Colors.orangeAccent,
                        onChanged: (val) {
                          setDialogState(() {
                            duration = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    final item = NotificationItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      appName: appName,
                      senderName: nameController.text.trim().isEmpty ? "Unknown" : nameController.text.trim(),
                      messageBody: bodyController.text.trim().isEmpty ? "Notification Alert" : bodyController.text.trim(),
                      triggerDelay: delay,
                      displayDuration: duration,
                    );
                    setState(() {
                      _queue.add(item);
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text("ADD", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _startTake() async {
    if (_queue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one notification to the queue.")),
      );
      return;
    }

    final config = NotificationConfig(
      style: _style,
      wallpaperPath: _wallpaperPath,
      queue: _queue,
    );

    // Save config
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_notification_config', jsonEncode(config.toJson()));

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NotificationScreen(
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
          primary: Colors.purpleAccent,
          secondary: Colors.purple,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            "NOTIFICATION OVERLAYS CONFIG",
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
                // Style Selector
                const Text("OVERLAY RENDER STYLE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Center(
                    child: SegmentedButton<String>(
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'lockScreen',
                          label: Text('Lock Screen'),
                          icon: Icon(Icons.lock),
                        ),
                        ButtonSegment<String>(
                          value: 'banner',
                          label: Text('Top Banner'),
                          icon: Icon(Icons.publish),
                        ),
                      ],
                      selected: <String>{_style},
                      onSelectionChanged: (Set<String> val) {
                        setState(() {
                          _style = val.first;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Wallpaper Picker
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

                // Notification Queue Builder
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("NOTIFICATION ALERTS QUEUE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.purpleAccent),
                      onPressed: _showAddNotificationDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: _queue.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text("No alerts added yet. Click '+' to build queue.", style: TextStyle(color: Colors.white38, fontSize: 13)),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _queue.length,
                          separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05)),
                          itemBuilder: (context, index) {
                            final item = _queue[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.white10,
                                child: Text(item.appName[0], style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                              ),
                              title: Text("${item.senderName} (${item.appName})", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                "Body: ${item.messageBody}\nDelay: ${item.triggerDelay}s | Duration: ${item.displayDuration}s",
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _queue.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 40),

                // Start Take Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _startTake,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      "START TAKE",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
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
