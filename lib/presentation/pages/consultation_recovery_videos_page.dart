import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class RecoveryVideoItem {
  final String title;
  final String videoId;
  final String channel;

  const RecoveryVideoItem({
    required this.title,
    required this.videoId,
    required this.channel,
  });
}

class ConsultationRecoveryVideosPage extends StatefulWidget {
  final List<RecoveryVideoItem> videos;
  final RecoveryVideoItem? initialVideo;

  const ConsultationRecoveryVideosPage({
    super.key,
    required this.videos,
    this.initialVideo,
  });

  @override
  State<ConsultationRecoveryVideosPage> createState() =>
      _ConsultationRecoveryVideosPageState();
}

class _ConsultationRecoveryVideosPageState
    extends State<ConsultationRecoveryVideosPage> {
  YoutubePlayerController? _controller;
  RecoveryVideoItem? _selected;
  bool _hasEmbedError = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialVideo;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selectVideo(initial);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _thumbnailFor(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  Future<void> _openExternal(RecoveryVideoItem video) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=${video.videoId}');
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open YouTube link')),
      );
    }
  }

  Future<void> _selectVideo(RecoveryVideoItem video) async {
    _controller?.dispose();
    setState(() {
      _selected = video;
      _hasEmbedError = false;
    });

    final controller = YoutubePlayerController(
      initialVideoId: video.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );

    controller.addListener(() {
      if (!mounted) return;
      final value = controller.value;
      if (value.hasError && !_hasEmbedError) {
        setState(() {
          _hasEmbedError = true;
        });
      }
    });

    setState(() {
      _controller = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Videos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_selected != null)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasEmbedError)
                      Container(
                        height: 190,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: colorScheme.error, size: 38),
                            const SizedBox(height: 8),
                            const Text('Embedding failed for this video.'),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: () => _openExternal(_selected!),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Watch on YouTube'),
                            ),
                          ],
                        ),
                      )
                    else if (_controller != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: YoutubePlayer(
                          controller: _controller!,
                          showVideoProgressIndicator: true,
                          progressColors: ProgressBarColors(
                            playedColor: colorScheme.primary,
                            handleColor: colorScheme.secondary,
                            bufferedColor:
                              colorScheme.primary.withValues(alpha: 0.35),
                            backgroundColor:
                              colorScheme.onSurface.withValues(alpha: 0.15),
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
                    const SizedBox(height: 10),
                    Text(
                      _selected!.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selected!.channel,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...widget.videos.map(
            (video) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _thumbnailFor(video.videoId),
                        width: 110,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            video.channel,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _selectVideo(video),
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
