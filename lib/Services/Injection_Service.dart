import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class InjectionService {
  InjectionService();

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<String> getHospitalId() async {
    final hospitalId = await secureStorage.read(key: 'hospitalId');
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
      print('Hospital ID: $hospitalId');
      print('Query: $query');

      final response = await http.get(
        Uri.parse('$baseUrl/injections/getByName/$hospitalId/$query'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);

        // ✅ Handle both possible structures:
        if (decoded is Map && decoded['data'] is List) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        } else if (decoded is List) {
          // In case backend someday returns a plain list
          return List<Map<String, dynamic>>.from(decoded);
        } else {
          print('Unexpected response structure: $decoded');
          return [];
        }
      }

      print('Unexpected status code: ${response.statusCode}');
      return [];
    } catch (e) {
      print("Error fetching suggestions: $e");
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
      print(response.body);
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

      print("🔹 Response: ${response.statusCode} => ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          // Safely convert all items to Map<String, dynamic>
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        } else {
          print("⚠️ Invalid format: Missing 'data' list in response");
          return [];
        }
      } else {
        print("❌ Failed to fetch injections: ${response.body}");
        return [];
      }
    } catch (e, stack) {
      print("🔥 Exception in getAllinjections: $e");
      print(stack);
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
      } else {
        print("❌ Injection update failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Injection update error: $e");
    }
    return null;
  }
}
