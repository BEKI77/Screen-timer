import 'package:flutter/material.dart';
import '../services/usage_monitor.dart';
// import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

final List<Color> hourlyGradientColors = [
  Color(0xFFB2EBF2), // lightest
  Color(0xFF80DEEA),
  Color(0xFF4DD0E1),
  Color(0xFF26C6DA),
  Color(0xFF00BCD4),
  Color(0xFF00ACC1), // darkest
];

class ScreenTimeDashboard extends StatefulWidget {
  const ScreenTimeDashboard({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _ScreenTimeDashboardState createState() => _ScreenTimeDashboardState();
}

class _ScreenTimeDashboardState extends State<ScreenTimeDashboard> {
  Map<String, int> _todayUsage = {};
  List<double> _weeklyTotals = List.filled(7, 0);
  final int _currentDayIndex = DateTime.now().weekday - 1;

  int totalMinutes = 0;

  @override
  void initState() {
    super.initState();
    fetchUsage();
    fetchWeeklyUsage();
  }

  Future<void> fetchUsage() async {
    final usage = await UsageMonitor.instance.getTodayUsage();
    int total = usage.values.fold(0, (a, b) => a + b);
    setState(() {
      _todayUsage = usage;
      totalMinutes = total;
    });
  }

  void fetchWeeklyUsage() async {
    final weeklyUsage =
        await UsageMonitor.instance.getWeeklyUsage(); // your platform method
    final formatter = DateFormat('yyyy-MM-dd');
    final now = DateTime.now();
    final List<double> totals = List.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final key = formatter.format(date);
      if (weeklyUsage.containsKey(key)) {
        totals[i] =
            weeklyUsage[key]!.fold(0, (sum, mins) => sum + mins).toDouble() /
            60.0; // to hours
      }
    }

    setState(() {
      _weeklyTotals = totals;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> topApps = _todayUsage.keys.take(3).toList();

    List<double> segments =
        totalMinutes == 0
            ? List.filled(3, 0.0)
            : topApps
                .map((app) => (_todayUsage[app] ?? 0) / totalMinutes)
                .toList();

    List<Color> colors = [Colors.pink, Colors.blue, Colors.green];

    final time = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: Icon(
          Icons.phone_android,
          color: const Color.fromARGB(244, 53, 180, 151),
        ),
        title: Text("Screen Time"),
        backgroundColor: Colors.black87,
        surfaceTintColor: Colors.black87,
      ),

      // dark gray background
      body: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(left: 20),
              margin: EdgeInsetsGeometry.only(bottom: 30, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM').format(time),
                    style: TextStyle(
                      color: Color.fromARGB(125, 255, 255, 255),
                      fontSize: 20,
                    ),
                  ),
                  // Time
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        "${time.hour}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                        ),
                      ),
                      Text(
                        "h",
                        style: const TextStyle(
                          color: Color.fromARGB(125, 255, 255, 255),
                          fontSize: 35,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        "${time.minute}",
                        style: TextStyle(color: Colors.white, fontSize: 40),
                      ),
                      Text(
                        "m",
                        style: const TextStyle(
                          color: Color.fromARGB(125, 255, 255, 255),
                          fontSize: 35,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(160, 66, 66, 66),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "↑ 20% from last week",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Date
            const SizedBox(height: 16),

            // Weekly Bar Chart
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return Text(
                            labels[value.toInt()],
                            style: const TextStyle(
                              color: Color.fromARGB(125, 255, 255, 255),
                              fontSize: 16,
                            ),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  barGroups:
                      _weeklyTotals.asMap().entries.map((entry) {
                        final index = entry.key;
                        final value = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              width: 16,
                              gradient: LinearGradient(
                                colors:
                                    index == _currentDayIndex
                                        ? [
                                          Color.fromARGB(80, 33, 149, 243),
                                          Colors.lightBlueAccent,
                                        ]
                                        : [
                                          Color.fromARGB(57, 158, 158, 158),
                                          Colors.grey[600]!,
                                        ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Category Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(topApps.length, (i) {
                final app = topApps[i];
                final usage = _todayUsage[app] ?? 0;
                final hours = usage ~/ 60;
                final minutes = usage % 60;
                final timeStr =
                    hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m";
                final colorList = [
                  Colors.cyan,
                  Colors.orange,
                  Colors.amber,
                  Colors.purple,
                ];
                return _StatLabel(
                  color: colorList[i % colorList.length],
                  label: app.isNotEmpty ? app : "N/A",
                  time: timeStr,
                );
              }),
            ),

            SizedBox(height: 40),

            Container(
              padding: EdgeInsets.only(left: 20),
              margin: EdgeInsetsGeometry.only(bottom: 30, top: 20),
              child: Text(
                "Today's Usage",
                style: TextStyle(
                  color: Color.fromARGB(125, 255, 255, 255),
                  fontSize: 20,
                ),
              ),
            ),
            SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  size: Size(100, 100),
                  painter: MultiColorCircularProgressPainter(segments, colors),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "6h 58m",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          "+15%",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLabel extends StatelessWidget {
  final Color color;
  final String label;
  final String time;

  const _StatLabel({
    required this.color,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(time, style: TextStyle(color: color, fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}

class MultiColorCircularProgressPainter extends CustomPainter {
  final List<double> segments;
  final List<Color> colors;

  MultiColorCircularProgressPainter(this.segments, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    double startAngle = -pi / 2;
    final strokeWidth = 10.0;
    final radius = size.width;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    for (int i = 0; i < segments.length; i++) {
      final sweepAngle = segments[i] * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
