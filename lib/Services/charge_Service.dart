import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class ChargeService {
  Future<bool> updateChargesByAdmission({
    required List<int> chargesIds,
    required String status, // PAID / PARTIALLY_PAID
  }) async {
    final url = Uri.parse('$baseUrl/charges/admissionId');

    final response = await http.patch(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": status, 'chargesId': chargesIds}),
    );
    print('response: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      debugPrint("Update failed: ${response.body}");
      return false;
    }
  }

  Future<bool> updateAdvanceChargesByAdmission({
    required List<int> chargesIds, // PAID / PARTIALLY_PAID
    required num amount,
  }) async {
    final url = Uri.parse('$baseUrl/charges/admissionId/advance');

    final response = await http.patch(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'chargesId': chargesIds, 'amount': amount}),
    );
    print('response: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      debugPrint("Update failed: ${response.body}");
      return false;
    }
  }

  Future<bool> updateStatusByAdmission({
    required int admissionId,
    required String status, // PAID / PARTIALLY_PAID
  }) async {
    final url = Uri.parse(
      '$baseUrl/admissions/admissionId/status/$admissionId',
    );

    final response = await http.patch(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": status}),
    );
    print('response: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      debugPrint("Update failed: ${response.body}");
      return false;
    }
  }

  static Future<bool> dischargeAdmission(int admissionId) async {
    try {
      final url = Uri.parse('$baseUrl/admissions/discharge1/$admissionId');

      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        // 👇 No body needed (backend uses param only)
      );

      debugPrint('Discharge response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Discharge failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Discharge exception: $e');
      return false;
    }
  }
}
