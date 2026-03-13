import 'package:flutter/material.dart';

class ConsultationDoctorConsultPage extends StatelessWidget {
  const ConsultationDoctorConsultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Consultation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _AdviceCard(
            icon: Icons.warning_amber_rounded,
            title: 'Seek urgent care immediately',
            points: [
              'Heavy bleeding (soaking pads rapidly).',
              'Severe abdominal pain or persistent cramping.',
              'Fever, chills, or foul-smelling discharge.',
              'Fainting, dizziness, or breathlessness.',
            ],
          ),
          _AdviceCard(
            icon: Icons.event_note_rounded,
            title: 'Book a routine follow-up',
            points: [
              'Confirm physical recovery progress.',
              'Discuss lab reports and medication plans.',
              'Ask about next steps for future pregnancy planning.',
            ],
          ),
          _AdviceCard(
            icon: Icons.question_answer_outlined,
            title: 'Questions to discuss with your doctor',
            points: [
              'Which symptoms are expected vs concerning?',
              'How long should recovery typically take?',
              'What emotional support options are available?',
            ],
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> points;

  const _AdviceCard({
    required this.icon,
    required this.title,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(icon, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(point)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
