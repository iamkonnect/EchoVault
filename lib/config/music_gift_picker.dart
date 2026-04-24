import 'package:flutter/material.dart';

class MusicGift {
  final String id;
  final String name;
  final String icon;
  final double price;

  MusicGift({required this.id, required this.name, required this.icon, required this.price});
}

class MusicGiftPicker extends StatelessWidget {
  final String targetId; // ID of the Song, Short, or Stream
  final String targetType; // 'SONG', 'SHORT', or 'STREAM'
  final List<MusicGift> gifts; // Now passed from a FutureBuilder or Provider

  const MusicGiftPicker({super.key, required this.targetId, required this.targetType, required this.gifts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 250,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return InkWell(
            onTap: () {
              // Sending context to backend: Who gets the split?
              print('ACTION: Sending ${gift.name} (\$${gift.price}) to $targetType ($targetId)');
              // API Call would happen here
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(gift.icon, style: const TextStyle(fontSize: 32)),
                Text(gift.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text('\$${gift.price}', style: const TextStyle(fontSize: 10, color: Colors.green)),
              ],
            ),
          );
        },
      ),
    );
  }
}