// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/web.dart';
import 'package:simple_heatmap_calendar/simple_heatmap_calendar.dart';

class AppUsageDetailScreen extends StatefulWidget {
  final String appName;

  const AppUsageDetailScreen({super.key, required this.appName});

  @override
  State<AppUsageDetailScreen> createState() => _AppUsageDetailScreenState();
}

class _AppUsageDetailScreenState extends State<AppUsageDetailScreen> {
  static final Logger _logger = Logger();

  static const platform = MethodChannel('com.yourapp/usage');

  Map<DateTime, int> usageMap = {};
  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    _setDateRange();
    _fetchUsageData();
  }

  void _setDateRange() {
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _fetchUsageData() async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod(
        'getMonthlyUsage',
        {'packageName': widget.appName},
      );

      if (result.isEmpty) return;

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

      _logger.i(parsed);

      setState(() {
        usageMap = parsed;
      });
    } on PlatformException catch (e) {
      _logger.i("Error fetching usage: ${e.message}");
    }
  }

  final valueColorMap = {
    10: const Color.fromARGB(206, 165, 214, 167),
    20: const Color.fromARGB(249, 102, 187, 106),
    30: const Color.fromARGB(204, 67, 160, 72),
    40: Colors.green.shade700,
    50: Colors.green.shade900,
  };

  Map<int, num> getWeeklyUsageSummary() {
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

  // Helper to get ISO week number
  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final diff = date.difference(firstMonday).inDays;
    return ((diff) / 7).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    String appName = widget.appName;
    return Scaffold(
      backgroundColor: Colors.black, // dark mode background
      appBar: AppBar(
        title: Text(
          '$appName Usage',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        surfaceTintColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child:
            usageMap.isEmpty
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Monthly Usage Heatmap",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      HeatmapCalendar<num>(
                        startDate: startDate,
                        endedDate: endDate,
                        colorMap: valueColorMap,
                        selectedMap: usageMap,
                        cellSize: const Size.square(18.0),
                        cellSpaceBetween: 5,
                        colorTipCellSize: const Size.square(12.0),
                        style: HeatmapCalendarStyle.defaults(
                          cellBackgroundColor: Colors.grey[900],
                          weekLabelColor: Colors.white70,
                          cellValueFontSize: 8.0,
                          cellRadius: BorderRadius.all(Radius.circular(6.0)),
                          showYearOnMonthLabel: true,
                          weekLabelValueFontSize: 12.0,
                          monthLabelFontSize: 14.0,
                          monthLabelColor: Colors.white,
                        ),
                        layoutParameters:
                            const HeatmapLayoutParameters.defaults(
                              monthLabelPosition:
                                  CalendarMonthLabelPosition.top,
                              weekLabelPosition: CalendarWeekLabelPosition.left,
                              colorTipPosition: CalendarColorTipPosition.bottom,
                            ),
                      ),

                      const SizedBox(height: 40),

                      const Text(
                        "Daily Usage Bar Graph",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AspectRatio(
                        aspectRatio: 1,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceBetween,
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, _) {
                                    final date = usageMap.keys.elementAt(
                                      value.toInt(),
                                    );
                                    return Text(
                                      '${date.day}/${date.month}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups:
                                usageMap.entries.toList().asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final usage = entry.value.value;
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: usage.toDouble(),
                                        color: Colors.greenAccent,
                                        width: 12,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        "Weekly Usage Summary",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: getWeeklyUsageSummary().length,
                        itemBuilder: (context, index) {
                          final entries =
                              getWeeklyUsageSummary().entries.toList()
                                ..sort((a, b) => a.key.compareTo(b.key));
                          final week = entries[index].key;
                          final total = entries[index].value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Week $week',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${total.toStringAsFixed(2)} Minutes',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
