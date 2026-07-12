import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_config.dart';
import '../models/script_item.dart';
import 'chat_screen.dart';
import 'audio_call_screen.dart';
import 'video_call_screen.dart';

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
  int _typingDelay = 2;
  bool _useGreenBubbles = false;
  bool _useDarkMode = true;
  
  // Sprint 3 Call configurations
  SceneType _activeScene = SceneType.text;
  bool _isIncomingCall = true;
  String? _videoCallerPath;

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
          _activeScene = config.sceneType;
          _isIncomingCall = config.isIncomingCall;
          _videoCallerPath = config.videoCallerPath;
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
      _activeScene = SceneType.text;
      _isIncomingCall = true;
      _videoCallerPath = null;
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

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _videoCallerPath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
    }
  }

  Future<void> _startTake() async {
    if (!_formKey.currentState!.validate()) return;

    List<ScriptItem> scriptItems = [];
    if (_activeScene == SceneType.text) {
      scriptItems = _parseScriptText(_scriptController.text);
      if (scriptItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please write at least one line of script.")),
        );
        return;
      }
    }

    if (_activeScene == SceneType.videoCall && (_videoCallerPath == null || _videoCallerPath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a video asset for the video stream.")),
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
      sceneType: _activeScene,
      isIncomingCall: _isIncomingCall,
      videoCallerPath: _videoCallerPath,
    );

    // Save configuration
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_project_config', jsonEncode(config.toJson()));

    // Navigate to selected Screen Mode
    if (mounted) {
      Widget targetScreen;
      switch (_activeScene) {
        case SceneType.text:
          targetScreen = ChatScreen(config: config);
          break;
        case SceneType.audioCall:
          targetScreen = AudioCallScreen(config: config);
          break;
        case SceneType.videoCall:
          targetScreen = VideoCallScreen(config: config);
          break;
      }

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => targetScreen),
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
              // Segmented Scene Selector at the top
              Center(
                child: SegmentedButton<SceneType>(
                  segments: const <ButtonSegment<SceneType>>[
                    ButtonSegment<SceneType>(
                      value: SceneType.text,
                      label: Text('Text Chat'),
                      icon: Icon(Icons.chat),
                    ),
                    ButtonSegment<SceneType>(
                      value: SceneType.audioCall,
                      label: Text('Audio Call'),
                      icon: Icon(Icons.phone),
                    ),
                    ButtonSegment<SceneType>(
                      value: SceneType.videoCall,
                      label: Text('Video Call'),
                      icon: Icon(Icons.videocam),
                    ),
                  ],
                  selected: <SceneType>{_activeScene},
                  onSelectionChanged: (Set<SceneType> newSelection) {
                    setState(() {
                      _activeScene = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

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
                            backgroundImage: _avatarPath != null && File(_avatarPath!).existsSync()
                                ? FileImage(File(_avatarPath!))
                                : null,
                            child: _avatarPath == null || !File(_avatarPath!).existsSync()
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
                      "Tap to set contact avatar",
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

              // DYNAMIC SETTINGS DEPENDING ON SCENE SELECTION
              if (_activeScene == SceneType.text) ...[
                // Opponent Delay Slider (only for Text)
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

                // Layout Toggles (only for Text)
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

                // Screenplay Script input (only for Text)
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
                    if (_activeScene == SceneType.text && (value == null || value.trim().isEmpty)) {
                      return "Please write a screenplay script";
                    }
                    return null;
                  },
                ),
              ] else if (_activeScene == SceneType.audioCall) ...[
                // Call Options (Incoming vs Outgoing)
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SwitchListTile(
                    title: const Text("Incoming Call", style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text("True: Show Slide to Answer; False: Simulate dial Outgoing", style: TextStyle(fontSize: 11)),
                    value: _isIncomingCall,
                    onChanged: (val) {
                      setState(() {
                        _isIncomingCall = val;
                      });
                    },
                  ),
                ),
              ] else if (_activeScene == SceneType.videoCall) ...[
                // Video Call Options (Select incoming video file)
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "FaceTime Incoming Stream Asset",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Select a video file from your device library to stream as the incoming caller's video background.",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickVideo,
                              icon: const Icon(Icons.video_library),
                              label: const Text("Choose Video"),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _videoCallerPath != null
                                    ? "Selected: ${File(_videoCallerPath!).path.split('/').last}"
                                    : "No video selected",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

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
