import 'package:flutter/material.dart';

class ConsultationMedicalGuidancePage extends StatelessWidget {
  const ConsultationMedicalGuidancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Guidance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _GuidanceTile(
            title: 'When to contact your doctor',
            body: 'Heavy bleeding, severe pain, fever, or dizziness should be evaluated quickly.',
          ),
          _GuidanceTile(
            title: 'Follow-up planning',
            body: 'Schedule your follow-up visit and keep your reports/medications organized.',
          ),
          _GuidanceTile(
            title: 'Questions to ask',
            body: 'Ask about recovery signs, next checkups, and emotional support resources.',
          ),
        ],
      ),
    );
  }
}

class _GuidanceTile extends StatelessWidget {
  final String title;
  final String body;

  const _GuidanceTile({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.medical_services_outlined, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(body),
      ),
    );
  }
}
