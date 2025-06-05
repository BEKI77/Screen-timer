import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/web.dart';

class GeminiService {
  static final Logger _logger = Logger();

  static final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  static final String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

  static Future<List<Map<String, String>>> fetchTableData(
    String appInfo,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """

                      Analyze the following app usage data and return a detailed summary. I want the response to include:

                      1. A table with each app's name, total usage time (in hours and minutes), number of launches, and last time used.
                      2. No extra sentences just the tabel only.
                      App usage data:
                      $appInfo
                      """,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        String summary = json['candidates'][0]['content']['parts'][0]['text'];

        final lines = summary.trim().split('\n');

        if (lines.length < 3) return [];

        final headers =
            lines[0]
                .split('|')
                .map((h) => h.trim())
                .where((h) => h.isNotEmpty)
                .toList();
        final dataLines = lines.sublist(2); // skip headers and separator
        final data =
            dataLines
                .map((line) {
                  final values =
                      line
                          .split('|')
                          .map((v) => v.trim())
                          .where((v) => v.isNotEmpty)
                          .toList();

                  if (values.length == headers.length) {
                    return Map<String, String>.fromIterables(headers, values);
                  }
                  return null;
                })
                .where((row) => row != null)
                .cast<Map<String, String>>()
                .toList();

        return data;
      } else {
        _logger.e('Gemini API Error: ${response.statusCode}');
        _logger.d(response.body);
        return [];
      }
    } catch (e) {
      _logger.e("Error using Gemini API: $e");
      return [];
    }
  }

  static Future<String?> summarizeAppUsage(String appInfo) async {
    if (_apiKey == null || appInfo == "") {
      _logger.i("Gemini API key is missing or appInfo is empty string !");
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
                    I want the response to include:
                    1. Identify the top 3 most used apps.
                    2. Provide 3 personalized suggestions to reduce screen time or improve productivity based on the usage data.
                    App usage data:
                    $appInfo
                    """,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['candidates'][0]['content']['parts'][0]['text'];
      } else {
        _logger.e('Gemini API Error: ${response.statusCode}');
        _logger.d(response.body);
      }
    } catch (e) {
      _logger.e("Error using Gemini API: $e");
    }
    return null;
  }
}
