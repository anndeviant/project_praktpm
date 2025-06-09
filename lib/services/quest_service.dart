import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class QuestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  Future<List<Quest>> getQuestsByKodeKkn(String kodeKkn) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('quests')
              .where('kodeKkn', isEqualTo: kodeKkn)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) => Quest.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.e('Error getting quests: $e');
      return [];
    }
  }

  Future<List<Quest>> getQuestsByType(String kodeKkn, QuestType type) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('quests')
              .where('kodeKkn', isEqualTo: kodeKkn)
              .where('type', isEqualTo: type.index)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) => Quest.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.e('Error getting quests by type: $e');
      return [];
    }
  }  Future<bool> createQuest(Quest quest) async {
    try {
      DocumentReference docRef = await _firestore.collection('quests').add(quest.toMap());
      
      // Schedule deadline reminder notification if quest has deadline
      if (quest.deadline != null) {
        // Create a new quest object with the Firestore document ID
        Quest questForNotification = Quest(
          id: docRef.id,
          title: quest.title,
          description: quest.description,
          type: quest.type,
          status: quest.status,
          xpReward: quest.xpReward,
          cost: quest.cost,
          deadline: quest.deadline,
          startTime: quest.startTime,
          endTime: quest.endTime,
          kodeKkn: quest.kodeKkn,
          childQuestIds: quest.childQuestIds,
          parentQuestId: quest.parentQuestId,
          progress: quest.progress,
          maxProgress: quest.maxProgress,
          createdAt: quest.createdAt,
          createdBy: quest.createdBy,
        );
        await _notificationService.scheduleQuestDeadlineReminder(questForNotification);
      }
      
      _logger.i('Quest created successfully');
      return true;
    } catch (e) {
      _logger.e('Error creating quest: $e');
      return false;
    }
  }

  Future<bool> updateQuestProgress(String questId, int progress) async {
    try {
      // Get quest first to check maxProgress
      DocumentSnapshot questDoc =
          await _firestore.collection('quests').doc(questId).get();
      Quest quest = Quest.fromFirestore(questDoc);

      await _firestore.collection('quests').doc(questId).update({
        'progress': progress,
        'status':
            progress >= quest.maxProgress
                ? QuestStatus.completed.index
                : QuestStatus.inProgress.index,
      });

      // Get updated quest to check if it has parent
      DocumentSnapshot updatedQuestDoc =
          await _firestore.collection('quests').doc(questId).get();
      Quest updatedQuest = Quest.fromFirestore(updatedQuestDoc);

      // Update parent quest progress if exists
      if (updatedQuest.parentQuestId != null) {
        await _updateParentQuestProgress(updatedQuest.parentQuestId!);
      }      // Award XP if quest is completed
      if (progress >= quest.maxProgress) {
        await _awardXP(quest.xpReward);
        await _updateBudget(quest.cost);
        
        // Cancel notification reminder since quest is completed
        await _notificationService.cancelQuestNotification(questId);
      }

      return true;
    } catch (e) {
      _logger.e('Error updating quest progress: $e');
      return false;
    }
  }

  Future<void> _updateParentQuestProgress(String parentQuestId) async {
    try {
      DocumentSnapshot parentDoc =
          await _firestore.collection('quests').doc(parentQuestId).get();
      Quest parentQuest = Quest.fromFirestore(parentDoc);

      // Get all child quests
      QuerySnapshot childSnapshot =
          await _firestore
              .collection('quests')
              .where('parentQuestId', isEqualTo: parentQuestId)
              .get();

      List<Quest> childQuests =
          childSnapshot.docs.map((doc) => Quest.fromFirestore(doc)).toList();

      int completedChildren = childQuests.where((q) => q.isCompleted).length;
      int totalChildren = childQuests.length;

      if (totalChildren > 0) {
        double progressPercentage = completedChildren / totalChildren;
        int newProgress =
            (progressPercentage * parentQuest.maxProgress).round();

        await _firestore.collection('quests').doc(parentQuestId).update({
          'progress': newProgress,
          'status':
              newProgress >= parentQuest.maxProgress
                  ? QuestStatus.completed.index
                  : QuestStatus.inProgress.index,
        });
      }
    } catch (e) {
      _logger.e('Error updating parent quest progress: $e');
    }
  }

  Future<void> _awardXP(int xp) async {
    try {
      if (_authService.currentUser != null) {
        DocumentReference userRef = _firestore
            .collection('users')
            .doc(_authService.currentUser!.uid);

        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot userDoc = await transaction.get(userRef);
          UserProfile user = UserProfile.fromFirestore(userDoc);

          int newXP = user.xp + xp;
          int newLevel = (newXP ~/ 100) + 1;

          transaction.update(userRef, {
            'xp': newXP,
            'level': newLevel,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      }
    } catch (e) {
      _logger.e('Error awarding XP: $e');
    }
  }

  Future<void> _updateBudget(double cost) async {
    try {
      if (_authService.currentUser != null && cost > 0) {
        DocumentReference userRef = _firestore
            .collection('users')
            .doc(_authService.currentUser!.uid);

        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot userDoc = await transaction.get(userRef);
          UserProfile user = UserProfile.fromFirestore(userDoc);

          double newUsedBudget = user.usedBudget + cost;

          transaction.update(userRef, {
            'usedBudget': newUsedBudget,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      }
    } catch (e) {
      _logger.e('Error updating budget: $e');
    }
  }

  Stream<List<Quest>> getQuestsStream(String kodeKkn) {
    return _firestore
        .collection('quests')
        .where('kodeKkn', isEqualTo: kodeKkn)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Quest.fromFirestore(doc)).toList(),
        );
  }

  Future<void> resetExpiredQuests() async {
    try {
      DateTime now = DateTime.now();

      // Reset daily quests
      QuerySnapshot dailyQuests =
          await _firestore
              .collection('quests')
              .where('type', isEqualTo: QuestType.daily.index)
              .where('status', isEqualTo: QuestStatus.completed.index)
              .get();

      for (QueryDocumentSnapshot doc in dailyQuests.docs) {
        Quest quest = Quest.fromFirestore(doc);
        DateTime questDate = quest.createdAt;

        // If quest is from previous day, reset it
        if (questDate.day != now.day ||
            questDate.month != now.month ||
            questDate.year != now.year) {
          await doc.reference.update({
            'progress': 0,
            'status': QuestStatus.inProgress.index,
          });
        }
      }

      // Reset weekly quests
      QuerySnapshot weeklyQuests =
          await _firestore
              .collection('quests')
              .where('type', isEqualTo: QuestType.weekly.index)
              .where('status', isEqualTo: QuestStatus.completed.index)
              .get();

      for (QueryDocumentSnapshot doc in weeklyQuests.docs) {
        Quest quest = Quest.fromFirestore(doc);
        DateTime questDate = quest.createdAt;
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

        if (questDate.isBefore(startOfWeek)) {
          await doc.reference.update({
            'progress': 0,
            'status': QuestStatus.inProgress.index,
          });
        }
      }

      // Reset monthly quests
      QuerySnapshot monthlyQuests =
          await _firestore
              .collection('quests')
              .where('type', isEqualTo: QuestType.monthly.index)
              .where('status', isEqualTo: QuestStatus.completed.index)
              .get();

      for (QueryDocumentSnapshot doc in monthlyQuests.docs) {
        Quest quest = Quest.fromFirestore(doc);
        DateTime questDate = quest.createdAt;

        if (questDate.month != now.month || questDate.year != now.year) {
          await doc.reference.update({
            'progress': 0,
            'status': QuestStatus.inProgress.index,
          });
        }
      }

      _logger.i('Expired quests reset successfully');
    } catch (e) {
      _logger.e('Error resetting expired quests: $e');
    }
  }
  // Schedule notifications for all active quests with deadlines
  Future<void> scheduleAllQuestNotifications(String kodeKkn) async {
    try {
      // First cancel all existing notifications to avoid duplicates
      await _notificationService.cancelAllNotifications();
      
      final quests = await getQuestsByKodeKkn(kodeKkn);
      final activeQuests = quests.where((quest) => 
        !quest.isCompleted && quest.deadline != null).toList();

      _logger.i('Scheduling notifications for ${activeQuests.length} active quests (after clearing duplicates)');
      await _notificationService.scheduleMultipleQuestReminders(activeQuests);
      _logger.i('Successfully scheduled unique notifications for ${activeQuests.length} active quests');
    } catch (e) {
      _logger.e('Error scheduling quest notifications: $e');
    }
  }

  // Cancel notification for a specific quest
  Future<void> cancelQuestNotification(String questId) async {
    try {
      await _notificationService.cancelQuestNotification(questId);
      _logger.i('Cancelled notification for quest: $questId');
    } catch (e) {
      _logger.e('Error cancelling quest notification: $e');
    }
  }

  // Update quest deadline and reschedule notification
  Future<bool> updateQuestDeadline(String questId, DateTime? newDeadline) async {
    try {
      await _firestore.collection('quests').doc(questId).update({
        'deadline': newDeadline,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get updated quest and reschedule notification
      DocumentSnapshot doc = await _firestore.collection('quests').doc(questId).get();
      if (doc.exists) {
        Quest updatedQuest = Quest.fromFirestore(doc);
        if (newDeadline != null && !updatedQuest.isCompleted) {
          await _notificationService.updateQuestDeadlineReminder(updatedQuest);
        } else {
          await _notificationService.cancelQuestNotification(questId);
        }
      }

      _logger.i('Updated quest deadline and rescheduled notification');
      return true;
    } catch (e) {
      _logger.e('Error updating quest deadline: $e');
      return false;
    }
  }  // Check for quests approaching deadline (logging only, no immediate notifications)
  Future<void> checkUpcomingDeadlines() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime reminderThreshold = now.add(const Duration(minutes: 15));

      // Simple query to avoid Firestore composite index requirement
      // We'll filter the results in memory instead
      final QuerySnapshot snapshot = await _firestore
          .collection('quests')
          .where('deadline', isGreaterThan: now)
          .get();

      final List<Quest> upcomingQuests = snapshot.docs
          .map((doc) => Quest.fromFirestore(doc))
          .where((quest) => 
            !quest.isCompleted && 
            quest.deadline != null &&
            quest.deadline!.isBefore(reminderThreshold) &&
            quest.deadline!.isAfter(now))
          .toList();

      _logger.i('Found ${upcomingQuests.length} quests with approaching deadlines (scheduled notifications will handle them)');

      // Log deadline info without sending immediate notifications
      // The scheduled notifications will handle the actual reminders
      for (Quest quest in upcomingQuests) {
        if (quest.deadline != null) {
          final Duration timeUntilDeadline = quest.deadline!.difference(now);
          _logger.i('Quest "${quest.title}" deadline in ${timeUntilDeadline.inMinutes} minutes - notification scheduled');
        }
      }
    } catch (e) {
      _logger.e('Error checking upcoming deadlines: $e');
    }
  }

  // Smart notification check to prevent spam - tracks last notification time
  Future<void> checkUpcomingDeadlinesWithSmartNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final DateTime now = DateTime.now();
      final DateTime reminderThreshold = now.add(const Duration(minutes: 15));

      // Query for quests approaching deadline
      final QuerySnapshot snapshot = await _firestore
          .collection('quests')
          .where('deadline', isGreaterThan: now)
          .get();

      final List<Quest> upcomingQuests = snapshot.docs
          .map((doc) => Quest.fromFirestore(doc))
          .where((quest) => 
            !quest.isCompleted && 
            quest.deadline != null &&
            quest.deadline!.isBefore(reminderThreshold) &&
            quest.deadline!.isAfter(now))
          .toList();

      _logger.i('Smart check: Found ${upcomingQuests.length} quests approaching deadline');

      // Send notification only if we haven't sent one recently for this quest
      for (Quest quest in upcomingQuests) {
        if (quest.deadline != null) {
          final Duration timeUntilDeadline = quest.deadline!.difference(now);
          final String notificationKey = 'last_notification_${quest.id}';
          final int? lastNotificationTime = prefs.getInt(notificationKey);
          final int currentTime = now.millisecondsSinceEpoch;
          
          // Only send notification if:
          // 1. We haven't sent one for this quest before, OR
          // 2. It's been at least 10 minutes since last notification for this quest
          bool shouldSendNotification = false;
          if (lastNotificationTime == null) {
            shouldSendNotification = true;
          } else {
            final int timeSinceLastNotification = currentTime - lastNotificationTime;
            const int tenMinutesInMs = 10 * 60 * 1000;
            shouldSendNotification = timeSinceLastNotification > tenMinutesInMs;
          }
          
          if (shouldSendNotification && timeUntilDeadline.inMinutes <= 15 && timeUntilDeadline.inMinutes > 0) {
            await _notificationService.showImmediateNotification(
              title: 'Quest Deadline Reminder ⏰',
              body: '${quest.title} akan berakhir dalam ${timeUntilDeadline.inMinutes} menit!',
              payload: quest.id,
            );
            
            // Save the notification time to prevent spam
            await prefs.setInt(notificationKey, currentTime);
            _logger.i('Sent smart notification for quest: ${quest.title} (${timeUntilDeadline.inMinutes} min remaining)');
          } else if (!shouldSendNotification) {
            _logger.i('Skipped notification for quest: ${quest.title} (recently notified)');
          }
        }
      }
    } catch (e) {
      _logger.e('Error in smart deadline check: $e');
    }
  }
}
