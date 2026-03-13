import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maternal_infant_care/domain/services/garbha_sanskar_sound_catalog.dart';
import 'package:maternal_infant_care/domain/services/garbha_sanskar_audio_service.dart';
import 'package:maternal_infant_care/presentation/viewmodels/garbha_sanskar_audio_provider.dart';

enum BreathingPhase {
  inhale,
  hold,
  exhale,
}

class GarbhaSanskarMeditationPage extends ConsumerStatefulWidget {
  const GarbhaSanskarMeditationPage({super.key});

  @override
  ConsumerState<GarbhaSanskarMeditationPage> createState() =>
      _GarbhaSanskarMeditationPageState();
}

class _GarbhaSanskarMeditationPageState
    extends ConsumerState<GarbhaSanskarMeditationPage>
    with TickerProviderStateMixin {
  int _selectedDuration = 5;
  bool _isActive = false;
  bool _isPaused = false;
  Duration _meditationDuration = Duration.zero;
  Duration _remainingDuration = Duration.zero;
  final Stopwatch _sessionStopwatch = Stopwatch();
  late final GarbhaSanskarAudioService _audioService;
  late final AnimationController _breathingScaleController;
  late final AnimationController _holdPulseController;
  Timer? _timer;
  Timer? _phaseTimer;
  BreathingPhase _breathingPhase = BreathingPhase.inhale;
  int _phaseSecondsRemaining = 4;

  String _selectedBackgroundSound = 'None';

  final Map<String, String> _backgroundSounds = {
    'Om Chanting': 'assets/sounds/om_chanting.mp3',
    'Flute Meditation': 'assets/sounds/flute_meditation.mp3',
    'Nature Rain': 'assets/sounds/nature_rain.mp3',
    'Calm Bells': 'assets/sounds/calm_bells.mp3',
  };

  final List<int> _durations = [3, 5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(garbhaSanskarAudioServiceProvider);
    _breathingScaleController = AnimationController(
      vsync: this,
      lowerBound: 0.7,
      upperBound: 1.2,
      value: 0.7,
    );
    _holdPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  String get _phaseLabel {
    switch (_breathingPhase) {
      case BreathingPhase.inhale:
        return 'Breathe In';
      case BreathingPhase.hold:
        return 'Hold';
      case BreathingPhase.exhale:
        return 'Breathe Out';
    }
  }

  int _phaseDuration(BreathingPhase phase) {
    switch (phase) {
      case BreathingPhase.inhale:
        return 4;
      case BreathingPhase.hold:
        return 7;
      case BreathingPhase.exhale:
        return 8;
    }
  }

  BreathingPhase _nextPhase(BreathingPhase phase) {
    switch (phase) {
      case BreathingPhase.inhale:
        return BreathingPhase.hold;
      case BreathingPhase.hold:
        return BreathingPhase.exhale;
      case BreathingPhase.exhale:
        return BreathingPhase.inhale;
    }
  }

  void _setBreathingPhase(
    BreathingPhase phase, {
    int? secondsRemaining,
  }) {
    final nextSeconds = secondsRemaining ?? _phaseDuration(phase);
    setState(() {
      _breathingPhase = phase;
      _phaseSecondsRemaining = nextSeconds;
    });
    _syncBreathingAnimation();
  }

  void _syncBreathingAnimation() {
    final remainingDuration = Duration(seconds: _phaseSecondsRemaining);
    _holdPulseController.stop();

    switch (_breathingPhase) {
      case BreathingPhase.inhale:
        _holdPulseController.value = 0;
        _breathingScaleController.animateTo(
          1.2,
          duration: remainingDuration,
          curve: Curves.easeInOut,
        );
      case BreathingPhase.hold:
        _breathingScaleController.value = 1.2;
        _holdPulseController
          ..value = 0
          ..repeat(reverse: true);
      case BreathingPhase.exhale:
        _holdPulseController.value = 0;
        _breathingScaleController.animateBack(
          0.7,
          duration: remainingDuration,
          curve: Curves.easeInOut,
        );
    }
  }

  void _startBreathingCycle() {
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isActive || _isPaused) {
        return;
      }

      if (_phaseSecondsRemaining > 1) {
        setState(() {
          _phaseSecondsRemaining--;
        });
        return;
      }

      _setBreathingPhase(_nextPhase(_breathingPhase));
    });
  }

  void _resetBreathingVisualState() {
    _holdPulseController.stop();
    _holdPulseController.value = 0;
    _breathingScaleController.value = 0.7;
    _breathingPhase = BreathingPhase.inhale;
    _phaseSecondsRemaining = 4;
  }

  Color _phaseFillColor(ColorScheme colorScheme) {
    switch (_breathingPhase) {
      case BreathingPhase.inhale:
        return const Color(0xFFFFE0B2);
      case BreathingPhase.hold:
        return const Color(0xFFF8BBD0);
      case BreathingPhase.exhale:
        return const Color(0xFFFFCCBC);
    }
  }

  Color _phaseAccentColor(ColorScheme colorScheme) {
    switch (_breathingPhase) {
      case BreathingPhase.inhale:
        return colorScheme.secondary;
      case BreathingPhase.hold:
        return const Color(0xFFE91E63);
      case BreathingPhase.exhale:
        return colorScheme.primary;
    }
  }

  Future<void> _startMeditation() async {
    final selectedBackgroundAsset = _selectedBackgroundSound == 'None'
        ? null
        : _backgroundSounds[_selectedBackgroundSound];

    setState(() {
      _isActive = true;
      _isPaused = false;
      _meditationDuration = Duration(minutes: _selectedDuration);
      _remainingDuration = _meditationDuration;
    });
    _resetBreathingVisualState();

    try {
      await _audioService.startMeditationAudio(
        meditationAssetPath:
            GarbhaSanskarSoundCatalog.meditationNarrationSound.assetPath,
        backgroundAssetPath: selectedBackgroundAsset,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start meditation audio.')),
        );
      }
    }

    _sessionStopwatch
      ..reset()
      ..start();
    _setBreathingPhase(BreathingPhase.inhale, secondsRemaining: 4);
    _startBreathingCycle();
    _startSessionSync();
  }

  void _startSessionSync() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isActive) {
        return;
      }

      final elapsed = _sessionStopwatch.elapsed;
      final nextRemaining = _meditationDuration - elapsed;

      if (nextRemaining > Duration.zero) {
        setState(() {
          _remainingDuration = nextRemaining;
        });
      } else {
        _stopMeditation(didComplete: true);
      }
    });
  }

  Future<void> _togglePauseResumeMeditation() async {
    if (_isPaused) {
      await _audioService.resumeMeditationAudio();
      _sessionStopwatch.start();
      _syncBreathingAnimation();
      _startBreathingCycle();
      setState(() {
        _isPaused = false;
      });
    } else {
      await _audioService.pauseMeditationAudio();
      _sessionStopwatch.stop();
      _phaseTimer?.cancel();
      _breathingScaleController.stop(canceled: false);
      _holdPulseController.stop(canceled: false);
      setState(() {
        _isPaused = true;
      });
    }
  }

  Future<void> _stopMeditation({bool didComplete = false}) async {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _sessionStopwatch
      ..stop()
      ..reset();
    _resetBreathingVisualState();

    setState(() {
      _isActive = false;
      _isPaused = false;
      _remainingDuration = Duration.zero;
    });

    await _audioService.stopMeditationAudio();

    if (didComplete) {
      _showCompletionDialog();
    }
  }

  Future<void> _onBackgroundSoundSelected(String? sound) async {
    if (sound == null) {
      return;
    }

    setState(() {
      _selectedBackgroundSound = sound;
    });

    if (_isActive) {
      final selectedAsset =
          sound == 'None' ? null : _backgroundSounds[sound];
      try {
        await _audioService.updateBackgroundSound(selectedAsset);
      } catch (_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load selected background sound.')),
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFFDAA520)),
            SizedBox(width: 12),
            Flexible(child: Text('Session Complete')),
          ],
        ),
        content: const Text(
          'Well done! You\'ve completed your meditation session. Take a moment to notice how you feel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _audioService.stopMeditationAudio();
    _breathingScaleController.dispose();
    _holdPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guided Meditation'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _breathingScaleController,
                      _holdPulseController,
                    ]),
                    builder: (context, child) {
                      final pulseScale = _breathingPhase == BreathingPhase.hold
                          ? (_holdPulseController.value * 0.04)
                          : 0.0;
                      final glowBoost = _breathingPhase == BreathingPhase.hold
                          ? (_holdPulseController.value * 8)
                          : 0.0;
                      final accentColor = _phaseAccentColor(colorScheme);
                      final fillColor = _phaseFillColor(colorScheme);

                      return Transform.scale(
                        scale: _breathingScaleController.value + pulseScale,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                fillColor,
                                accentColor.withValues(alpha: 0.88),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(
                                  alpha: _breathingPhase == BreathingPhase.hold
                                      ? 0.36
                                      : 0.26,
                                ),
                                blurRadius: 28 + glowBoost,
                                spreadRadius: 8 + (glowBoost / 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _phaseLabel,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 215),
                      if (_isActive) ...[
                        Text(
                          '$_phaseSecondsRemaining',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: _phaseAccentColor(colorScheme),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(_remainingDuration),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (!_isActive) ...[
              Text(
                'Choose Duration',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: _durations.map((duration) {
                  final isSelected = _selectedDuration == duration;
                  return ChoiceChip(
                    label: Text('$duration min'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDuration = duration;
                      });
                    },
                    selectedColor: colorScheme.secondary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: colorScheme.secondary.withValues(alpha: 0.5),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Background Sound',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'None',
                groupValue: _selectedBackgroundSound,
                onChanged: _onBackgroundSoundSelected,
                title: const Text('None (Only meditation voice)'),
              ),
              ..._backgroundSounds.keys.map(
                (sound) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: sound,
                  groupValue: _selectedBackgroundSound,
                  onChanged: _onBackgroundSoundSelected,
                  title: Text(sound),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isActive ? _togglePauseResumeMeditation : _startMeditation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isActive
                    ? (_isPaused ? colorScheme.secondary : Colors.orange[700])
                    : colorScheme.secondary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isActive
                        ? (_isPaused ? Icons.play_arrow : Icons.pause)
                        : Icons.play_arrow,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _isActive
                          ? (_isPaused
                              ? 'Resume Meditation'
                              : 'Pause Meditation')
                          : 'Start Meditation',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isActive)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  onPressed: _stopMeditation,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Stop Meditation'),
                ),
              ),
            const SizedBox(height: 32),
            _TechniqueCard(
              title: '4-7-8 Breathing',
              description:
                  'Breathe in for 4 seconds, hold for 7, exhale for 8. This technique is traditionally believed to promote relaxation.',
              icon: Icons.air,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            _TechniqueCard(
              title: 'Benefits',
              description:
                  'Regular meditation may help reduce stress, improve focus, and create a sense of calm. Always listen to your body and consult with healthcare providers.',
              icon: Icons.favorite,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TechniqueCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _TechniqueCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
