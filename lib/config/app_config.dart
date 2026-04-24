class AppConfig {
  // For local testing with Android Emulator, use http://10.0.2.2:5000
  // For iOS Simulator or Web, use http://localhost:5000
  // For Production, use your deployed URL like https://api.echovault.com
  static const String baseUrl = 'http://10.0.2.2:5000';
  
  static const String apiBase = '$baseUrl/api';
  
  // API endpoints for dynamic gifts
  static const String giftsEndpoint = '$apiBase/gifts';
  
  // Gift Icon Mapping
  static const Map<String, String> giftIcons = {
    'mic': '🎤',
    'vinyl': '💿',
    'guitar': '🎸',
    'headphone': '🎧',
  };
}