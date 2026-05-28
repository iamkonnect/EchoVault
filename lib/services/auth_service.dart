import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:async';

class AuthService {
  final Dio _dio = Dio();
  final String baseUrl;
  String? _token;

  AuthService({this.baseUrl = 'http://localhost:5000'}) {
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      _setAuthHeader();
    }
  }

  void _setAuthHeader() {
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String role = 'USER',
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

      final data = response.data;
      final token = data['token'];

      // Save token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _token = token;
      _setAuthHeader();

      return {
        'success': true,
        'token': token,
        'user': data['user'],
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
        '$baseUrl/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      final token = data['token'];

      // Save token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _token = token;
      _setAuthHeader();

      return {
        'success': true,
        'token': token,
        'user': data['user'],
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
      await _dio.post('$baseUrl/api/auth/logout');
    } catch (e) {
      developer.log('Logout error: $e', name: 'AuthService');
    }

    // Clear token locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    _dio.options.headers.remove('Authorization');
  }

  String? getToken() => _token;

  bool isAuthenticated() => _token != null;

  Dio getDio() => _dio;
}
