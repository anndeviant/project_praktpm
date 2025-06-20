import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/prayer_service.dart';
import '../models/user_model.dart';
import '../models/prayer_model.dart';
import '../widgets/quest_theme.dart';
import 'login_view.dart';
import 'package:logger/logger.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthService _authService = AuthService();
  final PrayerService _prayerService = PrayerService();
  UserProfile? _userProfile;
  RandomAsmaul? _randomAsmaul;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isAsmaulLoading = false;
  final Logger _logger = Logger();

  final _nameController = TextEditingController();
  final _kodeKknController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadProfile(), _loadRandomAsmaul()]);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        _userProfile = profile;
        _nameController.text = profile.namaLengkap;
        _kodeKknController.text = profile.kodeKkn;
      }
    } catch (e) {
      _logger.e('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRandomAsmaul() async {
    setState(() => _isAsmaulLoading = true);
    try {
      _randomAsmaul = await _prayerService.getRandomAsmaul();
    } catch (e) {
      _logger.e('Error loading random asmaul: $e');
    } finally {
      setState(() => _isAsmaulLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: QuestTheme.primaryGradient),
        ),
        actions: [
          if (!_isEditing && _userProfile != null)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
            ),
          if (_isEditing)
            IconButton(onPressed: _saveProfile, icon: const Icon(Icons.save)),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [QuestTheme.backgroundLight, QuestTheme.surfaceColor],
          ),
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _userProfile == null
                ? const Center(child: Text('Error loading profile'))
                : _buildProfileContent(),
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildProfileForm(),
          const SizedBox(height: 20),
          _buildLevelCard(),
          const SizedBox(height: 20),
          _buildBudgetCard(),
          const SizedBox(height: 20),
          _buildAsmaulHusnaCard(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Avatar section
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Profile info section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userProfile!.namaLengkap,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userProfile!.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'KKN: ${_userProfile!.kodeKkn}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kodeKknController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Kode KKN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _userProfile!.email,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                helperText: 'Email cannot be changed',
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _isEditing = false);
                      _nameController.text = _userProfile!.namaLengkap;
                      _kodeKknController.text = _userProfile!.kodeKkn;
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Level & XP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ), // Reduced font size
            ),
            const SizedBox(height: 12), // Reduced spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level ${_userProfile!.level}',
                  style: const TextStyle(
                    fontSize: 20, // Reduced font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_userProfile!.xp} XP Total',
                  style: const TextStyle(fontSize: 14), // Reduced font size
                ),
              ],
            ),
            const SizedBox(height: 6), // Reduced spacing
            LinearProgressIndicator(value: _userProfile!.xpProgress),
            const SizedBox(height: 4),
            Text(
              '${_userProfile!.currentLevelXp}/${_userProfile!.xpForNextLevel} XP to next level',
              style: const TextStyle(fontSize: 12), // Reduced font size
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ), // Reduced font size
            ),
            const SizedBox(height: 12), // Reduced spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Budget', style: TextStyle(fontSize: 14)),
                Text(
                  'Rp${_userProfile!.totalBudget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6), // Reduced spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Used Budget', style: TextStyle(fontSize: 14)),
                Text(
                  'Rp${_userProfile!.usedBudget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Reduced spacing
            LinearProgressIndicator(value: _userProfile!.budgetUsagePercentage),
          ],
        ),
      ),
    );
  }

  Widget _buildAsmaulHusnaCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Asmaul Husna',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _isAsmaulLoading ? null : _loadRandomAsmaul,
                  icon:
                      _isAsmaulLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_randomAsmaul != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade50, Colors.amber.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _randomAsmaul!.arab,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _randomAsmaul!.latin,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _randomAsmaul!.indo,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else if (_isAsmaulLoading) ...[
              const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else ...[
              SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'Gagal memuat Asmaul Husna',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showChangePasswordDialog,
              icon: const Icon(Icons.lock),
              label: const Text('Change Password'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _kodeKknController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final updatedProfile = _userProfile!.copyWith(
      namaLengkap: _nameController.text.trim(),
      kodeKkn: _kodeKknController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final success = await _authService.updateUserProfile(updatedProfile);

    if (success) {
      setState(() {
        _userProfile = updatedProfile;
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change password feature coming soon')),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kodeKknController.dispose();
    super.dispose();
  }
}
