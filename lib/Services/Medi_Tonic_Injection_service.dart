import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class MedicineTonicInjectionService {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  /// Create a Testing/Scanning record
  Future<void> createMediTonicInj(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/medicine_tonic_injection/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    print(response.body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create testing/scanning: ${response.body}');
    }
  }

  Future<dynamic> updateMedicationRecord({
    required String type, // "medicine" | "tonic" | "injection"
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse("$baseUrl/medicine_tonic_injection/update/$type/$id");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Failed to update record: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("❌ Error updating record: $e");
      rethrow;
    }
  }
}
