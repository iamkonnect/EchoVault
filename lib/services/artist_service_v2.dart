import 'package:dio/dio.dart';
import 'api_client.dart';
import 'cache_service.dart';
import 'compatibility_service.dart';
import 'dart:developer' as developer;

class ArtistServiceV2 {
  final ApiClient _apiClient;
  late final CompatibilityService _compatService;

  ArtistServiceV2(
      {required ApiClient apiClient, required CacheService cacheService})
      : _apiClient = apiClient {
    _compatService =
        CompatibilityService(apiClient: apiClient, cacheService: cacheService);
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response =
          await _apiClient.get<Map<String, dynamic>>('/artist/dashboard');
      return response;
    } catch (e) {
      developer.log('Dashboard fetch failed: ' + e.toString(),
          name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getArtistMusic() async {
    try {
      final response =
          await _apiClient.get<Map<String, dynamic>>('/artist/music');
      return response;
    } catch (e) {
      developer.log('Failed to fetch artist music: ' + e.toString(),
          name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Start a live stream
  Future<Map<String, dynamic>> startLiveStream({required String title}) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/artist/start-stream',
        body: {'title': title},
      );
      return response;
    } catch (e) {
      developer.log('Failed to start live stream: ' + e.toString(),
          name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Stop a live stream
  Future<Map<String, dynamic>> stopLiveStream(String streamId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/artist/stop-stream',
        body: {'streamId': streamId},
      );
      return response;
    } catch (e) {
      developer.log('Failed to stop live stream: ' + e.toString(),
          name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Upgrade current user from USER to ARTIST role
  Future<Map<String, dynamic>> upgradeToArtist() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/upgrade-artist',
      );
      return response;
    } catch (e) {
      developer.log('Failed to upgrade to artist: ' + e.toString(),
          name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get artist insights data
  Future<Map<String, dynamic>> getArtistInsights() async {
    try {
      final response =
          await _apiClient.get<Map<String, dynamic>>('/artist/insights');
      return response;
    } catch (e) {
      developer.log('Failed to fetch insights: ' + e.toString(),
          name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get shorts insights data
  Future<Map<String, dynamic>> getShortsInsights() async {
    try {
      final response =
          await _apiClient.get<Map<String, dynamic>>('/artist/shorts-insights');
      return response;
    } catch (e) {
      developer.log('Failed to fetch shorts insights: ' + e.toString(),
          name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get revenue data
  Future<Map<String, dynamic>> getRevenueData() async {
    try {
      final response =
          await _apiClient.get<Map<String, dynamic>>('/artist/earnings');
      return response;
    } catch (e) {
      developer.log('Failed to fetch revenue: ' + e.toString(),
          name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get payout history
  Future<List<Map<String, dynamic>>> getPayoutHistory() async {
    try {
      final response =
          await _apiClient.get<Map<String, dynamic>>('/artist/withdrawals');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      developer.log('Failed to fetch payout history: ' + e.toString(),
          name: 'ArtistService');
      return [];
    }
  }

  /// Request a withdrawal / payout
  Future<Map<String, dynamic>> requestWithdrawal(
      {required double amount, String? paymentMethod}) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/artist/withdraw',
        body: {
          'amount': amount,
          'paymentMethod': paymentMethod ?? 'BANK',
        },
      );
      return response;
    } catch (e) {
      developer.log('Failed to request withdrawal: ' + e.toString(),
          name: 'ArtistService');
      return {'success': false, 'error': e.toString()};
    }
  }
}
