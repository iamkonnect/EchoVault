/// API Configuration Management
/// Centralized configuration for all API connections with environment support
library;

class ApiConfig {
  // Environment selection
  static const Environment currentEnvironment = Environment.development;

  // Port Configuration
  static const int portDevelopment = 5000;
  static const int portProduction = 5000;

  // Base URLs by environment
  static const Map<Environment, String> baseUrls = {
    Environment.development: 'http://localhost:5000',
    Environment.staging: 'http://staging.echovault.com',
    Environment.production: 'https://api.echovault.com',
  };

  // WebSocket URLs by environment
  static const Map<Environment, String> socketUrls = {
    Environment.development: 'http://localhost:5000',
    Environment.staging: 'http://staging.echovault.com',
    Environment.production: 'https://api.echovault.com',
  };

  // Get current base URL
  static String get baseUrl => baseUrls[currentEnvironment] ?? 'http://localhost:5000';

  // Get current WebSocket URL
  static String get socketUrl => socketUrls[currentEnvironment] ?? 'http://localhost:5000';

  // API version
  static const String apiVersion = '/api';

  // Timeout settings (in seconds)
  static const int requestTimeout = 30;
  static const int uploadTimeout = 120;

  // Enable debug logging
  static const bool enableDebugLogging = true;

  // Feature flags
  static const bool useNewApiVersion = true; // Toggle between v1 and v2
  static const bool enableEndpointMapping = true; // Use compatibility layer
  static const bool enableResponseNormalization = true; // Normalize all responses
}

enum Environment {
  development,
  staging,
  production,
}

/// API Endpoint Mapper
/// Maps frontend calls to actual backend endpoints handling naming inconsistencies
class EndpointMapper {
  // Normalize endpoint names between versions
  static const Map<String, String> endpointMappings = {
    // Artist endpoints - handle naming differences
    '/api/artist/revenue': '/api/artist/earnings',
    '/api/artist/payouts': '/api/artist/withdrawals',

    // Upload endpoints - handle path differences
    '/api/artist/upload/audio': '/api/artist/upload-music',
    '/api/artist/upload/video': '/api/artist/upload-short',
    '/api/artist/upload/shorts': '/api/artist/upload-short',

    // Dashboard endpoints - ensure API responses, not views
    '/api/artist/dashboard': '/api/artist/dashboard',
    '/api/artist/my-music': '/api/artist/my-music',
  };

  /// Map endpoint from frontend naming to backend naming
  static String mapEndpoint(String endpoint) {
    if (!ApiConfig.enableEndpointMapping) return endpoint;
    return endpointMappings[endpoint] ?? endpoint;
  }

  /// Get all endpoint mappings (for documentation)
  static Map<String, String> getAllMappings() => Map.from(endpointMappings);
}

/// Response Format Normalizer
/// Ensures all API responses follow a consistent structure
class ResponseNormalizer {
  /// Normalize any response to standard format
  static Map<String, dynamic> normalize(dynamic response) {
    if (!ApiConfig.enableResponseNormalization) {
      if (response is Map<String, dynamic>) return response;
      return {'data': response};
    }

    if (response is! Map<String, dynamic>) {
      return {
        'success': true,
        'data': response,
        'message': 'Success',
      };
    }

    // Already has success field - good
    if (response.containsKey('success')) {
      return response;
    }

    // Has error field - convert to standard format
    if (response.containsKey('error')) {
      return {
        'success': false,
        'message': response['error'],
        'error': response['error'],
      };
    }

    // Has data field - assume success
    if (response.containsKey('data')) {
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Success',
      };
    }

    // Has items field - convert to data
    if (response.containsKey('items')) {
      return {
        'success': true,
        'data': response['items'],
        'message': 'Success',
      };
    }

    // Has tracks field - convert to data
    if (response.containsKey('tracks')) {
      return {
        'success': true,
        'data': response['tracks'],
        'message': 'Success',
      };
    }

    // Has recommended field - convert to data
    if (response.containsKey('recommended')) {
      return {
        'success': true,
        'data': response['recommended'],
        'message': 'Success',
      };
    }

    // Default: wrap entire response as data
    return {
      'success': true,
      'data': response,
      'message': 'Success',
    };
  }

  /// Extract data from normalized response
  static dynamic extractData(Map<String, dynamic> normalizedResponse) {
    return normalizedResponse['data'];
  }

  /// Check if response indicates success
  static bool isSuccess(Map<String, dynamic> normalizedResponse) {
    return normalizedResponse['success'] ?? false;
  }

  /// Get error message from response
  static String getErrorMessage(Map<String, dynamic> normalizedResponse) {
    return normalizedResponse['message'] ??
        normalizedResponse['error'] ??
        'Unknown error';
  }
}

/// Missing Endpoints Stub Handler
/// Provides fallback implementations for missing backend endpoints
class MissingEndpointsStub {
  /// Stub for search endpoint until backend implements it
  static Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    // TODO: Remove this when backend implements search
    return [];
  }

  /// Stub for albums until backend implements
  static Future<Map<String, dynamic>> getAlbum(String id) async {
    // TODO: Remove this when backend implements
    return {};
  }

  /// Stub for artist profiles until backend implements
  static Future<Map<String, dynamic>> getArtist(String id) async {
    // TODO: Remove this when backend implements
    return {};
  }

  /// Stub for playlists until backend implements
  static Future<Map<String, dynamic>> getPlaylist(String id) async {
    // TODO: Remove this when backend implements
    return {};
  }

  /// Stub for user profile until backend implements
  static Future<Map<String, dynamic>> getUserProfile() async {
    // TODO: Remove this when backend implements
    return {};
  }
}
