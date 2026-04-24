import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/artist_dashboard_screen.dart';
import 'inbox_screen.dart';
import 'subscription_screen.dart';
import 'screens/player_screen.dart';
import 'screens/live_broadcast_screen.dart';

import 'l10n/app_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    await _initializeServices();

    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    debugPrint('Fatal error during startup: $e');
    // Note: If initialization fails, the app may crash later or show a blank screen.
  }
}

/// Centralized service initialization.
Future<void> _initializeServices() async {
  // Initialize Audio Service (Required for background playback)
  // Ensure AndroidManifest.xml uses com.ryanheise.audioservice.AudioServiceActivity
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.echovault.audio',
    androidNotificationChannelName: 'EchoVault Playback',
    androidNotificationOngoing: true,
  );

  // Initialize Hive
  await Hive.initFlutter();
  
  // Pre-open essential Hive boxes to prevent "Box not found" errors during build
  await Hive.openBox('settings');
  // await Hive.openBox('user_vault'); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EchoVault',
      theme: ThemeData.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/artist-dashboard': (context) => const ArtistDashboardScreen(),
        '/live-broadcast': (context) => LiveBroadcastScreen(streamData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
        '/inbox': (context) => const InboxScreen(),
        '/subscriptions': (context) => const SubscriptionScreen(),
        '/player': (context) => const PlayerScreen(),
      },

    );
  }
}
