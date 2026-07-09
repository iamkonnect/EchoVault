import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/auth_service_v2.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

// Auth Service Provider - uses dynamic ApiConfig.baseUrl
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(apiClient: ApiClient());
});

// API Client Provider - uses dynamic ApiConfig.baseUrl
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Auth State Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final String? error;
  final String? token;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.token,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Map<String, dynamic>? user,
    String? error,
    String? token,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;

  AuthNotifier(this.authService)
      : super(AuthState(
          isAuthenticated: authService.isAuthenticated(),
          token: authService.getToken(),
        ));

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await authService.login(email: email, password: password);

      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: result['user'],
          token: result['token'],
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['error'] ?? 'Login failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> register(
    String email,
    String password,
    String name, {
    String role = 'ARTIST',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: result['user'],
          token: result['token'],
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['error'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await authService.logout();
    state = state.copyWith(
      isAuthenticated: false,
      user: null,
      token: null,
    );
  }
}
