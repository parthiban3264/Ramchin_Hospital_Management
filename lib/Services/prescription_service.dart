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

  Future<void> updatePrescriptionDispenseQuantity({
    required int id,
    required int dispensedQuantity,
    required double amount,
    required String batchId,
    required int days,
  }) async {
    final url = Uri.parse('$baseUrl/prescriptions/prescriptionDispense/$id');

    final headers = await _buildHeaders();

    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode({
        'dispensed_quantity': dispensedQuantity,
        'amount': amount,
        'batchNo': batchId,
        'days': days,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to update prescription: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> updatePrescriptionCreateMedicineAdministration({
    required int prescriptionId,
    required int hospitalId,
    required int patientId,
    required String status,
    required String patientType,
    required int dispenseId,
    required int dispensedQuantity,
    required int days,
    required double amount,
    required String batchId,
    required String mediStatus,
  }) async {
    print('work $prescriptionId $hospitalId $patientId $status $patientType');
    final headers = await _buildHeaders();
    final response = await http.post(
      Uri.parse(
        '$baseUrl/prescriptions/updateAndCreateMedicineAdministration/$prescriptionId',
      ),
      headers: headers,
      body: jsonEncode({
        'hospital_Id': hospitalId,
        'patient_Id': patientId,
        'status': status,
        'patientType': patientType,
        'dispense_Id': dispenseId,
        'current_quantity': dispensedQuantity,
        'current_days': days,
        'current_amount': amount,
        'batchNo': batchId,
        'mediStatus': mediStatus,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to update prescription: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> updateAdmissionNotes({
    required int admissionId,
    required String notes,
    required Map<String, List<Map<String, String>>> notesByDate,
  }) async {
    final url = Uri.parse('$baseUrl/admissions/notes/$admissionId/$notes');

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(notesByDate),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update admission notes: ${response.body}');
    }
  }

  Future<void> createDoctorInstruction({
    required int admissionId,
    required int doctorId,
    required String instruction,
  }) async {
    print('work $admissionId $doctorId $instruction');
    final url = Uri.parse(
      '$baseUrl/admissions/create/doctor-instruction/$admissionId',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'doctor_Id': doctorId, 'instruction': instruction}),
    );
    print('response ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create doctor instruction');
    }
  }

  Future<List<dynamic>> getDoctorInstructions({
    required int admissionId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/admissions/get/doctor-instructions/$admissionId',
    );

    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to fetch doctor instructions');
    }

    return jsonDecode(response.body);
  }

  Future<void> updateInstructionStatus({required int instructionId}) async {
    final url = Uri.parse(
      '$baseUrl/admissions/update/doctor-instruction/$instructionId',
    );

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"status": "COMPLETED"}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update instruction status');
    }
  }

  Future<Map<String, dynamic>> editNote({
    required int admissionId,
    required String noteType, // "drNotes" or "notes"
    required String date,
    required int index,
    required String newText,
  }) async {
    print('work $admissionId $noteType $date $index $newText');
    final response = await http.patch(
      Uri.parse('$baseUrl/admissions/notes/edit/$admissionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'noteType': noteType,
        'date': date,
        'index': index,
        'text': newText,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Edit note failed: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// 🗑 DELETE NOTE
  Future<Map<String, dynamic>> deleteNote({
    required int admissionId,
    required String noteType,
    required String date,
    required int index,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admissions/notes/delete/$admissionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'noteType': noteType, 'date': date, 'index': index}),
    );

    if (response.statusCode != 200 || response.statusCode != 201) {
      throw Exception('Delete note failed: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> editInstruction({
    required int admissionId,
    required int instructionId,
    required String newText,
  }) async {
    final url = Uri.parse(
      '$baseUrl/admissions/updateInstruction/$instructionId',
    );

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'admission_Id': admissionId, 'instruction': newText}),
    );

    if (response.statusCode != 200 || response.statusCode != 201) {
      throw Exception('Failed to update instruction');
    }
  }

  Future<void> deleteInstruction({
    required int admissionId,
    required int instructionId,
  }) async {
    print('work $admissionId $instructionId');
    final url = Uri.parse(
      '$baseUrl/admissions/deleteInstruction/$instructionId',
    );

    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'admission_Id': admissionId}),
    );

    if (response.statusCode != 200 || response.statusCode != 201) {
      throw Exception('Failed to delete instruction');
    }
  }

  // Medical prescription
  Future<List<dynamic>> getMedicalPrescriptions(String hospitalId) async {
    final url = Uri.parse(
      '$baseUrl/prescriptions/medical-prescriptions/$hospitalId',
    );

    final response = await http.get(url);

    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load prescriptions");
    }
  }

  Future<bool> updateMedicineAdministrationStatus({
    required int id,
    required String status,
  }) async {
    print('work $id $status');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = Uri.parse(
      "$baseUrl/prescriptions/medicineAdministrationStatus/$id",
    );

    try {
      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // if needed
        },
        body: jsonEncode({"status": status}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> getStatusAnalysis(int consultationId) async {
    final uri = Uri.parse(
      '$baseUrl/prescriptions/inpatient/medicine-administration/status-analysis/$consultationId',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load status analysis: ${response.statusCode}');
    }
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
