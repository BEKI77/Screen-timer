import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_api_call.dart';
import 'package:screen_timer/services/usage_monitor.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? summary;

  List<Map<String, String>> table = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    final apps = await UsageMonitor.instance.getRunningApps();
    final combinedAppInfo = apps
        .map((app) {
          return 'App: ${app['appName']}\n'
              'Package: ${app['packageName']}\n'
              'Usage Time: ${app['usageTime']} ms\n'
              'Last Used: ${DateTime.fromMillisecondsSinceEpoch(app['lastTimeUsed'])}\n';
        })
        .join('\n\n');

    final result = await GeminiService.summarizeAppUsage(combinedAppInfo);

    setState(() {
      summary = result ?? 'No summary available';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(
          Icons.analytics_outlined,
          color: const Color.fromARGB(244, 53, 180, 151),
        ),
        title: Text('App analytics'),
        backgroundColor: Colors.black87,
        surfaceTintColor: Colors.black87,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Summary Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      color: const Color.fromARGB(28, 227, 228, 228),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "🧠 AI Summary",
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            summary != null
                                ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      summary!
                                          .split('\n')
                                          .where(
                                            (line) => line.trim().isNotEmpty,
                                          )
                                          .map((line) {
                                            String cleanedLine =
                                                line.replaceAll('*', '').trim();
                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "• ",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    cleanedLine,
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          })
                                          .toList(),
                                )
                                : const Text("No summary found."),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
