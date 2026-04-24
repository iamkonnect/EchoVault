import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/realtime_service.dart';

class MusicGift {
  final String id;
  final String name;
  final String icon;
  final double price;

  MusicGift({required this.id, required this.name, required this.icon, required this.price});
}

/// Example screen demonstrating the gift system (monetization)
/// This shows how to integrate gifts in live streams
class GiftStreamScreen extends ConsumerStatefulWidget {
  final String streamId;
  final String artistId;
  final String artistName;

  const GiftStreamScreen({
    required this.streamId,
    required this.artistId,
    required this.artistName,
    super.key,
  });

  @override
  ConsumerState<GiftStreamScreen> createState() => _GiftStreamScreenState();
}

class _GiftStreamScreenState extends ConsumerState<GiftStreamScreen> {
  late RealtimeService _realtimeService;
  final List<Map<String, dynamic>> _receivedGifts = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeRealtime();
  }

  Future<void> _initializeRealtime() async {
    try {
      // Get token from auth service
      final authService = ref.read(authServiceProvider);
      final token = authService.getToken();

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
        return;
      }

      _realtimeService = ref.read(realtimeServiceProvider);
      
      // Connect to WebSocket
      await _realtimeService.connect(token);
      
      // Join stream
      await _realtimeService.joinStream(widget.streamId);
      
      // Listen for incoming gifts
      _realtimeService.onGift('stream_gifts', (gift) {
        setState(() {
          _receivedGifts.insert(0, gift);
          // Keep only last 10 gifts visible
          if (_receivedGifts.length > 10) {
            _receivedGifts.removeLast();
          }
        });

        // Show animation/notification
        _showGiftNotification(gift);
      });

      setState(() => _isConnected = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  void _showGiftNotification(Map<String, dynamic> gift) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Auto-dismiss after 1.5 seconds
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });
        return AlertDialog(
          backgroundColor: Colors.purple.shade900,
          title: Text(
            '🎁 ${gift['senderName']} sent a gift!',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${gift['quantity']}x ${gift['giftId']}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+\$${gift['amount'].toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendGift(MusicGift gift) async {
    try {
      final result = await _realtimeService.sendGift(
        receiverId: widget.artistId,
        amount: gift.price,
        quantity: 1,
        giftId: gift.id,
        streamId: widget.streamId,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gift sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send gift: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(revenueProvider);
    
    final List<MusicGift> musicGifts = [
      MusicGift(id: 'mic_1', name: 'Golden Mic', icon: '🎤', price: 10.0),
      MusicGift(id: 'note_1', name: 'Music Note', icon: '🎵', price: 1.0),
      MusicGift(id: 'vinyl_1', name: 'Vintage Vinyl', icon: '💿', price: 5.0),
      MusicGift(id: 'guitar_1', name: 'Electric Lead', icon: '🎸', price: 15.0),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.artistName}\'s Stream'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: _isConnected
                  ? const Chip(
                      label: Text('🔴 Live'),
                      backgroundColor: Colors.red,
                      labelStyle: TextStyle(color: Colors.white),
                    )
                  : const Chip(
                      label: Text('Connecting...'),
                      backgroundColor: Colors.orange,
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video/Stream area (placeholder)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_camera_back, size: 64, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      'Live Stream Video',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recent gifts display
          if (_receivedGifts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gifts Received',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _receivedGifts.length,
                      itemBuilder: (context, index) {
                        final gift = _receivedGifts[index];
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Chip(
                            label: Text(
                              '${gift['senderName']}: +\$${gift['amount']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.purple.shade700,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Artist revenue info
          revenueAsync.when(
            data: (revenue) => Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRevenueCard('Total Earnings', '\$${revenue['totalEarnings'] ?? 0}'),
                  _buildRevenueCard('Wallet Balance', '\$${revenue['walletBalance'] ?? 0}'),
                  _buildRevenueCard('Today', '\$${revenue['todayEarnings'] ?? 0}'),
                ],
              ),
            ),
            loading: () => Container(
              padding: const EdgeInsets.all(12),
              child: const SizedBox(
                height: 60,
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => Container(
              padding: const EdgeInsets.all(12),
              child: Text('Error loading revenue: $err'),
            ),
          ),

          // Gift selection
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Send a Gift to ${widget.artistName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: musicGifts.length,
                    itemBuilder: (context, index) => MusicGiftCard(
                      gift: musicGifts[index],
                      onTap: () => _sendGift(musicGifts[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String label, String amount) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _realtimeService.disconnect();
    super.dispose();
  }
}

class MusicGiftCard extends StatelessWidget {
  final MusicGift gift;
  final VoidCallback onTap;

  const MusicGiftCard({required this.gift, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: Colors.grey[900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(gift.icon, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 4),
            Text(
              gift.name,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            Text(
              '\$${gift.price}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
