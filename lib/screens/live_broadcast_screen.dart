import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../providers/user_provider.dart';
import '../services/realtime_service.dart';
import '../providers/app_providers.dart';
import '../widgets/gift_picker.dart';
import '../../models/user.dart';

class LiveBroadcastScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> streamData;
  const LiveBroadcastScreen({super.key, required this.streamData});

  @override
  ConsumerState<LiveBroadcastScreen> createState() => _LiveBroadcastScreenState();
}

class _LiveBroadcastScreenState extends ConsumerState<LiveBroadcastScreen> {
  CameraController? _cameraController;
  RealtimeService? _realtimeService;
  late TextEditingController _chatController;
  Timer? _adTimer;
  bool _isStreaming = false;
  final int _viewerCount = 0;
  final List<Map<String, dynamic>> _recentGifts = [];
  final List<Map<String, dynamic>> _recentMessages = [];
  bool get isBroadcaster => widget.streamData['isBroadcaster'] ?? false;
  bool get isGuest => ref.watch(userProvider) == null;

  @override
  void initState() {
    super.initState();
    _chatController = TextEditingController();
    _initializeCamera();
    _initializeRealtime();
    if (isGuest) {
      _adTimer = Timer(const Duration(seconds: 30), _showAdDialog);
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await _cameraController!.initialize();
    setState(() {});
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
          setState(() {
            _recentGifts.insert(0, gift);
            if (_recentGifts.length > 10) _recentGifts.removeLast();
          });
        });
        _realtimeService!.onChatMessage('broadcast_messages', (msg) {
          setState(() {
            _recentMessages.insert(0, msg);
            if (_recentMessages.length > 50) _recentMessages.removeLast();
          });
        });
        _realtimeService!.connectionState.listen((connected) {
          setState(() {});
        });
      } else if (isGuest) {
        // Guest: no realtime, but can see mock
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guest mode: Limited chat/gifts'), duration: Duration(seconds: 3)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Realtime error: $e')));
    }
  }

  Future<void> _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty || _realtimeService == null) return;
    try {
      final text = _chatController.text.trim();
      final user = ref.read(userProvider) ?? const User(id: 'guest', name: 'Guest', username: '@guest', email: 'guest@example.com');
      final result = await _realtimeService!.sendChatMessage(
        text: text,
        streamId: widget.streamData['id'],
      );
      if (result['success']) {
        _chatController.clear();
        // Mock local echo
        final mockMsg = {
          'text': text,
          'senderName': user.name,
          'senderId': user.id,
        };
        setState(() {
          _recentMessages.insert(0, mockMsg);
          if (_recentMessages.length > 50) _recentMessages.removeLast();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    }
  }

  void _showGiftPicker() {
    showGiftPicker(context, streamId: widget.streamData['id'], receiverId: widget.streamData['hostId'] ?? 'demo_artist');
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
            onPressed: () {
              Navigator.pop(context);
              // Mock skip after 5s, but instant for demo
            },
            child: const Text('Skip (5s)', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Mock upgrade
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premium unlocked! 🎉')));
            },
            child: const Text('Get Premium', style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStream() async {
    if (_isStreaming) {
      // Stop stream
      final artistService = ref.read(artistServiceProvider);
      await artistService.stopLiveStream(widget.streamData['id']);
      await _realtimeService?.leaveStream(widget.streamData['id']);
      _isStreaming = false;
    } else {
      // Start streaming (mock)
      _isStreaming = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final streamId = widget.streamData['id'];
    final title = widget.streamData['title'];
    final hostId = widget.streamData['hostId'] ?? 'demo';

    return Scaffold(
      appBar: AppBar(
        title: Text('$title ($_viewerCount viewers)'),
        actions: [
          if (isBroadcaster)
            IconButton(
              icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow, color: _isStreaming ? Colors.red : Colors.green),
              onPressed: _toggleStream,
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
          : _cameraController != null && _cameraController!.value.isInitialized
            ? Column(
              children: [
                // Camera Preview (broadcaster only)
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        child: CameraPreview(_cameraController!),
                      ),
                      if (_isStreaming)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Text('$_viewerCount viewers', style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom panel: chat + gifts
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Viewer count & controls
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
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
                                  decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(20)),
                                  child: Text('${gift['senderName']}: \$${gift['amount']}', style: const TextStyle(color: Colors.white)),
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
                                itemCount: _recentMessages.length,
                                itemBuilder: (context, index) {
                                  final msg = _recentMessages[index];
                                  return ListTile(
                                    title: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white)),
                                    subtitle: Text(msg['senderName'] ?? '', style: const TextStyle(color: Colors.grey)),
                                  );
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.grey),
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
                                      ),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send, color: Colors.white),
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
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _InfoChip(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _chatController.dispose();
    _cameraController?.dispose();
    _realtimeService?.disconnect();
    super.dispose();
  }
}

