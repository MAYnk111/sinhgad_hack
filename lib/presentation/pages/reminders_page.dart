import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:maternal_infant_care/core/utils/reminder_service.dart';
import 'package:maternal_infant_care/data/models/reminder_model.dart';
import 'package:maternal_infant_care/presentation/pages/activity_ideas_page.dart';
import 'package:maternal_infant_care/presentation/pages/diaper_tracking_page.dart';
import 'package:maternal_infant_care/presentation/pages/feeding_tracking_page.dart';
import 'package:maternal_infant_care/presentation/pages/sleep_tracking_page.dart';
import 'package:maternal_infant_care/presentation/viewmodels/auth_provider.dart';
import 'package:maternal_infant_care/presentation/viewmodels/parent_suggestions_provider.dart';
import 'package:maternal_infant_care/presentation/viewmodels/repository_providers.dart';
import 'package:maternal_infant_care/presentation/viewmodels/smart_reminder_provider.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_provider.dart';
import 'package:maternal_infant_care/presentation/widgets/smart_reminder_card.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  @override
  Widget build(BuildContext context) {
    final reminderRepo = ref.watch(reminderRepositoryProvider);
    final smartRemindersAsync = ref.watch(smartRemindersProvider);
    final userProfile = ref.watch(userProfileProvider);
    final parentSuggestionsAsync = ref.watch(parentSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: reminderRepo.when(
        data: (repo) {
          final todayReminders = repo.getTodaysReminders();
          final upcomingReminders = repo.getUpcomingReminders();

          return CustomScrollView(
            slivers: [
              if (userProfile == UserProfileType.toddlerParent)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.menu_book_outlined, 
                                  color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Story Time Reminder',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Set a daily story routine for your toddler.',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await _scheduleStoryTimeReminder(context, ref, repo);
                                },
                                icon: const Icon(Icons.schedule),
                                label: const Text('Set Story Time'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Smart Reminders Section
              smartRemindersAsync.when(
                data: (smartList) {
                  final existingIds = repo.getAllReminders().map((r) => r.id).toSet();
                  final visibleSmartList = smartList
                      .where((reminder) => !existingIds.contains(reminder.id))
                      .toList();

                  if (visibleSmartList.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                              const SizedBox(width: 8),
                              Text(
                                'Smart Reminders',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final reminder = visibleSmartList[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: SmartReminderCard(
                                reminder: reminder,
                                onDismiss: () {
                                  _handleSmartDismiss(context, ref, repo, reminder);
                                },
                                onComplete: () {
                                  _handleSmartSchedule(context, ref, repo, reminder);
                                },
                              ),
                            );
                          },
                          childCount: visibleSmartList.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: Divider(height: 32)),
                    ],
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: LinearProgressIndicator()),
                error: (e, s) => SliverToBoxAdapter(
                    child: Text('Error loading smart reminders: $e')),
              ),

              if (userProfile == UserProfileType.toddlerParent)
                parentSuggestionsAsync.when(
                  data: (suggestions) {
                    final dismissedIds = repo.getAllReminders()
                        .where((r) => r.isCompleted)
                        .map((r) => r.id)
                        .toSet();
                    final visibleSuggestions = suggestions
                        .where((s) => !dismissedIds.contains(s.id))
                        .toList();

                    if (visibleSuggestions.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    color: Theme.of(context).colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Smart Suggestions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final suggestion = visibleSuggestions[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: SmartReminderCard(
                                  reminder: suggestion,
                                  onDismiss: () {
                                    _handleSmartDismiss(context, ref, repo, suggestion);
                                  },
                                  onComplete: () {},
                                  actionLabel: 'Open Activity',
                                  onAction: () {
                                    _handleSuggestionAction(context, ref, repo, suggestion);
                                  },
                                ),
                              );
                            },
                            childCount: visibleSuggestions.length,
                          ),
                        ),
                        const SliverToBoxAdapter(child: Divider(height: 32)),
                      ],
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, s) => SliverToBoxAdapter(
                    child: Text('Error loading smart suggestions: $e'),
                  ),
                ),

              // Today's Reminders
              if (todayReminders.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.today,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Today\'s Tasks',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reminder = todayReminders[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4),
                        child: _ReminderCard(reminder: reminder, repo: repo),
                      );
                    },
                    childCount: todayReminders.length,
                  ),
                ),
              ],

              // Upcoming Reminders
              if (upcomingReminders.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.upcoming,
                            color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 12),
                        Text(
                          'Upcoming',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reminder = upcomingReminders[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4),
                        child: _ReminderCard(reminder: reminder, repo: repo),
                      );
                    },
                    childCount: upcomingReminders.length,
                  ),
                ),
              ],

              if (todayReminders.isEmpty && upcomingReminders.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No manual reminders set.')),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error: ${error.toString()}')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
        heroTag: 'fab_reminders',
      ),
    );
  }

  Future<void> _scheduleStoryTimeReminder(
    BuildContext context,
    WidgetRef ref,
    dynamic repo,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null) return;

    final user = ref.read(currentUserProvider);
    final userId = (user?['id'] as String?) ?? 'unknown';

    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );

    final reminder = ReminderModel(
      id: 'toddler_story_${userId}_${now.year}${now.month}${now.day}_${picked.hour}${picked.minute}',
      title: 'Story Time',
      description: 'Time for story reading and bonding with your toddler.',
      scheduledTime: scheduledTime,
      type: 'story',
      isAutoGenerated: false,
      sourceType: 'story',
    );

    final updatedReminder = await ReminderService.scheduleReminder(
      reminder,
      repeatsDaily: true,
    );
    await repo.saveReminder(updatedReminder);
    ref.invalidate(reminderRepositoryProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story time reminder scheduled')),
      );
    }
  }

  void _handleSmartDismiss(
    BuildContext context,
    WidgetRef ref,
    dynamic repo,
    ReminderModel reminder,
  ) {
    final dismissed = reminder.copyWith(isCompleted: true);
    repo.saveReminder(dismissed);
    ref.invalidate(reminderRepositoryProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suggestion dismissed')),
    );
  }

  Future<void> _handleSmartSchedule(
    BuildContext context,
    WidgetRef ref,
    dynamic repo,
    ReminderModel reminder,
  ) async {
    final scheduled = await ReminderService.scheduleReminder(reminder);
    await repo.saveReminder(scheduled);
    ref.invalidate(reminderRepositoryProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder scheduled')),
      );
    }
  }

  Future<void> _handleSuggestionAction(
    BuildContext context,
    WidgetRef ref,
    dynamic repo,
    ReminderModel suggestion,
  ) async {
    await repo.saveReminder(suggestion.copyWith(isCompleted: true));
    ref.invalidate(reminderRepositoryProvider);
    if (!context.mounted) return;
    _openSuggestionTarget(context, suggestion.sourceType);
  }

  void _openSuggestionTarget(BuildContext context, String? target) {
    if (target == 'activity_ideas') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ActivityIdeasPage()),
      );
      return;
    }
    if (target == 'feeding') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FeedingTrackingPage()),
      );
      return;
    }
    if (target == 'sleep') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SleepTrackingPage()),
      );
      return;
    }
    if (target == 'diaper') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DiaperTrackingPage()),
      );
      return;
    }
  }

  Future<void> _showAddReminderDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedType = 'General';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [
                    'General',
                    'Feeding',
                    'Sleep',
                    'Medical',
                    'Vaccination'
                  ].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Select Date'),
                  subtitle:
                      Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Select Time'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setState(() => selectedTime = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                try {
                  final repo =
                      await ref.read(reminderRepositoryProvider.future);
                  final scheduledTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  final reminder = ReminderModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descriptionController.text.isEmpty
                        ? 'Reminder for ${titleController.text}'
                        : descriptionController.text,
                    scheduledTime: scheduledTime,
                    type: selectedType,
                  );

                    final updatedReminder =
                      await ReminderService.scheduleReminder(reminder);
                  await repo.saveReminder(updatedReminder);

                  if (mounted) {
                    Navigator.pop(context);
                    // Force the provider to refresh and show the new reminder
                    ref.invalidate(reminderRepositoryProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reminder scheduled')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final ReminderModel reminder;
  final dynamic repo;

  const _ReminderCard({required this.reminder, required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: reminder.isCompleted
          ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6)
          : null,
      child: CheckboxListTile(
        value: reminder.isCompleted,
        onChanged: (value) async {
          try {
            final updated = reminder.copyWith(isCompleted: value ?? false);
            await repo.saveReminder(updated);
            
            // Cancel notification when task is marked complete
            if (updated.isCompleted && reminder.notificationId != null) {
              await ReminderService.cancelReminder(reminder.notificationId);
              print('✅ Reminder "${reminder.title}" marked complete. Notification ${reminder.notificationId} cancelled.');
            }
            
            // Refresh the provider to update UI
            ref.invalidate(reminderRepositoryProvider);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    updated.isCompleted 
                      ? '✓ Task marked complete'
                      : '○ Task marked incomplete',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        title: Text(
          reminder.title,
          style: TextStyle(
            decoration: reminder.isCompleted 
              ? TextDecoration.lineThrough 
              : TextDecoration.none,
            decorationThickness: 2,
            color: reminder.isCompleted
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
              : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              reminder.description,
              style: TextStyle(
                color: reminder.isCompleted
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a')
                      .format(reminder.scheduledTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ],
        ),
        secondary: CircleAvatar(
          backgroundColor:
              _getColorForType(context, reminder.type).withOpacity(0.2),
          child: Icon(
            _getIconForType(reminder.type),
            color: _getColorForType(context, reminder.type),
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  static IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'feeding':
        return Icons.restaurant;
      case 'sleep':
        return Icons.bedtime;
      case 'medical':
        return Icons.medical_services;
      case 'vaccination':
        return Icons.vaccines;
      case 'story':
        return Icons.menu_book;
      default:
        return Icons.notifications;
    }
  }

  static Color _getColorForType(BuildContext context, String type) {
    switch (type.toLowerCase()) {
      case 'feeding':
        return Theme.of(context).colorScheme.primary;
      case 'sleep':
        return Theme.of(context).colorScheme.secondary;
      case 'medical':
        return Colors.red;
      case 'vaccination':
        return Colors.orange;
      case 'story':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.tertiary;
    }
  }
}
