import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer' as developer;

/// Offline caching service using Hive local database
/// Stores API responses, user data, and preferences for offline access
class CacheService {
  static const String _cacheBox = 'api_cache';
  static const String _userBox = 'user_data';
  static const String _settingsBox = 'settings';
  static const String _playlistsBox = 'playlists';
  static const String _tracksBox = 'liked_tracks';

  late Box<Map> _apiCacheBox;
  late Box<Map> _userDataBox;
  late Box<dynamic> _appSettingsBox;
  late Box<List> _userPlaylistsBox;
  late Box<List> _likedTracksBox;

  bool _initialized = false;

  /// Initialize cache boxes
  Future<void> initialize() async {
    try {
      _apiCacheBox = await Hive.openBox<Map>(_cacheBox);
      _userDataBox = await Hive.openBox<Map>(_userBox);
      _appSettingsBox = await Hive.openBox<dynamic>(_settingsBox);
      _userPlaylistsBox = await Hive.openBox<List>(_playlistsBox);
      _likedTracksBox = await Hive.openBox<List>(_tracksBox);

      _initialized = true;
      developer.log('Cache service initialized', name: 'CacheService');
    } catch (e) {
      developer.log('Cache initialization failed: $e', name: 'CacheService');
      rethrow;
    }
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw Exception('CacheService not initialized. Call initialize() first.');
    }
  }

  // ============ CACHE METHODS ============

  /// Cache API response with TTL
  Future<void> cacheData(
    String key,
    Map<String, dynamic> data, {
    Duration ttl = const Duration(hours: 24),
  }) async {
    _checkInitialized();

    try {
      final cacheEntry = Map<dynamic, dynamic>.from({
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(ttl).toIso8601String(),
      });

      await _apiCacheBox.put(key, cacheEntry);
      developer.log('Cached: $key', name: 'CacheService');
    } catch (e) {
      developer.log('Cache write failed: $e', name: 'CacheService');
    }
  }

  /// Retrieve cached data if not expired
  Map<String, dynamic>? getCachedData(String key) {
    _checkInitialized();

    try {
      final cached = _apiCacheBox.get(key);

      if (cached == null) {
        return null;
      }

      final expiresAt = DateTime.parse(cached['expiresAt'] as String);
      
      if (DateTime.now().isAfter(expiresAt)) {
        // Cache expired, remove it
        _apiCacheBox.delete(key);
        developer.log('Cache expired: $key', name: 'CacheService');
        return null;
      }

      return Map<String, dynamic>.from(cached['data'] as Map);
    } catch (e) {
      developer.log('Cache read failed: $e', name: 'CacheService');
      return null;
    }
  }

  /// Check if cache exists and is valid
  bool hasCachedData(String key) {
    _checkInitialized();
    return getCachedData(key) != null;
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    _checkInitialized();

    try {
      await _apiCacheBox.delete(key);
      developer.log('Cleared cache: $key', name: 'CacheService');
    } catch (e) {
      developer.log('Cache clear failed: $e', name: 'CacheService');
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    _checkInitialized();

    try {
      await _apiCacheBox.clear();
      developer.log('Cleared all cache', name: 'CacheService');
    } catch (e) {
      developer.log('Clear all cache failed: $e', name: 'CacheService');
    }
  }

  // ============ USER DATA METHODS ============

  /// Save user profile
  Future<void> saveUserProfile(Map<String, dynamic> user) async {
    _checkInitialized();

    try {
      await _userDataBox.put('profile', Map<dynamic, dynamic>.from(user));
      developer.log('Saved user profile', name: 'CacheService');
    } catch (e) {
      developer.log('User save failed: $e', name: 'CacheService');
    }
  }

  /// Get cached user profile
  Map<String, dynamic>? getUserProfile() {
    _checkInitialized();

    try {
      final user = _userDataBox.get('profile');
      if (user != null) {
        return Map<String, dynamic>.from(user);
      }
      return null;
    } catch (e) {
      developer.log('User read failed: $e', name: 'CacheService');
      return null;
    }
  }

  /// Clear user data
  Future<void> clearUserData() async {
    _checkInitialized();

    try {
      await _userDataBox.clear();
      developer.log('Cleared user data', name: 'CacheService');
    } catch (e) {
      developer.log('User data clear failed: $e', name: 'CacheService');
    }
  }

  // ============ LIKED TRACKS METHODS ============

  /// Add track to liked tracks
  Future<void> addLikedTrack(Map<String, dynamic> track) async {
    _checkInitialized();

    try {
      final likedTracks = _likedTracksBox.get('liked_tracks') ?? [];
      final tracks = List<dynamic>.from(likedTracks);

      // Avoid duplicates
      if (!tracks.any((t) => t['id'] == track['id'])) {
        tracks.add(track);
        await _likedTracksBox.put('liked_tracks', tracks);
        developer.log('Added liked track: ${track['id']}', name: 'CacheService');
      }
    } catch (e) {
      developer.log('Add liked track failed: $e', name: 'CacheService');
    }
  }

  /// Remove track from liked tracks
  Future<void> removeLikedTrack(String trackId) async {
    _checkInitialized();

    try {
      final likedTracks = _likedTracksBox.get('liked_tracks') ?? [];
      final tracks = List<dynamic>.from(likedTracks);

      tracks.removeWhere((t) => t['id'] == trackId);
      await _likedTracksBox.put('liked_tracks', tracks);
      developer.log('Removed liked track: $trackId', name: 'CacheService');
    } catch (e) {
      developer.log('Remove liked track failed: $e', name: 'CacheService');
    }
  }

  /// Get all liked tracks
  List<Map<String, dynamic>> getLikedTracks() {
    _checkInitialized();

    try {
      final likedTracks = _likedTracksBox.get('liked_tracks') ?? [];
      return List<Map<String, dynamic>>.from(
        likedTracks.cast<Map<dynamic, dynamic>>().map(
          (track) => Map<String, dynamic>.from(track),
        ),
      );
    } catch (e) {
      developer.log('Get liked tracks failed: $e', name: 'CacheService');
      return [];
    }
  }

  // ============ PLAYLIST METHODS ============

  /// Cache playlists
  Future<void> cachePlaylists(List<Map<String, dynamic>> playlists) async {
    _checkInitialized();

    try {
      await _userPlaylistsBox.put('playlists', playlists.cast<dynamic>());
      developer.log('Cached playlists', name: 'CacheService');
    } catch (e) {
      developer.log('Cache playlists failed: $e', name: 'CacheService');
    }
  }

  /// Get cached playlists
  List<Map<String, dynamic>> getCachedPlaylists() {
    _checkInitialized();

    try {
      final playlists = _userPlaylistsBox.get('playlists') ?? [];
      return List<Map<String, dynamic>>.from(
        playlists.cast<Map<dynamic, dynamic>>().map(
          (playlist) => Map<String, dynamic>.from(playlist),
        ),
      );
    } catch (e) {
      developer.log('Get cached playlists failed: $e', name: 'CacheService');
      return [];
    }
  }

  // ============ SETTINGS METHODS ============

  /// Save app setting
  Future<void> saveSetting(String key, dynamic value) async {
    _checkInitialized();

    try {
      await _appSettingsBox.put(key, value);
      developer.log('Saved setting: $key', name: 'CacheService');
    } catch (e) {
      developer.log('Setting save failed: $e', name: 'CacheService');
    }
  }

  /// Get app setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    _checkInitialized();

    try {
      final value = _appSettingsBox.get(key);
      if (value == null) return defaultValue;
      return value as T?;
    } catch (e) {
      developer.log('Setting read failed: $e', name: 'CacheService');
      return defaultValue;
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    _checkInitialized();

    try {
      return {
        'cacheSize': _apiCacheBox.length,
        'userDataSize': _userDataBox.length,
        'playlistsCount': getCachedPlaylists().length,
        'likedTracksCount': getLikedTracks().length,
        'settingsCount': _appSettingsBox.length,
      };
    } catch (e) {
      developer.log('Cache stats failed: $e', name: 'CacheService');
      return {};
    }
  }

  /// Clear all offline data
  Future<void> clearAllData() async {
    _checkInitialized();

    try {
      await _apiCacheBox.clear();
      await _userDataBox.clear();
      await _userPlaylistsBox.clear();
      await _likedTracksBox.clear();
      // Keep settings
      developer.log('Cleared all offline data', name: 'CacheService');
    } catch (e) {
      developer.log('Clear all data failed: $e', name: 'CacheService');
    }
  }
}
