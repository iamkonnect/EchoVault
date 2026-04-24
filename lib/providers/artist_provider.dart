import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart'; // Import from app_providers where artistServiceProvider is defined

// Note: artistServiceProvider is defined in app_providers.dart
// Import it from there instead of duplicating

final artistInsightsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(artistServiceProvider);
  final result = await service.getArtistInsights();
  if (result['success']) {
    return result['data'];
  } else {
    throw Exception(result['error']);
  }
});

final artistMusicProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(artistServiceProvider);
  final result = await service.getArtistMusic();
  if (result['success']) {
    return result['data'];
  } else {
    throw Exception(result['error']);
  }
});
