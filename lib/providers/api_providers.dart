import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/api_service_v2.dart';
// cache_provider.dart no longer needed - provider defined in app_providers.dart
import 'cache_provider.dart';

final apiClientProvider = Provider((ref) => ApiClient());

// This provider should be initialized in your main.dart
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