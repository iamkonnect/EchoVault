import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Dynamic API base URL based on deployment environment
  static String get baseUrl {
    if (kIsWeb) {
      final windowLocation = Uri.base.toString();
      
      // Development: localhost
      if (windowLocation.contains('localhost') || windowLocation.contains('127.0.0.1')) {
        return 'http://localhost:5000';
      }
      
      // Production: Azure Container Instances
      // Point directly to backend Azure Container Instance
      if (windowLocation.contains('azurecontainers.io')) {
        return 'http://echovault-backend.eastus.azurecontainer.io:5000';
      }
      
      // Fallback for other deployments
      return 'http://echovault-backend.eastus.azurecontainer.io:5000';
    }
    
    // Mobile: Android emulator
    return 'http://10.0.2.2:5000';
  }

  static String get realtimeUrl {
    if (kIsWeb) {
      final windowLocation = Uri.base.toString();
      
      if (windowLocation.contains('localhost') || windowLocation.contains('127.0.0.1')) {
        return 'http://localhost:5000';
      }
      
      // Azure: connect directly to backend for WebSocket
      if (windowLocation.contains('azurecontainers.io')) {
        return 'http://echovault-backend.eastus.azurecontainer.io:5000';
      }
      
      return 'http://echovault-backend.eastus.azurecontainer.io:5000';
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

  // Endpoints
  static String get adsEndpoint => '$baseUrl/api/ads/log-impression';
  // Gifting endpoints — backend mounts at /api/gifting
  static String get giftsEndpoint => '$baseUrl/api/gifting/send';
  static String get fetchGiftsEndpoint => '$baseUrl/api/gifting';
  // Payment endpoints
  static String get fetchCoinPackagesEndpoint => '$baseUrl/api/payments/coin-packages';
  static String get initiatePaymentEndpoint => '$baseUrl/api/payments/initiate';
  static String get paymentWebhookEndpoint => '$baseUrl/api/payments/webhook';
  // Live stream endpoints — backend mounts at /api/live
  static String get streamJoinEndpoint => '$baseUrl/api/live/streams/join-request';
  static String get liveStreamEndpoint => '$baseUrl/api/artist/start-stream';
  static String get liveStreamStopEndpoint => '$baseUrl/api/artist/stop-stream';
}
