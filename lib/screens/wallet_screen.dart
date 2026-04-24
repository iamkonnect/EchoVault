import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(userProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: () async {
                // Simulate refresh
                await Future.delayed(const Duration(milliseconds: 1000));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _BalanceHeader(user: user),
                    const SizedBox(height: 32),
                    if (user.role == UserRole.artist) ...[
                      _RevenueBreakdown(user: user),
                      const SizedBox(height: 24),
                      _RecentEarnings(user: user),
                    ] else ...[
                      _RewardsBreakdown(user: user),
                      const SizedBox(height: 24),
                      _RecentRewards(user: user),
                    ],
                    const SizedBox(height: 24),
                    _ActionButtons(user: user),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  final User user;

  const _BalanceHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, size: 32, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    user.role == UserRole.artist ? 'Artist Wallet' : 'Listener Rewards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.role == UserRole.artist ? Colors.green : Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role == UserRole.artist ? 'Artist' : 'Listener',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '\$${user.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          Text(
            '+${(user.earnings.fold<double>(0, (sum, e) => sum + e.amount) * 0.05).toStringAsFixed(2)} this month',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

Map<String, double> _computeTotals(List<UserEarning> earnings) {
  final map = <String, double>{};
  for (final e in earnings) {
    map[e.type] = (map[e.type] ?? 0) + e.amount;
  }
  return map;
}

class _RevenueBreakdown extends StatelessWidget {
  final User user;

  const _RevenueBreakdown({required this.user});

  @override
  Widget build(BuildContext context) {
    final totals = _computeTotals(user.earnings);
    return _SectionCard(
      title: 'Revenue Breakdown',
      children: [
        _BreakdownRow(icon: Icons.music_note, label: 'Song Plays', amount: totals['song_plays'] ?? 0, color: Colors.purple),
        _BreakdownRow(icon: Icons.favorite, label: 'Gifts', amount: totals['gifts'] ?? 0, color: Colors.red),
        _BreakdownRow(icon: Icons.live_tv, label: 'Live Streams', amount: totals['live_stream'] ?? 0, color: Colors.green),
        _BreakdownRow(icon: Icons.video_file, label: 'Shorts', amount: totals['shorts_views'] ?? 0, color: Colors.blue),
      ],
    );
  }
}

class _RewardsBreakdown extends StatelessWidget {
  final User user;

  const _RewardsBreakdown({required this.user});

  @override
  Widget build(BuildContext context) {
    final totals = _computeTotals(user.earnings.where((e) => e.type.contains('reward') || e.type == 'watch_time').toList());
    return _SectionCard(
      title: 'Rewards Earned',
      children: [
        _BreakdownRow(icon: Icons.play_circle, label: 'Music Streams', amount: totals['stream_reward'] ?? 0, color: Colors.purple),
        _BreakdownRow(icon: Icons.video_file, label: 'Shorts Challenges', amount: totals['shorts_challenge'] ?? 0, color: Colors.orange),
        _BreakdownRow(icon: Icons.video_library, label: 'Video Watches', amount: totals['video_reward'] ?? 0, color: Colors.teal),
        _BreakdownRow(icon: Icons.live_tv, label: 'Live Views', amount: totals['live_view'] ?? 0, color: Colors.amber),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Upgrade to Artist to unlock more earning opportunities!', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
      ],
    );
  }
}

class _RecentEarnings extends StatelessWidget {
  final User user;

  const _RecentEarnings({required this.user});

  @override
  Widget build(BuildContext context) {
    final recent = user.earnings.reversed.take(10).toList();
    return _SectionCard(
      title: 'Recent Earnings',
      children: [
        ...recent.map((e) => ListTile(
              leading: Icon(_getTypeIcon(e.type), color: Colors.grey[400]),
              title: Text(e.type.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Colors.white)),
              subtitle: Text('${e.date.day}/${e.date.month} • +\$ ${e.amount.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[400])),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              onTap: () {},
            )),
        if (recent.length < user.earnings.length)
          ListTile(
            title: Text('View all (${user.earnings.length})', style: TextStyle(color: Colors.grey[400])),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400]!),
            onTap: () {},
          ),
      ],
    );
  }
}

class _RecentRewards extends StatelessWidget {
  final User user;

  const _RecentRewards({required this.user});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent Rewards',
      children: [
        ...user.earnings.reversed.take(5).map((e) => ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text('Reward from ${e.type}', style: const TextStyle(color: Colors.white)),
              subtitle: Text('${e.date.day}/${e.date.month} • +\$ ${e.amount.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[400])),
            )),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final User user;

  const _ActionButtons({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.account_balance_wallet),
            label: Text(user.role == UserRole.artist ? 'Request Payout' : 'Claim Rewards'),
            onPressed: () {
              // TODO: Integrate payout
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payout processed! (mock)')),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[400],
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.history),
            label: const Text('Transaction History'),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

IconData _getTypeIcon(String type) {
  final icons = {
    'song_plays': Icons.music_note,
    'gifts': Icons.favorite,
    'live_stream': Icons.live_tv,
    'shorts_views': Icons.video_file,
  };
  return icons[type] ?? Icons.monetization_on;
}

class _BreakdownRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  const _BreakdownRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(
                  '\$${amount.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
