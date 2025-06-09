import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../models/user_model.dart';
import '../models/quest_model.dart';
import '../widgets/quest_theme.dart';
import 'package:logger/logger.dart';

class MoneyTrackerView extends StatefulWidget {
  const MoneyTrackerView({super.key});

  @override
  State<MoneyTrackerView> createState() => _MoneyTrackerViewState();
}

class _MoneyTrackerViewState extends State<MoneyTrackerView> {
  final AuthService _authService = AuthService();
  final QuestService _questService = QuestService();
  UserProfile? _userProfile;
  List<Quest> _expenseQuests = [];
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

        final allQuests = await _questService.getQuestsByKodeKkn(
          userProfile.kodeKkn,
        );
        _expenseQuests =
            allQuests.where((q) => q.cost > 0 && q.isCompleted).toList();
      }
    } catch (e) {
      _logger.e('Error loading money data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [QuestTheme.backgroundLight, QuestTheme.surfaceColor],
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [QuestTheme.backgroundLight, QuestTheme.surfaceColor],
          ),
        ),
        child: const Center(child: Text('Error loading user data')),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [QuestTheme.backgroundLight, QuestTheme.surfaceColor],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBudgetHeader(),
            const SizedBox(height: 20),
            _buildBudgetOverview(),
            const SizedBox(height: 20),
            _buildBudgetActions(),
            const SizedBox(height: 20),
            _buildExpenseHistory(),
          ],
        ),
      ),
    );  }

  Widget _buildBudgetHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: QuestTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: QuestTheme.cardShadow,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 8),
          Text(
            'Budget Tracker',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Monitor your KKN expenses and budget',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Budget'),
                Text(
                  'Rp${_userProfile!.totalBudget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Used Budget'),
                Text(
                  'Rp${_userProfile!.usedBudget.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 18, color: Colors.red.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Remaining Budget'),
                Text(
                  'Rp${_userProfile!.remainingBudget.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 18, color: Colors.green.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _userProfile!.budgetUsagePercentage,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                _userProfile!.budgetUsagePercentage > 0.8
                    ? Colors.red
                    : _userProfile!.budgetUsagePercentage > 0.6
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_userProfile!.budgetUsagePercentage * 100).toStringAsFixed(1)}% used',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showSetBudgetDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Set Total Budget'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showBudgetAnalysis,
                icon: const Icon(Icons.analytics),
                label: const Text('View Budget Analysis'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_expenseQuests.isEmpty)
              const Text('No expenses recorded yet')
            else
              ..._expenseQuests.map((quest) => _buildExpenseItem(quest)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(Quest quest) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  quest.type.name.toUpperCase(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'Rp${quest.cost.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetBudgetDialog() async {
    final controller = TextEditingController(
      text: _userProfile!.totalBudget.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Set Total Budget'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Budget (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final budget = double.tryParse(controller.text);
                  if (budget != null && budget >= 0) {
                    Navigator.pop(context, budget);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter valid budget amount!'),
                        backgroundColor: Colors.yellow,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result != null) {
      final success = await _authService.updateUserBudget(result);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget updated successfully')),
          );
        }
      }
    }
  }

  void _showBudgetAnalysis() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Budget Analysis'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Expenses: ${_expenseQuests.length}'),
                Text(
                  'Average per Quest: Rp${_expenseQuests.isNotEmpty ? (_userProfile!.usedBudget / _expenseQuests.length).toStringAsFixed(0) : "0"}',
                ),
                const SizedBox(height: 16),
                if (_userProfile!.budgetUsagePercentage > 0.8)
                  const Text(
                    'Budget usage is high!',
                    style: TextStyle(color: Colors.red),
                  )
                else if (_userProfile!.budgetUsagePercentage > 0.6)
                  const Text(
                    'Monitor your spending',
                    style: TextStyle(color: Colors.orange),
                  )
                else
                  const Text(
                    'Budget is healthy',
                    style: TextStyle(color: Colors.green),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
