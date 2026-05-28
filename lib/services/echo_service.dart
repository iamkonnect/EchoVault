import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

class EchoService extends StateNotifier<List<EchoRealm>> {
  EchoService() : super([]);

  // Stub for AI-generated personalized echo realms based on listening history/mood
  Future<void> generateEchoRealms(
      String userId, List<String> recentTracks, String mood) async {
    // Simulate AI processing
    await Future.delayed(const Duration(milliseconds: 800));

    final realms = <EchoRealm>[];
    final moods = [
      'Summer Drive',
      'Rainy Night',
      'Festival Hype',
      'Cozy Fire',
      'City Lights'
    ];
    final colors = [0xFF8B5CF6, 0xFF06B6D4, 0xFF10B981, 0xFFF59E0B, 0xFFEF4444];

    for (int i = 0; i < 5; i++) {
      realms.add(EchoRealm(
        id: 'echo_$i',
        title: '${moods[Random().nextInt(moods.length)]} Echo',
        description:
            'Personalized realm from your $mood listens to ${recentTracks.take(3).join(', ')}',
        color: colors[Random().nextInt(colors.length)],
        tracks: recentTracks.sublist(0, min(3, recentTracks.length)),
      ));
    }

    state = realms;
  }
}

class EchoRealm {
  final String id;
  final String title;
  final String description;
  final int color;
  final List<String> tracks;

  EchoRealm({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.tracks,
  });
}

// Provider
final echoServiceProvider =
    StateNotifierProvider<EchoService, List<EchoRealm>>((ref) => EchoService());
