import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../services/prayer_service.dart';
import '../services/notification_service.dart';
import '../models/quest_model.dart';
import '../models/user_model.dart';
import '../models/prayer_model.dart';
import '../utils/notification_helper.dart';
import '../widgets/quest_theme.dart';
import '../widgets/enhanced_quest_card.dart';
import 'package:logger/logger.dart';

class QuestHomeView extends StatefulWidget {
  const QuestHomeView({super.key});

  @override
  State<QuestHomeView> createState() => _QuestHomeViewState();
}

class _QuestHomeViewState extends State<QuestHomeView> {
  final AuthService _authService = AuthService();
  final QuestService _questService = QuestService();
  final PrayerService _prayerService = PrayerService();
  UserProfile? _userProfile;
  List<Quest> _dailyQuests = [];
  List<Quest> _weeklyQuests = [];
  List<Quest> _monthlyQuests = [];
  PrayerSchedule? _prayerSchedule;
  String? _selectedCityName;
  bool _isLoading = true;
  final Logger _logger = Logger();
  bool _disposed = false; // Flag untuk mengecek apakah widget sudah di-dispose
  Timer? _deadlineCheckTimer; // Timer untuk mengecek deadline secara berkala
  @override
  void initState() {
    super.initState();
    _loadData();
    _startDeadlineCheckTimer();
  }

  void _startDeadlineCheckTimer() {
    // Check for upcoming deadlines every 15 minutes (reduced from 5 minutes)
    // This ensures notifications work even when scheduled notifications fail
    _deadlineCheckTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (!_disposed && mounted) {
        _questService.checkUpcomingDeadlinesWithSmartNotification();
      }
    });
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
        // Schedule notifications for all active quests with deadlines
        await _questService.scheduleAllQuestNotifications(kodeKkn);

        // Check for immediate deadline notifications (smart check to prevent spam)
        await _questService.checkUpcomingDeadlinesWithSmartNotification();
      }

      // Load prayer schedule
      await _loadPrayerSchedule();
    } catch (e) {
      _logger.e('Error loading data: $e');
    } finally {
      // Cek apakah widget masih mounted sebelum memanggil setState
      if (mounted && !_disposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPrayerSchedule() async {
    try {
      _selectedCityName = await _prayerService.getSelectedCityName();
      _prayerSchedule = await _prayerService.getTodayPrayerSchedule();
    } catch (e) {
      _logger.e('Error loading prayer schedule: $e');
    }
  }

  @override
  void dispose() {
    // Cancel timer
    _deadlineCheckTimer?.cancel();
    // Set flag bahwa widget sudah di-dispose
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(gradient: QuestTheme.primaryGradient),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Loading Quest Dashboard...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_userProfile == null) {
      return const Center(
        child: Text(
          'Error loading user data',
          style: TextStyle(fontSize: 16, color: QuestTheme.errorColor),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [QuestTheme.primaryBlue, QuestTheme.backgroundLight],
          stops: [0.0, 0.3],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildLevelCard(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildProgressOverview(),
            const SizedBox(height: 24),
            _buildPrayerScheduleCard(),
            const SizedBox(height: 24),
            _buildRecentQuests(),
            const SizedBox(height: 24),
            _buildNotificationTestCard(),
            const SizedBox(height: 100), // Extra padding for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerScheduleCard() {
    return QuestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row - simplified to prevent overflow
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: QuestTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: QuestTheme.smallBorderRadius,
                ),
                child: Icon(
                  Icons.mosque,
                  color: QuestTheme.successColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Jadwal Sholat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: QuestTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showCitySearchDialog,
                icon: const Icon(Icons.location_on, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: QuestTheme.primaryBlue.withValues(
                    alpha: 0.1,
                  ),
                  foregroundColor: QuestTheme.primaryBlue,
                  padding: const EdgeInsets.all(8),
                ),
                tooltip: 'Pilih Kota',
              ),
            ],
          ),

          // City name display below header
          if (_selectedCityName != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: QuestTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: QuestTheme.smallBorderRadius,
                border: Border.all(
                  color: QuestTheme.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_city,
                    size: 14,
                    color: QuestTheme.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selectedCityName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: QuestTheme.primaryBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          if (_prayerSchedule != null) ...[
            if (_prayerSchedule!.tanggal.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: QuestTheme.surfaceColor,
                  borderRadius: QuestTheme.smallBorderRadius,
                ),
                child: Text(
                  _prayerSchedule!.tanggal,
                  style: const TextStyle(
                    fontSize: 12,
                    color: QuestTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    QuestTheme.successColor.withValues(alpha: 0.1),
                    QuestTheme.successColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: QuestTheme.borderRadius,
                border: Border.all(
                  color: QuestTheme.successColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildPrayerTimeItem(
                          'Imsak',
                          _prayerSchedule!.imsak,
                        ),
                      ),
                      Expanded(
                        child: _buildPrayerTimeItem(
                          'Subuh',
                          _prayerSchedule!.subuh,
                        ),
                      ),
                      Expanded(
                        child: _buildPrayerTimeItem(
                          'Dzuhur',
                          _prayerSchedule!.dzuhur,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPrayerTimeItem(
                          'Ashar',
                          _prayerSchedule!.ashar,
                        ),
                      ),
                      Expanded(
                        child: _buildPrayerTimeItem(
                          'Maghrib',
                          _prayerSchedule!.maghrib,
                        ),
                      ),
                      Expanded(
                        child: _buildPrayerTimeItem(
                          'Isya',
                          _prayerSchedule!.isya,
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: QuestTheme.surfaceColor,
                borderRadius: QuestTheme.borderRadius,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.location_off,
                    size: 40,
                    color: QuestTheme.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedCityName == null
                        ? 'Pilih kota untuk melihat jadwal sholat'
                        : 'Gagal memuat jadwal sholat',
                    style: const TextStyle(
                      fontSize: 13,
                      color: QuestTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerTimeItem(String name, String time) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 10, // Further reduced font size
            color: QuestTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontSize: 11, // Further reduced font size
            fontWeight: FontWeight.bold,
            color: QuestTheme.successColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showCitySearchDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _CitySearchDialog(
            prayerService: _prayerService,
            onCitySelected: (cityId, cityName) async {
              await _prayerService.saveSelectedCity(cityId, cityName);
              await _loadPrayerSchedule();
              // Cek apakah widget masih mounted sebelum memanggil setState
              if (mounted && !_disposed) {
                setState(() {});
              }
            },
          ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: QuestTheme.largeBorderRadius,
        boxShadow: QuestTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12), // Reduced padding
                decoration: BoxDecoration(
                  gradient: QuestTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: 24,
                ), // Reduced icon size
              ),
              const SizedBox(width: 12), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang!',
                      style: const TextStyle(
                        fontSize: 14, // Reduced font size
                        color: QuestTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _userProfile!.namaLengkap,
                      style: const TextStyle(
                        fontSize: 18, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: QuestTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis, // Prevent overflow
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced spacing
          Container(
            padding: const EdgeInsets.all(12), // Reduced padding
            decoration: BoxDecoration(
              gradient: QuestTheme.questGradient,
              borderRadius: QuestTheme.borderRadius,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 20,
                ), // Reduced icon size
                const SizedBox(width: 10), // Reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KKN Quest ID',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11, // Reduced font size
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _userProfile!.kodeKkn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14, // Reduced font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
    return LevelProgressCard(
      currentLevel: _userProfile!.level,
      currentXP: _userProfile!.xp,
      xpForNextLevel: _userProfile!.xpForNextLevel,
      progress: _userProfile!.xpProgress,
    );
  }

  Widget _buildProgressOverview() {
    return QuestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quest Progress Overview',
            style: TextStyle(
              fontSize: 18, // Reduced font size
              fontWeight: FontWeight.bold,
              color: QuestTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16), // Reduced spacing
          _buildProgressRow(
            'Daily Quests',
            _dailyQuests,
            QuestTheme.dailyColor,
          ),
          const SizedBox(height: 12), // Reduced spacing
          _buildProgressRow(
            'Weekly Quests',
            _weeklyQuests,
            QuestTheme.weeklyColor,
          ),
          const SizedBox(height: 12),
          _buildProgressRow(
            'Monthly Quests',
            _monthlyQuests,
            QuestTheme.monthlyColor,
          ),
        ],
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
          children: [
            Expanded(
              // Wrap in Expanded to prevent overflow
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4), // Reduced padding
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4), // Reduced radius
                    ),
                    child: Icon(
                      QuestTypeHelper.getQuestTypeIcon(
                        title.split(' ')[0].toLowerCase(),
                      ),
                      color: color,
                      size: 14, // Reduced icon size
                    ),
                  ),
                  const SizedBox(width: 6), // Reduced spacing
                  Flexible(
                    // Use Flexible to prevent overflow
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13, // Reduced font size
                        fontWeight: FontWeight.w600,
                        color: QuestTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$completed/$total',
              style: TextStyle(
                fontSize: 13, // Reduced font size
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6), // Reduced spacing
        QuestProgressIndicator(
          progress: progress,
          valueColor: color,
          height: 6,
        ), // Thinner progress bar
      ],
    );
  }

  Widget _buildQuickStats() {
    int totalCompleted =
        _dailyQuests.where((q) => q.isCompleted).length +
        _weeklyQuests.where((q) => q.isCompleted).length +
        _monthlyQuests.where((q) => q.isCompleted).length;

    int totalQuests =
        _dailyQuests.length + _weeklyQuests.length + _monthlyQuests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quest Statistics',
          style: TextStyle(
            fontSize: 18, // Reduced font size
            fontWeight: FontWeight.bold,
            color: QuestTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12), // Reduced spacing
        Row(
          children: [
            Expanded(
              child: _buildCompactStatsCard(
                title: 'Completed',
                value: totalCompleted.toString(),
                icon: Icons.check_circle,
                color: QuestTheme.successColor,
                subtitle: 'Total done',
              ),
            ),
            const SizedBox(width: 12), // Reduced spacing
            Expanded(
              child: _buildCompactStatsCard(
                title: 'Active',
                value: (totalQuests - totalCompleted).toString(),
                icon: Icons.pending_actions,
                color: QuestTheme.warningColor,
                subtitle: 'In progress',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactStatsCard(
                title: 'Total XP',
                value: _userProfile!.xp.toString(),
                icon: Icons.stars,
                color: QuestTheme.accentGold,
                subtitle: 'Experience',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactStatsCard(
                title: 'Budget Used',
                value:
                    'Rp${(_userProfile!.usedBudget / 1000).toStringAsFixed(0)}K', // Shortened format
                icon: Icons.account_balance_wallet,
                color: QuestTheme.accentOrange,
                subtitle: 'From budget',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // New compact stats card widget to prevent overflow
  Widget _buildCompactStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Compact padding
      decoration: BoxDecoration(
        color: QuestTheme.cardBackground,
        borderRadius: QuestTheme.borderRadius,
        boxShadow: QuestTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: QuestTheme.smallBorderRadius,
                ),
                child: Icon(icon, color: color, size: 20), // Reduced icon size
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8), // Reduced spacing
          Text(
            value,
            style: TextStyle(
              fontSize: 20, // Reduced font size
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12, // Reduced font size
              color: QuestTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10, // Reduced font size
              color: QuestTheme.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentQuests() {
    List<Quest> allQuests = [
      ..._dailyQuests,
      ..._weeklyQuests,
      ..._monthlyQuests,
    ];
    allQuests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    List<Quest> recentQuests = allQuests.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Quests',
              style: TextStyle(
                fontSize: 18, // Reduced font size
                fontWeight: FontWeight.bold,
                color: QuestTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to quest list
              },
              child: const Text(
                'View All',
                style: TextStyle(fontSize: 13),
              ), // Reduced font size
            ),
          ],
        ),
        const SizedBox(height: 12), // Reduced spacing
        if (recentQuests.isEmpty)
          QuestCard(
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: QuestTheme.textMuted,
                ), // Reduced icon size
                const SizedBox(height: 12),
                Text(
                  'No quests yet',
                  style: const TextStyle(
                    fontSize: 14, // Reduced font size
                    fontWeight: FontWeight.w500,
                    color: QuestTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create your first quest to get started!',
                  style: const TextStyle(
                    fontSize: 12, // Reduced font size
                    color: QuestTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...recentQuests.map(
            (quest) => Padding(
              padding: const EdgeInsets.only(bottom: 12), // Reduced spacing
              child: QuestCard(
                padding: const EdgeInsets.all(12), // Reduced padding
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), // Reduced padding
                      decoration: BoxDecoration(
                        color:
                            quest.isCompleted
                                ? QuestTheme.successColor.withValues(alpha: 0.1)
                                : QuestTypeHelper.getQuestTypeColor(
                                  quest.type.name,
                                ).withValues(alpha: 0.1),
                        borderRadius: QuestTheme.smallBorderRadius,
                      ),
                      child: Icon(
                        quest.isCompleted
                            ? Icons.check_circle
                            : QuestTypeHelper.getQuestTypeIcon(quest.type.name),
                        color:
                            quest.isCompleted
                                ? QuestTheme.successColor
                                : QuestTypeHelper.getQuestTypeColor(
                                  quest.type.name,
                                ),
                        size: 20, // Reduced icon size
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest.title,
                            style: const TextStyle(
                              fontSize: 14, // Reduced font size
                              fontWeight: FontWeight.w600,
                              color: QuestTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              QuestChip(
                                label: quest.type.name.toUpperCase(),
                                backgroundColor:
                                    QuestTypeHelper.getQuestTypeColor(
                                      quest.type.name,
                                    ).withValues(alpha: 0.1),
                                textColor: QuestTypeHelper.getQuestTypeColor(
                                  quest.type.name,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ), // Reduced padding
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${quest.xpReward} XP',
                                style: const TextStyle(
                                  fontSize: 11, // Reduced font size
                                  color: QuestTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Colors.blue,
                  size: 20,
                ), // Reduced icon size
                SizedBox(width: 6),
                Text(
                  'Reminder Notification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ), // Reduced font size
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Sistem akan mengirim reminder 15 menit sebelum deadline quest',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ), // Reduced font size
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testNotification,
                    icon: const Icon(
                      Icons.notification_add,
                      size: 16,
                    ), // Reduced icon size
                    label: const Text(
                      'Test Notification',
                      style: TextStyle(fontSize: 12),
                    ), // Reduced font size
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                      ), // Reduced padding
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkNotificationPermission,
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text(
                      'Check Permission',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testNotification() async {
    try {
      final NotificationService notificationService = NotificationService();
      await notificationService.showTestNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification berhasil dikirim! 📱'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error testing notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim test notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final bool hasPermission =
          await NotificationHelper.areNotificationsEnabled();
      final int pendingCount =
          await NotificationService().getPendingNotificationsCount();

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Status Notifikasi'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasPermission ? Icons.check_circle : Icons.cancel,
                          color: hasPermission ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasPermission
                              ? 'Permission Diizinkan'
                              : 'Permission Ditolak',
                          style: TextStyle(
                            color: hasPermission ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Pending notifications: $pendingCount'),
                    if (!hasPermission) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Aktifkan notifikasi di pengaturan untuk mendapat reminder quest.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                  if (!hasPermission)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        NotificationHelper.requestPermission(context);
                      },
                      child: const Text('Request Permission'),
                    ),
                ],
              ),
        );
      }
    } catch (e) {
      _logger.e('Error checking notification permission: $e');
    }
  }
}

class _CitySearchDialog extends StatefulWidget {
  final PrayerService prayerService;
  final Function(String cityId, String cityName) onCitySelected;

  const _CitySearchDialog({
    required this.prayerService,
    required this.onCitySelected,
  });

  @override
  State<_CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<_CitySearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<CitySearch> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchCity() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final results = await widget.prayerService.searchCity(
      _searchController.text.trim(),
    );

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.7; // 70% of screen height

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Reduced radius
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 350, // Reduced width
          maxHeight: maxDialogHeight, // Dynamic height based on screen
        ),
        padding: const EdgeInsets.all(16), // Reduced padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - more compact
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Reduced padding
                  decoration: BoxDecoration(
                    color: QuestTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6), // Reduced radius
                  ),
                  child: Icon(
                    Icons.search,
                    color: QuestTheme.primaryBlue,
                    size: 18, // Reduced icon size
                  ),
                ),
                const SizedBox(width: 8), // Reduced spacing
                const Expanded(
                  child: Text(
                    'Cari Kota',
                    style: TextStyle(
                      fontSize: 16, // Reduced font size
                      fontWeight: FontWeight.bold,
                      color: QuestTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18), // Reduced icon size
                  style: IconButton.styleFrom(
                    backgroundColor: QuestTheme.surfaceColor,
                    padding: const EdgeInsets.all(6), // Reduced padding
                    minimumSize: const Size(32, 32), // Smaller button
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12), // Reduced spacing
            // Search field - more compact
            Container(
              height: 44, // Fixed compact height
              decoration: BoxDecoration(
                color: QuestTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10), // Reduced radius
                border: Border.all(
                  color: QuestTheme.textMuted.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama kota...',
                  hintStyle: const TextStyle(
                    fontSize: 13, // Reduced font size
                    color: QuestTheme.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.location_city,
                    size: 16, // Reduced icon size
                    color: QuestTheme.textSecondary,
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(2), // Reduced margin
                    child: IconButton(
                      onPressed: _searchCity,
                      icon: const Icon(
                        Icons.search,
                        size: 16,
                      ), // Reduced icon size
                      style: IconButton.styleFrom(
                        backgroundColor: QuestTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(6), // Reduced padding
                        minimumSize: const Size(32, 32), // Smaller button
                      ),
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, // Reduced padding
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 13), // Reduced font size
                onSubmitted: (_) => _searchCity(),
              ),
            ),

            const SizedBox(height: 12), // Reduced spacing
            // Search results - flexible height to prevent overflow
            Flexible(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: 80,
                  maxHeight:
                      maxDialogHeight - 180, // Reserve space for other elements
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: QuestTheme.textMuted.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(10), // Reduced radius
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildSearchResults(),
                ),
              ),
            ),

            const SizedBox(height: 12), // Reduced spacing
            // Footer - more compact
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, // Reduced padding
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32), // Smaller button
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 13, // Reduced font size
                    color: QuestTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Container(
        height: 80, // Reduced height
        padding: const EdgeInsets.all(16), // Reduced padding
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20, // Reduced size
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    QuestTheme.primaryBlue,
                  ),
                ),
              ),
              SizedBox(height: 8), // Reduced spacing
              Text(
                'Mencari kota...',
                style: TextStyle(
                  fontSize: 11, // Reduced font size
                  color: QuestTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true, // Important for preventing overflow
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final city = _searchResults[index];
          return InkWell(
            onTap: () {
              widget.onCitySelected(city.id, city.lokasi);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12, // Reduced padding
                vertical: 10,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: QuestTheme.textMuted.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4), // Reduced padding
                    decoration: BoxDecoration(
                      color: QuestTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4), // Reduced radius
                    ),
                    child: Icon(
                      Icons.location_city,
                      size: 12, // Reduced icon size
                      color: QuestTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8), // Reduced spacing
                  Expanded(
                    child: Text(
                      city.lokasi,
                      style: const TextStyle(
                        fontSize: 13, // Reduced font size
                        color: QuestTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10, // Reduced icon size
                    color: QuestTheme.textMuted,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (_searchController.text.isNotEmpty) {
      return Container(
        height: 80, // Reduced height
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 24, // Reduced icon size
                color: QuestTheme.textMuted,
              ),
              const SizedBox(height: 4), // Reduced spacing
              const Text(
                'Kota tidak ditemukan',
                style: TextStyle(
                  fontSize: 12, // Reduced font size
                  color: QuestTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                'Coba dengan kata kunci lain',
                style: TextStyle(
                  fontSize: 10, // Reduced font size
                  color: QuestTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 100, // Reduced height
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_searching,
              size: 24, // Reduced icon size
              color: QuestTheme.textMuted,
            ),
            const SizedBox(height: 4),
            const Text(
              'Masukkan nama kota',
              style: TextStyle(
                fontSize: 12, // Reduced font size
                color: QuestTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              'Contoh: Jakarta, Bandung',
              style: TextStyle(
                fontSize: 10, // Reduced font size
                color: QuestTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
