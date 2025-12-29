import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class MedicineService {
  MedicineService();

  Future<String> getHospitalId() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  Future<Map<String, dynamic>?> findByName(String name) async {
    try {
      final hospitalId = await getHospitalId();
      final response = await http.get(
        Uri.parse('$baseUrl/medicians/getById/$hospitalId/$name'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Fetch medicine suggestions by first letter
  Future<List<Map<String, dynamic>>> suggestMedicines(String query) async {
    if (query.isEmpty) return [];

    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse('$baseUrl/medicians/getByName/$hospitalId/$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);

        // ✅ Handle both possible structures:
        if (decoded is Map && decoded['data'] is List) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        } else if (decoded is List) {
          // In case backend someday returns a plain list
          return List<Map<String, dynamic>>.from(decoded);
        } else {
          return [];
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createMedician(Map<String, dynamic> data) async {
    final url = Uri.parse(
      '$baseUrl/medicians/create',
    ); // e.g., http://localhost:3000/medician/create

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to create medician. Status: ${response.statusCode}\nBody: ${response.body}',
        );
      }
    } catch (e) {
      return {'status': 'failed', 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getAllMedicines() async {
    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse('$baseUrl/medicians/all/$hospitalId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          // Safely convert all items to Map<String, dynamic>
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> updateMedicineStock(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/medicians/updateById/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {}
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> deleteMedicine(int id) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/medicians/deleteById/$id'),
        headers: {"Content-Type": "application/json"},
      );
    } catch (e) {
      return;
    }
  }
}
