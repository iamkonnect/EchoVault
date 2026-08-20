import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../config/api_config.dart';

class AuthService {
  final Dio _dio = Dio();
  final String baseUrl;

  AuthService({this.baseUrl = ''}) {
    _dio.options.baseUrl = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String role = 'ARTIST',
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
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

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      developer.log('Logout error: $e', name: 'AuthService');
    }
  }

  Dio getDio() => _dio;
}
