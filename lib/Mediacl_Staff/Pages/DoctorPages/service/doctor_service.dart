import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../utils/utils.dart';

class DoctorServices {
  static Future<void> createTestingScanning(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/testing_and_scanning_patient/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create testing/scanning: ${response.body}');
    }
  }

  static Future<void> createMedicineInjection(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/medicine-and-injection/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create medicine/injection: ${response.body}');
    }
  }

  static Future<List<dynamic>> getConsultationsByDoctorId({
    required int hospitalId,
    required String doctorId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/all/$hospitalId/Doctor/$doctorId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Decode JSON response first
        final decoded = jsonDecode(response.body);

        // ✅ FIX: Extract list safely from JSON object
        final List<dynamic> rawList;
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          rawList = decoded['data']; // data key contains list
        } else if (decoded is List) {
          rawList = decoded; // already a list
        } else {
          throw Exception('Unexpected JSON structure: $decoded');
        }

        return rawList;
      } else {
        throw Exception('Failed to fetch consultations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching consultations: $e');
    }
  }

  static Future<List<dynamic>> getAllConsultations({
    required int hospitalId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/all/$hospitalId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Decode JSON response first
        final decoded = jsonDecode(response.body);

        // ✅ FIX: Extract list safely from JSON object
        final List<dynamic> rawList;
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          rawList = decoded['data']; // data key contains list
        } else if (decoded is List) {
          rawList = decoded; // already a list
        } else {
          throw Exception('Unexpected JSON structure: $decoded');
        }

        return rawList;
      } else {
        throw Exception('Failed to fetch consultations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching consultations: $e');
    }
  }
}
