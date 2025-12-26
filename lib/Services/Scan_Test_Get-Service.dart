import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class ScanTestGetService {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<String> getHospitalId() async {
    final hospitalId = await secureStorage.read(key: 'hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  /// ✅ Fetch all test data (categories + options) from DB
  Future<List<Map<String, dynamic>>> fetchTests(String type) async {
    final hospitalId = await getHospitalId();

    final response = await http.get(
      Uri.parse('$baseUrl/scans_tests/all/$hospitalId/$type'),
    );
    print(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load test data');
    }
  }


  Future<List<Map<String, dynamic>>> fetchTestAndScan(String type) async {
    final hospitalId = await getHospitalId();

    final response = await http.get(
      Uri.parse('$baseUrl/scans_tests/all/$hospitalId/$type'),
    );
    print(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load test data');
    }
  }

  Future<List<dynamic>> getAllUnitReference(String type) async {
    final url = Uri.parse('$baseUrl/scans_tests/unit-reference/all/$type');

    final response = await http.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body); // List<dynamic>
    } else {
      throw Exception('Failed to load unit references');
    }
  }

  // Future<Map<String, dynamic>> createTestScan(Map<String, dynamic> data) async {
  //   final url = Uri.parse('$baseUrl/scan_test/create');
  //   print('Creating scan_test with data: $data');
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(data),
  //     );
  //     print(response.body);
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       return jsonDecode(response.body);
  //     } else {
  //       throw Exception(
  //         'Failed to create scan_test. Status: ${response.statusCode}\nBody: ${response.body}',
  //       );
  //     }
  //   } catch (e) {
  //     return {'status': 'failed', 'error': e.toString()};
  //   }
  // }

  Future<Map<String, dynamic>> createTestScan(
    List<Map<String, dynamic>> data,
  ) async {
    print('Creating scan_test with data: $data');
    final url = Uri.parse('$baseUrl/scans_tests/create');
// =======
//   Future<Map<String, dynamic>> createTestScan(Map<String, dynamic> data) async {
//     final url = Uri.parse('$baseUrl/scan_test/create');
// >>>>>>> 3f063fbf1fae91f45feca0bca76a410ab6083f20

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},

        body: jsonEncode(data), // sending ARRAY
      );
      print(' response ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      print(e);
      return {'status': 'failed', 'error': e.toString()};
    }
  }

  /// ---------------- HEADERS ----------------
  Future<Map<String, String>> _headers() async {
    final token = await secureStorage.read(key: 'token');
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // /// ---------------- CREATE ----------------
  // Future<void> createTestScan(Map<String, dynamic> data) async {
  //   final response = await http.post(
  //     Uri.parse("$baseUrl/scan-test"),
  //     headers: await _headers(),
  //     body: jsonEncode(data),
  //   );
  //
  //   if (response.statusCode != 201 && response.statusCode != 200) {
  //     throw Exception("Failed to create scan/test");
  //   }
  // }

  // /// ---------------- UPDATE ----------------
  // Future<void> updateScanTest(int id, Map<String, dynamic> data) async {
  //   print('updateScanTest $data');
  //   final response = await http.patch(
  //     Uri.parse("$baseUrl/scan-test/updateById/$id"),
  //     headers: await _headers(),
  //     body: jsonEncode(data),
  //   );
  //   print('updateScanTest ${response.body}');
  //   if (response.statusCode != 200) {
  //     throw Exception("Failed to update scan/test");
  //   }
  // }
  Future<void> updateScanTest(int id, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/scans_tests/updateById/$id"),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    print('updateScanTest $data');
    print('updateScanTest ${response.body}');

    if (response.statusCode != 200) {
      throw Exception("Failed to update scan/test");
    }
  }

  /// ---------------- DELETE ----------------
  // Future<void> deleteScanTest(int id) async {
  //   print('deleteScanTest $id');
  //   final response = await http.delete(
  //     Uri.parse("$baseUrl/scan-test/deleteById/$id"),
  //     headers: await _headers(),
  //   );
  //   print(response.body);
  //   if (response.statusCode != 200) {
  //     throw Exception("Failed to delete scan/test");
  //   }
  // }
  Future<void> deleteScanTest(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/scan_test/deleteById/$id"),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete scan/test");
    }
  }

}
