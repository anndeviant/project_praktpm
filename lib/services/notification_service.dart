import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:logger/logger.dart';
import '../models/quest_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  // Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions for Android 13+
      await _requestPermissions();

      _logger.i('Notification service initialized successfully');
    } catch (e) {
      _logger.e('Error initializing notification service: $e');
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      _logger.e('Error requesting notification permissions: $e');
    }
  }

  // Request notification permissions (public method)
  Future<bool?> requestPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
        return granted;
      }      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final bool? granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted;
      }
      
      return true; // Default to true if platform not detected
    } catch (e) {
      _logger.e('Error requesting notification permissions: $e');
      return false;
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap here
    // You can navigate to specific quest or show quest details
    final Logger logger = Logger();
    logger.i('Notification tapped: ${response.payload}');
  }
  // Schedule reminder notification for quest deadline
  Future<void> scheduleQuestDeadlineReminder(Quest quest) async {
    if (quest.deadline == null) {
      _logger.w('Quest ${quest.title} has no deadline, skipping notification');
      return;
    }

    try {
      // Request permission first
      final bool? permissionGranted = await requestPermission();
      if (permissionGranted != true) {
        _logger.w('Notification permission not granted, cannot schedule reminder');
        return;
      }

      // Calculate reminder time (15 minutes before deadline)
      final DateTime reminderTime = quest.deadline!.subtract(const Duration(minutes: 15));
      final DateTime now = DateTime.now();

      _logger.i('Quest: ${quest.title}');
      _logger.i('Deadline: ${quest.deadline}');
      _logger.i('Reminder time: $reminderTime');
      _logger.i('Current time: $now');

      // Check if reminder time is in the future
      if (reminderTime.isBefore(now)) {
        _logger.w('Quest ${quest.title} deadline is too close or has passed, skipping notification');
        return;
      }

      // Convert to timezone aware datetime
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);      // Create notification details with high priority for better delivery
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'quest_deadline_channel',
        'Quest Deadline Reminders',
        channelDescription: 'Notifications for quest deadlines',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        showWhen: true,
        when: null,
        usesChronometer: false,
        chronometerCountDown: false,
        autoCancel: false,
        ongoing: false,
        category: AndroidNotificationCategory.reminder,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );      // Schedule the notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        quest.id.hashCode, // Use quest ID hash as notification ID
        'Quest Deadline Reminder ⏰',
        '${quest.title} akan berakhir dalam 15 menit!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: quest.id,
      );

      _logger.i('✅ Scheduled deadline reminder for quest: ${quest.title}');
      _logger.i('🕒 Reminder time: $reminderTime');
      _logger.i('🎯 Deadline: ${quest.deadline}');
      _logger.i('🆔 Notification ID: ${quest.id.hashCode}');
    } catch (e) {
      _logger.e('Error scheduling quest deadline reminder: $e');
    }
  }

  // Cancel notification for a quest
  Future<void> cancelQuestNotification(String questId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(questId.hashCode);
      _logger.i('Cancelled notification for quest: $questId');
    } catch (e) {
      _logger.e('Error cancelling notification: $e');
    }
  }

  // Update quest deadline reminder (cancel old and schedule new)
  Future<void> updateQuestDeadlineReminder(Quest quest) async {
    await cancelQuestNotification(quest.id);
    await scheduleQuestDeadlineReminder(quest);
  }

  // Schedule multiple quest reminders
  Future<void> scheduleMultipleQuestReminders(List<Quest> quests) async {
    for (Quest quest in quests) {
      if (quest.deadline != null && !quest.isCompleted) {
        await scheduleQuestDeadlineReminder(quest);
      }
    }
  }  // Show a test notification (for debugging)
  Future<void> showTestNotification() async {
    try {
      // Request permission first
      final bool? permissionGranted = await requestPermission();
      _logger.i('Test notification - Permission granted: $permissionGranted');
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Channel for test notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _flutterLocalNotificationsPlugin.show(
        999,
        'Test Notification',
        'Notifikasi reminder quest sudah aktif! 🎯',
        platformChannelSpecifics,
        payload: 'test',
      );
      
      _logger.i('Test notification sent successfully');
    } catch (e) {
      _logger.e('Error showing test notification: $e');
    }
  }

  // Show immediate notification (for urgent reminders)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'immediate_reminder_channel',
        'Immediate Reminders',
        channelDescription: 'Urgent notifications for immediate attention',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
        showWhen: true,
        autoCancel: true,
        ticker: 'Quest Reminder',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'reminder',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      _logger.i('Immediate notification sent: $title');
    } catch (e) {
      _logger.e('Error showing immediate notification: $e');
    }
  }

  // Get pending notifications count (for debugging)
  Future<int> getPendingNotificationsCount() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      _logger.i('Pending notifications count: ${pendingNotifications.length}');
      return pendingNotifications.length;
    } catch (e) {
      _logger.e('Error getting pending notifications: $e');
      return 0;
    }
  }

  // Clear all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      _logger.i('All notifications cancelled');
    } catch (e) {
      _logger.e('Error cancelling all notifications: $e');
    }
  }
}
