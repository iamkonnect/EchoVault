import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Dynamic API base URL based on environment
  static String get baseUrl {
    if (kIsWeb) {
      // For web, use relative URL or environment variable
      // This allows the frontend to call backend on same domain/port
      final windowLocation = Uri.base.toString();
      
      // If running on localhost, use localhost:5000
      if (windowLocation.contains('localhost') || windowLocation.contains('127.0.0.1')) {
        return 'http://localhost:5000/api';
      }
      
      // If running on Azure container, try to reach backend on same host or specific URL
      // Update this to your actual backend URL
      return 'https://echovault-backend.azurewebsites.net/api';
      // OR use same origin: return '/api'; (if backend is reverse-proxied)
    }
    
    // Mobile defaults
    return 'http://10.0.2.2:5000/api'; // Android emulator
    // For physical device, use your actual backend IP/domain
    // return 'http://192.168.x.x:5000/api'; // Update with your backend IP
  }

  static String get realtimeUrl {
    if (kIsWeb) {
      final windowLocation = Uri.base.toString();
      
      if (windowLocation.contains('localhost') || windowLocation.contains('127.0.0.1')) {
        return 'http://localhost:5000';
      }
      
      // Azure backend URL
      return 'https://echovault-backend.azurewebsites.net';
      // OR use same origin: return window.location.origin
    }
    
    // Mobile defaults
    return 'http://10.0.2.2:5000'; // Android emulator
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
  static String get adsEndpoint => '$baseUrl/ads/log-impression';
  static String get giftsEndpoint => '$baseUrl/gifts/send';
  static String get fetchGiftsEndpoint => '$baseUrl/gifts';
  static String get fetchCoinPackagesEndpoint => '$baseUrl/payments/coin-packages';
  static String get initiatePaymentEndpoint => '$baseUrl/payments/initiate';
  static String get paymentWebhookEndpoint => '$baseUrl/payments/webhook';
  static String get streamJoinEndpoint => '$baseUrl/streams/join-request';
  static String get liveStreamEndpoint => '$baseUrl/streams/start';
  static String get liveStreamStopEndpoint => '$baseUrl/streams/stop';
}
