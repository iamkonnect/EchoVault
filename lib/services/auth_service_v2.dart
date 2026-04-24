import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'api_client.dart';

/// Comprehensive authentication service for EchoVault
/// Supports user and artist authentication with token management
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

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String role = 'USER',
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
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

  /// Login user with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {
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

  /// Login dashboard (web interface)
  Future<Map<String, dynamic>> loginDashboard({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/login-dashboard',
        data: {
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

  /// Logout and clear authentication
  Future<void> logout() async {
    try {
      await _apiClient.post('/api/auth/logout', data: {});
    } catch (e) {
      developer.log('Logout error: $e', name: 'AuthService');
    } finally {
      await _apiClient.clearToken();
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() => _apiClient.isAuthenticated();

  /// Get current auth token
  String? getToken() => _apiClient.getToken();

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
