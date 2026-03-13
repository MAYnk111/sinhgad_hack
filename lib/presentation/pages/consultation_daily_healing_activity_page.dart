import 'package:flutter/material.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_emotional_check_in_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_healing_stories_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_meditation_page.dart';

class ConsultationDailyHealingActivityPage extends StatefulWidget {
  const ConsultationDailyHealingActivityPage({super.key});

  @override
  State<ConsultationDailyHealingActivityPage> createState() =>
      _ConsultationDailyHealingActivityPageState();
}

class _ConsultationDailyHealingActivityPageState
    extends State<ConsultationDailyHealingActivityPage> {
  int _index = DateTime.now().day % 3;

  static const List<_HealingActivity> _activities = [
    _HealingActivity(
      title: 'Breathing Meditation',
      description: 'Complete a 2-minute guided breathing session.',
      icon: Icons.self_improvement,
    ),
    _HealingActivity(
      title: 'Read Healing Story',
      description: 'Read one story to build perspective and hope.',
      icon: Icons.menu_book_rounded,
    ),
    _HealingActivity(
      title: 'Reflection Exercise',
      description: 'Do an emotional check-in and note how you feel today.',
      icon: Icons.edit_note_rounded,
    ),
  ];

  void _openSelectedActivity(BuildContext context, _HealingActivity activity) {
    if (activity.title == 'Breathing Meditation') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConsultationMeditationPage()),
      );
      return;
    }

    if (activity.title == 'Read Healing Story') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConsultationHealingStoriesPage()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConsultationEmotionalCheckInPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activities[_index];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Healing Activity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(activity.icon, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(activity.description),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openSelectedActivity(context, activity),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Activity'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _index = (_index + 1) % _activities.length;
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Another Activity'),
          ),
          const SizedBox(height: 12),
          _QuickActionCard(
            title: 'Breathing meditation',
            subtitle: 'Open guided meditation session',
            icon: Icons.self_improvement,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConsultationMeditationPage()),
            ),
          ),
          _QuickActionCard(
            title: 'Read healing story',
            subtitle: 'Open recovery stories',
            icon: Icons.menu_book_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConsultationHealingStoriesPage(),
              ),
            ),
          ),
          _QuickActionCard(
            title: 'Reflection exercise',
            subtitle: 'Open emotional check-in',
            icon: Icons.edit_note_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConsultationEmotionalCheckInPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealingActivity {
  final String title;
  final String description;
  final IconData icon;

  const _HealingActivity({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
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
