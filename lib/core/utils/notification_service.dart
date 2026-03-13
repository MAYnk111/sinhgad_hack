import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const String _defaultReminderChannelId = 'reminder_channel';
  static const String _defaultReminderChannelName = 'Reminder Notifications';

  static Future<void> initialize() async {
    if (_initialized) {
      print('🔔 NOTIFICATION DEBUG: Initialization already completed, skipping');
      return;
    }

    print('🔔 NOTIFICATION DEBUG: Starting Initialization...');
    try {
      // 1. Initialize Timezones
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        print('🔔 NOTIFICATION DEBUG: Timezone set to Asia/Kolkata');
      } catch (e) {
        tz.setLocalLocation(tz.getLocation('UTC'));
        print('🔔 NOTIFICATION DEBUG: Timezone fallback to UTC. Error: $e');
      }
      
      // 2. Settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 3. Initialize Plugin
      final result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          print('🔔 NOTIFICATION DEBUG: Notification tapped. Payload: ${details.payload}');
        },
      );
      print('🔔 NOTIFICATION DEBUG: Plugin .initialize result: $result');

      // 4. Create Channel (Android Only)
      const androidChannel = AndroidNotificationChannel(
        _defaultReminderChannelId,
        _defaultReminderChannelName,
        description: 'This channel is used for reminder notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        print('🔔 NOTIFICATION DEBUG: Android Plugin found. Creating channel and checking permissions...');
        await androidPlugin.createNotificationChannel(androidChannel);
        
        // Check for Android 13+ permission specifically
        final isGranted = await androidPlugin.requestNotificationsPermission();
        print('🔔 NOTIFICATION DEBUG: Post-Android 13 notification permission: $isGranted');
        
        // Check for Exact Alarm permission (Android 12+)
        try {
          final exactAlarm = await androidPlugin.requestExactAlarmsPermission();
          print('🔔 NOTIFICATION DEBUG: Exact Alarm permission: $exactAlarm');
        } catch (e) {
          print('🔔 NOTIFICATION DEBUG: Exact Alarm check threw error (possibly older ANDROID): $e');
        }
      } else {
        print('🔔 NOTIFICATION DEBUG: Android Plugin was NULL (expected on non-Android platforms)');
      }

      _initialized = true;
      
      print('🔔 NOTIFICATION DEBUG: Initialization Finished Successfully');
    } catch (e, stack) {
      print('❌ NOTIFICATION ERROR during Initialization: $e');
      print('❌ STACK TRACE: $stack');
    }
  }

  static Future<bool> requestPermission() async {
    print('🔔 NOTIFICATION DEBUG: Manually requesting permission...');
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        print('🔔 NOTIFICATION DEBUG: Manual permission result: $granted');
        return granted ?? false;
      }
    } catch (e) {
      print('❌ NOTIFICATION ERROR requesting permission: $e');
    }
    return true;
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
  }) async {
    print('🔔 NOTIFICATION DEBUG: showInstantNotification called. ID: $id TITLE: $title');
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId ?? 'high_importance_channel',
        'Urgent Alerts',
        channelDescription: 'Important alerts',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.show(id, title, body, details);
      print('🔔 NOTIFICATION DEBUG: .show() command sent to system');
    } catch (e) {
      print('❌ NOTIFICATION ERROR during showInstant: $e');
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? channelId,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    print('🔔 NOTIFICATION DEBUG: scheduleNotification called. ID: $id, Title: $title, Date: $scheduledDate');
    try {
      if (!_initialized) {
        await initialize();
      }

      final now = DateTime.now();
      var effectiveDate = scheduledDate;

      if (!effectiveDate.isAfter(now)) {
        effectiveDate = now.add(const Duration(seconds: 2));
        print(
          '🔔 NOTIFICATION DEBUG: Adjusted past schedule to future time: $effectiveDate',
        );
      }

      // Convert to TZDateTime
      final tzDateTime = tz.TZDateTime.from(effectiveDate, tz.local);
      
      print('Scheduling reminder for $tzDateTime');
      print('Reminder scheduled at: $tzDateTime');
      print('🔔 NOTIFICATION DEBUG: Scheduling for $tzDateTime (Local timezone)');

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId ?? _defaultReminderChannelId,
            _defaultReminderChannelName,
            channelDescription: 'Scheduled reminders and notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('notification'),
            // Ensure notification persists even if device is low on memory
            autoCancel: true,
            tag: 'reminder_$id',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      print('🔔 NOTIFICATION DEBUG: ✅ Notification scheduled successfully! ID: $id');
      
      // Verify it was scheduled
      final pending = await _notifications.pendingNotificationRequests();
      final scheduled = pending.where((r) => r.id == id).isNotEmpty;
      print('🔔 NOTIFICATION DEBUG: Pending verification - Scheduled: $scheduled (Total pending: ${pending.length})');
    } catch (e, stack) {
      print('❌ NOTIFICATION ERROR during schedule: $e');
      print('❌ STACK TRACE: $stack');
    }
  }

  static Future<void> scheduleDebugReminderIn10Seconds() async {
    final fireAt = DateTime.now().add(const Duration(seconds: 10));
    print('🔔 NOTIFICATION DEBUG: Scheduling 10-second test reminder for $fireAt');

    await cancelNotification(909001);
    await scheduleNotification(
      id: 909001,
      title: 'Reminder Test',
      body: 'This is a 10-second scheduled reminder test.',
      scheduledDate: fireAt,
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
  }) async {
    await showInstantNotification(id: id, title: title, body: body, channelId: channelId);
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('🔔 NOTIFICATION DEBUG: Notification $id cancelled');
    } catch (e) {
      print('❌ NOTIFICATION ERROR during cancel: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      print('🔔 NOTIFICATION DEBUG: All notifications cancelled');
    } catch (e) {
      print('❌ NOTIFICATION ERROR during cancelAll: $e');
    }
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('🔔 NOTIFICATION DEBUG: ${pending.length} pending notifications');
      for (var notification in pending) {
        print('   - ID: ${notification.id}, Title: ${notification.title}');
      }
      return pending;
    } catch (e) {
      print('❌ NOTIFICATION ERROR fetching pending: $e');
      return [];
    }
  }
}
