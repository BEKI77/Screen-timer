import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:simple_heatmap_calendar/simple_heatmap_calendar.dart';
import 'package:screen_timer/services/usage_monitor.dart';

class AppUsageDetailScreen extends StatefulWidget {
  final String packageName;

  const AppUsageDetailScreen({super.key, required this.packageName});

  @override
  State<AppUsageDetailScreen> createState() => _AppUsageDetailScreenState();
}

class _AppUsageDetailScreenState extends State<AppUsageDetailScreen> {
  Map<DateTime, int> usageMap = {};
  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    final range = UsageMonitor.instance.getCurrentMonthRange();
    startDate = range['start']!;
    endDate = range['end']!;
    _fetchUsageData();
  }

  Future<void> _fetchUsageData() async {
    final data = await UsageMonitor.instance.getMonthlyUsage(
      widget.packageName,
    );
    setState(() {
      usageMap = data;
    });
  }

  Map<int, num> getWeeklyUsageSummary() {
    return UsageMonitor.instance.getWeeklySummary(usageMap);
  }

  final valueColorMap = {
    10: const Color.fromARGB(206, 165, 214, 167),
    20: const Color.fromARGB(249, 102, 187, 106),
    30: const Color.fromARGB(204, 67, 160, 72),
    40: Colors.green.shade700,
    50: Colors.green.shade900,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // dark mode background
      appBar: AppBar(
        title: Text('Usage stat', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        surfaceTintColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          padding: EdgeInsets.all(10),
          child:
              usageMap.isEmpty
                  ? const Center(child: CircularProgressIndicator())
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
                                weekLabelPosition:
                                    CalendarWeekLabelPosition.left,
                                colorTipPosition:
                                    CalendarColorTipPosition.bottom,
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
                                  usageMap.entries.toList().asMap().entries.map(
                                    (entry) {
                                      final index = entry.key;
                                      final usage = entry.value.value;
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: usage.toDouble(),
                                            color: Colors.greenAccent,
                                            width: 12,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ).toList(),
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
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
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
      ),
    );
  }
}
