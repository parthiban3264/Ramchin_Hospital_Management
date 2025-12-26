// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class PatientService {
//   final String baseUrl;
//
//   PatientService({required this.baseUrl});
//
//   // ✅ Create a new patient
//   Future<Map<String, dynamic>> createPatient(Map<String, dynamic> data) async {
//     final url = Uri.parse('$baseUrl/patients/create');
//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(data),
//     );
//
//     return _handleResponse(response);
//   }
//
//   // ✅ Get all patients
//   Future<Map<String, dynamic>> getAllPatients() async {
//     final url = Uri.parse('$baseUrl/patients/all');
//     final response = await http.get(url);
//
//     return _handleResponse(response);
//   }
//
//   // ✅ Get patient by hospital_Id + user_Id
//   Future<Map<String, dynamic>> getPatientByUserId(
//     int hospitalId,
//     String userId,
//   ) async {
//     final url = Uri.parse('$baseUrl/patients/get/$hospitalId/$userId');
//     final response = await http.get(url);
//
//     return _handleResponse(response);
//   }
//
//   // ✅ Update patient by hospital_Id + user_Id
//   Future<Map<String, dynamic>> updatePatient(
//     int hospitalId,
//     String userId,
//     Map<String, dynamic> data,
//   ) async {
//     final url = Uri.parse('$baseUrl/patients/update/$hospitalId/$userId');
//     final response = await http.patch(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(data),
//     );
//
//     return _handleResponse(response);
//   }
//
//   // ✅ Delete patient by hospital_Id + user_Id
//   Future<Map<String, dynamic>> deletePatient(
//     int hospitalId,
//     String userId,
//   ) async {
//     final url = Uri.parse('$baseUrl/patients/delete/$hospitalId/$userId');
//     final response = await http.delete(url);
//
//     return _handleResponse(response);
//   }
//
//   Future<bool> checkUserIdExists(int hospitalId, String userId) async {
//     if (userId.trim().isEmpty) {
//       throw Exception('User ID cannot be empty.');
//     }
//
//     final url = Uri.parse('$baseUrl/patients/get/$hospitalId/$userId');
//
//     try {
//       final response = await http.get(url);
//       final body = jsonDecode(response.body);
//
//       // If patient is found, return true
//       return body['data'] != null;
//     } catch (e) {
//       // If not found (e.g., 404), return false
//       return false;
//     }
//   }
//
//   // ✅ Private response handler
//   Map<String, dynamic> _handleResponse(http.Response response) {
//     final body = jsonDecode(response.body);
//
//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       return body;
//     } else {
//       throw Exception(body['message'] ?? 'An error occurred');
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/utils.dart';

class PatientService {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  PatientService();

  /// Helper function to get hospitalId from secure storage
  Future<String> _getHospitalId() async {
    final hospitalId = await secureStorage.read(key: 'hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in secure storage.');
    }
    return hospitalId;
  }

  // ✅ Create a new patient
  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> data) async {
    final hospitalId = await _getHospitalId();

    final url = Uri.parse('$baseUrl/patients/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({...data, 'hospital_Id': int.parse(hospitalId)}),
    );
    print(jsonEncode({...data, 'hospital_Id': int.parse(hospitalId)}));

    return _handleResponse(response);
  }

  // ✅ Get all patients
  Future<Map<String, dynamic>> getAllPatients() async {
    final url = Uri.parse('$baseUrl/patients/all');
    final response = await http.get(url);

    return _handleResponse(response);
  }

  // ✅ Get patient by user_Id (hospitalId from secure storage)
  Future<Map<String, dynamic>> getPatientByUserId(String userId) async {
    final hospitalId = await _getHospitalId();

    final url = Uri.parse('$baseUrl/patients/get/$hospitalId/$userId');
    final response = await http.get(url);
    print(response.body);

    return _handleResponse(response);
  }

  // Future<Map<String, dynamic>> getPatientById(String userId) async {
  //   final hospitalId = await _getHospitalId();
  //
  //   final response = await http.get(
  //     Uri.parse('$baseUrl/patients/get/check/$hospitalId/$userId'),
  //   );
  //   print(response.body);
  //
  //   final json = jsonDecode(response.body);
  //   if (json['status'] == 'success' && json['data'] != null) {
  //     return json['data']; // ✅ return the actual patient map
  //   } else {
  //     throw Exception(json['message'] ?? 'Failed to fetch patient');
  //   }
  // }
  Future<List<Map<String, dynamic>>> getPatientsByUserId(String userId) async {
    final hospitalId = await _getHospitalId();

    final response = await http.get(
      Uri.parse('$baseUrl/patients/get/check/$hospitalId/$userId'),
    );

    print(response.body);

    final json = jsonDecode(response.body);
    if (json['status'] == 'success' && json['data'] != null) {
      // Ensure we convert each item to Map<String, dynamic>
      final List<dynamic> data = json['data'];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception(json['message'] ?? 'Failed to fetch patient');
    }
  }

  // ✅ Update patient by user_Id (hospitalId from secure storage)
  Future<Map<String, dynamic>> updatePatient(
    String userId,
    Map<String, dynamic> data,
  ) async {
    print('$userId :: $data');
    final hospitalId = await _getHospitalId();

    final url = Uri.parse('$baseUrl/patients/update/$hospitalId/$userId');
    print(url.toString());
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    print(response.body);

    return _handleResponse(response);
  }

  // ✅ Delete patient by user_Id (hospitalId from secure storage)
  Future<Map<String, dynamic>> deletePatient(String userId) async {
    final hospitalId = await _getHospitalId();

    final url = Uri.parse('$baseUrl/patients/delete/$hospitalId/$userId');
    final response = await http.delete(url);

    return _handleResponse(response);
  }

  // ✅ Check if userId exists (hospitalId from secure storage)
  Future<bool> checkUserIdExists(String userId) async {
    if (userId.trim().isEmpty) {
      throw Exception('User ID cannot be empty.');
    }

    final hospitalId = await _getHospitalId();
    final url = Uri.parse('$baseUrl/patients/get/$hospitalId/$userId');

    try {
      final response = await http.get(url);
      final body = jsonDecode(response.body);
      return body['data'] != null;
    } catch (e) {
      return false;
    }
  }

  // ✅ Private response handler
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['message'] ?? 'An error occurred');
    }
  }
}
