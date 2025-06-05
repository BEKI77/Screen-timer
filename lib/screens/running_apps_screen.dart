import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/web.dart';
import 'package:screen_timer/screens/app_usage_detail_screen.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RunningAppsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> appUsageData;

  const RunningAppsScreen({super.key, required this.appUsageData});

  @override
  State<RunningAppsScreen> createState() => _RunningAppsScreenState();
}

class _RunningAppsScreenState extends State<RunningAppsScreen> {
  List<Map<String, dynamic>> runningApps = [];

  @override
  void initState() {
    super.initState();
    runningApps = widget.appUsageData;
  }

  void _showTimeLimitDialog(Map<String, dynamic> app) async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Usage Limit for ${app['appName']}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter time limit in minutes',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final limit = int.tryParse(controller.text);
                if (limit != null) {
                  _setAppLimit(app['appName'], limit);
                }
                Navigator.pop(context);
              },
              child: Text('Set'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(
          Icons.view_timeline_outlined,
          color: const Color.fromARGB(244, 53, 180, 151),
        ),
        title: const Text('Running Apps'),
        backgroundColor: Colors.black87,
        surfaceTintColor: Colors.black87,
      ),
      body:
          runningApps.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: runningApps.length,
                itemBuilder: (context, index) {
                  final app = runningApps[index];
                  return FutureBuilder<int?>(
                    future: getAppLimit(app['appName']),
                    builder: (context, snapshot) {
                      final limit = snapshot.data;
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              LucideIcons.rulerDimensionLine,
                              color: Color.fromARGB(244, 53, 180, 151),
                              size: 35,
                            ),
                            title: Text(app['appName']),
                            subtitle: Text(
                              'Used: ${(app['usageTime'] / 1000).round()} sec\nLast: ${DateTime.fromMillisecondsSinceEpoch(app['lastTimeUsed'])}',
                              style: GoogleFonts.hammersmithOne(
                                color: Colors.grey[800],
                                textStyle: TextStyle(letterSpacing: .5),
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(LucideIcons.timer),
                              color: const Color.fromARGB(244, 53, 180, 151),
                              onPressed: () => _showTimeLimitDialog(app),
                            ),
                            onTap:
                                () => {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => AppUsageDetailScreen(
                                            appName: app['appName'],
                                          ),
                                    ),
                                  ),
                                },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 56, right: 40),
                            child: LinearProgressIndicator(
                              value:
                                  (limit != null && limit > 0)
                                      ? (app['usageTime'] / (limit * 60000))
                                          .clamp(0.0, 1.0)
                                      : 0,
                              minHeight: 3,
                              backgroundColor: Colors.grey[900],
                              color: const Color.fromARGB(244, 53, 180, 151),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
    );
  }
}

Future<void> _setAppLimit(String packageName, int minutes) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('limit_$packageName', minutes);
}

Future<int?> getAppLimit(String packageName) async {
  final Logger logger = Logger();
  final prefs = await SharedPreferences.getInstance();
  logger.i(prefs.getInt('limit_$packageName'));
  return prefs.getInt('limit_$packageName');
}
