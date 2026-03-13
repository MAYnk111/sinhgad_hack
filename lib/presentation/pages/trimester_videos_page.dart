import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maternal_infant_care/domain/services/youtube_video_service.dart';
import 'package:maternal_infant_care/presentation/viewmodels/trimester_video_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TrimesterVideosPage extends ConsumerWidget {
  const TrimesterVideosPage({super.key});

  static const Map<String, String> _trimesterWeeks = {
    'First Trimester': 'Weeks 1–12',
    'Second Trimester': 'Weeks 13–27',
    'Third Trimester': 'Weeks 28–40',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(trimesterVideoProvider);
    final notifier = ref.read(trimesterVideoProvider.notifier);
    final controller = notifier.controller;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pregnancy Learning Videos'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              theme.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (state.selectedVideo == null) {
                return false;
              }

              if (notification.direction == ScrollDirection.reverse && state.isPlaying) {
                notifier.showMiniPlayer();
              }

              if (notification.direction == ScrollDirection.forward &&
                  notification.metrics.pixels < 80) {
                notifier.hideMiniPlayer();
              }

              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                ),
                if (state.selectedVideo != null &&
                    !state.isMiniPlayerVisible &&
                    (controller != null || state.hasEmbedError))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: _PlayerCard(
                        controller: controller,
                        title: state.selectedVideo!.title,
                        videoId: state.selectedVideo!.videoId,
                        progress: state.progress,
                        hasEmbedError: state.hasEmbedError,
                        onClose: notifier.closePlayer,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    state.isMiniPlayerVisible && state.selectedVideo != null ? 98 : 20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      notifier.pregnancyVideos.entries.map((entry) {
                        final videos = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _TrimesterSectionCard(
                            title: entry.key,
                            weekRange: _trimesterWeeks[entry.key] ?? '',
                            videos: videos,
                            selectedVideo: state.selectedVideo,
                            onVideoTap: (video) => notifier.selectVideo(entry.key, video),
                            thumbnailFor: notifier.thumbnailFor,
                            accentColor: colorScheme.secondary,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.isMiniPlayerVisible && state.selectedVideo != null && !state.hasEmbedError)
            _MiniPlayer(
              title: state.selectedVideo!.title,
              thumbnailUrl: notifier.thumbnailFor(state.selectedVideo!.videoId),
              isPlaying: state.isPlaying,
              onTap: notifier.hideMiniPlayer,
              onPlayPause: notifier.togglePlayPause,
              onClose: notifier.closePlayer,
            ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final YoutubePlayerController? controller;
  final String title;
  final String videoId;
  final double progress;
  final bool hasEmbedError;
  final VoidCallback onClose;

  const _PlayerCard({
    required this.controller,
    required this.title,
    required this.videoId,
    required this.progress,
    required this.hasEmbedError,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardTheme.color,
        border: Border.all(
          color: colorScheme.secondary.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasEmbedError)
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.surfaceVariant,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 40, color: colorScheme.error),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'This video cannot play inside the app.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(
                            'https://www.youtube.com/watch?v=$videoId'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Watch on YouTube'),
                    ),
                  ],
                ),
              )
            else if (controller != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayer(
                  controller: controller!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: colorScheme.secondary,
                  progressColors: ProgressBarColors(
                    playedColor: colorScheme.secondary,
                    handleColor: colorScheme.primary,
                    bufferedColor: colorScheme.secondary.withOpacity(0.35),
                    backgroundColor: colorScheme.onSurface.withOpacity(0.12),
                  ),
                  bottomActions: const [
                    CurrentPosition(),
                    SizedBox(width: 8),
                    ProgressBar(isExpanded: true),
                    SizedBox(width: 8),
                    RemainingDuration(),
                    FullScreenButton(),
                  ],
                ),
              ),
            if (!hasEmbedError) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: colorScheme.onSurface.withOpacity(0.12),
                color: colorScheme.secondary,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrimesterSectionCard extends StatelessWidget {
  final String title;
  final String weekRange;
  final List<PregnancyLearningVideo> videos;
  final PregnancyLearningVideo? selectedVideo;
  final ValueChanged<PregnancyLearningVideo> onVideoTap;
  final String Function(String videoId) thumbnailFor;
  final Color accentColor;

  const _TrimesterSectionCard({
    required this.title,
    required this.weekRange,
    required this.videos,
    required this.selectedVideo,
    required this.onVideoTap,
    required this.thumbnailFor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardTheme.color,
        border: Border.all(
          color: accentColor.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title ($weekRange)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 10),
            if (videos.isEmpty)
              Text(
                'No videos available for this trimester.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              )
            else
              ...videos.map((video) {
                final isSelected = selectedVideo?.videoId == video.videoId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _VideoCard(
                    video: video,
                    thumbnailUrl: thumbnailFor(video.videoId),
                    isSelected: isSelected,
                    onTap: () => onVideoTap(video),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final PregnancyLearningVideo video;
  final String thumbnailUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.thumbnailUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.secondary
                  : colorScheme.secondary.withOpacity(0.25),
              width: isSelected ? 1.4 : 1,
            ),
            color: isSelected
                ? colorScheme.secondary.withOpacity(0.08)
                : colorScheme.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 110,
                    height: 70,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.surfaceVariant,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.play_circle_outline_rounded,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                          ),
                        ),
                        Container(
                          color: Colors.black.withOpacity(0.15),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (video.description != null &&
                          video.description!.isNotEmpty) ...[              
                        const SizedBox(height: 4),
                        Text(
                          video.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.75),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (video.duration != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              video.duration!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final String title;
  final String thumbnailUrl;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onClose;

  const _MiniPlayer({
    required this.title,
    required this.thumbnailUrl,
    required this.isPlaying,
    required this.onTap,
    required this.onPlayPause,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12 + MediaQuery.of(context).padding.bottom,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.cardTheme.color,
              border: Border.all(
                color: colorScheme.secondary.withOpacity(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      thumbnailUrl,
                      width: 64,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 40,
                        color: colorScheme.surfaceVariant,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onPlayPause,
                    icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
