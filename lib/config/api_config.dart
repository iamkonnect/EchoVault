import 'package:flutter/material.dart';

class ApiConfig {
  static const String baseUrl = 'http://20.75.223.217:5000/api';
  
  // Debug settings
  static const bool enableDebugLogging = false;
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
  static const String adsEndpoint = '$baseUrl/ads/log-impression';
  static const String giftsEndpoint = '$baseUrl/gifts/send';
  static const String fetchGiftsEndpoint = '$baseUrl/gifts';
  static const String fetchCoinPackagesEndpoint = '$baseUrl/payments/coin-packages';
  static const String initiatePaymentEndpoint = '$baseUrl/payments/initiate';
  static const String paymentWebhookEndpoint = '$baseUrl/payments/webhook';
  static const String streamJoinEndpoint = '$baseUrl/streams/join-request';
}
