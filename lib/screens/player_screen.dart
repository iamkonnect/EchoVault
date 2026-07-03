import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../services/queue_service.dart' as queue_service;
import '../services/audio_player_service.dart';
import '../services/image_utils.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final queue = ref.watch(queue_service.queueServiceProvider);
    final currentTrack = queue.currentTrack;

    if (currentTrack == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child:
              Text('No track playing', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Cover Art Header
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Hero(
                tag: 'cover_${currentTrack.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: ImageUtils.getTrackImage(currentTrack.cover),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Track Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              children: [
                Text(
                  currentTrack.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  currentTrack.artist?.name ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  currentTrack.album?.title ?? '',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: StreamBuilder<PlaybackState?>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final position = state?.position ?? Duration.zero;
                final duration = Duration(milliseconds: currentTrack.duration);
                final progress = duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0;
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF8B5CF6)),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position),
                            style: const TextStyle(color: Colors.white)),
                        Text(_formatDuration(duration),
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => audioHandler.skipToPrevious(),
                  icon: const Icon(Icons.skip_previous,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () async {
                    final playing = audioHandler.playbackState.value.playing;
                    if (playing) {
                      await audioHandler.pause();
                    } else {
                      await audioHandler.play();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: StreamBuilder<PlaybackState?>(
                      stream: audioHandler.playbackState,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;
                        return Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                          size: 48,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: () => audioHandler.skipToNext(),
                  icon: const Icon(Icons.skip_next,
                      color: Colors.white, size: 48),
                ),
              ],
            ),
          ),
          // Secondary Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () =>
                    ref.read(queue_service.queueServiceProvider.notifier).toggleShuffle(),
                icon: Icon(
                  Icons.shuffle,
                  color: queue.shuffleActive ? Colors.white : Colors.white60,
                ),
              ),
              IconButton(
                onPressed: () =>
                    ref.read(queue_service.queueServiceProvider.notifier).cycleRepeat(),
                icon: Icon(
                  _getRepeatIcon(queue.repeatMode),
                  color: Colors.white60,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.music_note, color: Colors.white60),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getRepeatIcon(queue_service.RepeatMode mode) {
    switch (mode) {
      case queue_service.RepeatMode.off:
        return Icons.repeat;
      case queue_service.RepeatMode.one:
        return Icons.repeat_one;
      case queue_service.RepeatMode.all:
        return Icons.repeat_on;
      default:
        return Icons.repeat;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
