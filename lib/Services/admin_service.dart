import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class AdminService {
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hospitalId = prefs.getString('hospitalId');
      final userId = prefs.getString('userId');

      if (userId == null || hospitalId == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/admins/getByUser/$hospitalId/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // Assuming API returns { data: {...} }
      } else {
        throw Exception('Failed to fetch profile');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getLabProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get userId from secure storage
      //final userId = await storage.read(key: 'userId');
      final hospitalId = prefs.getString('hospitalId');

      if (hospitalId == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/admins/getByUser/$hospitalId/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // Assuming API returns { data: {...} }
      } else {
        throw Exception('Failed to fetch profile');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getProfileAssignDr(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get userId from secure storage
      //final userId = await storage.read(key: 'userId');
      final hospitalId = prefs.getString('hospitalId');

      if (hospitalId == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/admins/getByUser/$hospitalId/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // Assuming API returns { data: {...} }
      } else {
        throw Exception('Failed to fetch profile');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<Map<String, dynamic>> updateAdminProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getString('userId');
      final hospitalId = prefs.getString('hospitalId');

      if (userId == null || hospitalId == null) {
        throw Exception("User ID or Hospital ID not found in secure storage");
      }

      final url = Uri.parse('$baseUrl/admins/update/$hospitalId/$userId');

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success') {
          return result; // ✅ Successful update
        } else {
          throw Exception(result['message'] ?? 'Update failed');
        }
      } else {
        throw Exception(
          "Server error: ${response.statusCode} - ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      return {"status": "failed", "message": e.toString()};
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final hospitalId = prefs.getString('hospitalId');

    final uri = Uri.parse(
      '$baseUrl/admins/updateProfilePhoto/$hospitalId/$userId',
    );

    final request = http.MultipartRequest('PUT', uri);

    request.headers.addAll({'Accept': 'application/json'});

    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    final result = jsonDecode(responseBody);

    if (response.statusCode == 200 && result['status'] == 'success') {
      return result['photo'];
    } else {
      throw Exception(result['message'] ?? 'Image upload failed');
    }
  }

  // Future<Map<String, dynamic>> updateAdminProfile({
  //   required Map<String, String> data,
  //   File? photoFile,
  // }) async {
  //   try {
  //     final userId = await storage.read(key: 'userId');
  //     final hospitalId = await storage.read(key: 'hospitalId');
  //
  //     if (userId == null || hospitalId == null) {
  //       throw Exception("User ID or Hospital ID not found");
  //     }
  //
  //     final url = Uri.parse('$baseUrl/admins/update/$hospitalId/$userId');
  //
  //     final request = http.MultipartRequest('PATCH', url);
  //
  //     // ✅ Add text fields
  //     data.forEach((key, value) {
  //       request.fields[key] = value;
  //     });
  //
  //     // ✅ Add image file ONLY if selected
  //     if (photoFile != null) {
  //       request.files.add(
  //         await http.MultipartFile.fromPath(
  //           'photo', // must match backend field name
  //           photoFile.path,
  //         ),
  //       );
  //     }
  //
  //     final response = await request.send();
  //     final responseBody = await response.stream.bytesToString();
  //     final result = jsonDecode(responseBody);
  //
  //     if (response.statusCode == 200 && result['status'] == 'success') {
  //       return result;
  //     } else {
  //       throw Exception(result['message'] ?? 'Update failed');
  //     }
  //   } catch (e) {
  //     return {"status": "failed", "message": e.toString()};
  //   }
  // }

  Future<Map<String, dynamic>> createAdmin(Map<String, dynamic> data) async {
    final url = Uri.parse(
      '$baseUrl/admins/create',
    ); // adjust base URL as needed

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Created successfully
        return jsonDecode(response.body);
      } else {
        // Backend returned an error
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to create admin');
      }
    } catch (e) {
      throw Exception('Network or server error: $e');
    }
  }

  /// GET all admins by hospital ID
  // Future<List<dynamic>> getMedicalStaff() async {
  //   final hospitalId = await storage.read(key: 'hospitalId');
  //   final url = Uri.parse("$baseUrl/admins/all/$hospitalId");
  //
  //   final response = await http.get(url);
  //
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception("Failed to load admins");
  //   }
  // }

  /// 🔍 Check if User ID already exists for a hospital
  Future<bool> checkUserIdExists({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final uri = Uri.parse('$baseUrl/admins/check-user-id/$hospitalId/$userId');

    final response = await http.get(uri);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['exists'] == true;
    } else {
      throw Exception('Failed to check user id');
    }
  }

  Future<List<dynamic>> getMedicalStaff() async {
    final prefs = await SharedPreferences.getInstance();

    final hospitalId = prefs.getString("hospitalId");
    final url = Uri.parse("$baseUrl/admins/all/$hospitalId");

    final response = await http.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);

      // if API returns { "data": [...] }
      if (json is Map && json["data"] is List) {
        return json["data"];
      }

      // if API returns [] directly
      if (json is List) {
        return json;
      }

      return [];
    }

    throw Exception("Failed to load admins");
  }

  Future<Map<String, dynamic>> updateAdminAmount(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse("$baseUrl/admins/updateById/$id");

    final response = await http.patch(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Failed to update admin amount. Status: ${response.statusCode}, Body: ${response.body}",
      );
    }
  }

  /// PATCH update admin by ID
  // Future<dynamic> updateStatus(int id, Map<String, dynamic> data) async {
  //   final url = Uri.parse("$baseUrl/updateById/$id");
  //
  //   final response = await http.patch(
  //     url,
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode(data),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception("Failed to update admin");
  //   }
  // }
  Future updateStatus(int id, bool isActive) async {
    final url = Uri.parse("$baseUrl/admins/updateById/$id");

    final response = await http.patch(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": isActive ? "ACTIVE" : "INACTIVE"}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update status");
    }
  }

  Future deleteAdmin(int id) async {
    final url = Uri.parse("$baseUrl/admins/deleteById/$id");

    final response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to delete admin");
    }
  }
}
