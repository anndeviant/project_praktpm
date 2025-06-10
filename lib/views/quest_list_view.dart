import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../services/favorite_service.dart';
import '../services/prayer_service.dart';
import '../models/quest_model.dart';
import '../models/prayer_model.dart';
import '../widgets/quest_theme.dart';
import '../widgets/enhanced_quest_card.dart';
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadHijriCalendar() async {
    try {
      _hijriCalendar = await _prayerService.getHijriCalendar();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _logger.e('Error loading hijri calendar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestTheme.backgroundLight,
      body: Column(
        children: [
          _buildHijriCalendarCard(),
          _buildFilterChips(),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          QuestTheme.primaryBlue,
                        ),
                      ),
                    )
                    : _buildQuestList(),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: QuestTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: QuestTheme.buttonShadow,
        ),
        child: FloatingActionButton(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateQuestView(),
                ),
              ).then((_) => _loadQuests()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildHijriCalendarCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuestTheme.successColor.withValues(alpha: 0.1),
            QuestTheme.successColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: QuestTheme.largeBorderRadius,
        border: Border.all(
          color: QuestTheme.successColor.withValues(alpha: 0.2),
        ),
        boxShadow: QuestTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: QuestTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: QuestTheme.smallBorderRadius,
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: QuestTheme.successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Kalender Hijriah',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: QuestTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_hijriCalendar != null) ...[
            // Hijriah calendar card - more compact
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: QuestTheme.borderRadius,
                border: Border.all(
                  color: QuestTheme.successColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _hijriCalendar!.fullDate,
                    style: const TextStyle(
                      fontSize: 16, // Reduced font size
                      fontWeight: FontWeight.bold,
                      color: QuestTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6), // Reduced spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Hijriah',
                              style: TextStyle(
                                fontSize: 11, // Reduced font size
                                color: QuestTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _hijriCalendar!.formattedHijriDate,
                              style: TextStyle(
                                fontSize: 12, // Reduced font size
                                fontWeight: FontWeight.w600,
                                color: QuestTheme.successColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30, // Reduced height
                        color: QuestTheme.surfaceColor,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Masehi',
                              style: TextStyle(
                                fontSize: 11,
                                color: QuestTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _hijriCalendar!.formattedGregorianDate,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: QuestTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: QuestTheme.surfaceColor,
                borderRadius: QuestTheme.borderRadius,
              ),
              child: Center(
                child: Text(
                  'Gagal memuat kalender hijriah',
                  style: TextStyle(color: QuestTheme.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', _selectedType == null, () {
              setState(() => _selectedType = null);
              _loadQuests();
            }, QuestTheme.primaryBlue),
            const SizedBox(width: 8),
            _buildFilterChip('Daily', _selectedType == QuestType.daily, () {
              setState(
                () =>
                    _selectedType =
                        _selectedType == QuestType.daily
                            ? null
                            : QuestType.daily,
              );
              _loadQuests();
            }, QuestTheme.dailyColor),
            const SizedBox(width: 8),
            _buildFilterChip('Weekly', _selectedType == QuestType.weekly, () {
              setState(
                () =>
                    _selectedType =
                        _selectedType == QuestType.weekly
                            ? null
                            : QuestType.weekly,
              );
              _loadQuests();
            }, QuestTheme.weeklyColor),
            const SizedBox(width: 8),
            _buildFilterChip('Monthly', _selectedType == QuestType.monthly, () {
              setState(
                () =>
                    _selectedType =
                        _selectedType == QuestType.monthly
                            ? null
                            : QuestType.monthly,
              );
              _loadQuests();
            }, QuestTheme.monthlyColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: isSelected ? null : Colors.white,
          borderRadius: QuestTheme.borderRadius,
          border: Border.all(
            color:
                isSelected ? Colors.transparent : color.withValues(alpha: 0.3),
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(
                QuestTypeHelper.getQuestTypeIcon(label.toLowerCase()),
                size: 16,
                color: Colors.white,
              ),
            if (isSelected) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestList() {
    if (_quests.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: QuestTheme.surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: QuestTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No quests found',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: QuestTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedType != null
                    ? 'No ${_selectedType!.name} quests available'
                    : 'Create your first quest to get started!',
                style: const TextStyle(
                  fontSize: 14,
                  color: QuestTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              QuestButton(
                text: 'Create Quest',
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateQuestView(),
                      ),
                    ).then((_) => _loadQuests()),
                icon: Icons.add,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _quests.length,
      itemBuilder: (context, index) {
        final quest = _quests[index];
        return FutureBuilder<bool>(
          future: _favoriteService.isFavorite(
            quest.id,
            _authService.currentUser?.uid ?? '',
          ),
          builder: (context, snapshot) {
            final isFavorite = snapshot.data ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: EnhancedQuestCard(
                quest: quest,
                isFavorite: isFavorite,
                onFavorite: () => _toggleFavorite(quest, isFavorite),
                onProgress:
                    quest.isCompleted ? null : () => _updateProgress(quest),
                showProgress: true,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleFavorite(Quest quest, bool isFavorite) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;
    if (isFavorite) {
      await _favoriteService.removeFavorite(quest.id, userId);
    } else {
      await _favoriteService.addFavorite(quest.id, userId, quest.title);
    }
    if (mounted) {
      setState(() {});
    }
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

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
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
