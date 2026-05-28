import '../services/api_client.dart';

/// Service handling gifting logic and coin package management.
class GiftService {
  final ApiClient apiClient;

  GiftService({required this.apiClient});

  /// Retrieves available coin packages for the user to purchase.
  Future<List<dynamic>> getCoinPackages() async {
    try {
      final response = await apiClient.get('/api/gifts/packages');
      return response['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// Sends a gift to a creator.
  /// [entityId] is the ID of the Song, Short, or Live Session.
  /// [entityType] should be 'SONG', 'SHORT', or 'LIVE'.
  Future<Map<String, dynamic>> sendGift({
    required String entityId,
    required String entityType,
    required String giftId,
  }) async {
    try {
      return await apiClient.post('/api/gifting/send', body: {
        'entityId': entityId,
        'entityType': entityType,
        'giftId': giftId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
