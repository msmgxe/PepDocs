import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/tabs/home_screen.dart';
import '../screens/tabs/weight_screen.dart';
import '../screens/tabs/progress_screen.dart';
import '../screens/tabs/reminders_screen.dart';
import '../screens/tabs/support_screen.dart';

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
    SupportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('onboarding_done') ?? false;

      if (!done) {
        final profile = await getProfile();
        if (profile == null ||
            profile['full_name'] == null ||
            profile['full_name'].toString().isEmpty) {
          if (mounted) {
            setState(() {
              _needsOnboarding = true;
              _checkingOnboarding = false;
            });
          }
          return;
        }
        await prefs.setBool('onboarding_done', true);
      }
    } catch (e) {
      // ignore — will fall through to show home
    } finally {
      if (mounted) setState(() => _checkingOnboarding = false);
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

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight_outlined),
            activeIcon: Icon(Icons.monitor_weight),
            label: 'Peso',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progreso',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Recordatorios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent_outlined),
            activeIcon: Icon(Icons.support_agent),
            label: 'Soporte',
          ),
        ],
      ),
    );
  }
}
