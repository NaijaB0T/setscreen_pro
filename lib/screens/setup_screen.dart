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
  
  // Call configurations
  SceneType _activeScene = SceneType.text;
  bool _isIncomingCall = true;
  String? _videoCallerPath;

  // Platform styling (Sprint 5)
  PlatformStyle _selectedPlatform = PlatformStyle.ios;

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
          _selectedPlatform = config.platformStyle;
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
      _selectedPlatform = PlatformStyle.ios;
      _scriptController.text = 
          "Them: Can't believe he did that.\n"
          "Me: Right?\n"
          "Me: [Photo]\n"
          "Them: [Map]\n"
          "Me: [Audio]\n"
          "Them: I thought you said it was finished?\n"
          "Me: It is, I just need to double-check the final scene structure.\n"
          "Them: Alright, sending it now.";
    });
  }

  String _formatScriptForTextField(List<ScriptItem> script) {
    return script.map((item) {
      String prefix = item.isUser ? 'Me' : 'Them';
      switch (item.type) {
        case MessageType.photo:
          return "$prefix: [Photo]";
        case MessageType.map:
          return "$prefix: [Map]";
        case MessageType.audio:
          return "$prefix: [Audio]";
        case MessageType.text:
          return "$prefix: ${item.text}";
      }
    }).join('\n');
  }

  List<ScriptItem> _parseScriptText(String text) {
    final List<ScriptItem> parsed = [];
    final lines = text.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      bool isUser = true;
      String lineContent = "";
      
      if (line.toLowerCase().startsWith('me:')) {
        isUser = true;
        lineContent = line.substring(3).trim();
      } else if (line.toLowerCase().startsWith('them:')) {
        isUser = false;
        lineContent = line.substring(5).trim();
      } else {
        isUser = true;
        lineContent = line;
      }
      
      if (lineContent.isEmpty) continue;
      
      MessageType type = MessageType.text;
      String msgText = lineContent;
      
      if (lineContent == '[Photo]') {
        type = MessageType.photo;
        msgText = "";
      } else if (lineContent == '[Map]') {
        type = MessageType.map;
        msgText = "";
      } else if (lineContent == '[Audio]') {
        type = MessageType.audio;
        msgText = "";
      }
      
      parsed.add(ScriptItem(text: msgText, isUser: isUser, type: type));
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
      platformStyle: _selectedPlatform,
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

  Widget _buildFrostedContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // Frosted glass look
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
          primary: Colors.tealAccent,
          secondary: Colors.teal,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black, // Premium pure black
        appBar: AppBar(
          title: const Text(
            "MESSAGES CONFIGURATION",
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
                // Segmented Scene Selector
                Center(
                  child: SegmentedButton<SceneType>(
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: const <ButtonSegment<SceneType>>[
                      ButtonSegment<SceneType>(
                        value: SceneType.text,
                        label: Text('Text Chat', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.chat, size: 16),
                      ),
                      ButtonSegment<SceneType>(
                        value: SceneType.audioCall,
                        label: Text('Audio', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.phone, size: 16),
                      ),
                      ButtonSegment<SceneType>(
                        value: SceneType.videoCall,
                        label: Text('FaceTime', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.videocam, size: 16),
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

                // Frosted Card 1: Avatar & Identity
                const Text("CONTACT IDENTITY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white10,
                              backgroundImage: _avatarPath != null && File(_avatarPath!).existsSync()
                                  ? FileImage(File(_avatarPath!))
                                  : null,
                              child: _avatarPath == null || !File(_avatarPath!).existsSync()
                                  ? const Icon(Icons.person, size: 40, color: Colors.white54)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.tealAccent,
                                child: const Icon(Icons.edit, size: 11, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: const InputDecoration(
                            labelText: "Contact Name",
                            labelStyle: TextStyle(color: Colors.white38),
                            border: UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter a contact name";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // DYNAMIC CONTROLS
                if (_activeScene == SceneType.text) ...[
                  // Frosted Card 2: Platform Engine styling (Sprint 5)
                  const Text("PLATFORM STYLE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _buildFrostedContainer(
                    child: Center(
                      child: SegmentedButton<PlatformStyle>(
                        segments: const <ButtonSegment<PlatformStyle>>[
                          ButtonSegment<PlatformStyle>(
                            value: PlatformStyle.ios,
                            label: Text('iOS iMessage', style: TextStyle(fontSize: 11)),
                            icon: Icon(Icons.apple, size: 14),
                          ),
                          ButtonSegment<PlatformStyle>(
                            value: PlatformStyle.android,
                            label: Text('Android SMS', style: TextStyle(fontSize: 11)),
                            icon: Icon(Icons.android, size: 14),
                          ),
                          ButtonSegment<PlatformStyle>(
                            value: PlatformStyle.generic,
                            label: Text('Generic', style: TextStyle(fontSize: 11)),
                            icon: Icon(Icons.devices, size: 14),
                          ),
                        ],
                        selected: <PlatformStyle>{_selectedPlatform},
                        onSelectionChanged: (Set<PlatformStyle> val) {
                          setState(() {
                            _selectedPlatform = val.first;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Frosted Card 3: Screenplay Script Box
                  const Text("CONVERSATION SCRIPT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _buildFrostedContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _scriptController,
                          maxLines: 8,
                          style: const TextStyle(fontFamily: 'Courier', fontSize: 13, color: Colors.tealAccent),
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            hintText: "Me: How is the shoot going?\nThem: [Photo]\nMe: [Map]\nThem: [Audio]\nMe: Finished!",
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (_activeScene == SceneType.text && (value == null || value.trim().isEmpty)) {
                              return "Please write a screenplay script";
                            }
                            return null;
                          },
                        ),
                        const Divider(color: Colors.white10),
                        const Text(
                          "Tags: [Photo] for Images, [Map] for Map Box, [Audio] for Audio waveform.",
                          style: TextStyle(fontSize: 10, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Frosted Card 4: Settings Toggles
                  const Text("SIMULATOR TIMINGS & LOOK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _buildFrostedContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Opponent Typing Delay", style: TextStyle(fontSize: 14)),
                            Text("$_typingDelay sec", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                          ],
                        ),
                        Slider(
                          value: _typingDelay.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          activeColor: Colors.tealAccent,
                          inactiveColor: Colors.white12,
                          onChanged: (val) {
                            setState(() {
                              _typingDelay = val.toInt();
                            });
                          },
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("SMS Green bubbles (iOS)", style: TextStyle(fontSize: 14)),
                          value: _useGreenBubbles,
                          onChanged: (val) {
                            setState(() {
                              _useGreenBubbles = val;
                            });
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Dark Theme mode", style: TextStyle(fontSize: 14)),
                          value: _useDarkMode,
                          onChanged: (val) {
                            setState(() {
                              _useDarkMode = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ] else if (_activeScene == SceneType.audioCall) ...[
                  // Audio Call Options
                  const Text("AUDIO CALL SETUP", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _buildFrostedContainer(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Incoming Audio Call", style: TextStyle(fontSize: 14)),
                      subtitle: const Text("Slide to answer; disable for dial Outgoing", style: TextStyle(fontSize: 10, color: Colors.white38)),
                      value: _isIncomingCall,
                      onChanged: (val) {
                        setState(() {
                          _isIncomingCall = val;
                        });
                      },
                    ),
                  ),
                ] else if (_activeScene == SceneType.videoCall) ...[
                  // Video Call Options
                  const Text("FACETIME INCOMING STREAM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _buildFrostedContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select a video file to stream as the incoming caller's video background feed.",
                          style: TextStyle(fontSize: 11, color: Colors.white38),
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
                                style: const TextStyle(fontSize: 12, color: Colors.white38),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
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
