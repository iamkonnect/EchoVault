import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';
import 'dart:developer' as developer;

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String selectedGenre = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredItems = [];

  final List<String> genres = [
    'All',
    'Afro Jazz',
    'Amapiano',
    'Bongo Flavour',
    'Genge',
    'Genge Tone',
    'Dancehall',
    'Reggae',
    'Singeli',
    'Hip Hop',
    'Rhumba',
    'Lingala',
    'RnB',
    'Soul Music',
    'Soulpiano',
    'Taarab',
    'Zouk'
  ];

  @override
  void initState() {
    super.initState();
  }

  void filterItems(List<Map<String, dynamic>> allItems) {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredItems = allItems.where((item) {
        bool genreMatch =
            selectedGenre == 'All' || item['genre'] == selectedGenre;
        bool searchMatch = query.isEmpty ||
            item['title'].toLowerCase().contains(query) ||
            (item['artist'] != null &&
                item['artist']['name'].toLowerCase().contains(query));
        return genreMatch && searchMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(allTracksProvider);

    return tracksAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Error loading tracks: $error', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(allTracksProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (allItems) {
        if (filteredItems.isEmpty && allItems.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            filterItems(allItems);
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search tracks, artists...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Colors.grey),
              ),
              onChanged: (_) => filterItems(allItems),
            ),
            backgroundColor: Colors.black,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bool isDesktop = constraints.maxWidth > 1200;
              final double aspectRatio = isDesktop ? 228 / 232 : 0.75;
              final int crossAxisCount = isDesktop ? 4 : 2;
              return Column(
                children: [
                  // Genre chips
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: genres.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final genre = genres[index];
                        final isSelected = selectedGenre == genre;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedGenre = genre;
                            });
                            filterItems(allItems);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF8B5CF6)
                                    : Colors.white24,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.music_note_outlined,
                                  size: 16,
                                  color: isSelected
                                      ? const Color(0xFF8B5CF6)
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  genre,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white60,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? const Center(
                            child: Text('No tracks found',
                                style: TextStyle(color: Colors.white60)))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: aspectRatio,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return GestureDetector(
                                onTap: () => developer.log(
                                    'Tapped ${item['title']}',
                                    name: 'DiscoverScreen'),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              item['cover'] ??
                                                  item['thumbnail'] ??
                                                  'https://ui-avatars.com/api/?name=No+Cover&background=333333&color=ffffff&size=300',
                                            ),
                                            fit: BoxFit.cover,
                                            onError: (exception,
                                                stackTrace) {
                                              developer.log(
                                                  'Image load error: $exception',
                                                  name: 'DiscoverScreen');
                                            },
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      item['title'] ?? 'Untitled',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      item['artist']?['name'] ??
                                          'Unknown Artist',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${item['plays'] ?? 0} plays',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
