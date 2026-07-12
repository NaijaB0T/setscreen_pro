import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/call_config.dart';
import 'audio_call_screen.dart';

class CallSetupScreen extends StatefulWidget {
  const CallSetupScreen({super.key});

  @override
  State<CallSetupScreen> createState() => _CallSetupScreenState();
}

class _CallSetupScreenState extends State<CallSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  String? _avatarPath;
  String? _posterPath;
  bool _isIncoming = true;
  String _layoutVersion = 'ios13'; // 'ios13', 'ios17', 'ios26'
  String _ringtone = 'Marimba';
  double _ringtoneVolume = 0.8;

  final List<String> _ringtones = ['Marimba', 'Classic Bell', 'Digital Watch'];

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('saved_call_config');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final config = CallConfig.fromJson(jsonDecode(jsonStr));
        setState(() {
          _firstNameController.text = config.firstName;
          _lastNameController.text = config.lastName;
          _avatarPath = config.avatarPath;
          _posterPath = config.posterPath;
          _isIncoming = config.isIncoming;
          _layoutVersion = config.layoutVersion;
          _ringtone = config.ringtone;
          _ringtoneVolume = config.ringtoneVolume;
        });
      } catch (e) {
        debugPrint("Error loading call config: $e");
        _loadDefaultValues();
      }
    } else {
      _loadDefaultValues();
    }
  }

  void _loadDefaultValues() {
    setState(() {
      _firstNameController.text = "Michael";
      _lastNameController.text = "Naizu";
      _avatarPath = null;
      _posterPath = null;
      _isIncoming = true;
      _layoutVersion = 'ios13';
      _ringtone = 'Marimba';
      _ringtoneVolume = 0.8;
    });
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
      debugPrint("Error picking avatar: $e");
    }
  }

  Future<void> _pickPoster() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _posterPath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking poster: $e");
    }
  }

  Future<void> _startTake() async {
    if (!_formKey.currentState!.validate()) return;

    final config = CallConfig(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      avatarPath: _avatarPath,
      posterPath: _posterPath,
      isIncoming: _isIncoming,
      layoutVersion: _layoutVersion,
      ringtone: _ringtone,
      ringtoneVolume: _ringtoneVolume,
    );

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_call_config', jsonEncode(config.toJson()));

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AudioCallScreen(
            config: null, // For backward compatibility
            callConfig: config,
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
    final showPosterPicker = _layoutVersion == 'ios17' || _layoutVersion == 'ios26';

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blue,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            "PROP CALL CONFIGURATION",
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
                // Layout Version Segmented Button
                const Text("LAYOUT VERSION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Center(
                    child: SegmentedButton<String>(
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'ios13',
                          label: Text('iOS 13 Classic'),
                          icon: Icon(Icons.phone_iphone),
                        ),
                        ButtonSegment<String>(
                          value: 'ios17',
                          label: Text('iOS 17 Poster'),
                          icon: Icon(Icons.portrait),
                        ),
                        ButtonSegment<String>(
                          value: 'ios26',
                          label: Text('iOS 26 Slide'),
                          icon: Icon(Icons.swipe_right),
                        ),
                      ],
                      selected: <String>{_layoutVersion},
                      onSelectionChanged: (Set<String> val) {
                        setState(() {
                          _layoutVersion = val.first;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name Details Card
                const Text("CALLER IDENTITY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "First Name",
                          labelStyle: TextStyle(color: Colors.white38),
                          border: UnderlineInputBorder(),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "First name is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Last Name",
                          labelStyle: TextStyle(color: Colors.white38),
                          border: UnderlineInputBorder(),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Image Assets Picker
                const Text("MEDIA ASSETS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Avatar Picker
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _pickAvatar,
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white10,
                              backgroundImage: _avatarPath != null && File(_avatarPath!).existsSync()
                                  ? FileImage(File(_avatarPath!))
                                  : null,
                              child: _avatarPath == null || !File(_avatarPath!).existsSync()
                                  ? const Icon(Icons.person, size: 40, color: Colors.white38)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text("Small Avatar", style: TextStyle(fontSize: 11, color: Colors.white54)),
                        ],
                      ),

                      if (showPosterPicker) ...[
                        const SizedBox(width: 24),
                        // Poster Picker
                        Column(
                          children: [
                            GestureDetector(
                              onTap: _pickPoster,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                  image: _posterPath != null && File(_posterPath!).existsSync()
                                      ? DecorationImage(
                                          image: FileImage(File(_posterPath!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _posterPath == null || !File(_posterPath!).existsSync()
                                    ? const Icon(Icons.portrait, size: 36, color: Colors.white38)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text("Full Poster", style: TextStyle(fontSize: 11, color: Colors.white54)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Direction & Ringtones
                const Text("RINGTONE & SETTINGS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildFrostedContainer(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Incoming Call", style: TextStyle(fontSize: 14)),
                        subtitle: const Text("True: rings/slides; False: Outgoing Calling dial", style: TextStyle(fontSize: 10, color: Colors.white38)),
                        value: _isIncoming,
                        onChanged: (val) {
                          setState(() {
                            _isIncoming = val;
                          });
                        },
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      DropdownButtonFormField<String>(
                        initialValue: _ringtone,
                        decoration: const InputDecoration(
                          labelText: "Select Ringtone",
                          labelStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                        items: _ringtones.map((String rt) {
                          return DropdownMenuItem<String>(
                            value: rt,
                            child: Text(rt),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _ringtone = val;
                            });
                          }
                        },
                      ),
                    ],
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
                      backgroundColor: Colors.blueAccent,
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
