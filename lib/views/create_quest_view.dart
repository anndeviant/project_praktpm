import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../services/notification_service.dart';
import '../models/quest_model.dart';

class CreateQuestView extends StatefulWidget {
  const CreateQuestView({super.key});

  @override
  State<CreateQuestView> createState() => _CreateQuestViewState();
}

class _CreateQuestViewState extends State<CreateQuestView> {  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final QuestService _questService = QuestService();
  final NotificationService _notificationService = NotificationService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _xpController = TextEditingController(text: '10');
  final _costController = TextEditingController(text: '0');
  final _maxProgressController = TextEditingController(text: '1');  QuestType _selectedType = QuestType.daily;
  DateTime? _deadline;
  TimeOfDay? _deadlineTime;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        title: const Text('Create Quest'),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Quest Title',
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<QuestType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Quest Type',
                border: OutlineInputBorder(),
              ),
              items:
                  QuestType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _xpController,
                    decoration: const InputDecoration(
                      labelText: 'XP Reward',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final xp = int.tryParse(value ?? '');
                      if (xp == null || xp < 0) {
                        return 'Invalid XP';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'Cost (Rp)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final cost = double.tryParse(value ?? '');
                      if (cost == null || cost < 0) {
                        return 'Invalid cost';
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
              decoration: const InputDecoration(
                labelText: 'Max Progress',
                border: OutlineInputBorder(),
                helperText: 'Number of steps to complete this quest',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final progress = int.tryParse(value ?? '');
                if (progress == null || progress < 1) {
                  return 'Progress must be at least 1';
                }
                return null;
              },
            ),            const SizedBox(height: 16),
            // Deadline Section with Date and Time
            const Text(
              'Deadline (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDeadlineDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _deadline != null
                            ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                            : 'Select date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _deadline != null ? _selectDeadlineTime : null,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Time',
                        border: const OutlineInputBorder(),
                        enabled: _deadline != null,
                      ),
                      child: Text(
                        _deadlineTime != null
                            ? '${_deadlineTime!.hour.toString().padLeft(2, '0')}:${_deadlineTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select time',
                        style: TextStyle(
                          color: _deadline != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],            ),
            if (_deadline != null && _deadlineTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Deadline: ${_getFormattedDateTime()}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (_deadline != null && _deadlineTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: _testDeadlineNotification,
                  icon: const Icon(Icons.timer),
                  label: const Text('Test Deadline Reminder (2 min)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createQuest,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Create Quest'),
            ),
          ],
        ),
      ),
    );
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
        // Reset time when date changes
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
    
    // If no time selected, default to end of day (23:59)
    return DateTime(
      _deadline!.year,
      _deadline!.month,
      _deadline!.day,
      23,
      59,
    );  }

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
          SnackBar(content: Text('Error sending test notification: $e')),
        );
      }
    }  }
  Future<void> _testDeadlineNotification() async {
    if (_deadline == null || _deadlineTime == null) return;
    
    try {
      // Create a test quest with deadline 17 seconds from now (so reminder fires in 2 seconds)
      final testDeadline = DateTime.now().add(const Duration(seconds: 17));
      
      final testQuest = Quest(
        id: 'test_quest_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Test Quest Deadline',
        description: 'This is a test quest to verify deadline notifications',
        type: QuestType.daily,
        xpReward: 10,
        cost: 0,
        maxProgress: 1,
        deadline: testDeadline,
        kodeKkn: 'TEST',
        createdAt: DateTime.now(),
        createdBy: 'test_user',
      );

      await _notificationService.scheduleQuestDeadlineReminder(testQuest);
      
      if (mounted) {
        final reminderTime = testDeadline.subtract(const Duration(minutes: 15));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test deadline reminder scheduled!\nReminder: ${reminderTime.hour}:${reminderTime.minute}:${reminderTime.second}\nDeadline: ${testDeadline.hour}:${testDeadline.minute}:${testDeadline.second}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling test deadline: $e')),
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
      }      final quest = Quest(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
