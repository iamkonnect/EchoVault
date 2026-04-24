import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';

class InsightsSection extends ConsumerWidget {
  const InsightsSection({super.key});

  Map<String, double> _computeTotals(List<UserEarning> earnings, {String? filter}) {
    final map = <String, double>{};
    final filtered = filter == null ? earnings : earnings.where((e) => e.type.contains(filter)).toList();
    for (final e in filtered) {
      map[e.type] = (map[e.type] ?? 0) + e.amount;
    }
    return map;
  }

  List<double> _getTrendData(List<UserEarning> earnings, {int days = 7}) {
    final now = DateTime.now();
    final trend = List<double>.filled(days, 0);
    for (final e in earnings) {
      final daysAgo = now.difference(e.date).inDays;
      if (daysAgo < days) {
        trend[daysAgo] += e.amount;
      }
    }
    return trend.reversed.toList(); // Recent first
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(userProvider);
    if (user == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final isArtist = user.role == UserRole.artist;
    final themeColor = isArtist ? Colors.green : Colors.purple;
    final sectionTitle = isArtist ? 'Artist Insights' : 'Listener Insights';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.insights, color: themeColor, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sectionTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isArtist ? 'Artist Dashboard' : 'Your Habits',
                      style: TextStyle(
                        color: themeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Role-specific content
          if (isArtist) ...[
            // Artist: Balance + Revenue Breakdown
            _BalanceCard(balance: user.balance, themeColor: themeColor),
            const SizedBox(height: 20),
            _BreakdownCard(
              title: 'Revenue Sources',
              totals: _computeTotals(user.earnings),
              earnings: user.earnings,
              themeColor: themeColor,
            ),
            const SizedBox(height: 20),
            _TrendCard(
              title: '7-Day Earnings Trend',
              data: _getTrendData(user.earnings),
              themeColor: themeColor,
            ),
          ] else ...[
            // Listener: Stats Grid
            _ListenerStatsGrid(user: user, themeColor: themeColor),
            const SizedBox(height: 20),
            _GenresCard(genres: user.favoriteGenres, themeColor: themeColor),
            const SizedBox(height: 20),
            _TopTracksCard(tracks: user.topTracks),
          ],
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final Color themeColor;

  const _BalanceCard({required this.balance, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Available Balance',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 12,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (balance / 5000).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [themeColor.withValues(alpha: 0.4), themeColor]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Payout goal: \$5,000',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ListenerStatsGrid extends StatelessWidget {
  final User user;
  final Color themeColor;

  const _ListenerStatsGrid({required this.user, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatItem(icon: Icons.play_circle, label: 'Total Plays', value: user.totalPlays.toString()),
      StatItem(icon: Icons.queue_music, label: 'Playlists', value: user.playlistCount.toString()),
      StatItem(icon: Icons.favorite, label: 'Genres', value: user.favoriteGenres.length.toString()),
      const StatItem(icon: Icons.trending_up, label: 'Avg Session', value: '2h 45m'),
    ];

    return _SectionCard(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(stat.icon, color: themeColor, size: 32),
                const SizedBox(height: 8),
                Text(stat.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(stat.label, style: TextStyle(color: Colors.grey[400]!, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StatItem {
  final IconData icon;
  final String label;
  final String value;

  const StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _GenresCard extends StatelessWidget {
  final List<String> genres;
  final Color themeColor;

  const _GenresCard({required this.genres, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Favorite Genres',
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: genres.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [themeColor.withValues(alpha: 0.3), themeColor.withValues(alpha: 0.1)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  genres[index],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopTracksCard extends StatelessWidget {
  final List<String> tracks;

  const _TopTracksCard({required this.tracks});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Top Tracks This Week',
      child: Column(
        children: tracks.take(5).map((track) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 20),
          ),
          title: Text(track, style: const TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () => _showTrackDetails(context, track),
        )).toList(),
      ),
    );
  }

  void _showTrackDetails(BuildContext context, String track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(track, style: const TextStyle(color: Colors.white)),
        content: Text('Play count: 1,247 • Added to 5 playlists', style: TextStyle(color: Colors.grey[400])),

        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final Map<String, double> totals;
  final List<UserEarning> earnings;
  final Color themeColor;

  const _BreakdownCard({
    required this.title,
    required this.totals,
    required this.earnings,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const BreakdownItem(type: 'song_plays', label: 'Song Plays', icon: Icons.music_note, color: Colors.purple),
      const BreakdownItem(type: 'gifts', label: 'Gifts', icon: Icons.favorite, color: Colors.red),
      const BreakdownItem(type: 'live_stream', label: 'Live', icon: Icons.live_tv, color: Colors.green),
      const BreakdownItem(type: 'shorts_views', label: 'Shorts', icon: Icons.video_file, color: Colors.blue),
    ];

    return _SectionCard(
      title: title,
      child: Column(
        children: items.map((item) {
          final amount = totals[item.type] ?? 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.label, style: const TextStyle(color: Colors.white)),
                ),
                Text('\$${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BreakdownItem {
  final String type;
  final String label;
  final IconData icon;
  final Color color;

  const BreakdownItem({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _TrendCard extends StatelessWidget {
  final String title;
  final List<double> data;
  final Color themeColor;

  const _TrendCard({
    required this.title,
    required this.data,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: CustomPaint(
              painter: SparklinePainter(data, themeColor),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TrendLabel('+\$${data.last.toStringAsFixed(1)}', Colors.green),
              const _TrendLabel('+12%', Colors.green),
              _TrendLabel('Avg \$45/day', Colors.grey[400]!),

            ],
          ),
        ],
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final range = max - min > 0 ? max - min : 1;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedY = (max - data[i]) / range;
      final y = size.height * normalizedY;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // Fill below line
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TrendLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _TrendLabel(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final String? title;

  const _SectionCard({required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: title != null ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      child: title != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                child,
              ],
            )
          : child,
    );
  }
}
