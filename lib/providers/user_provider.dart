import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../models/user.dart';
import '../models/gift.dart';
import '../services/auth_service_v2.dart';
import '../l10n/gift_service.dart';
import 'app_providers.dart';

class UserNotifier extends StateNotifier<User?> {
  final AuthService authService;

  UserNotifier(this.authService) : super(null) {
    _loadUser();
  }

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _twoFactorKey = 'is2FAEnabled';
  static const double _platformCommission = 0.30;

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);

    if (userData == null) {
      state = null;
      return;
    }

    try {
      final Map<String, dynamic> userMap = jsonDecode(userData);
      state = User(
        id: userMap['id'] ?? '',
        name: userMap['name'] ?? 'User',
        username: userMap['username'] ?? '',
        email: userMap['email'] ?? '',
        role: userMap['role'] == 'ARTIST' ? UserRole.artist : UserRole.user,
        balance: (userMap['balance'] ?? 0.0).toDouble(),
        avatarUrl: userMap['avatarUrl'],
      );
    } catch (e) {
      developer.log('Error loading user: $e', name: 'UserProvider');
      state = null;
    }
  }

  Future<void> toggle2FA() async {
    if (state == null) return;
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state!.is2FAEnabled;
    await prefs.setBool(_twoFactorKey, newValue);
    state = state!.copyWith(is2FAEnabled: newValue);
  }

  Future<void> updateProfile({
    String? name,
    String? username,
    String? email,
    String? bio,
  }) async {
    if (state == null) return;
    state = state!.copyWith(
      name: name ?? state!.name,
      username: username ?? state!.username,
      email: email ?? state!.email,
      bio: bio ?? state!.bio,
    );
  }

  void setRole(UserRole newRole) {
    if (state == null) return;
    state = state!.copyWith(role: newRole);
  }

  void addEarning(UserEarning earning) {
    if (state == null) return;
    final newEarnings = List<UserEarning>.from(state!.earnings)..add(earning);
    state = state!.copyWith(
        earnings: newEarnings, balance: state!.balance + earning.amount);
  }

  Future<bool> sendGift(Gift gift) async {
    if (state == null || state!.balance < gift.coinPrice) return false;
    state = state!.copyWith(balance: state!.balance - gift.coinPrice);
    return true;
  }

  Future<void> topUpBalance(int coins) async {
    if (state == null) return;
    state = state!.copyWith(balance: state!.balance + coins);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await authService.logout('');
    state = null;
  }

  Future<void> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await authService.logout('');
    state = null;
  }

  /// Sign in with backend API
  Future<bool> signIn(String email, String password) async {
    try {
      developer.log('Attempting login for: $email', name: 'UserProvider');

      final result = await authService.login(email: email, password: password);

      developer.log('Login result: $result', name: 'UserProvider');

      if (result['success'] == true && result['user'] != null) {
        final user = result['user'];
        final token = result['token'];

        developer.log('Login successful, storing credentials',
            name: 'UserProvider');

        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString(_tokenKey, token);
        }

        await prefs.setString(
            _userKey,
            jsonEncode({
              'id': user['id'] ?? '',
              'name': user['name'] ?? '',
              'username': user['username'] ?? '',
              'email': user['email'] ?? email,
              'role': user['role'] ?? 'USER',
              'avatarUrl': user['avatarUrl'],
              'balance': (user['balance'] ?? 0.0).toDouble(),
            }));

        state = User(
          id: user['id'] ?? '',
          name: user['name'] ?? 'User',
          username: user['username'] ?? '',
          email: user['email'] ?? email,
          avatarUrl: user['avatarUrl'],
          role: (user['role'] ?? 'USER')
                  .toString()
                  .toUpperCase()
                  .contains('ARTIST')
              ? UserRole.artist
              : UserRole.user,
          balance: (user['balance'] ?? 0.0).toDouble(),
        );

        return true;
      }

      developer.log('Login failed: ${result['error']}', name: 'UserProvider');
      return false;
    } catch (e) {
      developer.log('Login exception: $e', name: 'UserProvider');
      return false;
    }
  }

  /// Sign up with backend API
  Future<bool> signUp(
      String name, String username, String email, String password) async {
    try {
      developer.log('Attempting signup for: $email', name: 'UserProvider');

      final result = await authService.register(
        email: email,
        password: password,
        name: name,
      );

      developer.log('Signup result: $result', name: 'UserProvider');

      if (result['success'] == true && result['user'] != null) {
        final user = result['user'];
        final token = result['token'];

        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString(_tokenKey, token);
        }

        await prefs.setString(
            _userKey,
            jsonEncode({
              'id': user['id'] ?? '',
              'name': user['name'] ?? name,
              'username': user['username'] ?? username,
              'email': user['email'] ?? email,
              'role': 'ARTIST',
              'balance': 0.0,
            }));

        state = User(
          id: user['id'] ?? '',
          name: user['name'] ?? name,
          username: user['username'] ?? username,
          email: user['email'] ?? email,
          role: UserRole.artist,
          balance: 0.0,
        );

        return true;
      }

      developer.log('Signup failed: ${result['error']}', name: 'UserProvider');
      return false;
    } catch (e) {
      developer.log('Signup exception: $e', name: 'UserProvider');
      return false;
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UserNotifier(authService);
});

final giftServiceProvider = Provider<GiftService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GiftService(apiClient: apiClient);
});

final userAsyncProvider = FutureProvider<User>((ref) async {
  final user = ref.watch(userProvider);
  if (user != null) return user;
  await Future.delayed(const Duration(milliseconds: 500));

  final finalUser = ref.read(userProvider);
  if (finalUser == null) throw Exception('User data not initialized');
  return finalUser;
});
