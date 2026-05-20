import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/units_service.dart';
import '../services/language_service.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/tabs/home_screen.dart';
import '../screens/tabs/weight_screen.dart';
import '../screens/tabs/progress_screen.dart';
import '../screens/tabs/reminders_screen.dart';
import '../screens/tabs/tips_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _checkingOnboarding = true;
  bool _needsOnboarding = false;

  final List<Widget> _tabs = const [
    HomeScreen(),
    WeightScreen(),
    ProgressScreen(),
    RemindersScreen(),
    TipsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    Map<String, dynamic>? profile;
    try {
      profile = await getProfile();
    } catch (_) {
      profile = null;
    }

    final needsOnboarding = profile == null ||
        (profile['full_name'] as String? ?? '').trim().isEmpty;

    if (mounted) {
      setState(() {
        _needsOnboarding = needsOnboarding;
        _checkingOnboarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingOnboarding) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsOnboarding) {
      return const OnboardingScreen();
    }

    // Rebuild tabs + nav bar when units or language changes.
    return ListenableBuilder(
      listenable: Listenable.merge([UnitsService.instance, LanguageService.instance]),
      builder: (context, _) {
        final l = LanguageService.instance;
        return Scaffold(
          body: _tabs[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: l.tr('nav_home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.monitor_weight_outlined),
                activeIcon: const Icon(Icons.monitor_weight),
                label: l.tr('nav_weight'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.show_chart),
                label: l.tr('nav_progress'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month_outlined),
                activeIcon: const Icon(Icons.calendar_month),
                label: l.tr('nav_reminders'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.tips_and_updates_outlined),
                activeIcon: const Icon(Icons.tips_and_updates),
                label: l.tr('nav_tips'),
              ),
            ],
          ),
        );
      },
    );
  }
}
