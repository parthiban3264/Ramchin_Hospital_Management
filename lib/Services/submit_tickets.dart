import "dart:convert";
import "package:http/http.dart" as http;

import "../utils/utils.dart";

class SubmitTickets {
  SubmitTickets();

  Future<List<dynamic>> getAll() async {
    final response = await http.get(Uri.parse("$baseUrl/submit-ticket/all"));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load data");
    }
  }

  /// ✅ GET BY HOSPITAL ID
  Future<List<dynamic>> getByHospitalId(int hospitalId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/submit-ticket/hospital/$hospitalId"),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load hospital data");
    }
  }

  Future<bool> updateTicket(int id, String status) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/submit-ticket/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception("Failed to update hospital: ${response.body}");
    }
  }

  /// ✅ DELETE
  Future<bool> deleteTicket(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/submit-ticket/$id"));

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception("Failed to delete hospital");
    }
  }
}
