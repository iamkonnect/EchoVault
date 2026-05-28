import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSubscriptionTile(
            context,
            title: 'Artist Subscription',
            price: '\$4.99/mo',
            description: 'Support your favorite artist and get exclusive content.',
            icon: Icons.star,
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildSubscriptionTile(
            context,
            title: 'Premium Livestream',
            price: '\$9.99/mo',
            description: 'Access to exclusive high-quality live sessions.',
            icon: Icons.live_tv,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          _buildSubscriptionTile(
            context,
            title: 'Ad-Free Experience',
            price: '\$2.99/mo',
            description: 'Listen to music without interruptions.',
            icon: Icons.block,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTile(
    BuildContext context, {
    required String title,
    required String price,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Subscribe Now'),
            ),
          ],
        ),
      ),
    );
  }
}