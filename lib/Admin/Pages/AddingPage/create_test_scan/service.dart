import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../utils/utils.dart';

class TestAndScanService {
  /// 🔹 Get Hospital ID
  Future<String> _getHospitalId() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');

    if (hospitalId == null) {
      throw Exception('Hospital ID not found');
    }
    return hospitalId;
  }

  /// 🔹 FETCH ALL
  Future<List<dynamic>> fetchAll() async {
    try {
      final hospitalId = await _getHospitalId();

      final response = await http.get(
        Uri.parse('$baseUrl/a_scanning_testing/all/$hospitalId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch tests & scans');
      }
    } catch (e) {
      throw Exception('Error fetching tests & scans: $e');
    }
  }

  /// 🔹 CREATE
  Future<Map<String, dynamic>> createTestOrScan({
    required String title,
    required String type,
    String? category,
    double? amount,
    required List<Map<String, dynamic>> options,
  }) async {
    try {
      final hospitalId = await _getHospitalId();

      final body = {
        "hospital_Id": int.parse(hospitalId),
        "title": title,
        "type": type,
        if (category != null) "category": category,
        "amount": amount,
        "options": options,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/a_scanning_testing'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create test/scan');
      }
    } catch (e) {
      throw Exception('Error creating test/scan: $e');
    }
  }

  /// 🔹 UPDATE
  Future<Map<String, dynamic>> updateTestOrScan({
    required int id,
    String? title,
    String? type,
    String? category, // Added category
    double? amount,
    List<Map<String, dynamic>>? options,
  }) async {
    try {
      final body = {
        if (title != null) "title": title,
        if (type != null) "type": type,
        if (category != null) "category": category,
        if (amount != null) "amount": amount,
        if (options != null) "options": options,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/a_scanning_testing/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update test/scan');
      }
    } catch (e) {
      throw Exception('Error updating test/scan: $e');
    }
  }

  /// 🔹 DELETE
  Future<bool> deleteTestOrScan(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/a_scanning_testing/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete test/scan');
      }
    } catch (e) {
      throw Exception('Error deleting test/scan: $e');
    }
  }

  Future<bool> deleteTestOrScanOption(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/a_scanning_testing/option/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete option');
      }
    } catch (e) {
      throw Exception('Error deleting option: $e');
    }
  }

  /// 🔹 UPDATE STATUS
  Future<bool> updateStatus(int id, bool isActive) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/a_scanning_testing/status/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"isActive": isActive}),
      );
      print(isActive);
      print(response.body);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 🔹 UPDATE OPTION STATUS
  Future<bool> updateOptionStatus(int id, bool isActive) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/a_scanning_testing/status/option/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"isActive": isActive}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
