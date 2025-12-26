import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class DrawerService {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  DrawerService();

  Future<String> getHospitalId() async {
    final hospitalId = await secureStorage.read(key: 'hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  // Create Drawer
  Future<Map<String, dynamic>> createDrawer(
    Map<String, dynamic> drawerData,
  ) async {
    final url = Uri.parse('$baseUrl/drawers/create');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(drawerData),
    );
    print(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create drawer: ${response.body}');
    }
  }

  // Example to get all drawers
  Future<List<dynamic>> getDrawers() async {
    final hospitalId = await getHospitalId();
    final url = Uri.parse('$baseUrl/drawers/getAll/$hospitalId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch drawers: ${response.body}');
    }
  }
}
