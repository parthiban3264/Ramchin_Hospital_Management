import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/utils.dart';

class AuthService {
  // Base URL of your backend
  final storage = FlutterSecureStorage();

  // Login function
  Future<Map<String, dynamic>> logins({
    required String hospitalId,
    required String userId,
    required String password,
  }) async {
    print(hospitalId + userId + password);
    final url = Uri.parse('$baseUrl/users/login');
    print(url);
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "hospital_Id": int.tryParse(hospitalId) ?? 0,
        "user_Id": userId,
        "password": password,
      }),
    );
    print("h----------${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // Save JWT token
      await storage.write(key: 'jwt_token', value: data['access_token']);

      return {"success": true, "data": data};
    } else {
      final data = jsonDecode(response.body);
      return {"success": false, "message": data['message'] ?? 'Login failed'};
    }
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  // Future<void> logout() async {
  //   await storage.delete(key: 'jwt_token');
  // }

  // Example of authenticated request
  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/users/profile');

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch profile: ${response.body}');
      return null;
    }
  }

  // -------------------- USER CRUD --------------------
  Future<Map<String, dynamic>?> createUser(
    Map<String, dynamic> userData,
  ) async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/users/create');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Create user failed: ${response.body}');
      return null;
    }
  }

  Future<List<dynamic>?> getAllUsers() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/users/all');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Get all users failed: ${response.body}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/users/getById/$id');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Get user by id failed: ${response.body}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateUser(
    int id,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/users/updateById/$id');
    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Update user failed: ${response.body}');
      return null;
    }
  }

  Future<bool> deleteUser(int id) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/users/deleteById/$id');
    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Delete user failed: ${response.body}');
      return false;
    }
  }

  /// main login
  Future<Map<String, dynamic>> login({
    required String hospitalId,
    required String userId,
    required String password,
    required String deviceId,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');
    print("Login URL: $url");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "hospital_Id": int.tryParse(hospitalId) ?? 0,
        "user_Id": userId,
        "password": password,
        "device_Id": deviceId,
      }),
    );

    print("Response: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final token = data["data"]["access_token"];
      final user = data["data"]["user"];
      final role = user["role"];
      final designation = user["admin"]?["designation"];
      final staffStatus = user["admin"]?["status"];
      final hospitalName = user["hospital"]?["name"];
      final hospitalPlace = user["hospital"]?["address"];
      final hospitalPhoto = user["hospital"]?["photo"];
      final hospitalStatus = user["hospital"]?["HospitalStatus"];
      print('hospitalStatus Server: $hospitalStatus');
      // ✅ Save token & user details
      await storage.write(key: 'jwt_token', value: token);
      await storage.write(key: 'role', value: role ?? "");
      await storage.write(key: 'designation', value: designation ?? "");
      await storage.write(key: 'staffStatus', value: staffStatus ?? "");
      await storage.write(key: 'hospitalId', value: hospitalId);
      await storage.write(key: 'hospitalName', value: hospitalName ?? "");
      await storage.write(key: 'hospitalPlace', value: hospitalPlace ?? "");
      await storage.write(key: 'hospitalStatus', value: hospitalStatus ?? "");
      await storage.write(
        key: 'hospitalPhoto',
        value:
            hospitalPhoto ??
            "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg",
      );
      await storage.write(key: 'userId', value: userId);
      print(response.body);
      return {"success": true, "data": data["data"]};
    } else {
      return {"success": false, "message": data["message"] ?? "Login failed"};
    }
  }

  Future<void> logout() async {
    final token = await storage.read(key: 'jwt_token');

    final hospital_Id = await storage.read(key: 'hospitalId');
    if (token == null) return;
    print(token);
    final id = await storage.read(key: 'userId');
    final url = Uri.parse(
      '$baseUrl/users/logout/$hospital_Id/$id',
    ); // ✅ match backend route
// =======
//     if (token == null) return;
//     print(token);
//     final id = await storage.read(key: 'userId');
//     final url = Uri.parse('$baseUrl/users/logout/$id'); // ✅ match backend route
// >>>>>>> 3f063fbf1fae91f45feca0bca76a410ab6083f20
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("Logout response: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        data['success'] == true) {
      print('Logout successful');
      await storage.delete(key: 'jwt_token');
    } else {
      throw Exception(data['message'] ?? 'Logout failed');
    }
  }

  Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return android.id ?? android.fingerprint; // Android unique ID
    }

    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return ios.identifierForVendor ?? ""; // iOS unique ID
    }

    return "UNKNOWN_DEVICE";
  }


  /// ------------------------
  /// CHECK OLD PASSWORD
  /// ------------------------
  Future<bool> checkOldPassword(int userId, String oldPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/CheckOldPassword/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"oldPassword": oldPassword}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) return false;

        final data = jsonDecode(response.body);
        return data['result'] == true; // ✅ now matches backend
      } else {
        print("Server error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error checking old password: $e");
      return false;
    }
  }

  /// ------------------------
  /// CHANGE PASSWORD
  /// ------------------------
  Future<bool> changePassword(int userId, String newPassword) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/ChangePassword/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"newPassword": newPassword}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print("Password changed successfully.");
          return true;
        } else {
          print(
            "Password change failed: ${data['message'] ?? 'Unknown error'}",
          );
          return false;
        }
      } else {
        print("Server error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error changing password: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getById(
    String hospitalId,
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/GetByUserId/$userId/$hospitalId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response body: ${response.body}'); // debug

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) return null;

        final decoded = jsonDecode(response.body);

        // Backend returns: { data: { id: 3 } }
        return decoded['data'] as Map<String, dynamic>?;
      } else {
        print('Failed to get user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

}
