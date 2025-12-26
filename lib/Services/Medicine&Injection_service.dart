import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class MedicineInjectionService {
  /// Create a Medicine/Injection record
  Future<void> createMedicineInjection(Map<String, dynamic> data) async {
    print(data);
    final url = Uri.parse('$baseUrl/medicine-and-injection/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    print(response.body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create medicine/injection: ${response.body}');
    }
  }

  final http.Client _client;

  MedicineInjectionService([http.Client? client])
    : _client = client ?? http.Client();

  /// Fetches all medicine & injection records
  Future<List<dynamic>> getAllMedicineAndInjection() async {
    final url = Uri.parse(
      '$baseUrl/medicine-and-injection/all',
    ); // change path if needed
    final res = await _client.get(url);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'] as List<dynamic>;
      } else if (decoded is List) {
        return decoded;
      } else {
        throw Exception('Unexpected response structure: ${res.body}');
      }
    } else {
      throw Exception('Failed to load: ${res.statusCode} ${res.body}');
    }
  }

  /// Update a record by id. payload should be map with keys you want to change.
  Future<Map<String, dynamic>> updateMedicineAndInjection(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse(
      '$baseUrl/medicine-and-injection/updateById/$id',
    ); // change path if needed
    final res = await _client.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    print(res.body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body);
      return decoded as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update: ${res.statusCode} ${res.body}');
    }
  }

  /// Close underlying client (useful in tests)
  void dispose() => _client.close();
}
