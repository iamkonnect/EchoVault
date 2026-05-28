import 'package:flutter/material.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Album Art Placeholder
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.music_note, size: 100),
          ),
          const SizedBox(height: 40),
          const Text(
            'Track Title',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Artist Name',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 40),
                onPressed: () {},
              ),
              const SizedBox(width: 20),
              CircleAvatar(
                radius: 35,
                child: IconButton(
                  icon: const Icon(Icons.play_arrow, size: 40),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 40),
                onPressed: () {},
              ),
            ],
          ),
          const Slider(value: 0.3, onChanged: null),
        ],
      ),
    );
  }
}