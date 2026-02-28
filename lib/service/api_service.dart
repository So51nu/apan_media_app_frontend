// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ApiService {
//   // 🔁 CHANGE THIS TO YOUR LAPTOP IP
//   static const String baseUrl = "http://192.168.1.9:8000";
//
//   // ---------------------------
//   // SEND OTP
//   // ---------------------------
//   static Future<bool> sendOtp(String email) async {
//     final res = await http.post(
//       Uri.parse("$baseUrl/api/auth/send-otp/"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"email": email}),
//     );
//
//     return res.statusCode == 200;
//   }
//
//   // ---------------------------
//   // VERIFY OTP
//   // ---------------------------
//   static Future<bool> verifyOtp(String email, String otp) async {
//     final res = await http.post(
//       Uri.parse("$baseUrl/api/auth/verify-otp/"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"email": email, "otp": otp}),
//     );
//
//     if (res.statusCode == 200) {
//       final data = jsonDecode(res.body);
//       final prefs = await SharedPreferences.getInstance();
//
//       await prefs.setString("access_token", data["access"]);
//       await prefs.setString("refresh_token", data["refresh"]);
//       return true;
//     }
//     return false;
//   }
//
//   // ---------------------------
//   // CHECK LOGIN
//   // ---------------------------
//   static Future<bool> isLoggedIn() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.containsKey("access_token");
//   }
//
//   // ---------------------------
//   // LOGOUT
//   // ---------------------------
//   static Future<void> logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//   }
//
//   static Future<String?> _accessToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString("access_token");
//   }
//
//   static Future<List<dynamic>> fetchVideos({required String category}) async {
//     final token = await _accessToken();
//     final res = await http.get(
//       Uri.parse("$baseUrl/api/videos/?category=$category"),
//       headers: {"Authorization": "Bearer $token"},
//     );
//     if (res.statusCode == 200) {
//       return jsonDecode(res.body) as List<dynamic>;
//     }
//     return [];
//   }
// }

// lib/service/api_service.dart
//
// ✅ Fully corrected ApiService
// - OTP login (sendOtp, verifyOtp)
// - Token store (access/refresh) in SharedPreferences
// - Auto headers + JSON helpers
// - fetchVideos(category)
// - Reels feed: fetchFeed(page,pageSize,category)
// - Persist actions: react(videoId, like/save/download/share/progress)
// - Safe error handling + optional debug logs
//
// NOTE:
// 1) baseUrl must be your laptop IP (same Wi-Fi)
// 2) If you use HTTP on Android, keep usesCleartextTraffic=true (already discussed)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 🔁 CHANGE THIS TO YOUR LAPTOP IP
  static const String baseUrl = "https://apna.app.backend.clickconnectmedia.cloud";

  // Keys
  static const _kAccess = "access_token";
  static const _kRefresh = "refresh_token";

  // --------------- Helpers ---------------

  static Map<String, String> _jsonHeaders() => const {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  static Future<String?> _accessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccess);
  }

  static Future<String?> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefresh);
  }

  static Future<void> _saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    await prefs.setString(_kRefresh, refresh);
  }
  static Future<Map<String, dynamic>> createCancelFeeOrder() async {
    final res = await http.post(
      _u("/api/payments/cancel-fee-order/"),
      headers: await _authHeaders(json: true),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await _accessToken();
    final headers = <String, String>{
      if (json) ..._jsonHeaders(),
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
    return headers;
  }

  static Uri _u(String path, [Map<String, String>? q]) {
    // path example: "/api/videos/"
    final p = path.startsWith("/") ? path : "/$path";
    return Uri.parse("$baseUrl$p").replace(queryParameters: q);
  }

  // --------------- OTP LOGIN ---------------

  static Future<bool> sendOtp(String email) async {
    final res = await http.post(
      _u("/api/auth/send-otp/"),
      headers: _jsonHeaders(),
      body: jsonEncode({"email": email.trim()}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final res = await http.post(
      _u("/api/auth/verify-otp/"),
      headers: _jsonHeaders(),
      body: jsonEncode({"email": email.trim(), "otp": otp.trim()}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      // backend should return: { access: "...", refresh: "..." }
      final access = (data["access"] ?? "").toString();
      final refresh = (data["refresh"] ?? "").toString();

      if (access.isEmpty || refresh.isEmpty) return false;

      await _saveTokens(access, refresh);
      return true;
    }
    return false;
  }

  static Future<bool> isLoggedIn() async {
    final token = await _accessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    // If you also have backend logout endpoint, you can call it here.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
  }

  // --------------- Token Refresh (Optional but recommended) ---------------

  static Future<bool> refreshAccessToken() async {
    final refresh = await _refreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    final res = await http.post(
      _u("/api/auth/refresh/"),
      headers: _jsonHeaders(),
      body: jsonEncode({"refresh": refresh}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final access = (data["access"] ?? "").toString();
      if (access.isEmpty) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAccess, access);
      return true;
    }
    return false;
  }

  // --------------- Videos (Category list) ---------------

  static Future<List<dynamic>> fetchVideos({required String category}) async {
    final headers = await _authHeaders(json: false);
    final res = await http.get(
      _u("/api/videos/", {"category": category}),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }

    // If token expired, try refresh once
    if (res.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final headers2 = await _authHeaders(json: false);
        final res2 = await http.get(
          _u("/api/videos/", {"category": category}),
          headers: headers2,
        );
        if (res2.statusCode == 200) {
          return jsonDecode(res2.body) as List<dynamic>;
        }
      }
    }

    return [];
  }

  // --------------- Reels Feed (Paged) ---------------
  // GET /api/videos/feed/?page=1&page_size=10&category=popular

  static Future<List<dynamic>> fetchContinue() async {
    final headers = await _authHeaders(json: false);
    final res = await http.get(_u("/api/videos/continue/"), headers: headers);
    if (res.statusCode == 200) return (jsonDecode(res.body) as List);
    return [];
  }
  static Future<Map<String, dynamic>> fetchFeed({
    required int page,
    int pageSize = 10,
    String? category,
  }) async {
    final headers = await _authHeaders(json: false);

    final qp = <String, String>{
      "page": page.toString(),
      "page_size": pageSize.toString(),
      if (category != null && category.isNotEmpty) "category": category,
    };

    final res = await http.get(_u("/api/videos/feed/", qp), headers: headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    // retry once on 401
    if (res.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final headers2 = await _authHeaders(json: false);
        final res2 = await http.get(_u("/api/videos/feed/", qp), headers: headers2);
        if (res2.statusCode == 200) {
          return jsonDecode(res2.body) as Map<String, dynamic>;
        }
      }
    }

    return {"results": [], "has_more": false, "page": page, "page_size": pageSize};
  }

  // --------------- Persist Reactions / Progress ---------------
  // POST /api/videos/<id>/react/
  // body supports:
  //  like_status: -1/0/1
  //  is_saved: true/false
  //  is_downloaded: true/false
  //  share_increment: true
  //  last_position_ms: int

  static Future<Map<String, dynamic>> watchStart(int videoId) async {
    final res = await http.post(
      _u("/api/watch/start/"),
      headers: await _authHeaders(json: true),
      body: jsonEncode({"video_id": videoId}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createOrder(int amount) async {
    final res = await http.post(
      _u("/api/payments/create-order/"),
      headers: await _authHeaders(json: true),
      body: jsonEncode({"amount": amount}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> payload) async {
    final res = await http.post(
      _u("/api/payments/verify/"),
      headers: await _authHeaders(json: true),
      body: jsonEncode(payload),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createSubscription() async {
    final res = await http.post(
      _u("/api/payments/create-subscription/"),
      headers: await _authHeaders(json: true),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
  static Future<Map<String, dynamic>?> react({
    required int videoId,
    int? likeStatus,
    bool? isSaved,
    bool? isDownloaded,
    bool? shareIncrement,
    int? lastPositionMs,
  }) async {
    final body = <String, dynamic>{};
    if (likeStatus != null) body["like_status"] = likeStatus;
    if (isSaved != null) body["is_saved"] = isSaved;
    if (isDownloaded != null) body["is_downloaded"] = isDownloaded;
    if (shareIncrement != null) body["share_increment"] = shareIncrement;
    if (lastPositionMs != null) body["last_position_ms"] = lastPositionMs;

    final headers = await _authHeaders(json: true);

    final res = await http.post(
      _u("/api/videos/$videoId/react/"),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    // retry once on 401
    if (res.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final headers2 = await _authHeaders(json: true);
        final res2 = await http.post(
          _u("/api/videos/$videoId/react/"),
          headers: headers2,
          body: jsonEncode(body),
        );
        if (res2.statusCode == 200) {
          return jsonDecode(res2.body) as Map<String, dynamic>;
        }
      }
    }

    return null;
  }

  // --------------- Optional: Me endpoint (if you want) ---------------
  static Future<Map<String, dynamic>?> me() async {
    final headers = await _authHeaders(json: false);
    final res = await http.get(_u("/api/auth/me/"), headers: headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    if (res.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final headers2 = await _authHeaders(json: false);
        final res2 = await http.get(_u("/api/auth/me/"), headers: headers2);
        if (res2.statusCode == 200) {
          return jsonDecode(res2.body) as Map<String, dynamic>;
        }
      }
    }

    return null;
  }
}