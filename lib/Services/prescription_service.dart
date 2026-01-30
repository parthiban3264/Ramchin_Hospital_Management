import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class PrescriptionService {
  PrescriptionService();

  /// -----------------------------------
  /// BUILD HEADERS WITH TOKEN
  /// -----------------------------------
  Future<Map<String, String>> _buildHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// -----------------------------------
  /// CREATE PRESCRIPTION
  /// -----------------------------------
  Future<Map<String, dynamic>> createPrescription(
    Map<String, dynamic> payload,
  ) async {
    try {
      final headers = await _buildHeaders();

      final response = await http
          .post(
            Uri.parse('$baseUrl/prescriptions'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw HttpException(
        'Server error ${response.statusCode}: ${response.body}',
      );
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on FormatException {
      throw Exception('Invalid response format from server');
    } catch (e) {
      throw Exception('Create prescription failed: $e');
    }
  }

  Future<Map<String, dynamic>> createPrescriptionDispense(
    Map<String, dynamic> payload,
  ) async {
    final headers = await _buildHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/prescriptions/dispense'),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(response.body);
  }
}

/// -----------------------------------
/// CUSTOM HTTP EXCEPTION
/// -----------------------------------
class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}
