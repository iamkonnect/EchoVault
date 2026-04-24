import 'package:flutter/material.dart';
import 'dart:convert';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> allShorts = [];
  List<Map<String, dynamic>> filteredShorts = [];
  bool loading = true;
  int selectedTab = 0; 

  final List<Map<String, String>> songCatalog = [
    {'id': '1', 'title': 'Echo Afro Jazz Sunset', 'artist': 'Afro Collective', 'cover': 'assets/WhatsApp Image 2026-03-17 at 13.04.45.jpeg', 'trending': 'true'},
    {'id': '2', 'title': 'Echo Amapiano Nights', 'artist': 'Amapiano Kings', 'cover': 'assets/WhatsApp Image 2026-03-17 at 13.04.46 (1).jpeg', 'trending': 'true'},
    {'id': '3', 'title': 'Echo Bongo Flavour Mix', 'artist': 'Bongo Stars', 'cover': 'assets/WhatsApp Image 2026-03-17 at 13.04.46 (2).jpeg', 'trending': 'false'},
    {'id': '4', 'title': 'Echo Genge Fire', 'artist': 'Genge Crew', 'cover': 'assets/WhatsApp Image 2026-03-17 at 13.04.46 (3).jpeg', 'trending': 'true'},
    {'id': '5', 'title': 'Echo Dancehall Party', 'artist': 'Dancehall DJ', 'cover': 'assets/WhatsApp Image 2026-03-17 at 13.04.46 (4).jpeg', 'trending': 'false'},
    {'id': '6', 'title': 'Echo Reggae Roots', 'artist': 'Reggae Legends', 'cover': 'assets/WhatsApp Image 2026-03-17 at 13.04.46.jpeg', 'trending': 'false'},
    {'id': '7', 'title': 'Echo Hip Hop Cypher', 'artist': 'Hip Hop Heads', 'cover': 'assets/WhatsApp Image 2026-03-17 at 13.04.46 (5).jpeg', 'trending': 'false'},
    {'id': '8', 'title': 'Echo Rhumba Romance', 'artist': 'Rhumba Orchestra', 'cover': 'assets/WhatsApp Image 2026-03-17 at 13.04.46 (6).jpeg', 'trending': 'true'},
  ];

  @override
  void initState() {
    super.initState();
    loadDemoShorts();
  }

  void loadDemoShorts() {
    const jsonData = r'''
[
  {"id": "s1", "title": "Afro Jazz Vibes Clip", "description": "Loving this sunset groove!", "artist": "User DJFresh", "views": 12456, "comments": 234, "likes": 1567, "gifts": 45, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.45.jpeg", "songId": "1"},
  {"id": "s2", "title": "Amapiano Dance Challenge", "description": "Hit that trending beat!", "artist": "DanceQueen", "views": 85634, "comments": 890, "likes": 4567, "gifts": 123, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (1).jpeg", "songId": "2"},
  {"id": "s3", "title": "Bongo Short Fun", "description": "Family vibes only", "artist": "BongoKid", "views": 2345, "comments": 67, "likes": 345, "gifts": 12, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (2).jpeg", "songId": "3"},
  {"id": "s4", "title": "Genge Fire Short", "description": "Street energy!", "artist": "GengeBoss", "views": 67890, "comments": 456, "likes": 2345, "gifts": 78, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (3).jpeg", "songId": "4"},
  {"id": "s5", "title": "Dancehall Party Clip", "description": "Weekend mood", "artist": "PartyVibes", "views": 4567, "comments": 123, "likes": 678, "gifts": 23, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (4).jpeg", "songId": "5"},
  {"id": "s6", "title": "Reggae Chill Short", "description": "Roots music love", "artist": "ReggaeFan", "views": 7890, "comments": 234, "likes": 890, "gifts": 34, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.46.jpeg", "songId": "6"},
  {"id": "s7", "title": "Hip Hop Cypher Clip", "description": "Bars on fire", "artist": "RapGod", "views": 12345, "comments": 345, "likes": 1234, "gifts": 56, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (5).jpeg", "songId": "7"},
  {"id": "s8", "title": "Rhumba Dance Short", "description": "Classic moves", "artist": "RhumbaQueen", "views": 5678, "comments": 156, "likes": 567, "gifts": 89, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (6).jpeg", "songId": "8"},
  {"id": "s9", "title": "Listener Short Remix", "description": "My take on trending Amapiano", "artist": "ListenerX", "views": 34567, "comments": 678, "likes": 3456, "gifts": 101, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (1).jpeg", "songId": "2"},
  {"id": "s10", "title": "Artist Catalog Short", "description": "From my new album!", "artist": "ArtistPro", "views": 90123, "comments": 901, "likes": 5678, "gifts": 200, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.45.jpeg", "songId": "1"},
  {"id": "s11", "title": "Trending Song Clip", "description": "Genge trending now!", "artist": "TrendSetter", "views": 23456, "comments": 456, "likes": 2345, "gifts": 67, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (3).jpeg", "songId": "4"},
  {"id": "s12", "title": "Gift Reaction Short", "description": "Thanks for gifts!", "artist": "GiftHunter", "views": 11234, "comments": 278, "likes": 1678, "gifts": 150, "thumbnail": "assets/WhatsApp Image 2026-03-17 at 13.04.46 (6).jpeg", "songId": "8"}
]
    ''';
    setState(() {
      allShorts = List<Map<String, dynamic>>.from(json.decode(jsonData));
      for (var s in allShorts) {
        final song = songCatalog.firstWhere((c) => c['id'] == s['songId'], orElse: () => {});
        s['trending'] = song['trending'] == 'true';
        s['songTitle'] = song['title'];
        s['fullArtist'] = '${s['artist']} • ${song['artist']}';
      }
      filteredShorts = List<Map<String, dynamic>>.from(allShorts);
      loading = false;
    });
  }

  bool isTrending(Map<String, dynamic> short) => short['trending'] == true;

  List<Map<String, dynamic>> get filteredByTab {
    var items = filteredShorts;
    switch (selectedTab) {
      case 1:
        items = filteredShorts.where((s) => isTrending(s)).toList();
        break;
      case 2:
        items = filteredShorts.where((s) {
          final idStr = s['id'].split('s')[1] ?? '0';
          final idNum = int.tryParse(idStr) ?? 0;
          return idNum.isEven;
        }).toList();
        break;
    }
    return items;
  }

  void filterSearch(String query) {
    setState(() {
      filteredShorts = allShorts.where((s) =>
        s['title'].toLowerCase().contains(query.toLowerCase()) ||
        s['description'].toLowerCase().contains(query.toLowerCase()) ||
        s['artist'].toLowerCase().contains(query.toLowerCase())
      ).toList();
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
                  Text(short['title'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${short['comments']} comments', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5 + ((short['comments'] as num).toInt() % 10),
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
                      CircleAvatar(backgroundColor: Color(0xFF8B5CF6), child: Icon(Icons.person, color: Colors.white, size: 20)),
                      SizedBox(width: 12),
                      Expanded(child: Text('Great clip!', style: TextStyle(color: Colors.white))),
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
    final bool isDesktop = MediaQuery.of(context).size.width > 1200;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = isDesktop ? screenWidth / 3 - 32 : screenWidth - 64;
    final cardHeight = cardWidth * 1.6;

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
          onChanged: filterSearch,
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Column(
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
                              onTap: () => setState(() => selectedTab = e.key),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedTab == e.key ? const Color(0xFF8B5CF6).withValues(alpha: 0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  e.value,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedTab == e.key ? Colors.white : Colors.white60,
                                    fontWeight: selectedTab == e.key ? FontWeight.bold : FontWeight.normal,
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
                    await Future.delayed(const Duration(seconds: 1));
                    loadDemoShorts();
                  },
                  color: const Color(0xFF8B5CF6),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 1,
                      childAspectRatio: cardWidth / cardHeight,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredByTab.length,
                    itemBuilder: (context, index) {
                      final short = filteredByTab[index];
                      final song = songCatalog.firstWhere((c) => c['id'] == short['songId'], orElse: () => songCatalog[0]);
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
                              // Video placeholder bg (dark gradient for video feel)
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black26, Colors.black87],
                                  ),
                                ),
                              ),
                              // Song artwork popup right-bottom
                              Positioned(
                                bottom: 80,
                                right: 12,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.8),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundImage: AssetImage(song['cover']!),
                                  ),
                                ),
                              ),
                              // Play button center
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
                              // Trending badge top-left
                              if (isTrending(short))
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_fire_department, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('TRENDING', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                                  padding: const EdgeInsets.all(16).copyWith(bottom: 24),
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                                    gradient: LinearGradient(
                                      colors: [Colors.black87, Colors.transparent],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        short['title'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        short['description'],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        short['fullArtist'],
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
  _buildStat(Icons.visibility, short['views'].toString()),
                                          _buildStat(Icons.comment, short['comments'].toString()),
                                          _buildStat(Icons.favorite, short['likes'].toString()),
                                          _buildStat(Icons.card_giftcard, short['gifts'].toString()),
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
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create Short: Pick music from artist catalog & record! 🎥🎵')),
          );
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
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
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
