import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';
import 'dart:developer' as developer;

class ShortsScreen extends ConsumerStatefulWidget {
  const ShortsScreen({super.key});

  @override
  ConsumerState<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends ConsumerState<ShortsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredShorts = [];
  int selectedTab = 0;

  bool isTrending(Map<String, dynamic> short) => short['trending'] == true;

  List<Map<String, dynamic>> get filteredByTab {
    var items = filteredShorts;
    switch (selectedTab) {
      case 1:
        items = filteredShorts.where((s) => isTrending(s)).toList();
        break;
      case 2:
        items = filteredShorts
            .where((s) => s['artistId'] != null)
            .toList();
        break;
    }
    return items;
  }

  void filterSearch(String query, List<Map<String, dynamic>> allShorts) {
    setState(() {
      filteredShorts = allShorts
          .where((s) =>
              s['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
              s['description']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              s['artist'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void showCommentsModal(Map<String, dynamic> short) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(short['title'] ?? 'Untitled',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('${short['comments'] ?? 0} comments',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5 + (((short['comments'] as num?) ?? 0).toInt() % 10),
                itemBuilder: (context, i) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                          backgroundColor: Color(0xFF8B5CF6),
                          child: Icon(Icons.person,
                              color: Colors.white, size: 20)),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text('Great clip!',
                              style: TextStyle(color: Colors.white))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortsAsync = ref.watch(shortsProvider);
    final bool isDesktop = MediaQuery.of(context).size.width > 1200;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search shorts...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            suffixIcon: Icon(Icons.tune, color: Colors.white),
          ),
          onChanged: (query) {
            if (shortsAsync.hasValue) {
              filterSearch(query, shortsAsync.value ?? []);
            }
          },
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: shortsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Error loading shorts: $error',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(shortsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allShorts) {
          if (filteredShorts.isEmpty && allShorts.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => filteredShorts = allShorts);
            });
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final cardWidth = isDesktop ? screenWidth / 3 - 32 : screenWidth - 64;
          final cardHeight = cardWidth * 1.6;

          return Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['For You', 'Trending', 'Following']
                      .asMap()
                      .entries
                      .map((e) => Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => selectedTab = e.key),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedTab == e.key
                                      ? const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  e.value,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedTab == e.key
                                        ? Colors.white
                                        : Colors.white60,
                                    fontWeight: selectedTab == e.key
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(shortsProvider);
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  color: const Color(0xFF8B5CF6),
                  child: filteredByTab.isEmpty
                      ? const Center(
                          child: Text('No shorts found',
                              style: TextStyle(color: Colors.white60)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : 1,
                            childAspectRatio: cardWidth / cardHeight,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredByTab.length,
                          itemBuilder: (context, index) {
                            final short = filteredByTab[index];
                            return GestureDetector(
                              onTap: () => showCommentsModal(short),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black26,
                                            Colors.black87
                                          ],
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            short['thumbnail'] ??
                                                'https://ui-avatars.com/api/?name=No+Thumbnail&background=111111&color=ffffff&size=400',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    // Song artwork
                                    Positioned(
                                      bottom: 80,
                                      right: 12,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.8),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 28,
                                          backgroundImage: NetworkImage(
                                            short['songThumbnail'] ??
                                                'https://ui-avatars.com/api/?name=Song&background=333333&color=ffffff&size=56',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Play button
                                    const Positioned(
                                      top: 0,
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 80,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 4),
                                            blurRadius: 8,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Trending badge
                                    if (isTrending(short))
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                                colors: [
                                                  Colors.orange,
                                                  Colors.red
                                                ]),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons
                                                    .local_fire_department,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text('TRENDING',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    // Bottom info
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(16)
                                            .copyWith(bottom: 24),
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.vertical(
                                              bottom: Radius.circular(16)),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black87,
                                              Colors.transparent
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              short['title'] ?? 'Untitled',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              short['description'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              short['artist'] ?? 'Unknown',
                                              style: TextStyle(
                                                color: Colors.grey[300],
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                _buildStat(Icons.visibility,
                                                    (short['views'] ?? 0).toString()),
                                                _buildStat(Icons.comment,
                                                    (short['comments'] ?? 0).toString()),
                                                _buildStat(Icons.favorite,
                                                    (short['likes'] ?? 0).toString()),
                                                _buildStat(
                                                    Icons.card_giftcard,
                                                    (short['gifts'] ?? 0).toString()),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          developer.log('Create Short button tapped', name: 'ShortsScreen');
          Navigator.pushNamed(context, '/add-short');
        },
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Short'),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 16),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
