import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Dynamic API base URL based on deployment environment
  // IMPORTANT: ALL base URLs now end with /api so paths should NOT start with /api/
  static String get baseUrl {
    if (kIsWeb) {
      final windowLocation = Uri.base.toString();

      // Development: localhost HTTP
      if (windowLocation.contains('localhost') ||
          windowLocation.contains('127.0.0.1')) {
        return 'http://localhost:5000/api';
      }

      // Production: Use HTTPS for Traefik/admin.echovaultz.com
      if (windowLocation.contains('echovaultz.com')) {
        return 'https://admin.echovaultz.com/api';
      }

      // Fallback to production HTTPS
      return 'https://admin.echovaultz.com/api';
    }

    // Mobile: Android emulator
    return 'http://10.0.2.2:5000/api';
  }

  static String get realtimeUrl {
    if (kIsWeb) {
      final windowLocation = Uri.base.toString();

      if (windowLocation.contains('localhost') ||
          windowLocation.contains('127.0.0.1')) {
        return 'http://localhost:5000';
      }

      // Production: Use HTTPS for Traefik
      if (windowLocation.contains('echovaultz.com')) {
        return 'https://admin.echovaultz.com';
      }

      return 'https://admin.echovaultz.com';
    }

    return 'http://10.0.2.2:5000';
  }

  // Debug settings
  static const bool enableDebugLogging = true;
  static const int requestTimeout = 30;
  static const bool enableResponseNormalization = false;

  // Standard Gifting Icon
  static const IconData giftingIcon = Icons.card_giftcard;

  // Revenue Split Constants
  static const double adminShare = 0.20;
  static const double artistShareStandard = 0.80;
  static const double artistShareChallenge = 0.40;
  static const double listenerShareChallenge = 0.60;

  // Feature Flags
  static bool shouldShowAds(Map<String, dynamic>? user) {
    if (user == null) return true;
    return user['subscriptionStatus'] != 'premium';
  }

  // ============ AUTHENTICATION ENDPOINTS ============
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get logoutEndpoint => '$baseUrl/auth/logout';

  // ============ ARTIST ENDPOINTS ============
  static String get artistDashboardEndpoint => '$baseUrl/artist/dashboard';
  static String get artistInsightsEndpoint => '$baseUrl/artist/insights';
  static String get artistLiveInsightsEndpoint =>
      '$baseUrl/artist/live-insights';
  static String get artistMusicEndpoint => '$baseUrl/artist/music';
  static String get artistShortsInsightsEndpoint =>
      '$baseUrl/artist/shorts-insights';
  static String get artistEarningsEndpoint => '$baseUrl/artist/earnings';
  static String get artistWithdrawalsEndpoint => '$baseUrl/artist/withdrawals';
  static String get artistWithdrawEndpoint => '$baseUrl/artist/withdraw';
  static String get artistStartStreamEndpoint => '$baseUrl/artist/start-stream';
  static String get artistStopStreamEndpoint => '$baseUrl/artist/stop-stream';

  // ============ TRACK ENDPOINTS ============
  static String get tracksUploadEndpoint => '$baseUrl/tracks/upload';

  // ============ GIFTING ENDPOINTS ============
  static String get giftsEndpoint => '$baseUrl/gifting/send';
  static String get fetchGiftsEndpoint => '$baseUrl/gifting';

  // ============ PAYMENT ENDPOINTS ============
  static String get fetchCoinPackagesEndpoint =>
      '$baseUrl/payments/coin-packages';
  static String get initiatePaymentEndpoint => '$baseUrl/payments/initiate';
  static String get paymentWebhookEndpoint => '$baseUrl/payments/webhook';

  // ============ LIVE STREAM ENDPOINTS ============
  static String get liveStreamEndpoint => '$baseUrl/artist/start-stream';
  static String get liveStreamStopEndpoint => '$baseUrl/artist/stop-stream';
  static String get streamJoinEndpoint => '$baseUrl/live/streams/join-request';

  // ============ ADS ENDPOINTS ============
  static String get adsEndpoint => '$baseUrl/ads/log-impression';
}
