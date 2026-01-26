import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SafetyApiService {
  static const _baseUrl = "http://192.168.1.6:8084/api/sos";

  static Future<void> sendEvent({
    required String event,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) return;

    final response = await http.post(
      Uri.parse("$_baseUrl/event?event=$event"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to send SOS event");
    }
  }

  static Future<String> getCurrentState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final userId = prefs.getString("userId");

    if (token == null || userId == null) return "IDLE";

    final response = await http.get(
      Uri.parse("$_baseUrl/current?userId=$userId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return response.body.replaceAll('"', '');
    }
    return "IDLE";
  }

}
