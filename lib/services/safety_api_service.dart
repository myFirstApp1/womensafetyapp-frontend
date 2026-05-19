import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:womensafetyapp/core/config/api_config.dart';
import 'package:flutter/foundation.dart';

class SafetyApiService {
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

             // feature devices-intelligence

  static Future<void> startProtection() async {

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");
    final userId = prefs.getString("userId");

    if (token == null || userId == null) return;

    final response = await http.post(
      Uri.parse(
        "${ApiConfig.safetyBaseUrl}/api/heartbeat/start?userId=$userId",
      ),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    debugPrint("START PROTECTION = ${response.statusCode}");
  }

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

  static Future<void> sendHeartbeat() async {

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");
    final userId = prefs.getString("userId");

    if (token == null || userId == null) return;

    final response = await http.put(
      Uri.parse(
        "${ApiConfig.safetyBaseUrl}/api/heartbeat/$userId",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    ).timeout(const Duration(seconds: 10));

    debugPrint("HEARTBEAT STATUS = ${response.statusCode}");
  }

  static Future<void> sendBluetoothPing() async {

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");
    final userId = prefs.getString("userId");

    if (token == null || userId == null) return;

    final response = await http.put(
      Uri.parse(
        "${ApiConfig.safetyBaseUrl}/api/device/ping-bluetooth/$userId",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    ).timeout(const Duration(seconds: 10));

    debugPrint("BLUETOOTH STATUS = ${response.statusCode}");
  }

  static Future<void> updateTracking({
    required double latitude,
    required double longitude,
  }) async {

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");
    final userId = prefs.getString("userId");

    if (token == null || userId == null) return;

    final response = await http.post(

      Uri.parse(
        "${ApiConfig.safetyBaseUrl}/api/tracking/update",
      ),

      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },

      body: jsonEncode({

        "userId": userId,
        "trackingId": "track-1",

        "latitude": latitude,
        "longitude": longitude,

        "accuracyMeters": 5,
        "speed": 10

      }),
    ).timeout(const Duration(seconds: 10));

    debugPrint("TRACKING STATUS = ${response.statusCode}");
  }

  static Future<void> updateVitals({

    required int heartRate,
    required int movementScore,

  }) async {

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");
    final userId = prefs.getString("userId");

    if (token == null || userId == null) return;

    final response = await http.post(

      Uri.parse(
        "${ApiConfig.safetyBaseUrl}/api/device/vitals/update",
      ),

      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },

      body: jsonEncode({

        "userId": userId,
        "heartRate": heartRate,
        "movementScore": movementScore,

      }),
    ).timeout(const Duration(seconds: 10));

    debugPrint("VITALS STATUS = ${response.statusCode}");
  }
}
