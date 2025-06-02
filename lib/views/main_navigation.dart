import 'package:flutter/material.dart';
import 'quest_home_view.dart';
import 'quest_list_view.dart';
import 'money_tracker_view.dart';
import 'favorite_view.dart';
import 'profile_view.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const QuestHomeView(),
    const QuestListView(),
    const MoneyTrackerView(),
    const FavoriteView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Quest'),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Money',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorite',
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileView()),
                ),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Quest';
      case 2:
        return 'Money Tracker';
      case 3:
        return 'Favorites';
      default:
        return 'KKN Manager';
    }
  }
}
