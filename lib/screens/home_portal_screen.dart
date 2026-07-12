import 'dart:ui';
import 'package:flutter/material.dart';
import 'setup_screen.dart';
import 'green_screen_screen.dart';
import 'call_setup_screen.dart';

class HomePortalScreen extends StatelessWidget {
  const HomePortalScreen({super.key});

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: AlertDialog(
          backgroundColor: Colors.grey[900]?.withValues(alpha: 0.7) ?? Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10),
          ),
          title: const Text(
            "Coming Soon", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Coming soon in Step 2", 
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK", style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF1C1C1E), // Dark iOS card style
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Colored left-side border
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: accentColor, width: 5),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: accentColor.withValues(alpha: 0.15),
            child: Icon(icon, color: accentColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.white30,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Premium Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "SetScreen Pro",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "The professional prop device simulator for film and television.",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey[900]),
                  ],
                ),
              ),
            ),
            
            // Cards List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPortalCard(
                    context: context,
                    title: "Green Screen",
                    subtitle: "Chroma screen with tracking marks",
                    icon: Icons.aspect_ratio,
                    accentColor: const Color(0xFF34C759), // Green
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const GreenScreenScreen()),
                      );
                    },
                  ),
                  _buildPortalCard(
                    context: context,
                    title: "Prop Messages",
                    subtitle: "Mock messaging conversations for camera",
                    icon: Icons.chat,
                    accentColor: const Color(0xFF30B0C7), // Teal
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SetupScreen()),
                      );
                    },
                  ),
                  _buildPortalCard(
                    context: context,
                    title: "Prop Call",
                    subtitle: "Incoming-call screen for film and theater",
                    icon: Icons.phone,
                    accentColor: const Color(0xFF007AFF), // Blue
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const CallSetupScreen()),
                      );
                    },
                  ),
                  _buildPortalCard(
                    context: context,
                    title: "Prop Video Call",
                    subtitle: "Pre-recorded video call with live camera",
                    icon: Icons.videocam,
                    accentColor: const Color(0xFF5856D6), // Indigo
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildPortalCard(
                    context: context,
                    title: "Prop Screen Playback",
                    subtitle: "Lockable playback screen",
                    icon: Icons.play_circle_fill,
                    accentColor: const Color(0xFFFF9500), // Orange
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildPortalCard(
                    context: context,
                    title: "Prop Notifications",
                    subtitle: "Custom notification overlays",
                    icon: Icons.notifications,
                    accentColor: const Color(0xFFAF52DE), // Purple
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildPortalCard(
                    context: context,
                    title: "Prop Home Screen",
                    subtitle: "Home screen layout designer",
                    icon: Icons.home,
                    accentColor: const Color(0xFFFF2D55), // Magenta
                    onTap: () => _showComingSoon(context),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
