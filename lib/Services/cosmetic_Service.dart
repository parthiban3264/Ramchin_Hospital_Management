import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class CosmeticService {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  // --------------------- CREATE MANY ---------------------
  Future<bool> createCosmetics(List<Map<String, dynamic>> dataList) async {
    final url = Uri.parse("$baseUrl/cosmetics/create");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(dataList),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // --------------------- GET ALL BY HOSPITAL ---------------------
  Future<List<dynamic>> getAllCosmetics() async {
    final hospitalId = await secureStorage.read(key: "hospitalId");

    final url = Uri.parse("$baseUrl/cosmetics/getAll/$hospitalId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load cosmetics");
  }

  // --------------------- GET ONE ---------------------
  Future<Map<String, dynamic>> getCosmetic(int id) async {
    final url = Uri.parse("$baseUrl/cosmetics/getById/$id");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Cosmetic not found");
  }

  // --------------------- UPDATE ---------------------
  Future<bool> updateCosmetic(int id, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/cosmetics/updateById/$id");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }
}
