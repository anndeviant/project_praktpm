import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../models/quest_model.dart';
import '../models/user_model.dart';
import 'package:logger/logger.dart';

class QuestHomeView extends StatefulWidget {
  const QuestHomeView({super.key});

  @override
  State<QuestHomeView> createState() => _QuestHomeViewState();
}

class _QuestHomeViewState extends State<QuestHomeView> {
  final AuthService _authService = AuthService();
  final QuestService _questService = QuestService();
  UserProfile? _userProfile;
  List<Quest> _dailyQuests = [];
  List<Quest> _weeklyQuests = [];
  List<Quest> _monthlyQuests = [];
  bool _isLoading = true;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userProfile = await _authService.getUserProfile();
      if (userProfile != null) {
        _userProfile = userProfile;

        final kodeKkn = userProfile.kodeKkn;
        _dailyQuests = await _questService.getQuestsByType(
          kodeKkn,
          QuestType.daily,
        );
        _weeklyQuests = await _questService.getQuestsByType(
          kodeKkn,
          QuestType.weekly,
        );
        _monthlyQuests = await _questService.getQuestsByType(
          kodeKkn,
          QuestType.monthly,
        );
      }
    } catch (e) {
      _logger.e('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userProfile == null) {
      return const Center(child: Text('Error loading user data'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildProgressOverview(),
          const SizedBox(height: 20),
          _buildQuickStats(),
          const SizedBox(height: 20),
          _buildRecentQuests(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang, ${_userProfile!.namaLengkap}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Level ${_userProfile!.level} • ${_userProfile!.xp} XP'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _userProfile!.xpProgress),
            const SizedBox(height: 4),
            Text(
              '${_userProfile!.currentLevelXp}/${_userProfile!.xpForNextLevel} XP to next level',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildProgressRow('Daily Quests', _dailyQuests, Colors.orange),
            const SizedBox(height: 8),
            _buildProgressRow('Weekly Quests', _weeklyQuests, Colors.blue),
            const SizedBox(height: 8),
            _buildProgressRow('Monthly Quests', _monthlyQuests, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String title, List<Quest> quests, Color color) {
    int completed = quests.where((q) => q.isCompleted).length;
    int total = quests.length;
    double progress = total > 0 ? completed / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(title), Text('$completed/$total')],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: progress, color: color),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_turned_in,
                    size: 40,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_dailyQuests.where((q) => q.isCompleted).length + _weeklyQuests.where((q) => q.isCompleted).length + _monthlyQuests.where((q) => q.isCompleted).length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Completed'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.attach_money,
                    size: 40,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp${_userProfile!.usedBudget.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Used Budget'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentQuests() {
    List<Quest> allQuests = [
      ..._dailyQuests,
      ..._weeklyQuests,
      ..._monthlyQuests,
    ];
    allQuests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    List<Quest> recentQuests = allQuests.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Quests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recentQuests.map(
              (quest) => ListTile(
                leading: Icon(
                  quest.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: quest.isCompleted ? Colors.green : Colors.grey,
                ),
                title: Text(quest.title),
                subtitle: Text(quest.type.name.toUpperCase()),
                trailing: Text('${quest.xpReward} XP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
