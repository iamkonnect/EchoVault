import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' show FormData;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:echovault/config/api_config.dart';
import 'dart:developer' as developer;

/// Enhanced API Client with compatibility layer
/// Handles endpoint mapping, response normalization, and debug logging
class ApiClient {
  final String baseUrl;
  final bool isWeb;
  final _storage = const FlutterSecureStorage();
  String? _cachedToken;

  // Debug logging
  static const String _tag = 'ApiClient';

  ApiClient({String? baseUrl, this.isWeb = false})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<void> initializeToken() async {
    _cachedToken = await _storage.read(key: 'auth_token');
  }

  Future<void> setToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _storage.delete(key: 'auth_token');
  }

  bool isAuthenticated() => _cachedToken != null;
  String? getToken() => _cachedToken;
  dynamic getDio() => null; // Stub to satisfy providers

  Future<Map<String, String>> _getHeaders() async {
    final token = _cachedToken ?? await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET request with automatic endpoint mapping
  Future<T> get<T>(String endpoint) async {
    try {
      final mappedEndpoint = EndpointMapper.mapEndpoint(endpoint);
      final url = baseUrl.isEmpty
          ? Uri.parse('${Uri.base.origin}$mappedEndpoint')
          : Uri.parse('$baseUrl$mappedEndpoint');

      if (ApiConfig.enableDebugLogging) {
        developer.log('GET $url', name: _tag);
      }

      final response = await http
          .get(
            url,
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: ApiConfig.requestTimeout));

      return _handleResponse(response);
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        developer.log('GET error: $e', name: _tag, level: 1000);
      }
      rethrow;
    }
  }

  /// POST request with automatic endpoint mapping
  Future<T> post<T>(String endpoint,
      {Map<String, dynamic>? body, Map<String, dynamic>? data}) async {
    try {
      final mappedEndpoint = EndpointMapper.mapEndpoint(endpoint);
      final url = baseUrl.isEmpty
          ? Uri.parse('${Uri.base.origin}$mappedEndpoint')
          : Uri.parse('$baseUrl$mappedEndpoint');
      final bodyData = body ?? data ?? {};

      if (ApiConfig.enableDebugLogging) {
        developer.log('POST $url with body: $bodyData', name: _tag);
      }

      final response = await http
          .post(
            url,
            headers: await _getHeaders(),
            body: json.encode(bodyData),
          )
          .timeout(const Duration(seconds: ApiConfig.requestTimeout));

      return _handleResponse(response);
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        developer.log('POST error: $e', name: _tag, level: 1000);
      }
      rethrow;
    }
  }

  /// PUT request with automatic endpoint mapping
  Future<T> put<T>(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final mappedEndpoint = EndpointMapper.mapEndpoint(endpoint);
      final url = baseUrl.isEmpty
          ? Uri.parse('${Uri.base.origin}$mappedEndpoint')
          : Uri.parse('$baseUrl$mappedEndpoint');
      final bodyData = body ?? {};

      if (ApiConfig.enableDebugLogging) {
        developer.log('PUT $url with body: $bodyData', name: _tag);
      }

      final response = await http
          .put(
            url,
            headers: await _getHeaders(),
            body: json.encode(bodyData),
          )
          .timeout(const Duration(seconds: ApiConfig.requestTimeout));

      return _handleResponse(response);
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        developer.log('PUT error: $e', name: _tag, level: 1000);
      }
      rethrow;
    }
  }

  /// DELETE request with automatic endpoint mapping
  Future<T> delete<T>(String endpoint) async {
    try {
      final mappedEndpoint = EndpointMapper.mapEndpoint(endpoint);
      final url = baseUrl.isEmpty
          ? Uri.parse('${Uri.base.origin}$mappedEndpoint')
          : Uri.parse('$baseUrl$mappedEndpoint');

      if (ApiConfig.enableDebugLogging) {
        developer.log('DELETE $url', name: _tag);
      }

      final response = await http
          .delete(
            url,
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: ApiConfig.requestTimeout));

      return _handleResponse(response);
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        developer.log('DELETE error: $e', name: _tag, level: 1000);
      }
      rethrow;
    }
  }

  /// Form data upload with automatic endpoint mapping
  Future<T> postFormData<T>(String endpoint, dynamic data) async {
    try {
      // Map endpoint if needed
      final mappedEndpoint = EndpointMapper.mapEndpoint(endpoint);

      if (ApiConfig.enableDebugLogging) {
        final debugUrl = baseUrl.isEmpty
            ? '${Uri.base.origin}$mappedEndpoint'
            : '$baseUrl$mappedEndpoint';
        developer.log('FORM POST $debugUrl', name: _tag);
      }

      // Cast FormData fields to Map for JSON post (basic compatibility)
      if (data is FormData) {
        final formMap = <String, dynamic>{};
        for (final field in data.fields) {
          formMap[field.key] = field.value;
        }
        return post<T>(endpoint, body: formMap);
      } else {
        return post<T>(endpoint, body: data as Map<String, dynamic>);
      }
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        developer.log('FORM POST error: $e', name: _tag, level: 1000);
      }
      rethrow;
    }
  }

  /// Handle response with automatic normalization
  dynamic _handleResponse(http.Response response) {
    try {
      final body = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Normalize response format
        if (ApiConfig.enableResponseNormalization) {
          return ResponseNormalizer.normalize(body);
        }
        return body;
      } else {
        throw ApiException(
          message:
              body['error'] ?? body['message'] ?? 'An unknown error occurred',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }
}

/// Stub Endpoint Mapper - maps endpoint aliases to actual paths
class EndpointMapper {
  static String mapEndpoint(String endpoint) {
    // Direct pass-through - endpoint is used as-is
    if (endpoint.startsWith('/')) return endpoint;
    return '/$endpoint';
  }
}

/// Stub Response Normalizer - returns response as-is
class ResponseNormalizer {
  static dynamic normalize(dynamic body) => body;
}

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException({required this.message, required this.statusCode});
  @override
  String toString() => 'ApiException: $message (Code: $statusCode)';
}
