import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:maternal_infant_care/core/constants/app_constants.dart';
import 'package:maternal_infant_care/core/utils/notification_service.dart';
import 'package:maternal_infant_care/data/models/reminder_model.dart';
import 'package:maternal_infant_care/data/models/vaccination_model.dart';
import 'package:maternal_infant_care/data/models/pregnancy_model.dart';

class ReminderService {
  static int _notificationIdCounter = 1000;

  static int _getNextNotificationId() {
    _notificationIdCounter++;
    if (_notificationIdCounter > AppConstants.maxNotificationId) {
      _notificationIdCounter = 1000;
    }
    return _notificationIdCounter;
  }

  static int _stableNotificationId(String key) {
    return (key.hashCode & 0x7fffffff) % AppConstants.maxNotificationId;
  }

  static DateTime _nextDailyOccurrence(DateTime originalTime) {
    final now = DateTime.now();
    var reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      originalTime.hour,
      originalTime.minute,
    );

    if (!reminderTime.isAfter(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    return reminderTime;
  }

  static Future<ReminderModel> scheduleReminder(
    ReminderModel reminder, {
    bool repeatsDaily = false,
    bool preserveNotificationId = false,
  }) async {
    final notificationId = preserveNotificationId && reminder.notificationId != null
        ? reminder.notificationId!
        : (reminder.notificationId ?? _stableNotificationId('reminder_${reminder.id}'));

    var scheduledTime = repeatsDaily
        ? _nextDailyOccurrence(reminder.scheduledTime)
        : reminder.scheduledTime;

    final now = DateTime.now();
    if (!scheduledTime.isAfter(now)) {
      if (repeatsDaily) {
        scheduledTime = _nextDailyOccurrence(scheduledTime);
      } else {
        while (!scheduledTime.isAfter(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }
      }

      print('📱 REMINDER SERVICE: Adjusted past reminder to future time: $scheduledTime');
    }

    final updatedReminder = reminder.copyWith(
      notificationId: notificationId,
      scheduledTime: scheduledTime,
    );

    print('📱 REMINDER SERVICE: Scheduling reminder "${updatedReminder.title}"');
    print('   - Notification ID: $notificationId');
    print('   - Scheduled Time: $scheduledTime');
    print('   - Repeats Daily: $repeatsDaily');
    print('   - Title: ${updatedReminder.title}');
    print('   - Description: ${updatedReminder.description}');

    await NotificationService.scheduleNotification(
      id: notificationId,
      title: updatedReminder.title,
      body: updatedReminder.description,
      scheduledDate: scheduledTime,
      matchDateTimeComponents:
          repeatsDaily ? DateTimeComponents.time : null,
    );

    return updatedReminder;
  }

  static Future<ReminderModel> schedulePregnancyReminder(
    PregnancyModel pregnancy,
    ReminderModel reminder,
  ) async {
    return scheduleReminder(reminder, preserveNotificationId: true);
  }

  static Future<void> scheduleVaccinationReminder(
    VaccinationModel vaccination,
  ) async {
    if (vaccination.isCompleted) return;

    final daysUntilDue = vaccination.daysUntilDue;
    final reminderDates = <DateTime>[];

    if (daysUntilDue >= 7) {
      reminderDates.add(vaccination.scheduledDate.subtract(const Duration(days: 7)));
    }
    if (daysUntilDue >= 5) {
      reminderDates.add(vaccination.scheduledDate.subtract(const Duration(days: 5)));
    }
    if (daysUntilDue >= 3) {
      reminderDates.add(vaccination.scheduledDate.subtract(const Duration(days: 3)));
    }
    if (daysUntilDue >= 1) {
      reminderDates.add(vaccination.scheduledDate.subtract(const Duration(days: 1)));
    }
    reminderDates.add(vaccination.scheduledDate);

    for (var date in reminderDates) {
      // Create a date at 9 AM for the reminder
      final reminderTime = DateTime(date.year, date.month, date.day, 9, 0);
      
      if (reminderTime.isAfter(DateTime.now())) {
        final offsetDays = vaccination.scheduledDate.difference(date).inDays;
        final notificationId = _stableNotificationId(
          'vaccination_${vaccination.id}_$offsetDays',
        );
        final daysLeft = vaccination.scheduledDate.difference(reminderTime).inDays + 1;
        
        String bodyText;
        if (daysLeft == 0) {
          bodyText = 'Your vaccine ${vaccination.name} is due TODAY!';
        } else if (daysLeft == 1) {
          bodyText = 'Your vaccination ${vaccination.name} is due in next day';
        } else {
          bodyText = '${vaccination.name} is due in $daysLeft days (${DateFormat('dd/MM/yyyy').format(vaccination.scheduledDate)})';
        }

        await NotificationService.scheduleNotification(
          id: notificationId,
          title: 'Vaccination Reminder',
          body: bodyText,
          scheduledDate: reminderTime,
          matchDateTimeComponents: null,
        );
      }
    }
  }

  static Future<void> scheduleFeedingReminder({
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    final notificationId = _getNextNotificationId();
    await NotificationService.scheduleNotification(
      id: notificationId,
      title: 'Feeding Reminder',
      body: 'Time for feeding',
      scheduledDate: reminderTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleSleepReminder({
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    final notificationId = _getNextNotificationId();
    await NotificationService.scheduleNotification(
      id: notificationId,
      title: 'Sleep Time Reminder',
      body: 'Time for bedtime routine',
      scheduledDate: reminderTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<ReminderModel> scheduleDailyReminders(ReminderModel reminder) async {
    return scheduleReminder(reminder, repeatsDaily: true);
  }

  static Future<void> cancelReminder(int? notificationId) async {
    if (notificationId != null) {
      print('🔔 REMINDER SERVICE: Cancelling notification $notificationId');
      await NotificationService.cancelNotification(notificationId);
      print('✅ REMINDER SERVICE: Cancelled notification $notificationId');
    }
  }
}
