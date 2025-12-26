// import 'dart:convert';
//
// import 'package:http/http.dart' as http;
//
// import '../utils/utils.dart';
//
// class TreatmentService {
//   /// Create Treatment service
//   Future<void> createTreatment(Map<String, dynamic> data) async {
//     final url = Uri.parse('$baseUrl/treatments/create');
//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(data),
//     );
//     print(response.body);
//     if (response.statusCode != 201 && response.statusCode != 200) {
//       throw Exception('Failed to create treatment: ${response.body}');
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/utils.dart';

class TreatmentService {
  /// Create a new treatment
  Future<void> createTreatment(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/treatments/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create treatment: ${response.body}');
    }
  }

  /// Get all treatments
  Future<Map<String, dynamic>> getAllTreatments() async {
    final url = Uri.parse('$baseUrl/treatments/all');
    try {
      final response = await http.get(url);
      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "failed",
          "message": "Server returned ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "failed", "message": e.toString()};
    }
  }

  /// Update a treatment by id
  Future<Map<String, dynamic>> updateTreatment(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/treatments/updateById/$id');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "failed",
          "message": "Server returned ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "failed", "message": e.toString()};
    }
  }
}
