import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 🔁 CHANGE THIS TO YOUR LAPTOP IP
  static const String baseUrl = "http://192.168.1.9:8000";

  // ---------------------------
  // SEND OTP
  // ---------------------------
  static Future<bool> sendOtp(String email) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/auth/send-otp/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return res.statusCode == 200;
  }

  // ---------------------------
  // VERIFY OTP
  // ---------------------------
  static Future<bool> verifyOtp(String email, String otp) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/auth/verify-otp/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("access_token", data["access"]);
      await prefs.setString("refresh_token", data["refresh"]);
      return true;
    }
    return false;
  }

  // ---------------------------
  // CHECK LOGIN
  // ---------------------------
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey("access_token");
  }

  // ---------------------------
  // LOGOUT
  // ---------------------------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String?> _accessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  static Future<List<dynamic>> fetchVideos({required String category}) async {
    final token = await _accessToken();
    final res = await http.get(
      Uri.parse("$baseUrl/api/videos/?category=$category"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    return [];
  }
}