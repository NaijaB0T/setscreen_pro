import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/project_config.dart';

class AudioCallScreen extends StatefulWidget {
  final ProjectConfig config;

  const AudioCallScreen({
    super.key,
    required this.config,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  bool _isAnswered = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  String _callStatus = "";
  Timer? _timer;
  int _secondsElapsed = 0;
  
  // Slide to answer animation tracking
  double _slidePosition = 0.0;
  final double _slideMax = 200.0;

  @override
  void initState() {
    super.initState();
    if (widget.config.isIncomingCall) {
      _callStatus = "incoming call";
    } else {
      _callStatus = "Calling...";
      // Outgoing call: auto-connect after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isAnswered = true;
            _callStatus = "00:00";
          });
          _startTimer();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  void _answerCall() {
    setState(() {
      _isAnswered = true;
      _callStatus = "00:00";
    });
    _startTimer();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E), // Standard iOS calling dark background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            
            // Contact Name
            Text(
              widget.config.contactName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Calling Status or Timer
            Text(
              _callStatus,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            
            const Spacer(),
            
            // Center Profile Avatar (displays during audio call)
            Center(
              child: CircleAvatar(
                radius: 65,
                backgroundColor: Colors.grey[600],
                backgroundImage: widget.config.avatarPath != null && widget.config.avatarPath!.isNotEmpty
                    ? FileImage(File(widget.config.avatarPath!))
                    : null,
                child: widget.config.avatarPath == null || widget.config.avatarPath!.isEmpty
                    ? Text(
                        _getInitials(widget.config.contactName),
                        style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w300),
                      )
                    : null,
              ),
            ),
            
            const Spacer(),

            // Conditional Layout: Incoming Call UI vs Active Call UI
            if (widget.config.isIncomingCall && !_isAnswered) ...[
              // Slide to Answer Layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                child: Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Slide tracks / guide text
                      Center(
                        child: Text(
                          "slide to answer",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      // Slide Handle
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
                              _answerCall();
                            } else {
                              setState(() {
                                _slidePosition = 0.0;
                              });
                            }
                          },
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFF34C759), // iOS Green Answer Color
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
              // Decline and Message shortcuts
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 40, right: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFFFF3B30), // Decline Red
                            child: Icon(Icons.call_end, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Decline", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _answerCall,
                          child: const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFF34C759), // Accept Green
                            child: Icon(Icons.phone, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Accept", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Active Calling Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grid of 6 circular buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildUtilityButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: _isMuted ? "mute" : "mute",
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
              
              // End Call button
              GestureDetector(
                onTap: () {
                  _timer?.cancel();
                  Navigator.of(context).pop();
                },
                child: const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFFF3B30), // Decline Red
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
    );
  }
}
