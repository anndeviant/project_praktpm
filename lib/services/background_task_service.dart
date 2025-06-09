// Background task service - currently disabled
// TODO: Implement when workmanager package is added

/*
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../firebase_options.dart';
import '../models/quest_model.dart';
import 'notification_service.dart';

class BackgroundTaskService {
  static const String _questReminderTaskName = 'questReminderTask';
  static final Logger _logger = Logger();

  // Initialize background task service
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Set to false in production
      );

      // Register periodic task to check quest deadlines
      await Workmanager().registerPeriodicTask(
        _questReminderTaskName,
        _questReminderTaskName,
        frequency: const Duration(hours: 1), // Check every hour
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      _logger.i('Background task service initialized successfully');
    } catch (e) {
      _logger.e('Error initializing background task service: $e');
    }
  }

  // Cancel all background tasks
  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      _logger.i('All background tasks cancelled');
    } catch (e) {
      _logger.e('Error cancelling background tasks: $e');
    }
  }

  // Manually trigger quest reminder check
  static Future<void> checkQuestDeadlines() async {
    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final NotificationService notificationService = NotificationService();
      final DateTime now = DateTime.now();
      final DateTime reminderThreshold = now.add(const Duration(minutes: 15));

      // Query quests with deadlines approaching in the next 15 minutes
      final QuerySnapshot snapshot = await firestore
          .collection('quests')
          .where('deadline', isGreaterThan: now.toUtc())
          .where('deadline', isLessThanOrEqualTo: reminderThreshold.toUtc())
          .where('status', isNotEqualTo: QuestStatus.completed.index)
          .get();

      final List<Quest> upcomingQuests = snapshot.docs
          .map((doc) => Quest.fromFirestore(doc))
          .where((quest) => !quest.isCompleted)
          .toList();

      _logger.i('Found ${upcomingQuests.length} quests with approaching deadlines');

      // Schedule notifications for upcoming quests
      for (Quest quest in upcomingQuests) {
        if (quest.deadline != null) {
          final Duration timeUntilDeadline = quest.deadline!.difference(now);
          
          // If deadline is within 15 minutes, show immediate notification
          if (timeUntilDeadline.inMinutes <= 15 && timeUntilDeadline.inMinutes > 0) {
            await notificationService.showImmediateNotification(
              title: 'Quest Deadline Reminder ⏰',
              body: '${quest.title} akan berakhir dalam ${timeUntilDeadline.inMinutes} menit!',
              payload: quest.id,
            );
          }
        }
      }
    } catch (e) {
      _logger.e('Error checking quest deadlines: $e');
    }
  }
}

// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final Logger logger = Logger();
    
    try {
      logger.i('Executing background task: $task');

      switch (task) {
        case BackgroundTaskService._questReminderTaskName:
          await BackgroundTaskService.checkQuestDeadlines();
          break;
        default:
          logger.w('Unknown background task: $task');
      }

      return Future.value(true);
    } catch (e) {
      logger.e('Error executing background task $task: $e');
      return Future.value(false);
    }
  });
}
*/

// Placeholder class for now
class BackgroundTaskService {
  static Future<void> initialize() async {
    // TODO: Implement when workmanager package is added
  }
  
  static Future<void> checkQuestDeadlines() async {
    // TODO: Implement when workmanager package is added
  }
}
