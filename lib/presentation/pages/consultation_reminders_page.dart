import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:maternal_infant_care/core/utils/reminder_service.dart';
import 'package:maternal_infant_care/data/models/reminder_model.dart';
import 'package:maternal_infant_care/presentation/pages/reminders_page.dart';
import 'package:maternal_infant_care/presentation/viewmodels/repository_providers.dart';

class ConsultationRemindersPage extends ConsumerStatefulWidget {
  const ConsultationRemindersPage({super.key});

  @override
  ConsumerState<ConsultationRemindersPage> createState() =>
      _ConsultationRemindersPageState();
}

class _ConsultationRemindersPageState
    extends ConsumerState<ConsultationRemindersPage> {
  Future<void> _scheduleConsultationReminder({
    required String title,
    required String description,
    required String type,
    required bool repeatsDaily,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    final scheduledTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    try {
      final repo = await ref.read(reminderRepositoryProvider.future);
      final reminder = ReminderModel(
        id: 'consult_${DateTime.now().millisecondsSinceEpoch}_$type',
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        type: type,
        sourceType: 'consultation',
      );

      final saved = await ReminderService.scheduleReminder(
        reminder,
        repeatsDaily: repeatsDaily,
      );
      await repo.saveReminder(saved);
      ref.invalidate(reminderRepositoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation reminder scheduled')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to schedule reminder')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminderRepo = ref.watch(reminderRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Reminders'),
        centerTitle: true,
      ),
      body: reminderRepo.when(
        data: (repo) {
          final upcomingConsultation = repo
              .getUpcomingReminders()
              .where((item) => item.sourceType == 'consultation')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Set reminders that support recovery and follow-up care.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _ReminderTypeCard(
                icon: Icons.local_hospital_outlined,
                title: 'Follow-up Doctor Visits',
                subtitle: 'Track upcoming consultation appointments.',
                onTap: () => _scheduleConsultationReminder(
                  title: 'Doctor Follow-up Visit',
                  description:
                      'Attend your scheduled follow-up consultation appointment.',
                  type: 'medical',
                  repeatsDaily: false,
                ),
                actionLabel: 'Set Visit Reminder',
              ),
              _ReminderTypeCard(
                icon: Icons.medication_outlined,
                title: 'Medication',
                subtitle: 'Stay on time with prescribed medicines.',
                onTap: () => _scheduleConsultationReminder(
                  title: 'Medication Reminder',
                  description: 'Take your prescribed medication on time.',
                  type: 'medical',
                  repeatsDaily: true,
                ),
                actionLabel: 'Set Daily Medication',
              ),
              _ReminderTypeCard(
                icon: Icons.favorite_outline,
                title: 'Emotional Wellness Check',
                subtitle:
                    'Schedule moments for rest, reflection, and support.',
                onTap: () => _scheduleConsultationReminder(
                  title: 'Emotional Wellness Check',
                  description:
                      'Take a short pause for breathing, reflection, and support.',
                  type: 'general',
                  repeatsDaily: true,
                ),
                actionLabel: 'Set Wellness Check',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RemindersPage()),
                  );
                },
                icon: const Icon(Icons.alarm_add),
                label: const Text('Manage All Reminders'),
              ),
              const SizedBox(height: 20),
              Text(
                'Upcoming Consultation Reminders',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              if (upcomingConsultation.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No consultation reminders scheduled yet.'),
                  ),
                )
              else
                ...upcomingConsultation.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        Icons.notifications_active_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${item.description}\n${DateFormat('MMM dd, yyyy • hh:mm a').format(item.scheduledTime)}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading reminders: $error'),
        ),
      ),
    );
  }
}

class _ReminderTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _ReminderTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.schedule),
                label: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
