import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class ScanTestGetService {
  Future<String> getHospitalId() async {
    final prefs = await SharedPreferences.getInstance();

    final hospitalId = prefs.getString('hospitalId');
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

  Future<Map<String, dynamic>> createTestScan(
    List<Map<String, dynamic>> data,
  ) async {
    final url = Uri.parse('$baseUrl/scans_tests/create');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},

        body: jsonEncode(data), // sending ARRAY
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      return {'status': 'failed', 'error': e.toString()};
    }
  }

  /// ---------------- HEADERS ----------------
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<void> updateScanTest(int id, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/scans_tests/updateById/$id"),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update scan/test");
    }
  }

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
