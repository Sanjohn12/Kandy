import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // Existing API Configuration preserved from home_screen.dart
  static const String _apiKey = "AIzaSyBpoYWFFHDi0DRDqXOz7ABYafpfOhY2izs";
  static const String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$_apiKey";

  Future<String> chatQuery(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "You are a local travel expert for Kandy, Sri Lanka. Answer this question briefly and helpfully: $text"
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception(
            'Failed to connect to AI (Code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Connection failed. Please check your internet.');
    }
  }

  Future<String> generateItinerary({
    required String hours,
    required String interests,
    required String startLocation,
  }) async {
    final prompt = """
You are a professional local travel guide in Kandy, Sri Lanka.
Generate a high-quality, dense itinerary for a user with these constraints:
- Available Time: $hours
- Interests: $interests
- Starting Point: $startLocation

Format the response as a professional travel plan with:
1. A catchy title.
2. A chronological breakdown of places to visit.
3. Brief "Insider Tips" for each spot.
4. Total estimated travel time in Kandy traffic.

Hyper-local advice: If they like nature, suggest Udawattakele or Hanthana. If they like history, suggest the British Garrison Cemetery or Degaldoruwa. Avoid generic tourist traps unless specifically requested.
""";

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception(
            'Failed to generate plan (Code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Planning failed. Please try again.');
    }
  }
}
