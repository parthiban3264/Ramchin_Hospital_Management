import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class InjectionService {
  InjectionService();

  Future<String> getHospitalId() async {
    final prefs = await SharedPreferences.getInstance();

    final hospitalId = prefs.getString('hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  /// Fetch medicine suggestions by first letter
  Future<List<Map<String, dynamic>>> suggestInjection(String query) async {
    if (query.isEmpty) return [];

    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse('$baseUrl/injections/getByName/$hospitalId/$query'),
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

  Future<Map<String, dynamic>> createInjection(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse(
      '$baseUrl/injections/create',
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
          'Failed to create injection. Status: ${response.statusCode}\nBody: ${response.body}',
        );
      }
    } catch (e) {
      return {'status': 'failed', 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getAllInjection() async {
    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse('$baseUrl/injections/all/$hospitalId'),
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

  Future<Map<String, dynamic>?> updateInjectionStock(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/injections/updateById/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {}
    } catch (e) {
      return {};
    }
    return null;
  }
}
