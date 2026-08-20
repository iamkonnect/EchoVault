import '../services/api_client.dart';

/// Service handling gifting logic and coin package management.
class GiftService {
  final ApiClient apiClient;

  GiftService({required this.apiClient});

  /// Retrieves available coin packages for the user to purchase.
  Future<List<dynamic>> getCoinPackages() async {
    try {
      final response = await apiClient.get('/gifts/packages');
      return response['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves all available gifts from the backend.
  Future<List<dynamic>> getAvailableGifts() async {
    try {
      final response = await apiClient.get('/gifting');
      return response['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// Sends a gift to a creator.
  Future<Map<String, dynamic>> sendGift({
    required String receiverId,
    required double amount,
    required String giftId,
    int quantity = 1,
    String? streamId,
  }) async {
    try {
      return await apiClient.post('/gifting/send', body: {
        'receiverId': receiverId,
        'amount': amount,
        'giftId': giftId,
        'quantity': quantity,
        'streamId': streamId,
      });
    } catch (e) {
      rethrow;
    }
  }
}
