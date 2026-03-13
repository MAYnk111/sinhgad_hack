import 'package:maternal_infant_care/core/utils/notification_service.dart';
import 'package:maternal_infant_care/core/utils/reminder_service.dart';
import 'package:maternal_infant_care/data/repositories/reminder_repository.dart';
import 'package:maternal_infant_care/data/repositories/vaccination_repository.dart';

class ReminderBootstrapService {
  static Future<void> restorePendingSchedules() async {
    print('🔁 REMINDER BOOTSTRAP: Restoring pending reminder schedules');

    final reminderRepository = ReminderRepository();
    final vaccinationRepository = VaccinationRepository();

    await reminderRepository.init();
    await vaccinationRepository.init();

    await NotificationService.cancelAll();

    final now = DateTime.now();
    final reminders = reminderRepository.getAllReminders();
    for (final reminder in reminders) {
      if (reminder.isCompleted) {
        continue;
      }

      final repeatsDaily = reminder.type.toLowerCase() == 'story';
      if (!repeatsDaily && !reminder.scheduledTime.isAfter(now)) {
        continue;
      }

      final restored = await ReminderService.scheduleReminder(
        reminder,
        repeatsDaily: repeatsDaily,
        preserveNotificationId: true,
      );

      if (restored.notificationId != reminder.notificationId) {
        await reminderRepository.saveReminder(restored);
      }
    }

    final vaccinations = vaccinationRepository.getUpcomingVaccinations();
    for (final vaccination in vaccinations) {
      await ReminderService.scheduleVaccinationReminder(vaccination);
    }

    print('✅ REMINDER BOOTSTRAP: Reminder restore complete');
  }
}