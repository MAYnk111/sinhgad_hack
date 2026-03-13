import 'package:flutter/material.dart';

class ConsultationRecoveryGuidancePage extends StatelessWidget {
  const ConsultationRecoveryGuidancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      'Prioritize rest and hydration.',
      'Follow medication plans exactly as prescribed.',
      'Use gentle routines and avoid overexertion.',
      'Track symptoms and seek help for warning signs.',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Care')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
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
                            Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
