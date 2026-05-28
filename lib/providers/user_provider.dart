import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/gift.dart';

class UserNotifier extends StateNotifier<User?> {
  UserNotifier() : super(null) {
    _loadUser();
  }

  static const String _userKey = 'user_data';
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
      // Since the User model doesn't have a fromJson yet, 
      // we reconstruct the session user with default/saved values
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
    state = null;
  }

  Future<void> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all app data
    state = null;
    // TODO: Call API to deactivate account if backend exists
  }

  Future<bool> signIn(String identifier, String password) async {
    // Dummy auth - simulate network
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if ((identifier == 'akwera@gmail.com' || identifier == '@akwera') && password == '1234Abc!') {
      state = User(
        id: 'demo_user_1',
        name: 'Akwera Jr',
        username: identifier.startsWith('@') ? identifier : '@akwera',
        email: identifier.contains('@') && !identifier.startsWith('@') ? identifier : 'akwera@gmail.com',
        avatarUrl: 'https://ui-avatars.com/api/?name=Akwera+Jr&background=0D8ABC&color=fff',
        bio: 'Music enthusiast exploring Echo Realms 🌌',
        is2FAEnabled: false,
        subscriptionStatus: SubscriptionStatus.free,
        totalPlays: 12456,
        favoriteGenres: const ['Afro Jazz', 'Amapiano', 'Hip Hop'],
        playlistCount: 12,
        topTracks: const [
          'Bwana Atawapigania',
          'Halleluyah',
          'Echo Afro Jazz Sunset',
          'Echo Amapiano Nights',
          'Echo Bongo Flavour Mix',
        ],
        role: UserRole.artist,
        balance: 1250.50,
        earnings: [
          UserEarning(type: 'song_plays', amount: 245.00, date: DateTime.now().subtract(const Duration(days: 1))),
          UserEarning(type: 'gifts', amount: 50.00, date: DateTime.now().subtract(const Duration(days: 2))),
          UserEarning(type: 'live_stream', amount: 100.00, date: DateTime.now().subtract(const Duration(days: 3))),
          UserEarning(type: 'shorts_views', amount: 20.00, date: DateTime.now().subtract(const Duration(days: 4))),
          UserEarning(type: 'song_plays', amount: 180.50, date: DateTime.now().subtract(const Duration(days: 5))),
          UserEarning(type: 'gifts', amount: 75.00, date: DateTime.now().subtract(const Duration(days: 7))),
          UserEarning(type: 'live_stream', amount: 150.00, date: DateTime.now().subtract(const Duration(days: 10))),
          UserEarning(type: 'shorts_views', amount: 30.00, date: DateTime.now().subtract(const Duration(days: 12))),
        ],
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode({
        'id': state!.id,
        'email': state!.email,
        'loggedIn': true,
      }));
      return true;
    }
    return false;
  }

  Future<bool> signUp(String name, String username, String email, String password) async {
    // Dummy signup
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Basic validation
    if (password.length < 6) return false;
    
    state = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      username: username.startsWith('@') ? username : '@$username',
      email: email,
      avatarUrl: 'https://ui-avatars.com/api/?name=${name.replaceAll(' ', '+')}&background=0D8ABC&color=fff',
      bio: 'New to EchoVault',
      is2FAEnabled: false,
      subscriptionStatus: SubscriptionStatus.free,
      totalPlays: 0,
      favoriteGenres: const [],
      playlistCount: 0,
      topTracks: const [],
      role: UserRole.user,
      balance: 0.0,
      earnings: const [],
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode({
      'id': state!.id,
      'name': state!.name,
      'email': state!.email,
      'loggedIn': true,
    }));
    return true;
  }
}

final userProvider =
    StateNotifierProvider<UserNotifier, User?>((ref) => UserNotifier());

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
