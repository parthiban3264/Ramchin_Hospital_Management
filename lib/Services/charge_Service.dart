import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class ChargeService {
  Future<bool> updateChargesByAdmission({
    required int admissionId,
    required String status, // PAID / PARTIALLY_PAID
  }) async {
    final url = Uri.parse('$baseUrl/charges/admissionId/$admissionId');

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
}
