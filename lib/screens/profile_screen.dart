import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(userProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
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
                            const SizedBox(height: 60),
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.username,
                              style: const TextStyle(
                                  fontSize: 16, color: Color(0xFF9E9E9E)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _StatCard('Total Plays',
                                    (user.totalPlays ?? 0).toString()),
                                const SizedBox(width: 24),
                                _StatCard('Playlists',
                                    (user.playlistCount ?? 0).toString()),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 24,
                        child: GestureDetector(
                          onTap: () {},
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: user.avatarUrl != null
                                    ? AssetImage(user.avatarUrl!)
                                    : null,
                                backgroundColor: Colors.grey[800],
                                child: user.avatarUrl == null
                                    ? const Icon(Icons.person,
                                        size: 50, color: Colors.white70)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400]!,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _SectionCard(
                    title: 'Account',
                    children: [
                      ListTile(
                        leading: Icon(Icons.email, color: Colors.grey[400]!),
                        title: const Text('Email',
                            style: TextStyle(color: Colors.white)),
                        subtitle: Text(user.email,
                            style: const TextStyle(color: Color(0xFF9E9E9E))),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Color(0xFF9E9E9E)),
                        onTap: () {},
                      ),
                      SwitchListTile.adaptive(
                        secondary:
                            Icon(Icons.security, color: Colors.grey[400]!),
                        title: const Text('Two-Factor Authentication',
                            style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Extra security layer',
                            style: TextStyle(color: Color(0xFF9E9E9E))),
                        value: user.is2FAEnabled ?? false,
                        activeColor: Colors.grey[400]!,
                        onChanged: (value) {
                          ref.read(userProvider.notifier).toggle2FA();
                        },
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: 'Subscription',
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.star,
                          color:
                              user.subscriptionStatus == SubscriptionStatus.free
                                  ? Colors.grey
                                  : Colors.grey[400]!,
                        ),
                        title: Text(
                          user.subscriptionStatus == SubscriptionStatus.free
                              ? 'Free'
                              : user.subscriptionStatus ==
                                      SubscriptionStatus.premium
                                  ? 'Premium'
                                  : 'Pro',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          user.subscriptionStatus == SubscriptionStatus.free
                              ? 'Unlimited skips, no ads'
                              : user.subscriptionStatus ==
                                      SubscriptionStatus.premium
                                  ? 'Offline downloads, HD audio'
                                  : 'Everything + exclusive content',
                          style: const TextStyle(color: Color(0xFF9E9E9E)),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400]!,
                            foregroundColor: Colors.white,
                          ),
                          onPressed:
                              user.subscriptionStatus == SubscriptionStatus.pro
                                  ? null
                                  : () {},
                          child: Text(
                              user.subscriptionStatus == SubscriptionStatus.pro
                                  ? 'Pro'
                                  : 'Upgrade'),
                        ),
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: 'Role',
                    children: [
                      SwitchListTile.adaptive(
                        secondary:
                            Icon(Icons.music_note, color: Colors.grey[400]!),
                        title: const Text('Artist Mode',
                            style: TextStyle(color: Colors.white)),
                        subtitle: const Text(
                            'Toggle to view artist wallet / listener rewards',
                            style: TextStyle(color: Color(0xFF9E9E9E))),
                        value: user.role == UserRole.artist,
                        activeColor: Colors.green,
                        onChanged: (value) async {
                          if (value) {
                            // Attempt to upgrade to artist via backend
                            final success = await ref
                                .read(userProvider.notifier)
                                .upgradeToArtist();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'You are now an artist! Upload music and go live.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Failed to upgrade. Please try again later.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            // Just switch local view mode
                            ref
                                .read(userProvider.notifier)
                                .setRole(UserRole.user);
                          }
                        },
                      ),
                    ],
                  ),
                  _SectionCard(
                    title: 'Activity',
                    children: [
                      _StatRow(
                        icon: Icons.music_note,
                        label: 'Top Genres',
                        value: (user.favoriteGenres ?? []).take(3).join(', '),
                      ),
                      _StatRow(
                        icon: Icons.trending_up,
                        label: 'Recent Plays',
                        value: (user.topTracks ?? []).take(3).join(', '),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[900],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('Manage Playlists'),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text('Update Profile'),
                            onPressed: () => ref
                                .read(userProvider.notifier)
                                .updateProfile(name: 'Updated'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9E9E9E),
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
        ),
      ],
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
                  fontSize: 18,
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

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400]!),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFFBDBDBD), fontSize: 14)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
