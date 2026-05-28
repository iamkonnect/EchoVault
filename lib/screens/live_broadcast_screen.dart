import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../services/realtime_service.dart';
import '../providers/app_providers.dart';
import '../services/camera_service.dart';
import '../services/permission_service.dart';
import '../widgets/gift_picker.dart';
import '../../models/user.dart';

class LiveBroadcastScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> streamData;
  const LiveBroadcastScreen({super.key, required this.streamData});

  @override
  ConsumerState<LiveBroadcastScreen> createState() => _LiveBroadcastScreenState();
}

class _LiveBroadcastScreenState extends ConsumerState<LiveBroadcastScreen> {
  late CameraService _cameraService;
  RealtimeService? _realtimeService;
  late TextEditingController _chatController;
  Timer? _adTimer;
  bool _isStreaming = false;
  final int _viewerCount = 1245;
  final List<Map<String, dynamic>> _recentGifts = [];
  final List<Map<String, dynamic>> _recentMessages = [];
  bool _cameraReady = false;
  
  bool get isBroadcaster => widget.streamData['isBroadcaster'] ?? false;
  bool get isGuest => ref.watch(userProvider) == null;

  @override
  void initState() {
    super.initState();
    _chatController = TextEditingController();
    _cameraService = CameraService();
    _initializeCamera();
    _initializeRealtime();
    if (isGuest) {
      _adTimer = Timer(const Duration(seconds: 30), _showAdDialog);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      if (mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _initializeRealtime() async {
    try {
      _realtimeService = ref.read(realtimeServiceProvider);
      final user = ref.read(userProvider);
      final token = ref.read(authServiceProvider).getToken();
      if (token != null) {
        await _realtimeService!.connect(token);
        await _realtimeService!.joinStream(widget.streamData['id']);
        _realtimeService!.onGift('broadcast_gifts', (gift) {
          if (mounted) {
            setState(() {
              _recentGifts.insert(0, gift);
              if (_recentGifts.length > 10) _recentGifts.removeLast();
            });
          }
        });
        _realtimeService!.onChatMessage('broadcast_messages', (msg) {
          if (mounted) {
            setState(() {
              _recentMessages.insert(0, msg);
              if (_recentMessages.length > 50) _recentMessages.removeLast();
            });
          }
        });
        _realtimeService!.connectionState.listen((connected) {
          if (mounted) setState(() {});
        });
      } else if (isGuest) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Guest mode: Limited chat/gifts'),
          duration: Duration(seconds: 3),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Realtime error: $e')));
    }
  }

  Future<void> _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty || _realtimeService == null) return;
    try {
      final text = _chatController.text.trim();
      final user = ref.read(userProvider) ?? const User(
        id: 'guest',
        name: 'Guest',
        username: '@guest',
        email: 'guest@example.com',
      );
      
      final result = await _realtimeService!.sendChatMessage(
        text: text,
        streamId: widget.streamData['id'],
      );
      
      if (result['success']) {
        _chatController.clear();
        final mockMsg = {
          'text': text,
          'senderName': user.name,
          'senderId': user.id,
        };
        if (mounted) {
          setState(() {
            _recentMessages.insert(0, mockMsg);
            if (_recentMessages.length > 50) _recentMessages.removeLast();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    }
  }

  void _showGiftPicker() {
    showGiftPicker(
      context,
      streamId: widget.streamData['id'],
      receiverId: widget.streamData['hostId'] ?? 'demo_artist',
    );
  }

  void _showAdDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Sponsored Ad', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.yellow, size: 64),
            SizedBox(height: 16),
            Text('Upgrade to Premium for ad-free viewing!', style: TextStyle(color: Colors.white)),
            Text('Limited time offer!', style: TextStyle(color: Colors.yellow)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip (5s)', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium unlocked! 🎉')),
              );
            },
            child: const Text('Get Premium', style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStream() async {
    try {
      if (_isStreaming) {
        // Stop streaming
        final artistService = ref.read(artistServiceProvider);
        await _cameraService.stopRecording();
        await artistService.stopLiveStream(widget.streamData['id']);
        await _realtimeService?.leaveStream(widget.streamData['id']);
        
        if (mounted) {
          setState(() => _isStreaming = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stream ended'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Start streaming - request permissions first
        bool permissionsGranted = await PermissionService.requestCameraAndMicrophonePermissions();
        
        if (!permissionsGranted && !kIsWeb) {
          if (mounted) {
            _showPermissionDeniedDialog();
          }
          return;
        }

        if (kIsWeb) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎤 Requesting camera and microphone access...'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        
        await _cameraService.startRecording();
        
        if (mounted) {
          setState(() => _isStreaming = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Stream started - You\'re LIVE!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stream error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          '🔒 Permission Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Camera and microphone access is required to go live. Please enable these permissions in your app settings.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              PermissionService.openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streamId = widget.streamData['id'];
    final title = widget.streamData['title'];

    return Scaffold(
      appBar: AppBar(
        title: Text('$title ($_viewerCount viewers)'),
        backgroundColor: Colors.grey[900],
        actions: [
          if (isBroadcaster)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  _isStreaming ? '● LIVE' : 'Offline',
                  style: TextStyle(
                    color: _isStreaming ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          if (isBroadcaster)
            IconButton(
              icon: Icon(
                _isStreaming ? Icons.stop : Icons.play_arrow,
                color: _isStreaming ? Colors.red : Colors.green,
              ),
              onPressed: _toggleStream,
              tooltip: _isStreaming ? 'End Stream' : 'Go Live',
            ),
        ],
      ),
      floatingActionButton: !isBroadcaster && !isGuest
          ? FloatingActionButton(
              onPressed: _showGiftPicker,
              backgroundColor: Colors.purple,
              child: const Icon(Icons.card_giftcard, color: Colors.white),
            )
          : null,
      body: !isBroadcaster
          ? Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline, size: 128, color: Colors.white54),
                    SizedBox(height: 16),
                    Text('Live Stream', style: TextStyle(color: Colors.white54, fontSize: 24)),
                    Text('Waiting for video...', style: TextStyle(color: Colors.white38)),
                  ],
                ),
              ),
            )
          : !_cameraReady
              ? Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.purple),
                        SizedBox(height: 16),
                        Text(
                          'Initializing camera and microphone...',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Stream Preview
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                            child: _cameraService.getPreview(),
                          ),
                          if (_isStreaming)
                            Positioned(
                              top: 20,
                              right: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$_viewerCount viewers',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom panel: Chat + Gifts
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Viewer count & controls
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _InfoChip('Viewers', '$_viewerCount'),
                                _InfoChip('Gifts', '${_recentGifts.length}'),
                                _InfoChip('Messages', '${_recentMessages.length}'),
                              ],
                            ),
                          ),
                          // Recent gifts
                          if (_recentGifts.isNotEmpty)
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _recentGifts.length,
                                itemBuilder: (context, index) {
                                  final gift = _recentGifts[index];
                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.purple,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${gift['senderName']}: \$${gift['amount']}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          // Chat
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    reverse: true,
                                    itemCount: _recentMessages.length,
                                    itemBuilder: (context, index) {
                                      final msg = _recentMessages[_recentMessages.length - 1 - index];
                                      return ListTile(
                                        title: Text(
                                          msg['text'] ?? '',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        subtitle: Text(
                                          msg['senderName'] ?? '',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.grey[800]),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _chatController,
                                          onSubmitted: (_) => _sendChatMessage(),
                                          decoration: const InputDecoration(
                                            hintText: 'Chat with viewers...',
                                            border: InputBorder.none,
                                            hintStyle: TextStyle(color: Colors.white54),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.send, color: Colors.purple),
                                        onPressed: _sendChatMessage,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _InfoChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _chatController.dispose();
    _cameraService.dispose(); // This is a Future but called in dispose - OK
    _realtimeService?.disconnect();
    super.dispose();
  }
}
