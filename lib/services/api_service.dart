import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'dart:async';

class EchoVaultApiService {
  final Dio _dio;
  final String baseUrl;

  EchoVaultApiService({
    required Dio dio,
    this.baseUrl = 'http://localhost:5000',
  }) : _dio = dio;

  // Search tracks from external API or internal DB
  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/tracks/search',
        queryParameters: {'q': query},
      );

      final data = response.data;
      final items = data['items'] ?? data['tracks'] ?? [];
      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      developer.log('Search failed: $e', name: 'ApiService');
      return [];
    }
  }

  // Get home recommendations
  Future<List<Map<String, dynamic>>> getHomeRecommendations() async {
    try {
      final response = await _dio.get('$baseUrl/api/tracks/recommendations');
      return List<Map<String, dynamic>>.from(response.data['recommended'] ?? response.data ?? []);
    } catch (e) {
      developer.log('Home recommendations fetch failed: $e', name: 'ApiService');
      return [];
    }
  }

  // Get track details by ID
  Future<Map<String, dynamic>> getTrack(String id,
      {String quality = 'HI_RES_LOSSLESS'}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/tracks/$id',
        queryParameters: {'quality': quality},
      );
      return response.data;
    } catch (e) {
      developer.log('Track fetch failed: $e', name: 'ApiService');
      return {};
    }
  }

  // Get stream URL for a track
  Future<String> getStreamUrl(String id,
      {String quality = 'HI_RES_LOSSLESS'}) async {
    try {
      final trackData = await getTrack(id, quality: quality);
      return trackData['streamUrl'] ?? trackData['url'] ?? '';
    } catch (e) {
      developer.log('Stream URL fetch failed: $e', name: 'ApiService');
      return '';
    }
  }

  // Get album by ID
  Future<Map<String, dynamic>> getAlbum(String id) async {
    try {
      final response = await _dio.get('$baseUrl/api/albums/$id');
      return response.data;
    } catch (e) {
      developer.log('Album fetch failed: $e', name: 'ApiService');
      return {};
    }
  }

  // Get artist by ID
  Future<Map<String, dynamic>> getArtist(String id) async {
    try {
      final response = await _dio.get('$baseUrl/api/artists/$id');
      return response.data;
    } catch (e) {
      developer.log('Artist fetch failed: $e', name: 'ApiService');
      return {};
    }
  }

  // Get tracks by genre
  Future<List<Map<String, dynamic>>> getTracksByGenre(String genre) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/tracks/genre/$genre',
      );
      final items = response.data['items'] ?? response.data['tracks'] ?? [];
      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      developer.log('Genre fetch failed: $e', name: 'ApiService');
      return [];
    }
  }

  // Get trending tracks
  Future<List<Map<String, dynamic>>> getTrendingTracks() async {
    try {
      final response = await _dio.get('$baseUrl/api/tracks/trending');
      return List<Map<String, dynamic>>.from(response.data['tracks'] ?? response.data ?? []);
    } catch (e) {
      developer.log('Trending tracks fetch failed: $e', name: 'ApiService');
      return [];
    }
  }

  // Get user playlist
  Future<List<Map<String, dynamic>>> getUserPlaylist(String playlistId) async {
    try {
      final response = await _dio.get('$baseUrl/api/playlists/$playlistId');
      return List<Map<String, dynamic>>.from(response.data['tracks'] ?? response.data['items'] ?? []);
    } catch (e) {
      developer.log('Playlist fetch failed: $e', name: 'ApiService');
      return [];
    }
  }
}
