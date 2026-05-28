import 'package:flutter/foundation.dart';

enum SubscriptionStatus { free, premium, pro }

enum UserRole { user, artist }

class UserEarning {
  const UserEarning({
    required this.type,
    required this.amount,
    required this.date,
  });

  final String type;
  final double amount;
  final DateTime date;
}

@immutable
class User {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final bool is2FAEnabled;
  final SubscriptionStatus subscriptionStatus;
  final int totalPlays;
  final List<String> favoriteGenres;
  final int playlistCount;
  final List<String> topTracks; // top 5 track titles
  final UserRole role;
  final double balance;
  final List<UserEarning> earnings;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.is2FAEnabled = false,
    this.subscriptionStatus = SubscriptionStatus.free,
    this.totalPlays = 0,
    this.favoriteGenres = const [],
    this.playlistCount = 0,
    this.topTracks = const [],
    this.role = UserRole.user,
    this.balance = 0.0,
    this.earnings = const [],
  });

  User copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
    bool? is2FAEnabled,
    SubscriptionStatus? subscriptionStatus,
    int? totalPlays,
    List<String>? favoriteGenres,
    int? playlistCount,
    List<String>? topTracks,
    UserRole? role,
    double? balance,
    List<UserEarning>? earnings,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      is2FAEnabled: is2FAEnabled ?? this.is2FAEnabled,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      totalPlays: totalPlays ?? this.totalPlays,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      playlistCount: playlistCount ?? this.playlistCount,
      topTracks: topTracks ?? this.topTracks,
      role: role ?? this.role,
      balance: balance ?? this.balance,
      earnings: earnings ?? this.earnings,
    );
  }
}
