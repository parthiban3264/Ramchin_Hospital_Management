import 'dart:convert';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class AuthService {
  // -------------------- LOGIN (BASIC) --------------------
  Future<Map<String, dynamic>> logins({
    required String hospitalId,
    required String userId,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "hospital_Id": int.tryParse(hospitalId) ?? 0,
        "user_Id": userId,
        "password": password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['access_token']);
      return {"success": true, "data": data};
    } else {
      final data = jsonDecode(response.body);
      return {"success": false, "message": data['message'] ?? 'Login failed'};
    }
  }

  // -------------------- TOKEN --------------------
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // -------------------- PROFILE --------------------
  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // -------------------- MAIN LOGIN --------------------
  Future<Map<String, dynamic>> login({
    required String hospitalId,
    required String userId,
    required String password,
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "hospital_Id": int.tryParse(hospitalId) ?? 0,
        "user_Id": userId,
        "password": password,
        "device_Id": deviceId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();

      final token = data["data"]["access_token"];
      final user = data["data"]["user"];

      await prefs.setString('jwt_token', token);
      await prefs.setString('role', user["role"] ?? "");
      await prefs.setString('designation', user["admin"]?["designation"] ?? "");
      await prefs.setString('staffStatus', user["admin"]?["status"] ?? "");
      await prefs.setString('hospitalId', hospitalId);
      await prefs.setString('hospitalName', user["hospital"]?["name"] ?? "");
      await prefs.setString(
        'hospitalPlace',
        user["hospital"]?["address"] ?? "",
      );
      await prefs.setString(
        'hospitalStatus',
        user["hospital"]?["HospitalStatus"] ?? "",
      );
      await prefs.setString(
        'hospitalPhoto',
        user["hospital"]?["photo"] ??
            "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg",
      );
      await prefs.setString('userId', userId);

      return {"success": true, "data": data["data"]};
    } else {
      return {"success": false, "message": data["message"] ?? "Login failed"};
    }
  }

  // -------------------- LOGOUT --------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final hospitalId = prefs.getString('hospitalId');
    final userId = prefs.getString('userId');

    if (token == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/users/logout/$hospitalId/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || data['success'] == true) {
      await prefs.remove('jwt_token');
    } else {
      throw Exception(data['message'] ?? 'Logout failed');
    }
  }

  // -------------------- DEVICE ID (WEB + MOBILE SAFE) --------------------
  Future<String> getDeviceId() async {
    if (kIsWeb) {
      return await _getWebDeviceId();
    }

    final deviceInfo = DeviceInfoPlugin();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = await deviceInfo.androidInfo;
      return android.id;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = await deviceInfo.iosInfo;
      return ios.identifierForVendor ?? "IOS_UNKNOWN";
    }

    return "UNKNOWN_DEVICE";
  }

  Future<String> _getWebDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('web_device_id');

    if (id == null) {
      id = _generateRandomId();
      await prefs.setString('web_device_id', id);
    }

    return id;
  }

  String _generateRandomId() {
    final rand = Random();
    return List.generate(24, (_) => rand.nextInt(16).toRadixString(16)).join();
  }

  // -------------------- PASSWORD CHECK --------------------
  Future<bool> checkOldPassword(int userId, String oldPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/CheckOldPassword/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"oldPassword": oldPassword}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['result'] == true;
    }
    return false;
  }

  // -------------------- CHANGE PASSWORD --------------------
  Future<bool> changePassword(int userId, String newPassword) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/ChangePassword/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"newPassword": newPassword}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  // -------------------- GET USER BY ID --------------------
  Future<Map<String, dynamic>?> getById(
    String hospitalId,
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/GetByUserId/$userId/$hospitalId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      return decoded['data'];
    }
    return null;
  }
}
