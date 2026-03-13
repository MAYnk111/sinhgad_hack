import 'package:flutter/material.dart';
import 'package:maternal_infant_care/presentation/pages/careflow_ai_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_healing_stories_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_meditation_page.dart';

enum _Emotion { sad, anxious, calm, hopeful }

class ConsultationEmotionalCheckInPage extends StatefulWidget {
  const ConsultationEmotionalCheckInPage({super.key});

  @override
  State<ConsultationEmotionalCheckInPage> createState() =>
      _ConsultationEmotionalCheckInPageState();
}

class _ConsultationEmotionalCheckInPageState
    extends State<ConsultationEmotionalCheckInPage> {
  _Emotion? _selected;

  static const _messages = {
    _Emotion.sad:
        'It is okay to feel sad. Healing takes time, and support can make each day lighter.',
    _Emotion.anxious:
        'Your feelings are valid. Slow breathing and clear guidance can reduce anxiety today.',
    _Emotion.calm:
        'Your calmness is a strength. Keep nurturing it with gentle routines and reflection.',
    _Emotion.hopeful:
        'Hope is powerful. Continue with self-care and supportive steps that build confidence.',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Emotional Check-In')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _EmotionChip(
                    label: 'Sad',
                    selected: _selected == _Emotion.sad,
                    onTap: () => setState(() => _selected = _Emotion.sad),
                  ),
                  _EmotionChip(
                    label: 'Anxious',
                    selected: _selected == _Emotion.anxious,
                    onTap: () => setState(() => _selected = _Emotion.anxious),
                  ),
                  _EmotionChip(
                    label: 'Calm',
                    selected: _selected == _Emotion.calm,
                    onTap: () => setState(() => _selected = _Emotion.calm),
                  ),
                  _EmotionChip(
                    label: 'Hopeful',
                    selected: _selected == _Emotion.hopeful,
                    onTap: () => setState(() => _selected = _Emotion.hopeful),
                  ),
                ],
              ),
            ),
          ),
          if (_selected != null) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _messages[_selected]!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Recommended Next Steps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.self_improvement,
              title: 'Try Meditation',
              subtitle: 'Begin guided breathing and calming audio.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConsultationMeditationPage(),
                ),
              ),
            ),
            _ActionCard(
              icon: Icons.menu_book_rounded,
              title: 'Read a Healing Story',
              subtitle: 'Learn from supportive recovery experiences.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConsultationHealingStoriesPage(),
                ),
              ),
            ),
            _ActionCard(
              icon: Icons.chat_bubble_outline,
              title: 'Open Support Chat',
              subtitle: 'Ask personal questions with Vatsalya AI.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VatsalyaAiPage()),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Select an emotion to get supportive guidance and recommendations.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmotionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EmotionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
