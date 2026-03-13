import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:maternal_infant_care/domain/services/garbha_sanskar_sound_catalog.dart';
import 'package:maternal_infant_care/presentation/viewmodels/garbha_sanskar_audio_provider.dart';

class GarbhaSanskarMusicPage extends ConsumerStatefulWidget {
  const GarbhaSanskarMusicPage({super.key});

  @override
  ConsumerState<GarbhaSanskarMusicPage> createState() =>
      _GarbhaSanskarMusicPageState();
}

class _GarbhaSanskarMusicPageState
    extends ConsumerState<GarbhaSanskarMusicPage> {
  final List<GarbhaSanskarSound> _tracks = GarbhaSanskarSoundCatalog.sounds;

  int _currentTrackIndex(String? currentAsset) {
    if (currentAsset == null) {
      return -1;
    }
    return _tracks.indexWhere((track) => track.assetPath == currentAsset);
  }

  Future<void> _playTrackByIndex(int index) async {
    final service = ref.read(garbhaSanskarAudioServiceProvider);
    if (index < 0 || index >= _tracks.length) {
      return;
    }

    try {
      await service.playMusicTrack(_tracks[index]);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to play this sound.')),
      );
    }
  }

  Future<void> _playNext(String? currentAsset) async {
    final currentIndex = _currentTrackIndex(currentAsset);
    if (_tracks.isEmpty) {
      return;
    }
    final nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % _tracks.length;
    await _playTrackByIndex(nextIndex);
  }

  Future<void> _playPrevious(String? currentAsset) async {
    final currentIndex = _currentTrackIndex(currentAsset);
    if (_tracks.isEmpty) {
      return;
    }
    final previousIndex = currentIndex <= 0 ? _tracks.length - 1 : currentIndex - 1;
    await _playTrackByIndex(previousIndex);
  }

  Future<void> _toggleTrack(GarbhaSanskarSound track) async {
    final service = ref.read(garbhaSanskarAudioServiceProvider);

    try {
      await service.toggleMusicPlayback(track);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to play this sound.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final service = ref.watch(garbhaSanskarAudioServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music & Sounds'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<PlayerState>(
        stream: service.musicPlayer.playerStateStream,
        initialData: service.musicPlayer.playerState,
        builder: (context, snapshot) {
          return StreamBuilder<Duration>(
            stream: service.musicPlayer.positionStream,
            initialData: service.musicPlayer.position,
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration?>(
                stream: service.musicPlayer.durationStream,
                initialData: service.musicPlayer.duration,
                builder: (context, durationSnapshot) {
          final isPlayerRunning = snapshot.data?.playing ?? false;
          final currentAsset = service.currentMusicAsset;
          final position = positionSnapshot.data ?? Duration.zero;
          final duration = durationSnapshot.data ?? Duration.zero;
          GarbhaSanskarSound? currentTrack;
          for (final track in _tracks) {
            if (track.assetPath == currentAsset) {
              currentTrack = track;
              break;
            }
          }

          return Column(
            children: [
              if (currentTrack != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.secondary,
                        colorScheme.secondary.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPlayerRunning ? Icons.music_note : Icons.pause,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Now Playing',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentTrack.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white38,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                        ),
                        child: Slider(
                          min: 0,
                          max: duration.inMilliseconds > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1,
                          value: position.inMilliseconds
                              .clamp(
                                0,
                                duration.inMilliseconds > 0
                                    ? duration.inMilliseconds
                                    : 1,
                              )
                              .toDouble(),
                          onChanged: (value) {
                            service.seekMusic(
                              Duration(milliseconds: value.round()),
                            );
                          },
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => _playPrevious(currentAsset),
                              icon: const Icon(Icons.skip_previous, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: () => service.skipMusicBy(-10),
                              icon: const Icon(Icons.replay_10, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: () => _toggleTrack(currentTrack!),
                              icon: Icon(
                                isPlayerRunning
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            IconButton(
                              onPressed: () => service.skipMusicBy(10),
                              icon: const Icon(Icons.forward_10, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: () => _playNext(currentAsset),
                              icon: const Icon(Icons.skip_next, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    final isPlaying =
                        currentAsset == track.assetPath && isPlayerRunning;
                    final progress = isPlaying && duration.inMilliseconds > 0
                        ? (position.inMilliseconds / duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MusicCard(
                        track: track,
                        isPlaying: isPlaying,
                        progress: progress,
                        onPlay: () => _toggleTrack(track),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MusicCard extends StatelessWidget {
  final GarbhaSanskarSound track;
  final bool isPlaying;
  final double progress;
  final VoidCallback onPlay;

  const _MusicCard({
    required this.track,
    required this.isPlaying,
    required this.progress,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: track.color.withValues(alpha: isPlaying ? 0.8 : 0.3),
          width: isPlaying ? 2.5 : 1.5,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: track.color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPlay,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: track.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: track.color.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    track.icon,
                    color: track.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: track.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: isPlaying ? progress : 0,
                          backgroundColor:
                              track.color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(track.color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Icon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: track.color,
                      size: 40,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.duration,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
