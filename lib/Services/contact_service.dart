import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class ContactService {
  // ✅ CREATE
  Future<Map<String, dynamic>?> createContact(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/play_store_contact/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);
    } catch (e) {
      print("Create Error: $e");
      return null;
    }
  }

  // ✅ GET ALL
  Future<List<dynamic>> getContacts() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/play_store_contact/get"),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Get Error: $e");
      return [];
    }
  }

  // ✅ UPDATE
  Future<Map<String, dynamic>?> updateContact(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/play_store_contact/update/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);
    } catch (e) {
      print("Update Error: $e");
      return null;
    }
  }

  // ✅ DELETE
  Future<bool> deleteContact(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/play_store_contact/delete/$id"),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Delete Error: $e");
      return false;
    }
  }
}
