import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maternal_infant_care/domain/services/garbha_sanskar_sound_catalog.dart';
import 'package:maternal_infant_care/presentation/viewmodels/garbha_sanskar_audio_provider.dart';

class ConsultationMeditationPage extends ConsumerStatefulWidget {
  const ConsultationMeditationPage({super.key});

  @override
  ConsumerState<ConsultationMeditationPage> createState() =>
      _ConsultationMeditationPageState();
}

class _ConsultationMeditationPageState
    extends ConsumerState<ConsultationMeditationPage> {
  final List<GarbhaSanskarSound> _sounds =
      GarbhaSanskarSoundCatalog.meditationBackgroundOptions;
  bool _isBreathingActive = false;
  int _phaseIndex = 0;
  int _secondsRemaining = 4;
  int _sessionSecondsLeft = 120;
  DateTime? _lastTick;
  GarbhaSanskarSound? _selectedSound;

  static const _phases = [
    ('Inhale', 4),
    ('Hold', 4),
    ('Exhale', 6),
  ];

  @override
  void initState() {
    super.initState();
    if (_sounds.isNotEmpty) {
      _selectedSound = _sounds.first;
    }
  }

  void _handleTick() {
    if (!_isBreathingActive || !mounted) {
      return;
    }

    final now = DateTime.now();
    if (_lastTick != null && now.difference(_lastTick!).inSeconds < 1) {
      return;
    }
    _lastTick = now;

    if (_sessionSecondsLeft <= 0) {
      _stopSession();
      return;
    }

    setState(() {
      _sessionSecondsLeft -= 1;

      if (_secondsRemaining > 1) {
        _secondsRemaining -= 1;
      } else {
        _phaseIndex = (_phaseIndex + 1) % _phases.length;
        _secondsRemaining = _phases[_phaseIndex].$2;
      }
    });
  }

  Future<void> _startSession() async {
    final audioService = ref.read(garbhaSanskarAudioServiceProvider);
    if (_selectedSound == null) {
      return;
    }

    await audioService.playMusicTrack(_selectedSound!);

    setState(() {
      _isBreathingActive = true;
      _phaseIndex = 0;
      _secondsRemaining = _phases[0].$2;
      _sessionSecondsLeft = 120;
      _lastTick = null;
    });
  }

  Future<void> _toggleSoundPlayback() async {
    final audioService = ref.read(garbhaSanskarAudioServiceProvider);
    if (_selectedSound == null) {
      return;
    }
    await audioService.toggleMusicPlayback(_selectedSound!);
  }

  Future<void> _stopSession() async {
    final audioService = ref.read(garbhaSanskarAudioServiceProvider);
    await audioService.stopMusicPlayback();

    if (!mounted) {
      return;
    }

    setState(() {
      _isBreathingActive = false;
      _phaseIndex = 0;
      _secondsRemaining = _phases[0].$2;
      _sessionSecondsLeft = 120;
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    final audioService = ref.read(garbhaSanskarAudioServiceProvider);
    audioService.stopMusicPlayback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _handleTick();
    final audioService = ref.watch(garbhaSanskarAudioServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meditation & Relaxation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.self_improvement,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Guided Meditation Session',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Breathing phase: ${_phases[_phaseIndex].$1} (${_secondsRemaining}s)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text('Session timer: ${_formatTimer(_sessionSecondsLeft)}'),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    minHeight: 6,
                    value: (120 - _sessionSecondsLeft) / 120,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isBreathingActive ? null : _startSession,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start 2-min Session'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBreathingActive ? _stopSession : null,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Stop'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calming Sound Playback',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<GarbhaSanskarSound>(
                    initialValue: _selectedSound,
                    decoration: const InputDecoration(
                      labelText: 'Select calming sound',
                    ),
                    items: _sounds
                        .map(
                          (sound) => DropdownMenuItem(
                            value: sound,
                            child: Text(sound.title),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedSound = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<bool>(
                    stream: audioService.musicPlayer.playingStream,
                    initialData: audioService.musicPlayer.playing,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return FilledButton.icon(
                        onPressed: _toggleSoundPlayback,
                        icon: Icon(isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill),
                        label: Text(isPlaying ? 'Pause Sound' : 'Play Sound'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Breathing routine: Inhale 4s • Hold 4s • Exhale 6s. Repeat gently and stop if discomfort appears.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
