import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Running Apps')),
      body:
          runningApps.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: runningApps.length,
                itemBuilder: (context, index) {
                  final app = runningApps[index];
                  Uint8List? imageBytes;
                  if (app['icon'] != null) {
                    imageBytes = base64Decode(app['icon']);
                  }

                  return ListTile(
                    leading:
                        (imageBytes != null
                            ? Image.memory(imageBytes, width: 40, height: 40)
                            : const Icon(Icons.radar)),
                    title: Text(app['appName']),
                    subtitle: Text(
                      'Used: ${(app['usageTime'] / 1000).round()} sec\nLast: ${DateTime.fromMillisecondsSinceEpoch(app['lastTimeUsed'])}',
                      style: GoogleFonts.hammersmithOne(
                        textStyle: TextStyle(
                          color: Colors.blue,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
