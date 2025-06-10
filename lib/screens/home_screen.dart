import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/web.dart';
import 'package:screen_timer/screens/screen_time_dashboard.dart';
import 'running_apps_screen.dart';
import 'analytics_screen.dart';
// import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final Logger _logger = Logger();
  static const platform = MethodChannel('com.yourapp/usage');
  late List<Widget> _pages;

  int _selectedIndex = 0;

  Future<bool> checkUsageAccess() async {
    try {
      final bool granted = await platform.invokeMethod('hasUsageAccess');
      return granted;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openUsageSettings() async {
    try {
      await platform.invokeMethod('openUsageAccess');
    } on PlatformException catch (e) {
      _logger.e("Failed to open usage settings: ${e.message}");
    }
  }

  Future<void> fetchRunningApps() async {
    try {
      setState(() {
        _pages = [
          ScreenTimeDashboard(),
          RunningAppsScreen(),
          AnalyticsScreen(),
        ];
      });
    } on PlatformException catch (e) {
      _logger.e("Error getting apps: ${e.message}");
    }
  }

  @override
  void initState() {
    super.initState();
    _pages = [];
    checkUsageAccess().then((granted) {
      if (!granted) {
        openUsageSettings();
      }
      Future.delayed(const Duration(seconds: 3), () async {
        await fetchRunningApps();
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty || _selectedIndex >= _pages.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: const Color.fromARGB(244, 53, 180, 151),
        unselectedItemColor: const Color.fromARGB(239, 134, 134, 134),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps_rounded),
            label: 'Running Apps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
