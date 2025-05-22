import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_api_call.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> appUsageData;
  const AnalyticsScreen({super.key, required this.appUsageData});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Map<String, dynamic>> runningApps = [];
  String? summary;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    runningApps = widget.appUsageData;
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    final combinedAppInfo = runningApps
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
        title: Text(
          'App analytics',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  summary ?? 'No summary found.',
                  style: GoogleFonts.roboto(fontSize: 16),
                ),
              ),
    );
  }
}
