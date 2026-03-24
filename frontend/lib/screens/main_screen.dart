import 'package:flutter/material.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<RecordsScreenState> _recordsKey =
      GlobalKey<RecordsScreenState>();
  final GlobalKey<AnalyticsScreenState> _analyticsKey =
      GlobalKey<AnalyticsScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey),
    RecordsScreen(key: _recordsKey),
    AnalyticsScreen(key: _analyticsKey),
    const SettingsScreen(),
  ];

  void _onTabSelected(int i) {
    setState(() => _currentIndex = i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (i == 0) {
        _homeKey.currentState?.reload();
      } else if (i == 1) {
        _recordsKey.currentState?.reload();
      } else if (i == 2) {
        _analyticsKey.currentState?.reload();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: '기록'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: '분석'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
