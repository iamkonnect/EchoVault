import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';
import 'dart:developer' as developer;

class LiveAllScreen extends ConsumerStatefulWidget {
  const LiveAllScreen({super.key});

  @override
  ConsumerState<LiveAllScreen> createState() => _LiveAllScreenState();
}

class _LiveAllScreenState extends ConsumerState<LiveAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> filteredLive = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void filterSearch(String query, List<dynamic> allItems) {
    setState(() {
      filteredLive = allItems
          .where((item) =>
              item['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
              item['artist'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveAsync = ref.watch(liveStreamsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('All Live Streams'),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: liveAsync.when(
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
                'Error loading live streams: $error',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(liveStreamsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allItems) {
          if (filteredLive.isEmpty && allItems.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => filteredLive = allItems);
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
                    hintText: 'Search live streams...',
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
                child: filteredLive.isEmpty
                    ? const Center(
                        child: Text(
                          'No live streams found',
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredLive.length,
                        itemBuilder: (context, index) {
                          final stream = filteredLive[index];
                          return GestureDetector(
                            onTap: () {
                              developer.log(
                                'Tapped ${stream['title']}',
                                name: 'LiveAllScreen',
                              );
                            },
                            child: Card(
                              color: Colors.grey[900],
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Thumbnail with LIVE badge
                                    Stack(
                                      children: [
                                        Container(
                                          height: 150,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            color: Colors.grey[800],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.videocam,
                                              color: Colors.grey[400],
                                              size: 48,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.circle,
                                                    color: Colors.white, size: 8),
                                                SizedBox(width: 4),
                                                Text(
                                                  'LIVE',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Title
                                    Text(
                                      stream['title'] ?? 'Live Stream',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // Artist and viewers
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            stream['artist'] ?? 'Unknown',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${stream['viewers'] ?? 0} viewers',
                                          style: const TextStyle(
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Category
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        stream['category'] ?? 'General',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
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
