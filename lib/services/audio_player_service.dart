import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) => AudioPlayerHandler());

class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  AudioPlayerHandler() {
    _init();
  }

  void _init() {
    // 1. Listen to playback events and broadcast them to audio_service
    _player.playbackEventStream.listen(_broadcastState);

    // 2. Listen to current index changes to update the active MediaItem
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // 3. Initialize the player with our dynamic playlist
    _player.setAudioSource(_playlist);
  }

  /// Maps just_audio states to audio_service's PlaybackState
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState] ?? AudioProcessingState.idle,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  @override
  Future<void> addQueueItems(List<MediaItem> items) async {
    // Update just_audio's playlist
    final audioSources = items.map(_createAudioSource).toList();
    await _playlist.addAll(audioSources);

    // Update audio_service's queue stream
    final newQueue = [...queue.value, ...items];
    queue.add(newQueue);
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    await _playlist.clear();
    await _playlist.addAll(newQueue.map(_createAudioSource).toList());
    queue.add(newQueue);
  }

  @override
  Future<void> removeQueueItem(MediaItem item) async {
    final index = queue.value.indexOf(item);
    if (index != -1) {
      await _playlist.removeAt(index);
      final newQueue = List<MediaItem>.from(queue.value)..removeAt(index);
      queue.add(newQueue);
    }
  }

  AudioSource _createAudioSource(MediaItem item) {
    // Determine if the ID is a local asset or a remote URL
    if (item.id.startsWith('assets/')) {
      return AudioSource.asset(item.id);
    }
    return AudioSource.uri(Uri.parse(item.id));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    // Seek to the beginning of the specific track index in the playlist
    await _player.seek(Duration.zero, index: index);
  }

  AudioPlayer get player => _player;
}
