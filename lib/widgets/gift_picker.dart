import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gift.dart';
import '../providers/app_providers.dart';

class GiftPickerGrid extends ConsumerStatefulWidget {
  final String streamId;
  final String receiverId;
  final VoidCallback? onGiftSent;

  const GiftPickerGrid({
    super.key,
    required this.streamId,
    required this.receiverId,
    this.onGiftSent,
  });

  @override
  ConsumerState<GiftPickerGrid> createState() => _GiftPickerGridState();
}

class _GiftPickerGridState extends ConsumerState<GiftPickerGrid> {
  late Future<List<dynamic>> giftsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch gifts from backend on init
    final giftService = ref.read(giftServiceProvider);
    giftsFuture = giftService.getAvailableGifts();
  }

  @override
  Widget build(BuildContext context) {
    final realtimeService = ref.watch(realtimeServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(child: Text('Send Gift', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                const Text('Balance: 1250', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: giftsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading gifts: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final gifts = snapshot.data ?? [];
                if (gifts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No gifts available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: gifts.length,
                  itemBuilder: (context, index) {
                    final gift = gifts[index];
                    final giftName = gift['name'] ?? 'Gift';
                    final giftPrice = gift['price']?.toDouble() ?? 0.0;
                    final giftAmount = gift['actualAmount']?.toDouble() ?? 0.0;
                    final giftIcon = gift['icon'] ?? '🎁';
                    final giftId = gift['id'] ?? '';

                    return GestureDetector(
                      onTap: () async {
                        try {
                          final result = await realtimeService.sendGift(
                            receiverId: widget.receiverId,
                            amount: giftAmount,
                            quantity: 1,
                            giftId: giftId,
                            streamId: widget.streamId,
                          );
                          if (result['success'] == true) {
                            if (widget.onGiftSent != null) widget.onGiftSent!();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sent $giftName! 🎁')),
                              );
                            }
                            if (context.mounted) Navigator.pop(context);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${result['message']}')),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              giftIcon.isNotEmpty ? giftIcon : '🎁',
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            giftName.length > 12 ? '${giftName.substring(0, 12)}...' : giftName,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '\$${giftPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void showGiftPicker(BuildContext context, {required String streamId, required String receiverId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => GiftPickerGrid(
        streamId: streamId,
        receiverId: receiverId,
      ),
    ),
  );
}
