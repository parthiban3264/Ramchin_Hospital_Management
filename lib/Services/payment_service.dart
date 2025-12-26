import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../utils/utils.dart';

class PaymentService {
  // e.g., 'http://localhost:3000/payments'
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  PaymentService();

  // Create payment
  static Future<Map<String, dynamic>?> createPayment(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    print(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error creating payment: ${response.body}');
      return null;
    }
  }

  Future<List<dynamic>> getAllPayments() async {
    final hospitalId = await getHospitalId();
    final response = await http.get(
      Uri.parse('$baseUrl/payments/all/$hospitalId'),
    );
    print(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
        return jsonResponse['data'];
      } else {
        throw Exception('Invalid response format: missing "data" list');
      }
    } else {
      throw Exception('Failed to fetch payments: ${response.body}');
    }
  }

  // Get payment by id
  Future<Map<String, dynamic>?> getPaymentById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Payment not found: ${response.body}');
      return null;
    }
  }

  // Update / patch payment
  Future<Map<String, dynamic>?> updatePayment(
    int paymentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final hospitalId = await getHospitalId();
      print(updates);
      final response = await http.patch(
        Uri.parse('$baseUrl/payments/updateById/$paymentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );
      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        // The backend returns {status, message, data}
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        print('❌ Error updating payment: ${response.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Exception in updatePayment: $e');
      return null;
    }
  }

  Future<String> getHospitalId() async {
    final hospitalId = await secureStorage.read(key: 'hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  Future<List<dynamic>> getAllPendingFees() async {
    try {
      final hospitalId = await getHospitalId();
      final response = await http.get(
        Uri.parse('$baseUrl/payments/all/pending/$hospitalId'),
      );
      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        // Handle different backend JSON formats
        final List<dynamic> rawList;
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          rawList = decoded['data'];
        } else if (decoded is List) {
          rawList = decoded;
        } else {
          throw Exception('Unexpected JSON structure: $decoded');
        }

        // Filter only Pending payments
        final pending = rawList.where((item) {
          final status = item['status']?.toString().toLowerCase();
          return status == 'pending' || status == 'paid';
        }).toList();

        // Sort by createdAt (oldest first)
        pending.sort((a, b) {
          final aTime =
              DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final bTime =
              DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          return aTime.compareTo(bTime);
        });

        return pending;
      } else {
        throw Exception('Failed to fetch payments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  //   Future<List<dynamic>> getAllPaid() async {
  //     try {
  //       final hospitalId = await getHospitalId();
  //       final response = await http.get(
  //         Uri.parse('$baseUrl/payments/all/paid/$hospitalId'),
  //       );
  //       print(response.body);
  //
  //       if (response.statusCode == 200 || response.statusCode == 201) {
  //         final decoded = jsonDecode(response.body);
  //
  //         final List<dynamic> rawList =
  //             decoded is Map<String, dynamic> && decoded.containsKey('data')
  //             ? decoded['data']
  //             : (decoded is List ? decoded : []);
  //
  //         // Filter only Paid payments with at least one consultation with symptoms = false
  //         final pending = rawList.where((item) {
  //           if (item['status']?.toString().toLowerCase() != 'paid') return false;
  //           final consultations =
  //               item['Patient']?['Consultation'] as List<dynamic>? ?? [];
  //           return consultations.any(
  //             (c) =>
  //                 c['symptoms'] == false &&
  //                 c['paymentStatus'] == true &&
  //                 c['status'] == 'PENDING',
  //           );
  //         }).toList();
  //
  //         // Sort by createdAt (oldest first)
  //         final format = DateFormat("yyyy-MM-dd hh:mm a");
  //         pending.sort((a, b) {
  //           final aTime = format.parse(a['createdAt'] ?? '');
  //           final bTime = format.parse(b['createdAt'] ?? '');
  //           return aTime.compareTo(bTime);
  //         });
  //
  //         return pending;
  //       } else {
  //         throw Exception('Failed to fetch payments: ${response.body}');
  //       }
  //     } catch (e) {
  //       throw Exception('Error fetching payments: $e');
  //     }
  //   }
  // }

  Future<List<dynamic>> getAllPaid() async {
    try {
      final hospitalId = await getHospitalId();
      final response = await http.get(
        Uri.parse('$baseUrl/payments/all/paid/$hospitalId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> && decoded.containsKey('data')
            ? decoded['data']
            : (decoded is List ? decoded : []);
      } else {
        throw Exception('Failed to fetch payments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  Future<List<dynamic>> getAllPaidShowAccounts() async {
    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse('$baseUrl/payments/all/paid/Accounts/$hospitalId'),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        return decoded is Map<String, dynamic> && decoded.containsKey('data')
            ? decoded['data']
            : (decoded is List ? decoded : []);
      } else {
        throw Exception('Failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }
}
