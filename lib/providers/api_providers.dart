import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/api_service_v2.dart';
import 'cache_provider.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final apiServiceProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  final cacheAsync = ref.watch(cacheServiceProvider);
  final cache = cacheAsync.value!;
  return EchoVaultApiService(apiClient: client, cacheService: cache);
});

final featuredEchosProvider = FutureProvider((ref) async {
  return ref.watch(apiServiceProvider).getFeaturedEchos();
});

final trendingEchosProvider = FutureProvider((ref) async {
  return ref.watch(apiServiceProvider).getTrendingEchos();
});

final liveStreamsProvider = FutureProvider((ref) async {
  return ref.watch(apiServiceProvider).getLiveStreams();
});

final allTracksProvider = FutureProvider((ref) async {
  return ref.watch(apiServiceProvider).getAllTracks();
});

final shortsProvider = FutureProvider((ref) async {
  return ref.watch(apiServiceProvider).getShorts();
});
