import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'api_client.dart';

/// Token management service with automatic refresh capability
class TokenRefreshService {
  final ApiClient _apiClient;
  String? _currentToken;
  DateTime? _tokenExpiresAt;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const int _tokenExpiration = 24 * 60 * 60; // 24 hours in seconds

  TokenRefreshService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Initialize from stored token
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentToken = prefs.getString(_tokenKey);
    
    if (_currentToken != null) {
      _tokenExpiresAt = DateTime.now().add(const Duration(seconds: _tokenExpiration));
      await _apiClient.setToken(_currentToken!);
    }
  }

  /// Save new token
  Future<void> saveToken(String token) async {
    _currentToken = token;
    _tokenExpiresAt = DateTime.now().add(const Duration(seconds: _tokenExpiration));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await _apiClient.setToken(token);
  }

  /// Get current token
  String? getToken() => _currentToken;

  /// Check if token is expired or about to expire (within 5 minutes)
  bool isTokenExpiredOrExpiring() {
    if (_tokenExpiresAt == null) return true;
    
    final now = DateTime.now();
    final fiveMinutesFromNow = now.add(const Duration(minutes: 5));
    
    return _tokenExpiresAt!.isBefore(fiveMinutesFromNow);
  }

  /// Refresh the current token
  Future<bool> refreshToken() async {
    try {
      if (_currentToken == null) {
        developer.log('No token to refresh', name: 'TokenRefreshService');
        return false;
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'token': _currentToken},
      );

      if (response['token'] != null) {
        await saveToken(response['token']);
        developer.log('Token refreshed successfully', name: 'TokenRefreshService');
        return true;
      }

      return false;
    } catch (e) {
      developer.log('Token refresh failed: $e', name: 'TokenRefreshService');
      // If refresh fails, clear token
      await clearToken();
      return false;
    }
  }

  /// Verify current token is valid
  Future<bool> verifyToken() async {
    try {
      if (_currentToken == null) return false;

      await _apiClient.post('/api/auth/verify', data: {});
      return true;
    } catch (e) {
      developer.log('Token verification failed: $e', name: 'TokenRefreshService');
      return false;
    }
  }

  /// Clear token on logout
  Future<void> clearToken() async {
    _currentToken = null;
    _tokenExpiresAt = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await _apiClient.clearToken();
  }

  /// Get token info (for debugging)
  Map<String, dynamic> getTokenInfo() {
    return {
      'hasToken': _currentToken != null,
      'expiresAt': _tokenExpiresAt?.toString(),
      'isExpired': isTokenExpiredOrExpiring(),
      'secondsUntilExpiry': _tokenExpiresAt?.difference(DateTime.now()).inSeconds ?? 0,
    };
  }
}

/// Dio interceptor for automatic token refresh
class TokenRefreshInterceptor extends QueuedInterceptor {
  final TokenRefreshService tokenRefreshService;
  bool _isRefreshing = false;
  final List<RequestInterceptorHandler> _waitingRequests = [];

  TokenRefreshInterceptor({required this.tokenRefreshService});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check if token needs refresh before each request
    if (tokenRefreshService.isTokenExpiredOrExpiring()) {
      if (_isRefreshing) {
        // Wait for ongoing refresh to complete
        _waitingRequests.add(handler);
        return;
      }

      _isRefreshing = true;

      try {
        final refreshed = await tokenRefreshService.refreshToken();
        _isRefreshing = false;

        if (refreshed) {
          // Update request with new token
          final newToken = tokenRefreshService.getToken();
          if (newToken != null) {
            options.headers['Authorization'] = 'Bearer $newToken';
          }

          // Process waiting requests
          for (var waitingHandler in _waitingRequests) {
            final newToken = tokenRefreshService.getToken();
            if (newToken != null) {
              final waitingOptions = RequestOptions(
                path: '',
                baseUrl: '',
              );
              waitingOptions.headers['Authorization'] = 'Bearer $newToken';
            }
          }
          _waitingRequests.clear();

          handler.next(options);
        } else {
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Token refresh failed',
              type: DioExceptionType.unknown,
            ),
          );
        }
      } catch (e) {
        _isRefreshing = false;
        _waitingRequests.clear();
        handler.reject(
          DioException(
            requestOptions: options,
            error: 'Token refresh error: $e',
            type: DioExceptionType.unknown,
          ),
        );
      }
    } else {
      handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token might be invalid, try refresh
      try {
        final refreshed = await tokenRefreshService.refreshToken();
        if (refreshed) {
          // Retry original request with new token
          final newToken = tokenRefreshService.getToken();
          if (newToken != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final dio = Dio();
            final response = await dio.request(
              err.requestOptions.path,
              options: Options(
                method: err.requestOptions.method,
                headers: err.requestOptions.headers,
              ),
              data: err.requestOptions.data,
              queryParameters: err.requestOptions.queryParameters,
            );
            handler.resolve(response);
            return;
          }
        }
      } catch (e) {
        developer.log('Auto-refresh on 401 failed: $e', name: 'TokenRefreshService');
      }
    }

    handler.next(err);
  }
}
