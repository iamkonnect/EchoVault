import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/gift.dart';
import '../services/auth_service_v2.dart';
import '../services/api_client.dart';

class UserNotifier extends StateNotifier<User?> {
  final AuthService authService;
  
  UserNotifier(this.authService) : super(null) {
    _loadUser();
  }

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _twoFactorKey = 'is2FAEnabled';
  static const double _platformCommission = 0.30; // 30% Platform cut

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    
    // If no user data is found in SharedPreferences, keep state as null
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
        role: userMap['role'] == 'artist' ? UserRole.artist : UserRole.user,
        balance: (userMap['balance'] ?? 0.0).toDouble(),
        avatarUrl: userMap['avatarUrl'],
      );
    } catch (e) {
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
    // TODO: Persist full user or sync to backend
  }

  void setRole(UserRole newRole) {
    if (state == null) return;
    state = state!.copyWith(role: newRole);
  }

  void addEarning(UserEarning earning) {
    if (state == null) return;
    final newEarnings = List<UserEarning>.from(state!.earnings)..add(earning);
    state = state!.copyWith(earnings: newEarnings, balance: state!.balance + earning.amount);
  }

  Future<bool> sendGift(Gift gift) async {
    if (state == null || state!.balance < gift.coinPrice) return false;

    // Deduct coins from sender
    state = state!.copyWith(balance: state!.balance - gift.coinPrice);
    
    // Logic for recipient (Simplified): 
    // Net value = Tsh Value * (1 - Commission)
    // In a real app, this would be an API call to update both users
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
    await authService.logout();
    state = null;
  }

  Future<void> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all app data
    await authService.logout();
    state = null;
  }

  /// Sign in with backend API
  Future<bool> signIn(String email, String password) async {
    try {
      final result = await authService.login(email: email, password: password);
      
      if (result['success'] == true && result['user'] != null) {
        final user = result['user'];
        final token = result['token'];
        
        // Store token securely
        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString(_tokenKey, token);
        }
        
        // Store minimal user data locally
        await prefs.setString(_userKey, jsonEncode({
          'id': user['id'] ?? '',
          'name': user['name'] ?? '',
          'username': user['username'] ?? '',
          'email': user['email'] ?? email,
          'role': user['role'] ?? 'user',
          'avatarUrl': user['avatarUrl'],
          'balance': (user['balance'] ?? 0.0).toDouble(),
        }));
        
        // Update state
        state = User(
          id: user['id'] ?? '',
          name: user['name'] ?? 'User',
          username: user['username'] ?? '',
          email: user['email'] ?? email,
          avatarUrl: user['avatarUrl'],
          role: (user['role'] ?? 'user').toString().toLowerCase().contains('artist') 
              ? UserRole.artist 
              : UserRole.user,
          balance: (user['balance'] ?? 0.0).toDouble(),
        );
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Sign up with backend API
  Future<bool> signUp(String name, String username, String email, String password) async {
    try {
      final result = await authService.register(
        email: email,
        password: password,
        name: name,
        role: 'ARTIST', // Default role
      );
      
      if (result['success'] == true && result['user'] != null) {
        final user = result['user'];
        final token = result['token'];
        
        // Store token securely
        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString(_tokenKey, token);
        }
        
        // Store minimal user data locally
        await prefs.setString(_userKey, jsonEncode({
          'id': user['id'] ?? '',
          'name': user['name'] ?? name,
          'username': user['username'] ?? username,
          'email': user['email'] ?? email,
          'role': user['role'] ?? 'ARTIST',
          'balance': 0.0,
        }));
        
        // Update state
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
      return false;
    } catch (e) {
      return false;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(apiClient: ApiClient());
});

final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UserNotifier(authService);
});

// Helper to get user or loading/error
final userAsyncProvider = FutureProvider<User>((ref) async {
  final user = ref.watch(userProvider);
  if (user != null) return user;
  await Future.delayed(const Duration(milliseconds: 500)); // simulate load
  
  // Safely return the user or throw a meaningful error if initialization fails
  final finalUser = ref.read(userProvider);
  if (finalUser == null) throw Exception('User data not initialized');
  return finalUser;
});
