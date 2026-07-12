import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/project_config.dart';
import '../models/call_config.dart';
import '../services/console_network_service.dart';

class AudioCallScreen extends StatefulWidget {
  final ProjectConfig? config;       // For backward compatibility
  final CallConfig? callConfig;      // New Call Config

  const AudioCallScreen({
    super.key,
    this.config,
    this.callConfig,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  // Audio Player instances
  late AudioPlayer _audioPlayer;
  
  // Calling State
  bool _isAnswered = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  String _callStatus = "";
  Timer? _timer;
  int _secondsElapsed = 0;

  // Slide position tracking
  double _slidePosition = 0.0;
  final double _slideMax = 200.0;

  // Helper getters to consolidate configs
  String get firstName => widget.callConfig?.firstName ?? widget.config?.contactName.split(' ').first ?? 'Michael';
  String get lastName => widget.callConfig?.lastName ?? (widget.config != null ? widget.config!.contactName.substring(widget.config!.contactName.indexOf(' ') + 1) : 'Naizu');
  String get fullName => widget.callConfig?.fullName ?? widget.config?.contactName ?? 'Michael Naizu';
  String? get avatarPath => widget.callConfig?.avatarPath ?? widget.config?.avatarPath;
  String? get posterPath => widget.callConfig?.posterPath;
  bool get isIncoming => widget.callConfig?.isIncoming ?? widget.config?.isIncomingCall ?? true;
  String get layoutVersion => widget.callConfig?.layoutVersion ?? 'ios13';
  String get ringtone => widget.callConfig?.ringtone ?? 'Marimba';
  double get ringtoneVolume => widget.callConfig?.ringtoneVolume ?? 0.8;

  StreamSubscription? _consoleSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    if (ConsoleServer.instance.isRunning) {
      _consoleSubscription = ConsoleServer.instance.commandStream.listen((cmd) {
        if (cmd['action'] == 'force_ring') {
          if (mounted && !_isAnswered) {
            setState(() {
              _callStatus = "incoming call";
            });
            _playRingtone();
          }
        } else if (cmd['action'] == 'disconnect') {
          if (mounted) {
            _endCall();
          }
        }
      });
    }

    if (isIncoming) {
      _callStatus = "incoming call";
      _playRingtone();
    } else {
      _callStatus = "Calling...";
      _playDialTone();
      // Outgoing call: connect automatically after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _connectCall();
        }
      });
    }
  }

  @override
  void dispose() {
    _consoleSubscription?.cancel();
    _timer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playRingtone() async {
    String url = "https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg"; // Fallback
    if (ringtone == 'Classic Bell') {
      url = "https://actions.google.com/sounds/v1/office/phone_ringing.ogg";
    } else if (ringtone == 'Digital Watch') {
      url = "https://actions.google.com/sounds/v1/alarms/beep_short.ogg";
    }
    
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource(url), volume: ringtoneVolume);
    } catch (e) {
      debugPrint("Error playing ringtone: $e");
    }
  }

  Future<void> _playDialTone() async {
    try {
      // Use office phone ringing as dial tone representation
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource("https://actions.google.com/sounds/v1/office/phone_ringing.ogg"), volume: 0.5);
    } catch (e) {
      debugPrint("Error playing dial tone: $e");
    }
  }

  Future<void> _playDisconnectBeep() async {
    try {
      final player = AudioPlayer();
      await player.play(UrlSource("https://actions.google.com/sounds/v1/alarms/beep_short.ogg"), volume: 1.0);
      Future.delayed(const Duration(milliseconds: 600), () {
        player.dispose();
      });
    } catch (e) {
      debugPrint("Error playing disconnect beep: $e");
    }
  }

  void _connectCall() {
    _audioPlayer.stop();
    setState(() {
      _isAnswered = true;
      _callStatus = "00:00";
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
          final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
          final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
          _callStatus = "$minutes:$seconds";
        });
      }
    });
  }

  void _endCall() async {
    _timer?.cancel();
    await _audioPlayer.stop();
    await _playDisconnectBeep();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildUtilityButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 36,
            backgroundColor: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
            child: Icon(
              icon,
              size: 32,
              color: isActive ? Colors.black : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "U";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildCallLayoutContent() {
    final usePoster = (layoutVersion == 'ios17' || layoutVersion == 'ios26') && posterPath != null && posterPath!.isNotEmpty && File(posterPath!).existsSync();

    if (usePoster) {
      // Full screen poster background
      return Positioned.fill(
        child: Image.file(
          File(posterPath!),
          fit: BoxFit.cover,
        ),
      );
    } else if (layoutVersion == 'ios17' || layoutVersion == 'ios26') {
      // Abstract gradient fallback for Poster layouts
      return Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2C1C3E), // Abstract purple iOS style
                Color(0xFF0F0C20),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink(); // Classic iOS13 just uses pure black scaffold bg
  }

  @override
  Widget build(BuildContext context) {
    final isClassic = layoutVersion == 'ios13';
    final hasPoster = (layoutVersion == 'ios17' || layoutVersion == 'ios26');

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: Stack(
        children: [
          // 1. Poster / Gradient Background
          _buildCallLayoutContent(),

          // 2. Translucent overlay if poster is active to keep UI text legible
          if (hasPoster)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),

          // 3. Floating Calling details overlay
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),

                // Name Details (Header)
                if (isClassic) ...[
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _callStatus,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ] else ...[
                  // iOS 17/26 Bold Oversized Top Typography
                  Text(
                    firstName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (lastName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      lastName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    _callStatus.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],

                const Spacer(),

                // Center circular avatar (only for classic mode OR fallback when poster is inactive)
                if (isClassic || (!isIncoming && !_isAnswered))
                  Center(
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey[700],
                      backgroundImage: avatarPath != null && avatarPath!.isNotEmpty && File(avatarPath!).existsSync()
                          ? FileImage(File(avatarPath!))
                          : null,
                      child: avatarPath == null || avatarPath!.isEmpty || !File(avatarPath!).existsSync()
                          ? Text(
                              _getInitials(fullName),
                              style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w300),
                            )
                          : null,
                    ),
                  ),

                const Spacer(),

                // CALL CONTROLS BUTTONS (State Dependent)
                if (isIncoming && !_isAnswered) ...[
                  if (layoutVersion == 'ios26') ...[
                    // Slide to Answer Layout
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                      child: Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Center(
                              child: Text(
                                "slide to answer",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Positioned(
                              left: _slidePosition + 8,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) {
                                  setState(() {
                                    _slidePosition += details.primaryDelta!;
                                    if (_slidePosition < 0) _slidePosition = 0;
                                    if (_slidePosition > _slideMax) _slidePosition = _slideMax;
                                  });
                                },
                                onHorizontalDragEnd: (details) {
                                  if (_slidePosition >= _slideMax - 20) {
                                    _connectCall();
                                  } else {
                                    setState(() {
                                      _slidePosition = 0.0;
                                    });
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundColor: const Color(0xFF34C759),
                                  child: const Icon(
                                    Icons.phone,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // iOS 13 / 17 Accept & Decline buttons
                    Padding(
                      padding: const EdgeInsets.only(bottom: 60, left: 40, right: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _endCall,
                                child: const CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Color(0xFFFF3B30),
                                  child: Icon(Icons.call_end, color: Colors.white, size: 30),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text("Decline", style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _connectCall,
                                child: const CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Color(0xFF34C759),
                                  child: Icon(Icons.phone, color: Colors.white, size: 30),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text("Accept", style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // Connected State: Circular grids of utilities
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildUtilityButton(
                              icon: _isMuted ? Icons.mic_off : Icons.mic,
                              label: "mute",
                              isActive: _isMuted,
                              onTap: () => setState(() => _isMuted = !_isMuted),
                            ),
                            _buildUtilityButton(
                              icon: Icons.grid_on,
                              label: "keypad",
                              isActive: false,
                              onTap: () {},
                            ),
                            _buildUtilityButton(
                              icon: Icons.volume_up,
                              label: "speaker",
                              isActive: _isSpeakerOn,
                              onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildUtilityButton(
                              icon: Icons.add,
                              label: "add call",
                              isActive: false,
                              onTap: () {},
                            ),
                            _buildUtilityButton(
                              icon: Icons.video_call,
                              label: "FaceTime",
                              isActive: false,
                              onTap: () {},
                            ),
                            _buildUtilityButton(
                              icon: Icons.contacts,
                              label: "contacts",
                              isActive: false,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // End Call Red Button
                  GestureDetector(
                    onTap: _endCall,
                    child: const CircleAvatar(
                      radius: 36,
                      backgroundColor: Color(0xFFFF3B30),
                      child: Icon(
                        Icons.call_end,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
