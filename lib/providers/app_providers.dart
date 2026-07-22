import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/auth_service_v2.dart';
import '../services/api_service_v2.dart';
import '../services/artist_service_v2.dart';
import '../services/realtime_service.dart';
import '../services/token_refresh_service.dart';
import '../services/cache_service.dart';
import 'auth_provider.dart';

// ============ API CLIENT PROVIDERS ============

/// Global API client instance with dynamic configuration
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: ApiConfig.baseUrl,
  );
});

/// Global Dio instance for advanced use cases
final dioProvider = Provider<Dio>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getDio();
});

// ============ TOKEN MANAGEMENT PROVIDERS ============

/// Token refresh service
final tokenRefreshServiceProvider = Provider<TokenRefreshService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TokenRefreshService(apiClient: apiClient);
});

/// Token expiration monitoring
final tokenExpirationProvider = StreamProvider<bool>((ref) async* {
  final tokenService = ref.watch(tokenRefreshServiceProvider);

  while (true) {
    yield tokenService.isTokenExpiredOrExpiring();
    await Future.delayed(const Duration(seconds: 60)); // Check every minute
  }
});

// ============ CACHE SERVICE PROVIDER ============

/// Cache service for offline functionality
final cacheServiceProvider = FutureProvider<CacheService>((ref) async {
  final cacheService = CacheService();
  await cacheService.initialize();
  return cacheService;
});

// ============ REALTIME SERVICE PROVIDERS ============

/// Real-time WebSocket service with dynamic configuration
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService(baseUrl: ApiConfig.realtimeUrl);
});

/// WebSocket connection state
final wsConnectionProvider = StreamProvider<bool>((ref) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  return realtimeService.connectionState;
});

/// Gift events stream
final giftsStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  return realtimeService.gifts;
});

/// Chat messages stream
final messagesStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  return realtimeService.messages;
});

/// Notifications stream
final notificationsStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  return realtimeService.notifications;
});

// ============ SERVICE PROVIDERS ============

/// Authentication service
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(dio: apiClient.getDio());
});

/// General API service for tracks, albums, artists, playlists
final apiServiceProvider = Provider<EchoVaultApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cacheServiceAsync = ref.watch(cacheServiceProvider);
  final cacheService = cacheServiceAsync.value;
  return EchoVaultApiService(apiClient: apiClient, cacheService: cacheService!);
});

/// Artist-specific API service
final artistServiceProvider = Provider<ArtistServiceV2>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cacheServiceAsync = ref.watch(cacheServiceProvider);
  final cacheService = cacheServiceAsync.value;
  return ArtistServiceV2(apiClient: apiClient, cacheService: cacheService!);
});

// ============ AUTHENTICATION STATE PROVIDERS ============

/// Current authentication token
final authTokenProvider = StateProvider<String?>((ref) {
  return null;
});

/// Authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

// ============ USER DATA PROVIDERS ============

/// Current user profile data
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getUserProfile();
});

/// Cached user profile (from offline storage)
final cachedUserProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final cacheService = await ref.watch(cacheServiceProvider.future);
  return cacheService.getUserProfile();
});

// ============ TRACK PROVIDERS ============

/// Search tracks
final searchTracksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, query) async {
  final apiService = ref.watch(apiServiceProvider);
  final cacheService = await ref.watch(cacheServiceProvider.future);

  // Check cache first
  final cached = cacheService.getCachedData('search_$query');
  if (cached != null && cached['tracks'] != null) {
    return List<Map<String, dynamic>>.from(cached['tracks']);
  }

  // Fetch from API
  final tracks = await apiService.searchTracks(query);

  // Cache result
  await cacheService.cacheData('search_$query', {'tracks': tracks});

  return tracks;
});

/// Get trending tracks
final trendingTracksProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final cacheService = await ref.watch(cacheServiceProvider.future);

  // Check cache first
  final cached = cacheService.getCachedData('trending_tracks');
  if (cached != null && cached['tracks'] != null) {
    return List<Map<String, dynamic>>.from(cached['tracks']);
  }

  // Fetch from API
  final tracks = await apiService.getTrendingTracks();

  // Cache result
  await cacheService.cacheData('trending_tracks', {'tracks': tracks});

  return tracks;
});

/// Get home recommendations
final homeRecommendationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final cacheService = await ref.watch(cacheServiceProvider.future);

  // Check cache first
  final cached = cacheService.getCachedData('home_recommendations');
  if (cached != null && cached['recommendations'] != null) {
    return List<Map<String, dynamic>>.from(cached['recommendations']);
  }

  // Fetch from API
  final recommendations = await apiService.getHomeRecommendations();

  // Cache result
  await cacheService
      .cacheData('home_recommendations', {'recommendations': recommendations});

  return recommendations;
});

/// Get tracks by genre
final tracksByGenreProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, genre) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getTracksByGenre(genre);
});

/// Get single track details
final trackDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, trackId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getTrack(trackId);
});

/// Get user's liked tracks
final likedTracksProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final cacheService = await ref.watch(cacheServiceProvider.future);

  try {
    // Try to fetch from API
    final tracks = await apiService.getLikedTracks();

    // Cache result
    await cacheService.cachePlaylists(tracks);

    return tracks;
  } catch (e) {
    // Fallback to cached data
    final cached = cacheService.getLikedTracks();
    if (cached.isNotEmpty) {
      return cached;
    }
    rethrow;
  }
});

// ============ ALBUM PROVIDERS ============

/// Get album details
final albumDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, albumId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getAlbum(albumId);
});

/// Get tracks in album
final albumTracksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, albumId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getAlbumTracks(albumId);
});

// ============ ARTIST PROVIDERS ============

/// Get artist details
final artistDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, artistId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getArtist(artistId);
});

/// Get tracks by artist
final artistTracksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, artistId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getArtistTracks(artistId);
});

// ============ ARTIST DASHBOARD PROVIDERS ============

/// Get artist dashboard data
final artistDashboardProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final artistService = ref.watch(artistServiceProvider);
  return await artistService.getDashboardData();
});

/// Get artist's music uploads
final artistMusicProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final artistService = ref.watch(artistServiceProvider);
  return await artistService.getArtistMusic();
});

/// Get artist insights
final artistInsightsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final artistService = ref.watch(artistServiceProvider);
  return await artistService.getArtistInsights();
});

/// Get shorts insights
final shortsInsightsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final artistService = ref.watch(artistServiceProvider);
  return await artistService.getShortsInsights();
});

/// Get revenue data (important for gift-based income)
final revenueProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final artistService = ref.watch(artistServiceProvider);
  return await artistService.getRevenueData();
});

/// Get payout history
final payoutHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final artistService = ref.watch(artistServiceProvider);
  return await artistService.getPayoutHistory();
});

// ============ PLAYLIST PROVIDERS ============

/// Get playlist tracks
final playlistProvider = FutureProvider.family<Map<String, dynamic>, String>(
    (ref, playlistId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getUserPlaylist(playlistId);
});

// ============ GIFT & MONETIZATION PROVIDERS ============

/// Get available gifts for UI display
final availableGiftsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final realtimeService = ref.watch(realtimeServiceProvider);

  try {
    return await realtimeService.getAvailableGifts();
  } catch (e) {
    // Return default gifts if fetch fails
    return [
      {'id': 'rose', 'name': 'Rose', 'amount': 5, 'icon': '🌹'},
      {'id': 'heart', 'name': 'Heart', 'amount': 10, 'icon': '❤️'},
      {'id': 'diamond', 'name': 'Diamond', 'amount': 50, 'icon': '💎'},
      {'id': 'crown', 'name': 'Crown', 'amount': 100, 'icon': '👑'},
    ];
  }
});
