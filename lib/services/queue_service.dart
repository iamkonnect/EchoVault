import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import '../models/track.dart';
import 'audio_player_service.dart';
import '../services/image_utils.dart';

enum RepeatMode { off, one, all }

class QueueState {
  final List<Track> queue;
  final List<Track> shuffledQueue;
  final List<Track> originalQueueBeforeShuffle;
  final int currentIndex;
  final bool shuffleActive;
  final RepeatMode repeatMode;

  QueueState({
    required this.queue,
    this.shuffledQueue = const [],
    this.originalQueueBeforeShuffle = const [],
    this.currentIndex = -1,
    this.shuffleActive = false,
    this.repeatMode = RepeatMode.off,
  });

  QueueState copyWith({
    List<Track>? queue,
    List<Track>? shuffledQueue,
    List<Track>? originalQueueBeforeShuffle,
    int? currentIndex,
    bool? shuffleActive,
    RepeatMode? repeatMode,
  }) {
    return QueueState(
      queue: queue ?? this.queue,
      shuffledQueue: shuffledQueue ?? this.shuffledQueue,
      originalQueueBeforeShuffle:
          originalQueueBeforeShuffle ?? this.originalQueueBeforeShuffle,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffleActive: shuffleActive ?? this.shuffleActive,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }

  List<Track> get currentQueue => shuffleActive ? shuffledQueue : queue;
  Track? get currentTrack =>
      currentIndex >= 0 && currentIndex < currentQueue.length
          ? currentQueue[currentIndex]
          : null;
  Track? get nextTrack {
    final queue = currentQueue;
    if (currentIndex < queue.length - 1) return queue[currentIndex + 1];
    if (repeatMode == RepeatMode.all) return queue[0];
    return null;
  }
}

class QueueService extends StateNotifier<QueueState> {
  final Ref _ref;
  QueueService(this._ref) : super(QueueState(queue: []));

  AudioPlayerHandler get _handler => _ref.read(audioHandlerProvider);

  MediaItem _toMediaItem(Track track) {
    // Handle local assets (WhatsApp assets) vs remote URLs
    final String coverPath = ImageUtils.getImagePath(track.cover);

    // Sanitize the track ID (audio source) to avoid crashes in just_audio_web.
    String trackId = track.id;
    if (kReleaseMode || trackId.toLowerCase().contains('featured_echo') || 
        (!trackId.startsWith('assets/') && !trackId.startsWith('http'))) {
      // Skip demo audio in release to avoid missing asset crash
      return const MediaItem(
        id: 'silent',
        title: 'Demo Track',
        artist: 'EchoVault',
        duration: Duration(seconds: 30),
      );
    }

    final artUri = coverPath.startsWith('http')
        ? Uri.parse(coverPath)
        : Uri.parse(Uri.encodeFull('asset:///$coverPath'));

    return MediaItem(
      id: trackId,
      title: track.title,
      artist: track.artist?.name,
      album: track.album?.title,
      duration: Duration(milliseconds: track.duration),
      artUri: artUri,
    );
  }

  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    state = state.copyWith(
      queue: tracks,
      shuffledQueue: [],
      originalQueueBeforeShuffle: [],
      currentIndex: startIndex,
      shuffleActive: false,
    );
    _handler.updateQueue(tracks.map(_toMediaItem).toList()).then((_) {
      if (startIndex >= 0) {
        _handler.skipToQueueItem(startIndex);
      }
    });
  }

  void addToQueue(List<Track> tracks) {
    state = state.copyWith(queue: [...state.queue, ...tracks]);
    _handler.addQueueItems(tracks.map(_toMediaItem).toList());
  }

  void addNextToQueue(List<Track> tracks) {
    final insertIndex = state.currentIndex + 1;
    final newQueue = List<Track>.from(state.queue);
    newQueue.insertAll(insertIndex, tracks);
    state = state.copyWith(queue: newQueue);
    _handler.updateQueue(state.currentQueue.map(_toMediaItem).toList());
  }

  void removeFromQueue(int index) {
    final trackToRemove = state.queue[index];
    final newQueue = List<Track>.from(state.queue);
    newQueue.removeAt(index);
    int newIndex = state.currentIndex;
    if (index < newIndex) newIndex--;
    state = state.copyWith(queue: newQueue, currentIndex: newIndex);
    _handler.removeQueueItem(_toMediaItem(trackToRemove));
  }

  void moveInQueue(int fromIndex, int toIndex) {
    final newQueue = List<Track>.from(state.queue);
    final track = newQueue.removeAt(fromIndex);
    newQueue.insert(toIndex, track);
    state = state.copyWith(queue: newQueue);
    _handler.updateQueue(state.currentQueue.map(_toMediaItem).toList());
  }

  void clearQueue() {
    state = state.copyWith(queue: [], currentIndex: -1);
    _handler.updateQueue([]);
    _handler.stop();
  }

  void toggleShuffle() {
    if (state.shuffleActive) {
      // Disable shuffle - restore original order
      final currentTrack = state.currentQueue[state.currentIndex];
      final originalIndex = state.originalQueueBeforeShuffle
          .indexWhere((t) => t.id == currentTrack.id);
      state = state.copyWith(
        shuffleActive: false,
        currentIndex: originalIndex >= 0 ? originalIndex : 0,
      );
    } else {
      // Enable shuffle
      final tracksToShuffle = List<Track>.from(state.queue);
      if (state.currentIndex >= 0) tracksToShuffle.removeAt(state.currentIndex);

      // Fisher-Yates shuffle
      for (int i = tracksToShuffle.length - 1; i > 0; i--) {
        final j =
            ((DateTime.now().millisecondsSinceEpoch / 100) % (i + 1)).round();

        final temp = tracksToShuffle[i];
        tracksToShuffle[i] = tracksToShuffle[j];
        tracksToShuffle[j] = temp;
      }

      state = state.copyWith(
        shuffledQueue: [state.queue[state.currentIndex], ...tracksToShuffle],
        originalQueueBeforeShuffle: state.queue,
        shuffleActive: true,
        currentIndex: 0,
      );
    }
    _handler.updateQueue(state.currentQueue.map(_toMediaItem).toList());
  }

  void cycleRepeat() {
    RepeatMode nextMode;
    switch (state.repeatMode) {
      case RepeatMode.off:
        nextMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        nextMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        nextMode = RepeatMode.off;
        break;
    }
    state = state.copyWith(repeatMode: nextMode);
  }

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
    _handler.skipToQueueItem(index);
  }

  void nextTrack() {
    final queue = state.currentQueue;
    if (state.currentIndex < queue.length - 1) {
      setCurrentIndex(state.currentIndex + 1);
    } else if (state.repeatMode == RepeatMode.all) {
      setCurrentIndex(0);
    }
  }

  void previousTrack() {
    if (state.currentIndex > 0) {
      setCurrentIndex(state.currentIndex - 1);
    }
  }
}

final queueServiceProvider =
    StateNotifierProvider<QueueService, QueueState>((ref) => QueueService(ref));

