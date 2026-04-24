import 'package:flutter/material.dart';
import 'dart:convert';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String selectedGenre = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool loading = true;

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
    'Zouk'
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    // Hardcoded demo data with genres
    const jsonData = r'''
[
  {"id": "1", "title": "Echo Afro Jazz Sunset", "artist": {"name": "Afro Collective Echo"}, "cover": "assets/WhatsApp Image 2026-03-17 at 13.04.45.jpeg", "genre": "Afro Jazz", "plays": 12567},
  {"id": "2", "title": "Echo Amapiano Nights", "artist": {"name": "Amapiano Kings Echo"}, "cover": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (1).jpeg", "genre": "Amapiano", "plays": 23456},
  {"id": "3", "title": "Echo Bongo Flavour Mix", "artist": {"name": "Bongo Stars Echo"}, "cover": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (2).jpeg", "genre": "Bongo Flavour", "plays": 89234},
  {"id": "4", "title": "Echo Genge Fire", "artist": {"name": "Genge Crew Echo"}, "cover": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (3).jpeg", "genre": "Genge", "plays": 45678},
  {"id": "5", "title": "Echo Dancehall Party", "artist": {"name": "Dancehall DJ Echo"}, "cover": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (4).jpeg", "genre": "Dancehall", "plays": 78901},
  {"id": "6", "title": "Echo Reggae Roots", "artist": {"name": "Reggae Legends Echo"}, "cover": "assets/WhatsApp Image 2026-03-17 at 13.04.46.jpeg", "genre": "Reggae", "plays": 34567},
  {"id": "7", "title": "Echo Hip Hop Cypher", "artist": {"name": "Hip Hop Heads Echo"}, "cover": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (5).jpeg", "genre": "Hip Hop", "plays": 67890},
  {"id": "8", "title": "Echo Rhumba Romance", "artist": {"name": "Rhumba Orchestra Echo"}, "cover": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (6).jpeg", "genre": "Rhumba", "plays": 12345},
  {"id": "9", "title": "Echo Lingala Dance", "artist": {"name": "Lingala Beats Echo"}, "cover": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (7).jpeg", "genre": "Lingala", "plays": 56789},
  {"id": "10", "title": "Echo RnB Slow Jams", "artist": {"name": "RnB Soul Echo"}, "cover": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (8).jpeg", "genre": "RnB", "plays": 90123}
]
''';
    setState(() {
      allItems = List<Map<String, dynamic>>.from(json.decode(jsonData));
      filteredItems = List<Map<String, dynamic>>.from(allItems);
      loading = false;
    });
  }

  void filterItems() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredItems = allItems.where((item) {
        bool genreMatch =
            selectedGenre == 'All' || item['genre'] == selectedGenre;
        bool searchMatch = query.isEmpty ||
            item['title'].toLowerCase().contains(query) ||
            item['artist']['name'].toLowerCase().contains(query);
        return genreMatch && searchMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          onChanged: (value) => filterItems(),
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
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
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
                              filterItems();
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
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: aspectRatio,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return GestureDetector(
                            onTap: () => debugPrint('Tapped ${item['title']}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: AssetImage(item['cover'] ??
                                            'assets/WhatsApp Image 2026-03-17 at 13.04.45.jpeg'),
                                        fit: BoxFit.cover,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item['artist']['name'] ?? '',
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
