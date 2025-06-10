import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import '../widgets/quest_theme.dart';
import 'auth_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.assignment_outlined,
      title: 'Kelola Quest KKN',
      description:
          'Buat dan kelola berbagai quest untuk kegiatan KKN Anda dengan mudah dan terorganisir.',
      color: QuestTheme.primaryBlue,
    ),
    OnboardingPage(
      icon: Icons.favorite_outline,
      title: 'Simpan Favorit',
      description:
          'Tandai quest favorit Anda untuk akses cepat dan mudah kapan saja.',
      color: QuestTheme.primaryPurple,
    ),
    OnboardingPage(
      icon: Icons.analytics_outlined,
      title: 'Pantau Progress',
      description:
          'Lacak kemajuan kegiatan KKN dan catat pencapaian Anda secara real-time.',
      color: QuestTheme.primaryBlue,
    ),
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  void _finishOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0), // Reduced padding
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 800),
                          child: Container(
                            width: 120, // Reduced size
                            height: 120,
                            decoration: BoxDecoration(
                              color: _pages[index].color.withValues(
                                alpha: 0.1,
                              ), // Updated API
                              borderRadius: BorderRadius.circular(
                                60,
                              ), // Adjusted
                            ),
                            child: Icon(
                              _pages[index].icon,
                              size: 60, // Reduced icon size
                              color: _pages[index].color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32), // Reduced spacing
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            _pages[index].title,
                            style: const TextStyle(
                              fontSize: 24, // Reduced font size
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 400),
                          child: Text(
                            _pages[index].description,
                            style: const TextStyle(
                              fontSize: 14, // Reduced font size
                              color: Colors.grey,
                              height: 1.4, // Reduced line height
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page indicators and next button
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width:
                            _currentPage == index
                                ? 20
                                : 6, // Adjusted indicator size
                        height: 6, // Reduced height
                        decoration: BoxDecoration(
                          color:
                              _currentPage == index
                                  ? _pages[_currentPage].color
                                  : Colors.grey.withValues(
                                    alpha: 0.3,
                                  ), // Updated API
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Next/Get Started button - more compact
                  SizedBox(
                    width: double.infinity,
                    height: 48, // Reduced height
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // Reduced radius
                        ),
                        elevation: 2, // Reduced elevation
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16, // Reduced font size
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
