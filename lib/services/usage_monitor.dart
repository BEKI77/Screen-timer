import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/web.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageMonitor {
  // Private constructor
  UsageMonitor._privateConstructor();

  // The single instance
  static final UsageMonitor _instance = UsageMonitor._privateConstructor();

  // Getter to access the singleton instance
  static UsageMonitor get instance => _instance;

  static const MethodChannel _channel = MethodChannel("com.yourapp/usage");
  static final Logger _logger = Logger();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _pollTimer;

  /// Initializes local notifications
  void initNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Loads all stored usage limits
  Future<Map<String, int>> _loadAllLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final limits = <String, int>{};
    for (final key in keys) {
      if (key.startsWith('limit_')) {
        final pkg = key.substring(6); // remove 'limit_' prefix
        final minutes = prefs.getInt(key);
        if (minutes != null) {
          limits[pkg] = minutes;
        }
      }
    }
    return limits;
  }

  /// Starts periodic monitoring of app usage
  void startMonitoring() {
    _checkUsage();

    Timer.periodic(Duration(minutes: 5), (timer) async {
      _checkUsage();
    });
  }

  Future<void> _checkUsage() async {
    final limits = await _loadAllLimits();
    final recentApps = await getRunningApps();

    for (final app in recentApps) {
      final pkg = app['appName'];
      final usageMs = app['usageTime'] as int;
      final usageMin = (usageMs / 60000).round();

      if (limits.containsKey(pkg)) {
        final limitMin = limits[pkg]!;
        if (usageMin >= limitMin) {
          await _showUsageLimitNotification(app['appName']);
        }
      }
    }
  }

  /// Stops monitoring
  void stopMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Fetches running apps using platform channel
  Future<List<dynamic>> getRunningApps() async {
    try {
      final List<dynamic> apps = await _channel.invokeMethod('getRunningApps');
      return apps.map((app) => Map<String, dynamic>.from(app as Map)).toList();
    } catch (e) {
      _logger.e('Error getting running apps: $e');
      return [];
    }
  }

  /// Shows a notification when usage limit is reached
  Future<void> _showUsageLimitNotification(String appName) async {
    _logger.i(appName);
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'usage_channel',
          'Usage Alerts',
          channelDescription: 'Notifies when app usage exceeds limit',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Time Limit Reached',
      '$appName usage time exceeded the limit.',
      platformDetails,
    );
  }

  Future<Map<String, int>> getTodayUsage() async {
    final apps = await getRunningApps();
    final Map<String, int> usageMap = {};
    for (final app in apps) {
      usageMap[app['appName']] = app['usageTime'] ~/ 1000 ~/ 60; // in minutes
    }
    return usageMap;
  }

  Future<Map<String, List<int>>> getWeeklyUsage() async {
    final Map<dynamic, dynamic> usage = await _channel.invokeMethod(
      'getWeeklyUsage',
    );
    return usage.map((key, value) {
      List<int> list = List<int>.from(value);
      return MapEntry(key as String, list);
    });
  }

  Future<Map<DateTime, int>> getMonthlyUsage(String appName) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getMonthlyUsage',
        {'packageName': appName},
      );
      if (result.isEmpty) return {};

      final values = result.values.cast<num>().toList();
      final minUsage = values.reduce((a, b) => a < b ? a : b);
      final maxUsage = values.reduce((a, b) => a > b ? a : b);

      int mapToBucket(num value) {
        if (maxUsage == minUsage) return 10;
        final percent = (value - minUsage) / (maxUsage - minUsage);
        if (percent < 0.2) return 10;
        if (percent < 0.4) return 20;
        if (percent < 0.6) return 30;
        if (percent < 0.8) return 40;
        return 50;
      }

      final parsed = <DateTime, int>{};
      result.forEach((key, value) {
        parsed[DateTime.parse(key)] = mapToBucket(value);
      });
      return parsed;
    } on PlatformException catch (e) {
      _logger.e("Error fetching monthly usage: ${e.message}");
      return {};
    }
  }

  /// Returns the first and last day of current month
  Map<String, DateTime> getCurrentMonthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return {'start': start, 'end': end};
  }

  /// Returns a weekly summary (weekOfYear -> total)
  Map<int, num> getWeeklySummary(Map<DateTime, int> usageMap) {
    final weekMap = <int, num>{};

    for (final entry in usageMap.entries) {
      final weekOfYear = _getWeekOfYear(entry.key);
      weekMap.update(
        weekOfYear,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
    }

    return weekMap;
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final diff = date.difference(firstMonday).inDays;
    return ((diff) / 7).floor() + 1;
  }
}
