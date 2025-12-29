// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import '../../utils/utils.dart'; // Ensure this has your baseUrl defined
//
// class DoctorService {
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//
//   /// Get hospital ID from secure storage
//   Future<String> _getHospitalId() async {
//     final hospitalId = await secureStorage.read(key: 'hospitalId');
//     if (hospitalId == null || hospitalId.isEmpty) {
//       throw Exception('Hospital ID not found in secure storage.');
//     }
//     return hospitalId;
//   }
//
//   /// Fetch doctors from the Admin table for this hospital
//   Future<List<Map<String, dynamic>>> getDoctors() async {
//     try {
//       final hospitalId = await _getHospitalId();
//
//       // 👇 Use your backend route correctly
//       final url = Uri.parse('$baseUrl/admins/all/$hospitalId/Doctor');
//
//
//       final response = await http.get(url);
//
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//
//         // Expected response:
//         // { "status": "success", "data": [ { "name": "...", "role": "Doctor", ... } ] }
//         if (data['status'] == 'success' && data['data'] is List) {
//           final List doctors = data['data'];
//
//           // ✅ Map response to UI-friendly structure
//           return doctors.map<Map<String, dynamic>>((doc) {
//             return {
//               "id": doc['user_Id']?.toString() ?? '',
//               "name": doc['name']?.toString() ?? 'Unknown',
//               "department": doc['specialist']?.toString() ?? 'General',
//               "photo": (doc['photo']?.toString().isNotEmpty ?? false)
//                   ? doc['photo']
//                   : "https://cdn-icons-png.flaticon.com/512/387/387561.png",
//             };
//           }).toList();
//         } else {
//
//         }
//       } else {
//
//       }
//
//       return [];
//     } catch (e) {
//
//       return [];
//     }
//   }
// }

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/utils.dart';

class DoctorService {
  Future<String> getHospitalId() async {
    final prefs = await SharedPreferences.getInstance();

    final hospitalId = prefs.getString('hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final hospitalId = await getHospitalId();
      final url = Uri.parse('$baseUrl/admins/all/$hospitalId/DOCTOR');

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      // ✅ Backend returns List directly, not {"status":..., "data":...}
      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>((doc) {
              if (doc is Map<String, dynamic>) {
                return {
                  "id": doc["user_Id"]?.toString() ?? "",
                  "name": doc["name"]?.toString() ?? "Unknown",
                  "department": doc["specialist"]?.toString() ?? "General",
                  "status": doc['status']?.toString() ?? "INACTIVE",
                  "photo": (doc["photo"]?.toString().isNotEmpty ?? false)
                      ? doc["photo"]
                      : "https://cdn-icons-png.flaticon.com/512/387/387561.png",
                };
              } else {
                return {};
              }
            })
            .where((d) => d.isNotEmpty)
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStaffs() async {
    try {
      final hospitalId = await getHospitalId();
      final url = Uri.parse('$baseUrl/admins/all/$hospitalId/Nurse');

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      // ✅ Backend returns List directly, not {"status":..., "data":...}
      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>((doc) {
              if (doc is Map<String, dynamic>) {
                return {
                  "id": doc["user_Id"]?.toString() ?? "",
                  "name": doc["name"]?.toString() ?? "Unknown",
                  "department": doc["specialist"]?.toString() ?? "General",
                  "photo": (doc["photo"]?.toString().isNotEmpty ?? false)
                      ? doc["photo"]
                      : "https://cdn-icons-png.flaticon.com/512/387/387561.png",
                };
              } else {
                return {};
              }
            })
            .where((d) => d.isNotEmpty)
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
