import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';
import 'dart:async';
import 'dart:developer' as developer;

typedef GiftCallback = void Function(Map<String, dynamic> gift);
typedef MessageCallback = void Function(Map<String, dynamic> message);
typedef NotificationCallback = void Function(Map<String, dynamic> notification);
typedef StreamCallback = void Function(Map<String, dynamic> data);

/// Real-time WebSocket service for EchoVault
/// Handles live streams, gifts, chat, and notifications
class RealtimeService {
  late IO.Socket _socket;
  final String baseUrl;
  String? _token;
  bool _isConnected = false;

  RealtimeService({required this.baseUrl});

  // Callbacks
  final Map<String, List<GiftCallback>> _giftCallbacks = {};
  final Map<String, List<MessageCallback>> _messageCallbacks = {};
  final Map<String, List<NotificationCallback>> _notificationCallbacks = {};
  final Map<String, List<StreamCallback>> _streamCallbacks = {};

  // Stream controllers
  final _connectionStateController = StreamController<bool>.broadcast();
  final _giftController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  Stream<bool> get connectionState => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get gifts => _giftController.stream;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;
  bool get isConnected => _isConnected;



  /// Initialize WebSocket connection
  Future<void> connect(String token) async {
    try {
      _token = token;

      _socket = IO.io(
        baseUrl,
        OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .build(),
      );

      // Connection listeners
      _socket.onConnect((_) {
        _isConnected = true;
        _connectionStateController.add(true);
        developer.log('Socket connected: ${_socket.id}', name: 'RealtimeService');
      });

      _socket.onDisconnect((_) {
        _isConnected = false;
        _connectionStateController.add(false);
        developer.log('Socket disconnected', name: 'RealtimeService');
      });

      _socket.onError((data) {
        developer.log('Socket error: $data', name: 'RealtimeService');
      });

      // Register event listeners
      _setupEventListeners();

      // Connect
      _socket.connect();

      // Wait for connection
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      developer.log('Connection failed: $e', name: 'RealtimeService');
      rethrow;
    }
  }

  void _setupEventListeners() {
    // ============ GIFT EVENTS ============
    _socket.on('newGift', (data) {
      final gift = Map<String, dynamic>.from(data);
      _giftController.add(gift);
      _triggerCallbacks(_giftCallbacks, gift);
      developer.log('Received gift: ${gift['senderName']} sent ${gift['quantity']}x',
          name: 'RealtimeService');
    });

    _socket.on('giftReceived', (data) {
      final gift = Map<String, dynamic>.from(data);
      _giftController.add(gift);
      _triggerCallbacks(_giftCallbacks, gift);
      developer.log('Gift received: ${gift['senderName']}', name: 'RealtimeService');
    });

    // ============ STREAM EVENTS ============
    _socket.on('userJoinedStream', (data) {
      final streamData = Map<String, dynamic>.from(data);
      _streamCallbacks['userJoined']?.forEach((cb) => cb(streamData));
    });

    _socket.on('userLeftStream', (data) {
      final streamData = Map<String, dynamic>.from(data);
      _streamCallbacks['userLeft']?.forEach((cb) => cb(streamData));
    });

    // ============ CHAT EVENTS ============
    _socket.on('newChatMessage', (data) {
      final message = Map<String, dynamic>.from(data);
      _messageController.add(message);
      _triggerCallbacks(_messageCallbacks, message);
    });

    _socket.on('newDirectMessage', (data) {
      final message = Map<String, dynamic>.from(data);
      _messageController.add(message);
      _triggerCallbacks(_messageCallbacks, message);
    });

    // ============ NOTIFICATION EVENTS ============
    _socket.on('notification', (data) {
      final notification = Map<String, dynamic>.from(data);
      _notificationController.add(notification);
      _triggerCallbacks(_notificationCallbacks, notification);
    });
  }

  void _triggerCallbacks<T>(Map<String, List<Function>> callbacks, T data) {
    callbacks.forEach((_, callbackList) {
      for (var callback in callbackList) {
        try {
          callback(data);
        } catch (e) {
          developer.log('Callback error: $e', name: 'RealtimeService');
        }
      }
    });
  }

  // ============ STREAM METHODS ============

  /// Join a live stream
  Future<Map<String, dynamic>> joinStream(String streamId) async {
    if (!_isConnected) {
      throw Exception('Not connected to server');
    }

    return _emitAndWait('joinStream', streamId);
  }

  /// Leave a live stream
  Future<Map<String, dynamic>> leaveStream(String streamId) async {
    if (!_isConnected) {
      throw Exception('Not connected to server');
    }

    return _emitAndWait('leaveStream', streamId);
  }

  // ============ GIFT METHODS (MAIN INCOME SOURCE) ============

  /// Send a gift to a user in stream or directly
  /// This is the core monetization feature for artists
  Future<Map<String, dynamic>> sendGift({
    required String receiverId,
    required double amount,
    required int quantity,
    String? giftId,
    String? streamId,
  }) async {
    if (!_isConnected) {
      throw Exception('Not connected to server');
    }

    final giftData = {
      'receiverId': receiverId,
      'amount': amount,
      'quantity': quantity,
      if (giftId != null) 'giftId': giftId,
      if (streamId != null) 'streamId': streamId,
    };

    return _emitAndWait('sendGift', giftData);
  }

  /// Get available gifts for purchase
  Future<List<Map<String, dynamic>>> getAvailableGifts() async {
    if (!_isConnected) {
      throw Exception('Not connected to server');
    }

    final response = await _emitAndWait('getAvailableGifts', {});
    final gifts = response['gifts'] as List?;
    return gifts?.cast<Map<String, dynamic>>() ?? [];
  }

  // ============ CHAT METHODS ============

  /// Send a chat message in a stream or direct message
  Future<Map<String, dynamic>> sendChatMessage({
    required String text,
    String? streamId,
    String? receiverId,
  }) async {
    if (!_isConnected) {
      throw Exception('Not connected to server');
    }

    if (streamId == null && receiverId == null) {
      throw Exception('Either streamId or receiverId must be provided');
    }

    final messageData = {
      'text': text,
      if (streamId != null) 'streamId': streamId,
      if (receiverId != null) 'receiverId': receiverId,
    };

    return _emitAndWait('sendChatMessage', messageData);
  }

  /// Unified method to send a message
  Future<Map<String, dynamic>> sendMessage(String recipientId, String content, {bool isGroup = false}) async {
    if (!_isConnected) throw Exception('Not connected to server');

    final messageData = {
      'text': content,
      if (isGroup) 'streamId': recipientId else 'receiverId': recipientId,
    };

    return _emitAndWait('sendChatMessage', messageData);
  }

  /// Listen for chat messages
  void onChatMessage(String key, MessageCallback callback) {
    _messageCallbacks.putIfAbsent(key, () => []).add(callback);
  }

  /// Listen for gifts
  void onGift(String key, GiftCallback callback) {
    _giftCallbacks.putIfAbsent(key, () => []).add(callback);
  }

  /// Listen for notifications
  void onNotification(String key, NotificationCallback callback) {
    _notificationCallbacks.putIfAbsent(key, () => []).add(callback);
  }

  // ============ PRIVATE METHODS ============

  Future<Map<String, dynamic>> _emitAndWait(String event, dynamic data) {
    final completer = Completer<Map<String, dynamic>>();

      _socket.emitWithAck(event, data, ack: (response) {
        if (response is Map) {
          completer.complete(Map<String, dynamic>.from(response));
        } else {
          completer.completeError(Exception('Invalid response: $response'));
        }
      });

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Event timeout: $event');
      },
    );
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
      _connectionStateController.add(false);
      developer.log('Socket disconnected manually', name: 'RealtimeService');
    }
  }

  /// Cleanup resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _giftController.close();
    _messageController.close();
    _notificationController.close();
  }
}
