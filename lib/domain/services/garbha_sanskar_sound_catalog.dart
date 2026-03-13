import 'package:flutter/material.dart';

class GarbhaSanskarSound {
  final String fileName;
  final String title;
  final String category;
  final String duration;
  final String description;
  final Color color;
  final IconData icon;
  final String assetPath;

  const GarbhaSanskarSound({
    required this.fileName,
    required this.title,
    required this.category,
    required this.duration,
    required this.description,
    required this.color,
    required this.icon,
    required this.assetPath,
  });
}

class GarbhaSanskarSoundCatalog {
  static String _formatTitleFromFileName(String fileName) {
    const titleOverrides = {
      'om_chanting': 'Om Chanting',
      'flute_meditation': 'Flute Meditation',
      'nature_sounds': 'Nature Rain',
      'nature_rain': 'Nature Rain',
      'calm_bells': 'Calm Bells',
    };

    final baseName = fileName.split('.').first;
    final overridden = titleOverrides[baseName];
    if (overridden != null) {
      return overridden;
    }

    return baseName
        .split('_')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static GarbhaSanskarSound _soundFromFileName({
    required String fileName,
    required String category,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    return GarbhaSanskarSound(
      fileName: fileName,
      title: _formatTitleFromFileName(fileName),
      category: category,
      duration: '00:30',
      description: description,
      color: color,
      icon: icon,
      assetPath: 'assets/sounds/$fileName',
    );
  }

  static final List<GarbhaSanskarSound> sounds = [
    _soundFromFileName(
      fileName: 'om_chanting.mpeg',
      category: 'Mantra',
      description: 'Sacred chanting for a calm and centered session.',
      color: Color(0xFFCD853F),
      icon: Icons.graphic_eq,
    ),
    _soundFromFileName(
      fileName: 'flute_meditation.mpeg',
      category: 'Instrumental',
      description: 'Gentle flute tones for relaxation and mindfulness.',
      color: Color(0xFF800000),
      icon: Icons.music_note,
    ),
    _soundFromFileName(
      fileName: 'nature_sounds.mpeg',
      category: 'Ambient',
      description: 'Soft natural ambience to support deep breathing.',
      color: Color(0xFFB8860B),
      icon: Icons.nature,
    ),
    _soundFromFileName(
      fileName: 'raga_bhairav.mpeg',
      category: 'Classical',
      description: 'Traditional raga for a serene, grounded atmosphere.',
      color: Color(0xFFDAA520),
      icon: Icons.wb_sunny,
    ),
    _soundFromFileName(
      fileName: 'veena_meditation.mpeg',
      category: 'Classical Instrumental',
      description: 'Soothing veena melodies for reflective meditation.',
      color: Color(0xFF654321),
      icon: Icons.piano,
    ),
  ];

  static GarbhaSanskarSound get meditationNarrationSound => sounds.first;

  static List<GarbhaSanskarSound> get meditationBackgroundOptions {
    final preferredOrder = [
      'om_chanting.mpeg',
      'flute_meditation.mpeg',
      'nature_rain.mpeg',
      'nature_sounds.mpeg',
      'calm_bells.mpeg',
    ];

    final byFile = {for (final sound in sounds) sound.fileName: sound};

    final ordered = <GarbhaSanskarSound>[];
    for (final fileName in preferredOrder) {
      final sound = byFile[fileName];
      if (sound != null) {
        ordered.add(sound);
      }
    }

    return ordered;
  }
}
