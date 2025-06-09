import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../services/notification_service.dart';
import '../models/quest_model.dart';
import '../widgets/quest_theme.dart';

class CreateQuestView extends StatefulWidget {
  const CreateQuestView({super.key});

  @override
  State<CreateQuestView> createState() => _CreateQuestViewState();
}

class _CreateQuestViewState extends State<CreateQuestView> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final QuestService _questService = QuestService();
  final NotificationService _notificationService = NotificationService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _xpController = TextEditingController(text: '10');
  final _costController = TextEditingController(text: '0');
  final _maxProgressController = TextEditingController(text: '1');

  QuestType _selectedType = QuestType.daily;
  DateTime? _deadline;
  TimeOfDay? _deadlineTime;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Create Quest'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: QuestTheme.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _testNotification,
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test Notification',
          ),
          if (!_isLoading)
            IconButton(onPressed: _createQuest, icon: const Icon(Icons.save)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    QuestTheme.backgroundLight,
                    QuestTheme.surfaceColor,
                  ],
                ),
              ),
              child: _buildForm(),
            ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: QuestTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: QuestTheme.cardShadow,
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.add_task,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Create New Quest',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Design a new challenge for your KKN journey',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Form Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: QuestTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: QuestTheme.cardShadow,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader('Quest Details', Icons.info_outline),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Quest Title',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: QuestTheme.surfaceColor,
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: QuestTheme.surfaceColor,
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Quest Type', Icons.category),
                  const SizedBox(height: 16),
                  _buildQuestTypeSelector(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Rewards & Progress', Icons.emoji_events),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _xpController,
                          decoration: InputDecoration(
                            labelText: 'XP Reward',
                            prefixIcon: const Icon(Icons.star),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: QuestTheme.surfaceColor,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'XP is required';
                            }
                            final xp = int.tryParse(value!);
                            if (xp == null || xp <= 0) {
                              return 'XP must be positive';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _costController,
                          decoration: InputDecoration(
                            labelText: 'Cost (Rp)',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: QuestTheme.surfaceColor,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Cost is required';
                            }
                            final cost = double.tryParse(value!);
                            if (cost == null || cost < 0) {
                              return 'Cost must be non-negative';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _maxProgressController,
                    decoration: InputDecoration(
                      labelText: 'Max Progress',
                      prefixIcon: const Icon(Icons.track_changes),
                      helperText: 'Number of steps to complete this quest',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: QuestTheme.surfaceColor,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Max progress is required';
                      }
                      final progress = int.tryParse(value!);
                      if (progress == null || progress <= 0) {
                        return 'Max progress must be positive';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Deadline (Optional)', Icons.schedule),
                  const SizedBox(height: 16),
                  _buildDeadlineSelector(),
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _createQuest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuestTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_task),
                        SizedBox(width: 8),
                        Text(
                          'Create Quest',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: QuestTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: QuestTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: QuestTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: QuestType.values.map((type) {
          final isSelected = _selectedType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? QuestTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getQuestTypeIcon(type),
                      color: isSelected ? Colors.white : QuestTheme.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.name.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : QuestTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeadlineSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuestTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuestTheme.textMuted.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDeadlineDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: QuestTheme.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: QuestTheme.textMuted.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: QuestTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          _deadline != null
                              ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                              : 'Select date',
                          style: TextStyle(
                            color: _deadline != null ? QuestTheme.textPrimary : QuestTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _deadline != null ? _selectDeadlineTime : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _deadline != null ? QuestTheme.cardBackground : QuestTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: QuestTheme.textMuted.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: _deadline != null ? QuestTheme.textSecondary : QuestTheme.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _deadlineTime != null
                              ? '${_deadlineTime!.hour.toString().padLeft(2, '0')}:${_deadlineTime!.minute.toString().padLeft(2, '0')}'
                              : 'Select time',
                          style: TextStyle(
                            color: _deadline != null && _deadlineTime != null
                                ? QuestTheme.textPrimary
                                : QuestTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_deadline != null && _deadlineTime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: QuestTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: QuestTheme.primaryBlue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Deadline: ${_getFormattedDateTime()}',
                    style: const TextStyle(
                      color: QuestTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getQuestTypeIcon(QuestType type) {
    switch (type) {
      case QuestType.daily:
        return Icons.today;
      case QuestType.weekly:
        return Icons.date_range;
      case QuestType.monthly:
        return Icons.calendar_month;
    }
  }

  Future<void> _selectDeadlineDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _deadline = date;
        _deadlineTime = null;
      });
    }
  }

  Future<void> _selectDeadlineTime() async {
    if (_deadline == null) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _deadlineTime = time);
    }
  }

  String _getFormattedDateTime() {
    if (_deadline == null) return '';
    String dateStr = '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}';
    if (_deadlineTime != null) {
      String timeStr = '${_deadlineTime!.hour.toString().padLeft(2, '0')}:${_deadlineTime!.minute.toString().padLeft(2, '0')}';
      return '$dateStr at $timeStr';
    }
    return dateStr;
  }

  DateTime? _getCombinedDateTime() {
    if (_deadline == null) return null;
    if (_deadlineTime != null) {
      return DateTime(
        _deadline!.year,
        _deadline!.month,
        _deadline!.day,
        _deadlineTime!.hour,
        _deadlineTime!.minute,
      );
    }
    return DateTime(
      _deadline!.year,
      _deadline!.month,
      _deadline!.day,
    );
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notification sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _createQuest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userData = await _authService.getUserData();
      if (userData == null) {
        throw Exception('User data not found');
      }

      final quest = Quest(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        xpReward: int.parse(_xpController.text),
        cost: double.parse(_costController.text),
        maxProgress: int.parse(_maxProgressController.text),
        deadline: _getCombinedDateTime(),
        kodeKkn: userData['kodeKkn'],
        createdAt: DateTime.now(),
        createdBy: _authService.currentUser!.uid,
      );

      final success = await _questService.createQuest(quest);

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quest created successfully')),
          );
        }
      } else {
        throw Exception('Failed to create quest');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _xpController.dispose();
    _costController.dispose();
    _maxProgressController.dispose();
    super.dispose();
  }
}
