import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';
import '../providers/app_providers.dart';
import '../models/user.dart';
import '../config/api_config.dart';
import '../widgets/auth_modal.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  List<dynamic> liveStreams = [];
  bool loading = true;
  Timer? _authPromptTimer;

  @override
  void initState() {
    super.initState();
    fetchLiveStreams();
  }

  @override
  void dispose() {
    _authPromptTimer?.cancel();
    super.dispose();
  }

  void _showAuthModal() {
    _authPromptTimer?.cancel();
    AuthModal.show(context);
  }

  void _showLiveDescriptionDialog({required bool isArtist}) {
    final user = ref.read(userProvider);

    // Check authentication first
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to go live'),
          backgroundColor: Colors.orange,
        ),
      );
      _showAuthModal();
      return;
    }

    // Check artist role
    if (isArtist && user.role != UserRole.artist) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only artists can go live'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: Text(
          isArtist ? 'Start Your Live Stream' : 'Request a Live Stream',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Stream Title',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., "DJ Fresh - Late Night Vibes"',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'What is your live stream about? Tell viewers what to expect...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              const Text(
                'Category',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., "Electronic", "Acoustic", "Talk Show"',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              final category = categoryController.text.trim();

              if (title.isEmpty || description.isEmpty || category.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                }
                return;
              }

              Navigator.pop(context);

              // Create stream data
              final streamData = {
                'id': 'stream_${DateTime.now().millisecondsSinceEpoch}',
                'title': title,
                'description': description,
                'category': category,
                'timestamp': DateTime.now().toIso8601String(),
              };

              if (isArtist) {
                // Artist: Start streaming immediately
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Starting your live stream...')),
                  );
                }

                // Call API to start live stream
                try {
                  final currentUser = ref.read(userProvider);
                  if (currentUser == null) {
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/signin');
                    }
                    return;
                  }

                  final artistService = ref.read(artistServiceProvider);
                  final result =
                      await artistService.startLiveStream(title: title);

                  if (result['success']) {
                    final apiStreamData = result['data'] ?? streamData;
                    apiStreamData['isBroadcaster'] = true;
                    if (context.mounted) {
                      Navigator.pushNamed(
                        context,
                        '/live-broadcast',
                        arguments: apiStreamData,
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Error: ${result['error'] ?? 'Failed to start stream'}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  developer.log('Error starting stream: $e',
                      name: 'LiveScreen');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              } else {
                // Listener: Show confirmation and go to live screen
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text('Your request has been sent to creators!'),
                      backgroundColor: Colors.green[700],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Text(
              isArtist ? 'Go Live' : 'Send Request',
              style: const TextStyle(
                  color: Colors.purple, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchLiveStreams() async {
    setState(() => loading = true);
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/live/streams/active'),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          liveStreams =
              List<Map<String, dynamic>>.from(data['data'] ?? data ?? []);
          loading = false;
        });
        return;
      }
    } catch (e) {
      developer.log('API error fetching live streams: $e',
          name: 'LiveScreen', level: 1000);
    }

    setState(() {
      liveStreams = [];
      loading = false;
    });
  }

  void _joinLiveStream(Map<String, dynamic> stream) {
    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to join streams'),
          backgroundColor: Colors.orange,
        ),
      );
      _showAuthModal();
      return;
    }

    final updatedStream = Map<String, dynamic>.from(stream);
    updatedStream['hostId'] = stream['artist'];
    updatedStream['isBroadcaster'] = user.id == updatedStream['hostId'];
    Navigator.pushNamed(context, '/live-broadcast', arguments: updatedStream);
  }

  Widget _buildThumbnail(String? thumbnail) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[800],
      ),
      child: thumbnail != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: AssetImage('assets/$thumbnail'),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.image_not_supported,
                        color: Colors.grey[400], size: 48),
                  );
                },
              ),
            )
          : Center(
              child: Icon(Icons.videocam, color: Colors.grey[400], size: 48),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final isArtist = user?.role == UserRole.artist;
    final isAuthenticated = user != null;

    return Scaffold(
      floatingActionButton: isAuthenticated
          ? (isArtist
              ? // Artist Button
              Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFE91E63)]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    heroTag: 'goLive',
                    onPressed: () => _showLiveDescriptionDialog(isArtist: true),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    icon: const Icon(Icons.videocam,
                        color: Colors.white, size: 24),
                    label: const Text(
                      'Go LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : // Listener Button
              Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF00BCD4)]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    heroTag: 'requestLive',
                    onPressed: () =>
                        _showLiveDescriptionDialog(isArtist: false),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    icon: const Icon(Icons.favorite,
                        color: Colors.white, size: 24),
                    label: const Text(
                      'Request LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ))
          : // Not authenticated - show sign in button
          Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6D28D9), Color(0xFF8B5CF9)]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF9).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                heroTag: 'signIn',
                onPressed: _showAuthModal,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.login, color: Colors.white, size: 24),
                label: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : liveStreams.isEmpty
              ? const Center(
                  child: Text('No live streams',
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: liveStreams.length,
                  itemBuilder: (context, index) {
                    final stream = liveStreams[index];
                    return GestureDetector(
                      onTap: () => _joinLiveStream(stream),
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
                                  _buildThumbnail(stream['thumbnail']),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
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
                                stream['title'] ?? '',
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
                                      style:
                                          const TextStyle(color: Colors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${stream['viewers'] ?? 0} viewers',
                                    style:
                                        const TextStyle(color: Colors.purple),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Description
                              Text(
                                stream['description'] ?? '',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Category and Join button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      stream['category'] ?? 'General',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                    ),
                                    icon:
                                        const Icon(Icons.play_arrow, size: 16),
                                    label: const Text('Join'),
                                    onPressed: () => _joinLiveStream(stream),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
