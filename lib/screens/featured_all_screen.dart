import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';
import '../services/image_utils.dart';
import 'dart:developer' as developer;

class FeaturedAllScreen extends ConsumerStatefulWidget {
  const FeaturedAllScreen({super.key});

  @override
  ConsumerState<FeaturedAllScreen> createState() => _FeaturedAllScreenState();
}

class _FeaturedAllScreenState extends ConsumerState<FeaturedAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredFeatured = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void filterSearch(String query, List<Map<String, dynamic>> allItems) {
    setState(() {
      filteredFeatured = allItems
          .where((item) =>
              item['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
              item['artist'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredEchosProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Featured Echoes'),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: featuredAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Error loading featured: $error',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(featuredEchosProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allItems) {
          if (filteredFeatured.isEmpty && allItems.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => filteredFeatured = allItems);
            });
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search featured...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (query) {
                    filterSearch(query, allItems);
                  },
                ),
              ),
              // Content
              Expanded(
                child: filteredFeatured.isEmpty
                    ? const Center(
                        child: Text(
                          'No featured content found',
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: filteredFeatured.length,
                        itemBuilder: (context, index) {
                          final item = filteredFeatured[index];
                          return GestureDetector(
                            onTap: () {
                              developer.log(
                                'Tapped ${item['title']}',
                                name: 'FeaturedAllScreen',
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: ImageUtils.getTrackImage(
                                    item['cover'] ?? item['thumbnail'],
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? 'Untitled',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      item['artist'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
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
}
