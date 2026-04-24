import 'api_client.dart';
import 'cache_service.dart';
import 'compatibility_service.dart';

class EchoVaultApiService {
  final ApiClient apiClient;
  final CacheService cacheService;
  late final CompatibilityService _compatService;

  EchoVaultApiService({required this.apiClient, required this.cacheService}) {
    _compatService = CompatibilityService(
      apiClient: apiClient,
      cacheService: cacheService,
    );
  }

  Future<List<Map<String, dynamic>>> getFeaturedEchos() async {
    try {
      final response = await apiClient.get('/api/tracks/featured');
      final data = List<Map<String, dynamic>>.from(response['data']);
      
      // Cache for offline use
      await cacheService.cacheData('featured_echos', {'list': data});
      
      return data;
    } catch (e) {
      final cached = cacheService.getCachedData('featured_echos');
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached['list']);
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTrendingEchos() async {
    try {
      final response = await apiClient.get('/api/tracks/trending');
      return List<Map<String, dynamic>>.from(response['data']);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getLiveStream(String streamId) async {
    try {
      final response = await apiClient.get('/api/live/streams/$streamId');
      return response;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getLiveStreams() async {
    try {
      final response = await apiClient.get('/api/live/streams/active');
      return List<Map<String, dynamic>>.from(response['data']);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async => await apiClient.get('/api/user/profile');

  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    final res = await apiClient.get('/api/tracks/search?q=$query');
    return List<Map<String, dynamic>>.from(res['data'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getTrendingTracks() async {
    final res = await apiClient.get('/api/tracks/trending');
    return List<Map<String, dynamic>>.from(res['data'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getHomeRecommendations() async {
    final res = await apiClient.get('/api/tracks/recommendations');
    return List<Map<String, dynamic>>.from(res['data'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getTracksByGenre(String genre) async {
    final res = await apiClient.get('/api/tracks/genre/$genre');
    return List<Map<String, dynamic>>.from(res['data'] ?? []);
  }

  Future<Map<String, dynamic>> getTrack(String id) async => await apiClient.get('/api/tracks/$id');

  Future<List<Map<String, dynamic>>> getLikedTracks() async {
    final res = await apiClient.get('/api/user/liked-tracks');
    return List<Map<String, dynamic>>.from(res['data'] ?? []);
  }

  Future<Map<String, dynamic>> getAlbum(String id) async => await apiClient.get('/api/albums/$id');

  Future<List<Map<String, dynamic>>> getAlbumTracks(String id) async {
    final res = await apiClient.get('/api/albums/$id/tracks');
    return List<Map<String, dynamic>>.from(res['data'] ?? []);
  }

  Future<Map<String, dynamic>> getArtist(String id) async => await apiClient.get('/api/artists/$id');

  Future<List<Map<String, dynamic>>> getArtistTracks(String id) async {
    final res = await apiClient.get('/api/artists/$id/tracks');
    return List<Map<String, dynamic>>.from(res['data'] ?? []);
  }

  Future<Map<String, dynamic>> getUserPlaylist(String id) async => await apiClient.get('/api/playlists/$id');

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final res = await apiClient.get('/api/chat/conversations');
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    } catch (e) {
      return [];
    }
  }
}
