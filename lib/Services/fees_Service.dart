import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/utils.dart';

final storage = FlutterSecureStorage();

class FeesService {
  //---------------- CREATE ----------------//
  Future createFee(Map<String, dynamic> data) async {
    print(data);
    final res = await http.post(
      Uri.parse('$baseUrl/fees/create'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    print(res.body);

    return jsonDecode(res.body);
  }

  //---------------- GET ALL ----------------//
  Future<List<dynamic>> getAllFees() async {
    final res = await http.get(Uri.parse('$baseUrl/all'));
    return jsonDecode(res.body);
  }

  //---------------- GET BY HOSPITAL ID ----------------//
  Future<List<dynamic>> getFeesByHospital() async {
    final hospitalId = await storage.read(key: 'hospitalId');
    final res = await http.get(Uri.parse("$baseUrl/fees/all/$hospitalId"));
    return jsonDecode(res.body);
  }


  Future<List<dynamic>> getFeesByHospitals() async {
    final hospitalId = await storage.read(key: 'hospitalId');
    print("Hospital ID: $hospitalId");

    if (hospitalId == null) return [];

    final url = "$baseUrl/fees/all/$hospitalId";
    print("Requesting: $url");

    final res = await http.get(Uri.parse(url));
    print("Status code: ${res.statusCode}");
    print("Response body: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch fees");
    }

    final decoded = jsonDecode(res.body);
    print("Decoded: $decoded");
    return decoded;
  }


  //---------------- GET BY ID ----------------//
  Future<Map<String, dynamic>> getFeeById(int id) async {
    final res = await http.get(Uri.parse("$baseUrl/fees/getById/$id"));
    return jsonDecode(res.body);
  }

  //---------------- UPDATE ----------------//
  Future updateFee(int id, Map<String, dynamic> data) async {
    print('$id $data');
    final res = await http.patch(
      Uri.parse("$baseUrl/fees/updateById/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  //---------------- DELETE ----------------//
  Future deleteFee(int id) async {
    final res = await http.delete(Uri.parse("$baseUrl/fees/deleteById/$id"));
    return jsonDecode(res.body);
  }
}
