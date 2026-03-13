import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maternal_infant_care/domain/services/youtube_video_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

final youtubeVideoServiceProvider = Provider<YoutubeVideoService>((ref) {
  return YoutubeVideoService();
});

class TrimesterVideoState {
  final PregnancyLearningVideo? selectedVideo;
  final String? selectedTrimester;
  final bool isMiniPlayerVisible;
  final bool isPlaying;
  final double progress;
  final bool hasEmbedError;

  const TrimesterVideoState({
    this.selectedVideo,
    this.selectedTrimester,
    this.isMiniPlayerVisible = false,
    this.isPlaying = false,
    this.progress = 0,
    this.hasEmbedError = false,
  });

  TrimesterVideoState copyWith({
    PregnancyLearningVideo? selectedVideo,
    String? selectedTrimester,
    bool? isMiniPlayerVisible,
    bool? isPlaying,
    double? progress,
    bool? hasEmbedError,
    bool clearSelectedVideo = false,
  }) {
    return TrimesterVideoState(
      selectedVideo: clearSelectedVideo ? null : (selectedVideo ?? this.selectedVideo),
      selectedTrimester: clearSelectedVideo ? null : (selectedTrimester ?? this.selectedTrimester),
      isMiniPlayerVisible: isMiniPlayerVisible ?? this.isMiniPlayerVisible,
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
      hasEmbedError: hasEmbedError ?? this.hasEmbedError,
    );
  }
}

final trimesterVideoProvider = StateNotifierProvider.autoDispose<
    TrimesterVideoNotifier, TrimesterVideoState>((ref) {
  final service = ref.watch(youtubeVideoServiceProvider);
  final notifier = TrimesterVideoNotifier(service);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class TrimesterVideoNotifier extends StateNotifier<TrimesterVideoState> {
  final YoutubeVideoService _service;
  YoutubePlayerController? _controller;

  TrimesterVideoNotifier(this._service) : super(const TrimesterVideoState());

    Map<String, List<PregnancyLearningVideo>> get pregnancyVideos =>
      _service.pregnancyVideos;

  YoutubePlayerController? get controller => _controller;

  String thumbnailFor(String videoId) => _service.thumbnailFor(videoId);

  void selectVideo(String trimesterKey, PregnancyLearningVideo video) {
    if (_controller == null) {
      _controller = _service.createController(video.videoId)..addListener(_onControllerUpdate);
    } else {
      _controller!.load(video.videoId);
    }

    state = state.copyWith(
      selectedVideo: video,
      selectedTrimester: trimesterKey,
      isMiniPlayerVisible: false,
      isPlaying: true,
      progress: 0,
      hasEmbedError: false,
    );
  }

  void togglePlayPause() {
    if (_controller == null) {
      return;
    }

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  void showMiniPlayer() {
    if (state.selectedVideo == null || !state.isPlaying) {
      return;
    }
    state = state.copyWith(isMiniPlayerVisible: true);
  }

  void hideMiniPlayer() {
    if (!state.isMiniPlayerVisible) {
      return;
    }
    state = state.copyWith(isMiniPlayerVisible: false);
  }

  void closePlayer() {
    _controller?.pause();
    state = state.copyWith(
      clearSelectedVideo: true,
      isMiniPlayerVisible: false,
      isPlaying: false,
      progress: 0,
      hasEmbedError: false,
    );
  }

  void _onControllerUpdate() {
    if (_controller == null) {
      return;
    }

    final value = _controller!.value;

    if (value.hasError &&
        (value.errorCode == 150 || value.errorCode == 101)) {
      if (mounted) {
        state = state.copyWith(hasEmbedError: true, isPlaying: false);
      }
      return;
    }

    final durationMs = value.metaData.duration.inMilliseconds;
    final positionMs = value.position.inMilliseconds;

    final double nextProgress = durationMs <= 0
        ? 0
        : (positionMs / durationMs).clamp(0.0, 1.0);

    if (mounted) {
      state = state.copyWith(
        isPlaying: value.isPlaying,
        progress: nextProgress,
      );
    }
  }

  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _controller = null;
  }
}
