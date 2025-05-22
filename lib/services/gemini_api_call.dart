import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/web.dart';

class GeminiService {
  static final Logger _logger = Logger();

  static final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  static final String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

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
                  "text":
                      "Summarize the following app usage information:\n$appInfo",
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
