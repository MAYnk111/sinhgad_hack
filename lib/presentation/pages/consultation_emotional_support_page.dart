import 'package:flutter/material.dart';

class ConsultationEmotionalSupportPage extends StatelessWidget {
  const ConsultationEmotionalSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emotional Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Hero(icon: Icons.support_rounded, title: 'Emotional Support'),
          const SizedBox(height: 12),
          _BulletCard(items: const [
            'Acknowledge your feelings without judgment.',
            'Stay connected with trusted family or friends.',
            'Seek professional counseling when needed.',
            'Allow yourself time for recovery and rest.',
          ]),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final IconData icon;
  final String title;

  const _Hero({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  final List<String> items;

  const _BulletCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
