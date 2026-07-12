import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_portal_screen.dart';
import 'services/console_network_service.dart';
import 'screens/green_screen_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/call_setup_screen.dart';
import 'screens/video_setup_screen.dart';
import 'screens/playback_setup_screen.dart';
import 'screens/notification_setup_screen.dart';
import 'screens/home_setup_screen.dart';
import 'screens/social_setup_screen.dart';

// Global Console Navigator to handle remote navigation cues from anywhere
class GlobalConsoleNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static StreamSubscription? _subscription;

  static void init() {
    _subscription?.cancel();
    _subscription = ConsoleServer.instance.commandStream.listen((cmd) {
      if (cmd['action'] == 'navigate') {
        final route = cmd['data']?['route'] as String?;
        if (route != null) {
          _navigate(route);
        }
      }
    });
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static void _navigate(String route) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Pop back to root home portal
    navigatorKey.currentState?.popUntil((route) => route.isFirst);

    Widget target;
    switch (route) {
      case 'home':
        // popUntil isFirst leaves us on HomePortalScreen
        return;
      case 'green_screen':
        target = const GreenScreenScreen();
        break;
      case 'messages':
        target = const SetupScreen();
        break;
      case 'call':
        target = const CallSetupScreen();
        break;
      case 'video_call':
        target = const VideoSetupScreen();
        break;
      case 'playback':
        target = const PlaybackSetupScreen();
        break;
      case 'notifications':
        target = const NotificationSetupScreen();
        break;
      case 'home_screen':
        target = const HomeSetupScreen();
        break;
      case 'social_web':
        target = const SocialSetupScreen();
        break;
      default:
        return;
    }

    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => target),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for screen props
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Start global console command navigator
  GlobalConsoleNavigator.init();

  runApp(const SetScreenApp());
}

class SetScreenApp extends StatelessWidget {
  const SetScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SetScreen Pro',
      navigatorKey: GlobalConsoleNavigator.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark, // Default to dark mode for prop screens
      home: const HomePortalScreen(),
    );
  }
}
