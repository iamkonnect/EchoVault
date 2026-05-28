import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/artist_service.dart';
import '../config/api_config.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(baseUrl: ApiConfig.baseUrl.isEmpty ? 'http://localhost:5000' : ApiConfig.baseUrl);
});

// Authenticated Dio Provider
final dioProvider = Provider<Dio>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.getDio();
});

// API Service Provider
final apiServiceProvider = Provider<EchoVaultApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return EchoVaultApiService(dio: dio, baseUrl: ApiConfig.baseUrl.isEmpty ? 'http://localhost:5000' : ApiConfig.baseUrl);
});

// Artist Service Provider
final artistServiceProvider = Provider<ArtistService>((ref) {
  final dio = ref.watch(dioProvider);
  return ArtistService(dio: dio, baseUrl: ApiConfig.baseUrl.isEmpty ? 'http://localhost:5000' : ApiConfig.baseUrl);
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
    String role = 'USER',
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
