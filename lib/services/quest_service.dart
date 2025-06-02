import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/quest_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class QuestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();

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
  }

  Future<bool> createQuest(Quest quest) async {
    try {
      await _firestore.collection('quests').add(quest.toMap());
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
            progress >=
                    quest
                        .maxProgress // Fix: use maxProgress, not 1
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
      }

      // Award XP if quest is completed
      if (progress >= quest.maxProgress) {
        // Fix: use maxProgress
        await _awardXP(quest.xpReward);
        await _updateBudget(quest.cost);
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
}
