import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class ButtonPermissionService {
  final storage = FlutterSecureStorage();

  /// Fetch all button permissions by hospital_Id
  Future<List<dynamic>> getAllByHospital() async {
    final hospitalId = await storage.read(key: 'hospitalId');
    final url = Uri.parse("$baseUrl/button-permissions/getAll");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Failed to load button permissions. Status: ${response.statusCode}",
      );
    }
  }
}
