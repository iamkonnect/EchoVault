import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../services/queue_service.dart';
import '../services/audio_player_service.dart';
import '../screens/player_screen.dart';
import '../services/image_utils.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final queue = ref.watch(queueServiceProvider);
    final currentTrack = queue.currentTrack;

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PlayerScreen(),
          fullscreenDialog: true,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F12),
          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 23,
              offset: Offset(3, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Added Hero widget to match the transition in PlayerScreen
              Hero(
                tag: 'cover_${currentTrack.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 59,
                    height: 59,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: ImageUtils.getTrackImage(currentTrack.cover),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 19),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentTrack.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 19,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentTrack.artist?.name ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StreamBuilder<PlaybackState?>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final duration =
                      Duration(milliseconds: currentTrack.duration);
                  final position = state?.position ?? Duration.zero;
                  final progress = duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0;
                  return SizedBox(
                    width: 83,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF8B5CF6)),
                            minHeight: 5,
                          ),
                        ),
                        Text(
                          '${_formatDuration(position)} / ${_formatDuration(duration)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 19),
              IconButton(
                onPressed: () => audioHandler.skipToPrevious(),
                icon: const Icon(Icons.skip_previous, color: Colors.white),
              ),
              StreamBuilder<PlaybackState?>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return IconButton(
                    onPressed: () => playing ? audioHandler.pause() : audioHandler.play(),
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                        color: Colors.white, size: 35),
                  );
                },
              ),
              IconButton(
                onPressed: () => audioHandler.skipToNext(),
                icon: const Icon(Icons.skip_next, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
