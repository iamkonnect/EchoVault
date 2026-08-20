import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service_v2.dart';

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final Map<String, dynamic>? user;
  final String? error;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.token,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    Map<String, dynamic>? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      user: user ?? this.user,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  late SharedPreferences _prefs;

  AuthNotifier(this._authService) : super(AuthState());

  // Initialize preferences and restore session
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _restoreSession();
  }

  // Restore session from storage
  Future<void> _restoreSession() async {
    try {
      final token = _prefs.getString('auth_token');
      final userJson = _prefs.getString('user_data');

      if (token != null && userJson != null) {
        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          user: _parseUserJson(userJson),
        );
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
  }

  // Register
  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
      );

      if (result['success'] == true) {
        final token = result['token'];
        final user = result['user'];

        await _saveSession(token, user);

        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          user: user,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration error: ${e.toString()}',
      );
    }
  }

  // Login
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        final token = result['token'];
        final user = result['user'];

        await _saveSession(token, user);

        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          user: user,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login error: ${e.toString()}',
      );
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authService.logout(state.token ?? '');

      await _prefs.remove('auth_token');
      await _prefs.remove('user_data');

      state = AuthState();
    } catch (e) {
      debugPrint('Logout error: $e');
      await _prefs.remove('auth_token');
      await _prefs.remove('user_data');
      state = AuthState();
    }
  }

  // Handle OAuth callback (Google/Apple)
  Future<void> handleOAuthCallback(String token, String? provider) async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await _authService.verifyAuth(token);

      if (result['success'] == true && result['user'] != null) {
        final user = result['user'];
        await _saveSession(token, user);

        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          user: user,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
            isLoading: false, error: 'OAuth verification failed');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'OAuth error: $e');
    }
  }

  // Forgot password
  Future<String?> forgotPassword(String email) async {
    try {
      final result = await _authService.forgotPassword(email);
      return result['message'] as String?;
    } catch (e) {
      return 'Failed to send reset email';
    }
  }

  // Resend verification email
  Future<String?> resendVerificationEmail() async {
    try {
      if (state.token == null) return 'Not authenticated';
      final result = await _authService.resendVerification(state.token!);
      return result['message'] as String?;
    } catch (e) {
      return 'Failed to send verification email';
    }
  }

  // Refresh token
  Future<void> refreshToken() async {
    try {
      if (state.token == null) return;

      final result = await _authService.refreshToken(state.token!);

      if (result['success'] == true) {
        final newToken = result['token'];
        await _prefs.setString('auth_token', newToken);
        state = state.copyWith(token: newToken);
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await logout();
    }
  }

  // Helper methods
  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    await _prefs.setString('auth_token', token);
    await _prefs.setString('user_data', json.encode(user));
  }

  Map<String, dynamic> _parseUserJson(String userJson) {
    try {
      return json.decode(userJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing user JSON: $e');
      return {};
    }
  }

  String? getToken() => state.token;
  Map<String, dynamic>? getUser() => state.user;
}

// Providers
final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final notifier = AuthNotifier(authService);
  notifier.initialize();
  return notifier;
});

final isAuthenticatedProvider = Provider((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final currentUserProvider = Provider((ref) {
  return ref.watch(authStateProvider).user;
});

final authTokenProvider = Provider((ref) {
  return ref.watch(authStateProvider).token;
});
