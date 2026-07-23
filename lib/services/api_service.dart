import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../config/api_config.dart';

class EchoVaultApiService {
  final Dio _dio;
  final String baseUrl;

  EchoVaultApiService({
    required Dio dio,
    this.baseUrl = '',
  }) : _dio = dio {
    _dio.options.baseUrl = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
  }

  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    try {
      final url = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
      final response = await _dio.get(
        '$url/tracks/search',
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

  Future<List<Map<String, dynamic>>> getHomeRecommendations() async {
    try {
      final url = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
      final response = await _dio.get('$url/tracks/recommendations');
      return List<Map<String, dynamic>>.from(
          response.data['recommended'] ?? response.data ?? []);
    } catch (e) {
      developer.log('Home recommendations fetch failed: $e',
          name: 'ApiService');
      return [];
    }
  }

  Future<Map<String, dynamic>> getTrack(String id,
      {String quality = 'HI_RES_LOSSLESS'}) async {
    try {
      final url = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
      final response = await _dio.get(
        '$url/tracks/$id',
        queryParameters: {'quality': quality},
      );
      return response.data;
    } catch (e) {
      developer.log('Track fetch failed: $e', name: 'ApiService');
      return {};
    }
  }

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

  Future<Map<String, dynamic>> getAlbum(String id) async {
    try {
      final url = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
      final response = await _dio.get('$url/albums/$id');
      return response.data;
    } catch (e) {
      developer.log('Album fetch failed: $e', name: 'ApiService');
      return {};
    }
  }

  Future<Map<String, dynamic>> getArtist(String id) async {
    try {
      final url = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
      final response = await _dio.get('$url/artists/$id');
      return response.data;
    } catch (e) {
      developer.log('Artist fetch failed: $e', name: 'ApiService');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getTracksByGenre(String genre) async {
    try {
      final url = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
      final response = await _dio.get('$url/tracks/genre/$genre');
      final items = response.data['items'] ?? response.data['tracks'] ?? [];
      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      developer.log('Genre fetch failed: $e', name: 'ApiService');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTrendingTracks() async {
    try {
      final url = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
      final response = await _dio.get('$url/tracks/trending');
      return List<Map<String, dynamic>>.from(
          response.data['tracks'] ?? response.data ?? []);
    } catch (e) {
      developer.log('Trending tracks fetch failed: $e', name: 'ApiService');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserPlaylist(String playlistId) async {
    try {
      final url = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
      final response = await _dio.get('$url/playlists/$playlistId');
      return List<Map<String, dynamic>>.from(
          response.data['tracks'] ?? response.data['items'] ?? []);
    } catch (e) {
      developer.log('Playlist fetch failed: $e', name: 'ApiService');
      return [];
    }
  }
}
