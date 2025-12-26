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
//       print('Fetching doctors from: $url');
//
//       final response = await http.get(url);
//       print('Doctor API Response: ${response.body}');
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
//           print('Unexpected data format: ${data}');
//         }
//       } else {
//         print('Failed to fetch doctors: ${response.statusCode}');
//       }
//
//       return [];
//     } catch (e) {
//       print("Error fetching doctors: $e");
//       return [];
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/utils.dart';

class DoctorService {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<String> getHospitalId() async {
    final hospitalId = await secureStorage.read(key: 'hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final hospitalId = await getHospitalId();
      final url = Uri.parse('$baseUrl/admins/all/$hospitalId/DOCTOR');
      print('📡 Fetching doctors from: $url');

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('❌ Error: ${response.statusCode}');
        return [];
      }

      final decoded = jsonDecode(response.body);
      print('✅ Raw response: $decoded');

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
        print("⚠️ Unexpected response type: ${decoded.runtimeType}");
        return [];
      }
    } catch (e, stack) {
      print('❌ Error fetching doctors: $e');
      print(stack);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStaffs() async {
    try {
      final hospitalId = await getHospitalId();
      final url = Uri.parse('$baseUrl/admins/all/$hospitalId/Nurse');
      print('📡 Fetching doctors from: $url');

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('❌ Error: ${response.statusCode}');
        return [];
      }

      final decoded = jsonDecode(response.body);
      print('✅ Raw response: $decoded');

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
        print("⚠️ Unexpected response type: ${decoded.runtimeType}");
        return [];
      }
    } catch (e, stack) {
      print('❌ Error fetching doctors: $e');
      print(stack);
      return [];
    }
  }
}
