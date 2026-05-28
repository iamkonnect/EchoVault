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
  @override
  Widget build(BuildContext context) {
    final gifts = Gift.inventory;
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
            child: GridView.builder(
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
                return GestureDetector(
                  onTap: () async {
                    try {
                      final result = await realtimeService.sendGift(
                        receiverId: widget.receiverId,
                        amount: gift.tshValue,
                        quantity: 1,
                        giftId: gift.id,
                        streamId: widget.streamId,
                      );
                      if (result['success'] == true) {
                        if (widget.onGiftSent != null) widget.onGiftSent!();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sent ${gift.nameKey}! 🎁')),
                          );
                        }
                        Navigator.pop(context);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${result['error']}')),
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
                          gift.iconPath.isNotEmpty ? '🎁' : '🎵', // Mock icons; use Image.asset(gift.iconPath) if assets exist
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gift.nameKey.split('gift').last.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${gift.coinPrice}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
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
