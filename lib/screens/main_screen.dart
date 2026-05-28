import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sidebar.dart';
import 'discover_screen.dart';
import 'shorts_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';
import 'live_screen.dart';
import '../providers/user_provider.dart';
import '../providers/api_providers.dart';
import '../services/image_utils.dart';
import '../widgets/auth_modal.dart';
import '../inbox_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Map<String, dynamic>> musicVideos = [];
  Timer? autoScrollTimer;

  @override
  void initState() {
    super.initState();
    
    autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _currentIndex == 0 && musicVideos.isNotEmpty) {
        _currentPage = (_currentPage + 1) % musicVideos.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });

    _triggerAuthRedirect();
  }

  void _triggerAuthRedirect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        final user = ref.read(userProvider);
        if (user == null) {
          AuthModal.show(context);
        }
      });
    });
  }

  @override
  void dispose() {
    autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'Discover', 'Live', 'Shorts', 'Profile', 'Wallet', 'Insights', 'Settings', 'Inbox'];
    
    // Define screens inside build so they reflect state changes (like the slider index)
    final List<Widget> screens = [
      _buildDashboardContent(),
      const DiscoverScreen(),
      const LiveScreen(),
      const ShortsScreen(),
      const ProfileScreen(),
      const WalletScreen(),
      const InsightsScreen(),
      const SettingsScreen(),
      const InboxScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(titles[_currentIndex]),
        centerTitle: false,
      ),
      body: Row(
        children: [
            Container(
            width: 54.0,
            decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
            child: Sidebar(
              currentIndex: _currentIndex,
              onSelected: (index) => setState(() => _currentIndex = index),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final featuredAsync = ref.watch(featuredEchosProvider);
    final liveAsync = ref.watch(liveStreamsProvider);
    final trendingAsync = ref.watch(trendingEchosProvider);

    if (featuredAsync.hasValue && liveAsync.hasValue) {
      final featured = featuredAsync.value!;
      final live = liveAsync.value!;
      final trending = trendingAsync.valueOrNull;

      if (musicVideos.isEmpty && featured.isNotEmpty) {
        Future.microtask(() { if (mounted) setState(() => musicVideos = featured); });
      }

      return _buildScrollableDashboard(featured, live, trending: trending);
    }

    return featuredAsync.when(
      data: (_) => const Center(child: CircularProgressIndicator()),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildScrollableDashboard(List<Map<String, dynamic>> featured, List<dynamic> live, {List<Map<String, dynamic>>? trending}) {
    final gridItems = trending ?? featured;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Featured Slider
          _buildFeaturedSlider(featured),

// Music Gifts Section removed

          // Live Streams
          _buildSectionHeader(
            'Live Echo Streams',
            onSeeAll: () {
              Navigator.pushNamed(context, '/live-all');
            },
          ),
          _buildLiveStreams(live),

          // Realms Grid
          _buildSectionHeader(
            'Echo Realms',
            onSeeAll: () {
              Navigator.pushNamed(context, '/trending-all');
            },
          ),
          _buildRealmsGrid(gridItems),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }



  Widget _buildFeaturedSlider(List<Map<String, dynamic>> featured) {
    return Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => _currentPage = index,
              itemCount: featured.length,
              itemBuilder: (context, index) {
                final video = featured[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image(image: ImageUtils.getTrackImage(video['cover'] ?? video['thumbnail']), fit: BoxFit.cover),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: 0.87), Colors.transparent],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Text(
                        video['title'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
  }

  Widget _buildLiveStreams(List<dynamic> live) {
    return SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: live.length,
              itemBuilder: (context, index) {
                final liveItem = live[index];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              image: ImageUtils.getTrackImage(liveItem['thumbnail']),
                              height: 100,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                              child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(liveItem['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1),
                      Text('${liveItem['viewers'] ?? 0} Viewers', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          );
  }

  Widget _buildRealmsGrid(List<Map<String, dynamic>> gridItems) {
    return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: gridItems.length,
              itemBuilder: (context, index) {
                final video = gridItems[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: ImageUtils.getTrackImage(video['cover'] ?? video['thumbnail']),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(12),
                    child: Text(video['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('See all', style: TextStyle(color: Colors.purple, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
