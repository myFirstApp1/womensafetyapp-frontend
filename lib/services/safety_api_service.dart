import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:womensafetyapp/core/config/api_config.dart';

class SafetyApiService {
  //static const _baseUrl = "http://192.168.1.6:8084/api/sos";
  static Future<void> sendEvent({
    required String event,
    double? lat,
    double? lng,
    int? durationMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final userId = prefs.getString("userId");

    print("TOKEN: $token");
    print("USER ID: $userId");
    print("EVENT: $event");
    if (token == null || userId == null) return;

    final uri = Uri.parse("${ApiConfig.safetyBaseUrl}/event").replace(
      queryParameters: {
        "userId": userId,
        "event": event,
        if (lat != null) "lat": lat.toString(),
        if (lng != null) "lng": lng.toString(),
        if (durationMinutes != null)
          "durationMinutes": durationMinutes.toString(),
      },
    );

    print("API CALL: $uri");

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("API URL: $uri");
    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to send SOS event");
    }
  }
  // static Future<void> sendEvent({
  //   required String event,
  //   double? lat,
  //   double? lng,
  //   int? durationMinutes,
  // }) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString("token");
  //   final userId = prefs.getString("userId");
  //
  //   if (token == null || userId == null) return;
  //
  //   final uri = Uri.parse("$_baseUrl/event").replace(
  //     queryParameters: {
  //       "userId": userId,
  //       "event": event,
  //       if (lat != null) "lat": lat.toString(),
  //       if (lng != null) "lng": lng.toString(),
  //       if (durationMinutes != null)
  //         "durationMinutes": durationMinutes.toString(),
  //     },
  //   );
  //
  //   final response = await http.post(
  //     uri,
  //     headers: {
  //       "Authorization": "Bearer $token",
  //       "Content-Type": "application/json",
  //     },
  //   );
  //
  //   if (response.statusCode != 200) {
  //     throw Exception("Failed to send SOS event");
  //   }
  // }

  static Future<String> getCurrentState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final userId = prefs.getString("userId");

    if (token == null || userId == null) return "IDLE";

    final response = await http.get(
      Uri.parse("${ApiConfig.safetyBaseUrl}/current?userId=$userId"),
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
