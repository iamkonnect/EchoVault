import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'api_client.dart';

/// Comprehensive authentication service for EchoVault
/// Supports user and artist authentication with token management
/// Implements all authentication endpoints from Postman collection
class AuthService {
  final ApiClient _apiClient;
  final String baseUrl;

  AuthService({
    required ApiClient apiClient,
    this.baseUrl = '',
  })
      : _apiClient = apiClient {
    _initialize();
  }

  Future<void> _initialize() async {
    await _apiClient.initializeToken();
  }

  // ============ USER REGISTRATION ============

  /// Register a new user (EMAIL: artist@test.com, PASSWORD: password123)
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String role = 'ARTIST',
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/register',
        body: {
          'email': email,
          'password': password,
          'name': name,
          'role': role,
        },
      );

      if (response['token'] != null) {
        await _apiClient.setToken(response['token']);
      }

      return {
        'success': true,
        'token': response['token'],
        'user': response['user'],
      };
    } catch (e) {
      developer.log('Register failed: $e', name: 'AuthService');
      return {
        'success': false,
        'error': _parseError(e),
      };
    }
  }

  // ============ LOGIN/AUTHENTICATION ============

  /// Login user with email and password
  /// POST /api/auth/login
  /// Body: { "email": "artist@test.com", "password": "password123" }
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response['token'] != null) {
        await _apiClient.setToken(response['token']);
      }

      return {
        'success': true,
        'token': response['token'],
        'user': response['user'],
      };
    } catch (e) {
      developer.log('Login failed: $e', name: 'AuthService');
      return {
        'success': false,
        'error': _parseError(e),
      };
    }
  }

  /// Login to dashboard (web interface)
  Future<Map<String, dynamic>> loginDashboard({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/login-dashboard',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response['token'] != null) {
        await _apiClient.setToken(response['token']);
      }

      return {
        'success': true,
        'token': response['token'],
        'user': response['user'],
      };
    } catch (e) {
      developer.log('Dashboard login failed: $e', name: 'AuthService');
      return {
        'success': false,
        'error': _parseError(e),
      };
    }
  }

  // ============ LOGOUT ============

  /// Logout and clear authentication
  /// POST /api/auth/logout
  Future<void> logout() async {
    try {
      await _apiClient.post('/api/auth/logout', body: {});
    } catch (e) {
      developer.log('Logout error: $e', name: 'AuthService');
    } finally {
      await _apiClient.clearToken();
    }
  }

  // ============ TOKEN MANAGEMENT ============

  /// Check if user is authenticated
  bool isAuthenticated() => _apiClient.isAuthenticated();

  /// Get current auth token
  String? getToken() => _apiClient.getToken();

  /// Set token manually
  Future<void> setToken(String token) async {
    await _apiClient.setToken(token);
  }

  /// Clear stored token
  Future<void> clearToken() async {
    await _apiClient.clearToken();
  }

  /// Parse error message from exception
  String _parseError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        return error.response?.data['message'] ?? 'Authentication failed';
      }
      return error.message ?? 'Authentication failed';
    }
    return error.toString();
  }
}
