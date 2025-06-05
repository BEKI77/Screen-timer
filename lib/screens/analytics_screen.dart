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

  List<Map<String, String>> table = [];
  List<String> tableColumns = [];
  bool isTableLoading = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    runningApps = widget.appUsageData;
    _fetchSummary();
    _fetchTable();
  }

  Future<void> _fetchTable() async {
    final combinedAppInfo = runningApps
        .map((app) {
          return 'App: ${app['appName']}\n'
              'Package: ${app['packageName']}\n'
              'Usage Time: ${app['usageTime']} ms\n'
              'Last Used: ${DateTime.fromMillisecondsSinceEpoch(app['lastTimeUsed'])}\n';
        })
        .join('\n\n');

    List<Map<String, String>> tabelData = await GeminiService.fetchTableData(
      combinedAppInfo,
    );

    setState(() {
      table = tabelData;
      isTableLoading = false;
    });

    if (table.isNotEmpty) {
      tableColumns = table.first.keys.toList();
    }
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
                            Text(
                              summary ?? 'No summary found.',
                              style: GoogleFonts.roboto(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    isTableLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DataTable(
                          headingRowColor: WidgetStateColor.resolveWith(
                            (states) => Colors.transparent,
                          ),
                          columns:
                              tableColumns
                                  .map((col) => DataColumn(label: Text(col)))
                                  .toList(),
                          rows:
                              table
                                  .map(
                                    (row) => DataRow(
                                      cells:
                                          tableColumns
                                              .map((col) => DataCell(Text(col)))
                                              .toList(),
                                    ),
                                  )
                                  .toList(),
                        ),
                  ],
                ),
              ),
    );
  }
}
