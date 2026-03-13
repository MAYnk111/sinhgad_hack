import 'package:flutter/material.dart';

class ConsultationRecoveryTrackerPage extends StatefulWidget {
  const ConsultationRecoveryTrackerPage({super.key});

  @override
  State<ConsultationRecoveryTrackerPage> createState() =>
      _ConsultationRecoveryTrackerPageState();
}

class _ConsultationRecoveryTrackerPageState
    extends State<ConsultationRecoveryTrackerPage> {
  double _physical = 0.4;
  double _emotional = 0.35;
  bool _doctorFollowUpDone = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final followUpProgress = _doctorFollowUpDone ? 1.0 : 0.0;
    final overall = (_physical + _emotional + followUpProgress) / 3;

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Tracker')),
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
                  Text(
                    'Overall Recovery',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: overall,
                    minHeight: 8,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text('${(overall * 100).round()}% complete'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ProgressCard(
            title: 'Physical recovery',
            value: _physical,
            onChanged: (value) => setState(() => _physical = value),
            icon: Icons.healing_outlined,
          ),
          _ProgressCard(
            title: 'Emotional wellbeing',
            value: _emotional,
            onChanged: (value) => setState(() => _emotional = value),
            icon: Icons.favorite_border,
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: CheckboxListTile(
              value: _doctorFollowUpDone,
              onChanged: (value) =>
                  setState(() => _doctorFollowUpDone = value ?? false),
              title: const Text(
                'Doctor follow-up',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _doctorFollowUpDone
                    ? 'Follow-up marked complete.'
                    : 'Mark as complete after consultation visit.',
              ),
              secondary: Icon(
                _doctorFollowUpDone
                    ? Icons.check_circle_outline
                    : Icons.pending_actions_outlined,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final IconData icon;

  const _ProgressCard({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${(value * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: value,
              minHeight: 7,
              color: colorScheme.primary,
            ),
            Slider(
              value: value,
              onChanged: onChanged,
              min: 0,
              max: 1,
              divisions: 10,
              label: '${(value * 100).round()}%',
            ),
          ],
        ),
      ),
    );
  }
}
