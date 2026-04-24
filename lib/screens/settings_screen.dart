import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../services/image_utils.dart';

import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _currentOfferIndex = 0;

  final List<Map<String, String>> _offers = [
    {
      'title': 'Artist Shorts Rewards',
      'desc': 'Earn rewards by making shorts of your favorite artists!',
      'image': 'assets/featured_echo_1.jpeg',
    },
    {
      'title': 'Go Live Power',
      'desc': 'Connect with fans live and earn real gifts!',
      'image': 'assets/featured_echo_2.jpeg',
    },
    {
      'title': 'Challenge Wins',
      'desc': 'Join challenges for exclusive prizes!',
      'image': 'assets/featured_echo_3.jpeg',
    },
  ];

  Future<void> _logout() async {
    await ref.read(userProvider.notifier).logout();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    }
  }

  Future<void> _deactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Deactivate Account', style: TextStyle(color: Colors.red)),
        content: const Text('This action will permanently delete all your app data and account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(userProvider.notifier).deactivate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deactivated. All data cleared.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLanguageBottomSheet() {
    final notifier = ref.read(localeProvider.notifier);
    final currentLocale = ref.read(localeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ...ref.read(localeProvider.notifier).supportedLocales.map((locale) => ListTile(
              title: Text(
                locale.languageCode == 'en' ? 'English (Primary)' : 
                locale.languageCode == 'sw' ? 'Swahili' : 'French',
              ),
              leading: Radio<Locale>(
                value: locale,
                groupValue: currentLocale,
                onChanged: (value) {
                  notifier.setLocale(value!.languageCode);
                  Navigator.pop(context);
                },
              ),
              onTap: () => notifier.setLocale(locale.languageCode),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final notifier = ref.read(localeProvider.notifier);

  return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0a0a0a) : const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Offers Carousel Section (custom header)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.card_giftcard, color: Color(0xFF8B5CF6), size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Special Offers',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 240,
                      child: PageView.builder(
                        itemCount: _offers.length,
                        itemBuilder: (context, index) {
                          final offer = _offers[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  Image(
                                    image: ImageUtils.getTrackImage(offer['image']),
                                    height: 240,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 240,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Colors.purple]),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(Icons.music_note, size: 60, color: Colors.white),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 20,
                                    left: 20,
                                    right: 20,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          offer['title']!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          offer['desc']!,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        onPageChanged: (index) => setState(() => _currentOfferIndex = index),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_offers.length, (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentOfferIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentOfferIndex == index 
                            ? const Color(0xFF8B5CF6) 
                            : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Theme Toggle
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                title: Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  isDark ? 'Switch to light theme' : 'Switch to dark theme',
                  style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
                ),
                value: isDark,
                onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Language
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.translate, color: Color(0xFF8B5CF6)),
                title: Text(
                  'Language',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  notifier.currentLanguage,
                  style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showLanguageBottomSheet,
              ),
            ),
            const SizedBox(height: 40),
            // Action Buttons
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 24),
                label: const Text('Logout', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _deactivate,
                icon: const Icon(Icons.delete_forever, size: 24),
                label: const Text('Deactivate Account', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
