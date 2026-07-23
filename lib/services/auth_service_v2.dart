import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'dart:developer' as developer;

class AuthService {
  final Dio _dio;
  static const String _tag = 'AuthService';

  AuthService({Dio? dio}) : _dio = dio ?? _setupDio();

  static Dio _setupDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      developer.log('Register success: ${response.statusCode}', name: _tag);

      return {
        'success': response.data['success'] ?? false,
        'token': response.data['token'],
        'user': response.data['user'],
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      developer.log('Register error: ${e.message}', name: _tag);
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Registration failed',
        'error': e.message,
      };
    } catch (e) {
      developer.log('Register catch error: $e', name: _tag);
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      developer.log('Login success: ${response.statusCode}', name: _tag);

      return {
        'success': response.data['success'] ?? false,
        'token': response.data['token'],
        'user': response.data['user'],
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      developer.log('Login error: ${e.message}', name: _tag);
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Login failed',
        'error': e.message,
      };
    } catch (e) {
      developer.log('Login catch error: $e', name: _tag);
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Logout
  Future<bool> logout(String token) async {
    try {
      await _dio.post(
        '/auth/logout',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      developer.log('Logout success', name: _tag);
      return true;
    } catch (e) {
      developer.log('Logout error: $e', name: _tag);
      return false;
    }
  }

  /// Refresh token
  Future<Map<String, dynamic>> refreshToken(String token) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      developer.log('Token refresh success', name: _tag);

      return {
        'success': response.data['success'] ?? false,
        'token': response.data['token'],
        'message': response.data['message'],
      };
    } catch (e) {
      developer.log('Token refresh error: $e', name: _tag);
      return {
        'success': false,
        'message': 'Token refresh failed',
        'error': e.toString(),
      };
    }
  }

  /// Verify auth
  Future<Map<String, dynamic>> verifyAuth(String token) async {
    try {
      final response = await _dio.post(
        '/auth/verify',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return {
        'success': response.data['success'] ?? false,
        'user': response.data['user'],
      };
    } catch (e) {
      developer.log('Verify auth error: $e', name: _tag);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Set auth token for all requests
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear auth token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Forgot password - request reset email
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return {
        'success': response.data['success'] ?? false,
        'message': response.data['message'] ??
            'If your email exists, a reset link has been sent.',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to send reset email',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Resend verification email
  Future<Map<String, dynamic>> resendVerification(String token) async {
    try {
      final response = await _dio.post(
        '/auth/send-verification',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return {
        'success': response.data['success'] ?? false,
        'message': response.data['message'] ?? 'Verification email sent',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? 'Failed to send verification email',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Upgrade user role to ARTIST
  Future<Map<String, dynamic>> upgradeToArtist(String token) async {
    try {
      final response = await _dio.post(
        '/auth/upgrade-artist',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return {
        'success': response.data['success'] ?? false,
        'user': response.data['user'],
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to upgrade to artist',
        'error': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Get auth token from the current session
  String? getToken() {
    return _dio.options.headers['Authorization']
        ?.toString()
        .replaceFirst('Bearer ', '');
  }
}
