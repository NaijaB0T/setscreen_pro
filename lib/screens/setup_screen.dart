import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_config.dart';
import '../models/script_item.dart';
import 'chat_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _scriptController = TextEditingController();
  
  String? _avatarPath;
  int _typingDelay = 2; // Default 2 seconds
  bool _useGreenBubbles = false;
  bool _useDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('saved_project_config');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        final config = ProjectConfig.fromJson(decoded);
        setState(() {
          _nameController.text = config.contactName;
          _avatarPath = config.avatarPath;
          _typingDelay = config.opponentTypingDelay;
          _useGreenBubbles = config.initialUseGreenBubbles;
          _useDarkMode = config.initialUseDarkMode;
          _scriptController.text = _formatScriptForTextField(config.script);
        });
      } catch (e) {
        debugPrint("Error loading saved config: $e");
        _loadDefaultValues();
      }
    } else {
      _loadDefaultValues();
    }
  }

  void _loadDefaultValues() {
    setState(() {
      _nameController.text = "Michael Naizu";
      _typingDelay = 2;
      _useGreenBubbles = false;
      _useDarkMode = true;
      _scriptController.text = 
          "Them: Can't believe he did that.\n"
          "Me: Right?\n"
          "Me: Mike send me over your script\n"
          "Them: I thought you said it was finished?\n"
          "Me: It is, I just need to double-check the final scene structure.\n"
          "Them: Alright, sending it now.";
    });
  }

  String _formatScriptForTextField(List<ScriptItem> script) {
    return script.map((item) => "${item.isUser ? 'Me' : 'Them'}: ${item.text}").join('\n');
  }

  List<ScriptItem> _parseScriptText(String text) {
    final List<ScriptItem> parsed = [];
    final lines = text.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.toLowerCase().startsWith('me:')) {
        final content = line.substring(3).trim();
        if (content.isNotEmpty) {
          parsed.add(ScriptItem(text: content, isUser: true));
        }
      } else if (line.toLowerCase().startsWith('them:')) {
        final content = line.substring(5).trim();
        if (content.isNotEmpty) {
          parsed.add(ScriptItem(text: content, isUser: false));
        }
      } else {
        // Fallback: If no prefix, assume user text
        parsed.add(ScriptItem(text: line, isUser: true));
      }
    }
    return parsed;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _avatarPath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking avatar image: $e");
    }
  }

  Future<void> _startTake() async {
    if (!_formKey.currentState!.validate()) return;

    final scriptItems = _parseScriptText(_scriptController.text);
    if (scriptItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write at least one line of script.")),
      );
      return;
    }

    final config = ProjectConfig(
      contactName: _nameController.text.trim(),
      avatarPath: _avatarPath,
      opponentTypingDelay: _typingDelay,
      initialUseGreenBubbles: _useGreenBubbles,
      initialUseDarkMode: _useDarkMode,
      script: scriptItems,
    );

    // Save configuration to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_project_config', jsonEncode(config.toJson()));

    // Navigate to ChatScreen
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(config: config),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SetScreen Dashboard"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar & Name Card
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _avatarPath != null
                                ? FileImage(File(_avatarPath!))
                                : null,
                            child: _avatarPath == null
                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tap to set avatar",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Contact Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.contact_page),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter a contact name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Opponent Delay Slider
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Opponent Typing Delay", style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            "$_typingDelay sec",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _typingDelay.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (val) {
                          setState(() {
                            _typingDelay = val.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Layout Toggles
              Row(
                children: [
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SwitchListTile(
                        title: const Text("Green Bubbles", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: const Text("Standard SMS style", style: TextStyle(fontSize: 10)),
                        value: _useGreenBubbles,
                        onChanged: (val) {
                          setState(() {
                            _useGreenBubbles = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SwitchListTile(
                        title: const Text("Dark Theme", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: const Text("Low ambient reflection", style: TextStyle(fontSize: 10)),
                        value: _useDarkMode,
                        onChanged: (val) {
                          setState(() {
                            _useDarkMode = val;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Screenplay Script input
              const Text(
                "Conversation Script",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Prefix lines with 'Me:' for user and 'Them:' for the opponent.",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _scriptController,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: "Me: How is the shoot going?\nThem: Almost done, preparing camera.",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please write a screenplay script";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Start Take Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _startTake,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    "START TAKE",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
