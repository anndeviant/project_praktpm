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
  }  void _startDeadlineCheckTimer() {
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
      await _loadPrayerSchedule();} catch (e) {
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
          _buildPrayerScheduleCard(),
          const SizedBox(height: 20),          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildNotificationTestCard(),
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

  Widget _buildPrayerScheduleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jadwal Sholat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _showCitySearchDialog,
                  child: Text(_selectedCityName ?? 'Pilih Kota'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_prayerSchedule != null) ...[
              if (_prayerSchedule!.tanggal.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _prayerSchedule!.tanggal,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              _buildPrayerTimeRow('Imsak', _prayerSchedule!.imsak),
              _buildPrayerTimeRow('Subuh', _prayerSchedule!.subuh),
              _buildPrayerTimeRow('Dzuhur', _prayerSchedule!.dzuhur),
              _buildPrayerTimeRow('Ashar', _prayerSchedule!.ashar),
              _buildPrayerTimeRow('Maghrib', _prayerSchedule!.maghrib),
              _buildPrayerTimeRow('Isya', _prayerSchedule!.isya),
            ] else ...[
              Center(
                child: Text(
                  _selectedCityName == null
                      ? 'Pilih kota untuk melihat jadwal sholat'
                      : 'Gagal memuat jadwal sholat',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeRow(String prayer, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(prayer, style: const TextStyle(fontSize: 16)),
          Text(
            time,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showCitySearchDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _CitySearchDialog(
            prayerService: _prayerService,            onCitySelected: (cityId, cityName) async {
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

  Widget _buildNotificationTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Reminder Notification',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Sistem akan mengirim reminder 15 menit sebelum deadline quest',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testNotification,
                    icon: const Icon(Icons.notification_add),
                    label: const Text('Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkNotificationPermission,
                    icon: const Icon(Icons.settings),
                    label: const Text('Check Permission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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
      final bool hasPermission = await NotificationHelper.areNotificationsEnabled();
      final int pendingCount = await NotificationService().getPendingNotificationsCount();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
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
                      hasPermission ? 'Permission Diizinkan' : 'Permission Ditolak',
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
    return AlertDialog(
      title: const Text('Cari Kota'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama kota...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchCity,
                ),
              ),
              onSubmitted: (_) => _searchCity(),
            ),
            const SizedBox(height: 16),
            if (_isLoading) ...[
              const CircularProgressIndicator(),
            ] else if (_searchResults.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final city = _searchResults[index];
                    return ListTile(
                      title: Text(city.lokasi),
                      onTap: () {
                        widget.onCitySelected(city.id, city.lokasi);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ] else if (_searchController.text.isNotEmpty) ...[
              const Text('Kota tidak ditemukan'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
