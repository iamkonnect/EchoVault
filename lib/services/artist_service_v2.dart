import 'package:dio/dio.dart';
import 'api_client.dart';
import 'cache_service.dart';
import 'compatibility_service.dart';
import 'dart:developer' as developer;

/// Artist-specific API service for EchoVault
/// Handles artist uploads, dashboard data, insights, and revenue
class ArtistServiceV2 {
  final ApiClient _apiClient;
  late final CompatibilityService _compatService;

  ArtistServiceV2({required ApiClient apiClient, required CacheService cacheService})
      : _apiClient = apiClient {
    _compatService = CompatibilityService(
      apiClient: apiClient,
      cacheService: cacheService,
    );
  }

  // ============ DASHBOARD ENDPOINTS ============

  /// Get artist dashboard data (overview, stats)
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/artist/dashboard',
      );
      return response;
    } catch (e) {
      developer.log('Dashboard fetch failed: $e', name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ MUSIC UPLOAD ENDPOINTS ============

  /// Get artist's uploaded music
  Future<Map<String, dynamic>> getArtistMusic() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/artist/music',
      );
      return response;
    } catch (e) {
      developer.log('Failed to fetch artist music: $e', name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Upload audio track with metadata
  Future<Map<String, dynamic>> uploadAudio({
    required String title,
    required String filePath,
    String? genre,
    String? description,
    String quality = 'HI_RES_LOSSLESS',
    String? coverArtPath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        'quality': quality,
        if (genre != null) 'genre': genre,
        if (description != null) 'description': description,
        'audioFile': await MultipartFile.fromFile(filePath),
        if (coverArtPath != null)
          'coverArt': await MultipartFile.fromFile(coverArtPath),
      });

      final response = await _apiClient.postFormData<Map<String, dynamic>>(
        '/api/tracks/upload',
        formData,
      );

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      developer.log('Audio upload failed: $e', name: 'ArtistService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Upload video content
  Future<Map<String, dynamic>> uploadVideo({
    required String title,
    required String filePath,
    String? description,
    String? thumbnailPath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        if (description != null) 'description': description,
        'videoFile': await MultipartFile.fromFile(filePath),
        if (thumbnailPath != null)
          'thumbnail': await MultipartFile.fromFile(thumbnailPath),
      });

      final response = await _apiClient.postFormData<Map<String, dynamic>>(
        '/api/artist/upload/video',
        formData,
      );

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      developer.log('Video upload failed: $e', name: 'ArtistService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Upload shorts (short-form video)
  Future<Map<String, dynamic>> uploadShorts({
    required String title,
    required String filePath,
    String? description,
    String? thumbnailPath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        if (description != null) 'description': description,
        'shortFile': await MultipartFile.fromFile(filePath),
        if (thumbnailPath != null)
          'thumbnail': await MultipartFile.fromFile(thumbnailPath),
      });

      final response = await _apiClient.postFormData<Map<String, dynamic>>(
        '/api/artist/upload/shorts',
        formData,
      );

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      developer.log('Shorts upload failed: $e', name: 'ArtistService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ============ INSIGHTS ENDPOINTS ============

  /// Get music insights and analytics
  Future<Map<String, dynamic>> getArtistInsights() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/artist/live-insights',
      );
      return response;
    } catch (e) {
      developer.log('Failed to fetch artist insights: $e', name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get shorts-specific insights
  Future<Map<String, dynamic>> getShortsInsights() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/artist/shorts-insights',
      );
      return response;
    } catch (e) {
      developer.log('Failed to fetch shorts insights: $e', name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ REVENUE & PAYOUTS ENDPOINTS ============

  /// Get revenue data and statistics
  Future<Map<String, dynamic>> getRevenueData() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/artist/earnings',
      );
      return response;
    } catch (e) {
      developer.log('Failed to fetch revenue data: $e', name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Request fund withdrawal
  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    String? bankAccount,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/artist/withdraw',
        body: {
          'amount': amount,
          if (bankAccount != null) 'bankAccount': bankAccount,
        },
      );

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      developer.log('Withdrawal request failed: $e', name: 'ArtistService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Start live stream
  Future<Map<String, dynamic>> startLiveStream({
    required String title,
    String thumbnail = '',
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/artist/start-stream',
        body: {
          'title': title,
          if (thumbnail.isNotEmpty) 'thumbnail': thumbnail,
        },
      );
      return {'success': true, 'data': response};
    } catch (e) {
      developer.log('Start stream failed: $e', name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Stop live stream
  Future<Map<String, dynamic>> stopLiveStream(String streamId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/artist/stop-stream',
        body: {'streamId': streamId},
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get artist's payout history
  Future<List<Map<String, dynamic>>> getPayoutHistory() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/artist/withdrawals',
      );
      final payouts = response['payouts'] ?? response['items'] ?? [];
      return List<Map<String, dynamic>>.from(payouts);
    } catch (e) {
      developer.log('Failed to fetch payout history: $e', name: 'ArtistService');
      return [];
    }
  }

  // ============ MUSIC MANAGEMENT ENDPOINTS ============

  /// Edit music metadata
  Future<bool> editMusic({
    required String musicId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _apiClient.put(
        '/api/artist/music/$musicId',
        body: data,
      );
      return true;
    } catch (e) {
      developer.log('Failed to edit music: $e', name: 'ArtistService');
      return false;
    }
  }

  /// Delete music
  Future<bool> deleteMusic(String musicId) async {
    try {
      await _apiClient.delete(
        '/api/artist/music/$musicId',
      );
      return true;
    } catch (e) {
      developer.log('Failed to delete music: $e', name: 'ArtistService');
      return false;
    }
  }

  /// Get detailed music stats
  Future<Map<String, dynamic>> getMusicStats(String musicId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/artist/music/$musicId/stats',
      );
      return response;
    } catch (e) {
      developer.log('Failed to fetch music stats: $e', name: 'ArtistService');
      return {};
    }
  }
}
