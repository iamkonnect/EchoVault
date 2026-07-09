import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../config/api_config.dart';

/// DEPRECATED: Use auth_service_v2.dart instead
/// This file is kept for backward compatibility only
/// All authentication should use AuthService from auth_service_v2.dart with ApiClient

class AuthService {
  final Dio _dio = Dio();
  final String baseUrl;

  AuthService({this.baseUrl = ''}) {
    _dio.options.baseUrl = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// DEPRECATED: Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String role = 'ARTIST',
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'role': role,
        },
      );

      return {
        'success': true,
        'token': response.data['token'],
        'user': response.data['user'],
      };
    } catch (e) {
      developer.log('Register failed: $e', name: 'AuthService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// DEPRECATED: Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      return {
        'success': true,
        'token': response.data['token'],
        'user': response.data['user'],
      };
    } catch (e) {
      developer.log('Login failed: $e', name: 'AuthService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// DEPRECATED: Logout
  Future<void> logout() async {
    try {
      await _dio.post('$baseUrl/api/auth/logout');
    } catch (e) {
      developer.log('Logout error: $e', name: 'AuthService');
    }
  }

  Dio getDio() => _dio;
}
