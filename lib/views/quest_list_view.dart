import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../services/favorite_service.dart';
import '../services/prayer_service.dart';
import '../models/quest_model.dart';
import '../models/prayer_model.dart';
import 'create_quest_view.dart';
import 'package:logger/logger.dart';

class QuestListView extends StatefulWidget {
  const QuestListView({super.key});

  @override
  State<QuestListView> createState() => _QuestListViewState();
}

class _QuestListViewState extends State<QuestListView> {
  final AuthService _authService = AuthService();
  final QuestService _questService = QuestService();
  final FavoriteService _favoriteService = FavoriteService();
  final PrayerService _prayerService = PrayerService();
  final Logger _logger = Logger();

  QuestType? _selectedType;
  String _kodeKkn = '';
  List<Quest> _quests = [];
  HijriCalendar? _hijriCalendar;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadQuests(), _loadHijriCalendar()]);
  }

  Future<void> _loadQuests() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        _kodeKkn = userData['kodeKkn'];
        if (_selectedType != null) {
          _quests = await _questService.getQuestsByType(
            _kodeKkn,
            _selectedType!,
          );
        } else {
          _quests = await _questService.getQuestsByKodeKkn(_kodeKkn);
        }
      }
    } catch (e) {
      _logger.e('Error loading quests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHijriCalendar() async {
    try {
      _hijriCalendar = await _prayerService.getHijriCalendar();
    } catch (e) {
      _logger.e('Error loading hijri calendar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHijriCalendarCard(),
          _buildFilterChips(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildQuestList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateQuestView()),
            ).then((_) => _loadQuests()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHijriCalendarCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Kalender Hijriah',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_hijriCalendar != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hijriCalendar!.fullDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _hijriCalendar!.formattedHijriDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Masehi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _hijriCalendar!.formattedGregorianDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              Center(
                child: Text(
                  'Gagal memuat kalender hijriah',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _selectedType == null,
              onSelected: (selected) {
                setState(() => _selectedType = null);
                _loadQuests();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Daily'),
              selected: _selectedType == QuestType.daily,
              onSelected: (selected) {
                setState(
                  () => _selectedType = selected ? QuestType.daily : null,
                );
                _loadQuests();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Weekly'),
              selected: _selectedType == QuestType.weekly,
              onSelected: (selected) {
                setState(
                  () => _selectedType = selected ? QuestType.weekly : null,
                );
                _loadQuests();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Monthly'),
              selected: _selectedType == QuestType.monthly,
              onSelected: (selected) {
                setState(
                  () => _selectedType = selected ? QuestType.monthly : null,
                );
                _loadQuests();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestList() {
    if (_quests.isEmpty) {
      return const Center(child: Text('No quests found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _quests.length,
      itemBuilder: (context, index) {
        final quest = _quests[index];
        return _buildQuestCard(quest);
      },
    );
  }

  Widget _buildQuestCard(Quest quest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quest.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FutureBuilder<bool>(
                  future: _favoriteService.isFavorite(
                    quest.id,
                    _authService.currentUser?.uid ?? '',
                  ),
                  builder: (context, snapshot) {
                    final isFavorite = snapshot.data ?? false;
                    return IconButton(
                      onPressed: () => _toggleFavorite(quest, isFavorite),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : null,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(quest.description),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Chip(
                    label: Text(quest.type.name.toUpperCase()),
                    backgroundColor: _getTypeColor(quest.type),
                  ),
                  const SizedBox(width: 8),
                  if (quest.cost > 0)
                    Chip(
                      label: Text('Rp${quest.cost.toStringAsFixed(0)}'),
                      backgroundColor: Colors.orange.shade100,
                    ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${quest.xpReward} XP'),
                    backgroundColor: Colors.blue.shade100,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: quest.progressPercentage),
            const SizedBox(height: 4),
            Text('${quest.progress}/${quest.maxProgress} completed'),
            const SizedBox(height: 8),
            if (quest.progress <
                quest.maxProgress) // Fix: show button until maxProgress reached
              ElevatedButton(
                onPressed: () => _updateProgress(quest),
                child: const Text('Update Progress'),
              ),
            if (quest.isCompleted) // Add completion indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Quest Completed!',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(QuestType type) {
    switch (type) {
      case QuestType.daily:
        return Colors.orange.shade100;
      case QuestType.weekly:
        return Colors.blue.shade100;
      case QuestType.monthly:
        return Colors.green.shade100;
    }
  }

  Future<void> _toggleFavorite(Quest quest, bool isFavorite) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    if (isFavorite) {
      await _favoriteService.removeFavorite(quest.id, userId);
    } else {
      await _favoriteService.addFavorite(quest.id, userId, quest.title);
    }
    setState(() {});
  }

  Future<void> _updateProgress(Quest quest) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _ProgressUpdateDialog(quest: quest),
    );

    if (result != null) {
      await _questService.updateQuestProgress(quest.id, result);
      _loadQuests();
    }
  }
}

class _ProgressUpdateDialog extends StatefulWidget {
  final Quest quest;

  const _ProgressUpdateDialog({required this.quest});

  @override
  State<_ProgressUpdateDialog> createState() => _ProgressUpdateDialogState();
}

class _ProgressUpdateDialogState extends State<_ProgressUpdateDialog> {
  late int _progress;

  @override
  void initState() {
    super.initState();
    _progress = widget.quest.progress;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current: ${widget.quest.progress}/${widget.quest.maxProgress}'),
          const SizedBox(height: 16),
          Slider(
            value: _progress.toDouble(),
            min: 0,
            max: widget.quest.maxProgress.toDouble(),
            divisions: widget.quest.maxProgress,
            label: _progress.toString(),
            onChanged: (value) => setState(() => _progress = value.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _progress),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
