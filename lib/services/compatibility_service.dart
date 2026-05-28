import 'api_client.dart';
import 'cache_service.dart';
import 'dart:developer' as developer;

/// Compatibility service for handling missing backend endpoints
/// Provides graceful fallbacks and stubs for endpoints that don't exist yet
class CompatibilityService {
  final ApiClient apiClient;
  final CacheService cacheService;

  CompatibilityService({required this.apiClient, required this.cacheService});

  // ============ SEARCH (Currently missing in backend) ============

  /// Search tracks - stub until backend implements
  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/tracks/search?q=$query',
      );

      final data = response['data'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      developer.log('Search failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      
      // Return cached results if available
      final cached = cacheService.getCachedData('search_$query');
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached['results'] ?? []);
      }
      
      // Return empty list as graceful fallback
      return [];
    }
  }

  // ============ ALBUMS (Currently missing in backend) ============

  /// Get album - stub until backend implements
  Future<Map<String, dynamic>> getAlbum(String id) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/albums/$id',
      );
      return response;
    } catch (e) {
      developer.log('Album fetch failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      
      // Return cached if available
      final cached = cacheService.getCachedData('album_$id');
      if (cached != null) return cached;
      
      // Return empty as graceful fallback
      return {'success': false, 'data': null};
    }
  }

  /// Get album tracks - stub until backend implements
  Future<List<Map<String, dynamic>>> getAlbumTracks(String id) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/albums/$id/tracks',
      );

      final data = response['data'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      developer.log(
          'Album tracks fetch failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      return [];
    }
  }

  // ============ ARTISTS (Browse - different from dashboard) ============

  /// Get artist profile - stub until backend implements
  Future<Map<String, dynamic>> getArtist(String id) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/artists/$id',
      );
      return response;
    } catch (e) {
      developer.log(
          'Artist profile fetch failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      
      final cached = cacheService.getCachedData('artist_$id');
      if (cached != null) return cached;
      
      return {'success': false, 'data': null};
    }
  }

  /// Get artist tracks - stub until backend implements
  Future<List<Map<String, dynamic>>> getArtistTracks(String id) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/artists/$id/tracks',
      );

      final data = response['data'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      developer.log(
          'Artist tracks fetch failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      return [];
    }
  }

  // ============ PLAYLISTS (Currently missing in backend) ============

  /// Get playlist - stub until backend implements
  Future<Map<String, dynamic>> getPlaylist(String id) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/playlists/$id',
      );
      return response;
    } catch (e) {
      developer.log(
          'Playlist fetch failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      
      final cached = cacheService.getCachedData('playlist_$id');
      if (cached != null) return cached;
      
      return {'success': false, 'data': null};
    }
  }

  // ============ USER PROFILE (Currently missing in backend) ============

  /// Get user profile - stub until backend implements
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/user/profile',
      );
      return response;
    } catch (e) {
      developer.log(
          'User profile fetch failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      return {'success': false, 'data': null};
    }
  }

  // ============ LIKED TRACKS (Currently missing in backend) ============

  /// Get liked tracks - stub until backend implements
  Future<List<Map<String, dynamic>>> getLikedTracks() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/user/liked-tracks',
      );

      final data = response['data'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      developer.log(
          'Liked tracks fetch failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      
      // Return cached liked tracks
      final cached = cacheService.getCachedData('liked_tracks');
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached['tracks'] ?? []);
      }
      
      return [];
    }
  }

  // ============ GENRE FILTERING (Currently missing in backend) ============

  /// Get tracks by genre - stub until backend implements
  Future<List<Map<String, dynamic>>> getTracksByGenre(String genre) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/tracks/genre/$genre',
      );

      final data = response['data'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      developer.log(
          'Genre tracks fetch failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      return [];
    }
  }

  // ============ CHAT (Currently missing in backend) ============

  /// Get conversations - stub until backend implements
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/messages/conversations',
      );

      final data = response['data'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      developer.log(
          'Conversations fetch failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      return [];
    }
  }

  // ============ MUSIC STATS (Currently missing in backend) ============

  /// Get music stats - stub until backend implements
  Future<Map<String, dynamic>> getMusicStats(String musicId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/artist/music/$musicId/stats',
      );
      return response;
    } catch (e) {
      developer.log(
          'Music stats fetch failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      return {'success': false, 'data': null};
    }
  }

  // ============ MUSIC EDIT/DELETE (Currently missing in backend) ============

  /// Edit music metadata - stub until backend implements
  Future<bool> editMusic({
    required String musicId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await apiClient.put<Map<String, dynamic>>(
        '/api/artist/music/$musicId',
        body: data,
      );
      return true;
    } catch (e) {
      developer.log(
          'Edit music failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      return false;
    }
  }

  /// Delete music - stub until backend implements
  Future<bool> deleteMusic(String musicId) async {
    try {
      await apiClient.delete(
        '/api/artist/music/$musicId',
      );
      return true;
    } catch (e) {
      developer.log(
          'Delete music failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      return false;
    }
  }

  // ============ LIVE STREAM MANAGEMENT (Currently missing in backend) ============

  /// Start live stream - stub until backend implements
  Future<Map<String, dynamic>> startLiveStream({
    required String title,
    String thumbnail = '',
  }) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/api/artist/start-stream',
        body: {
          'title': title,
          if (thumbnail.isNotEmpty) 'thumbnail': thumbnail,
        },
      );
      return response;
    } catch (e) {
      developer.log(
          'Start stream failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Stop live stream - stub until backend implements
  Future<Map<String, dynamic>> stopLiveStream(String streamId) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/api/artist/stop-stream',
        body: {'streamId': streamId},
      );
      return response;
    } catch (e) {
      developer.log(
          'Stop stream failed (expected - not yet implemented): $e',
          name: 'CompatibilityService');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ HELPER: Check endpoint availability ============

  /// Check if an endpoint is available (for UI hints)
  Future<bool> isEndpointAvailable(String endpoint) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(endpoint);
      return response['success'] != false;
    } catch (e) {
      return false;
    }
  }
}
