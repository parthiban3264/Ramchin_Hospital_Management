import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class PaymentService {
  // e.g., 'http://localhost:3000/payments'

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

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createSupplementaryPayment(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create/supplementary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  Future<List<dynamic>> getAllPayments() async {
    final hospitalId = await getHospitalId();
    final response = await http.get(
      Uri.parse('$baseUrl/payments/all/$hospitalId'),
    );

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

  Future<Map<String, dynamic>> getAllOverviewPayments() async {
    final hospitalId = await getHospitalId();
    final response = await http.get(
      Uri.parse('$baseUrl/payments/all/overview/$hospitalId'),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] != null) {
        return decoded['data'] as Map<String, dynamic>;
      }
      throw Exception('Unexpected JSON structure: $decoded');
    } else {
      throw Exception('Failed to fetch dashboard: ${response.body}');
    }
  }

  Future<List<dynamic>> getOnePayments(int id) async {
    final hospitalId = await getHospitalId();
    final response = await http.get(
      Uri.parse('$baseUrl/payments/one/$hospitalId/$id'),
    );

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
      return null;
    }
  }

  // Update / patch payment
  Future<Map<String, dynamic>?> updatePayment(
    int paymentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // final hospitalId = await getHospitalId();

      final response = await http.patch(
        Uri.parse('$baseUrl/payments/updateById/$paymentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        // The backend returns {status, message, data}
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateDecreasePayment(
    int paymentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // final hospitalId = await getHospitalId();

      final response = await http.patch(
        Uri.parse('$baseUrl/payments/updateById/decreaseAmount/$paymentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        // The backend returns {status, message, data}
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String> getHospitalId() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  Future<List<dynamic>> getAllPendingFees(bool? isCtscan) async {
    try {
      final hospitalId = await getHospitalId();
      final response = await http.get(
        Uri.parse('$baseUrl/payments/all/pendingFee/$hospitalId/$isCtscan'),
      );

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
          return status == 'pending' ||
              status == 'paid' ||
              status == 'cancelled' ||
              status == 'partially_paid';
        }).toList();

        // Sort by createdAt (oldest first)
        pending.sort((b, a) {
          final aTime =
              DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final bTime =
              DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        return pending;
      } else {
        throw Exception('Failed to fetch payments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  Future<List<dynamic>> getAllOnlyCtScanPendingFees() async {
    try {
      final hospitalId = await getHospitalId();
      final response = await http.get(
        Uri.parse('$baseUrl/payments/all/ct-scan/pendingFee/$hospitalId'),
      );

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
          return status == 'pending' ||
              status == 'paid' ||
              status == 'cancelled' ||
              status == 'partially_paid';
        }).toList();

        // Sort by createdAt (oldest first)
        pending.sort((b, a) {
          final aTime =
              DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final bTime =
              DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        return pending;
      } else {
        throw Exception('Failed to fetch payments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  Future<List<dynamic>> getAllOnlyInitialPendingFees() async {
    try {
      final hospitalId = await getHospitalId();
      final response = await http.get(
        Uri.parse('$baseUrl/payments/all/initial/pendingFee/$hospitalId'),
      );

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
          return status == 'pending' ||
              status == 'paid' ||
              status == 'cancelled' ||
              status == 'partially_paid';
        }).toList();

        // Sort by createdAt (oldest first)
        pending.sort((b, a) {
          final aTime =
              DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final bTime =
              DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        return pending;
      } else {
        throw Exception('Failed to fetch payments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  // Future<List<dynamic>> getAllPendingLimitedFees() async {
  //   try {
  //     final hospitalId = await getHospitalId();
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/payments/all/pendingFee/$hospitalId'),
  //     );
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       final decoded = jsonDecode(response.body);
  //
  //       // Handle different backend JSON formats
  //       final List<dynamic> rawList;
  //       if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
  //         rawList = decoded['data'];
  //       } else if (decoded is List) {
  //         rawList = decoded;
  //       } else {
  //         throw Exception('Unexpected JSON structure: $decoded');
  //       }
  //
  //       // Filter only Pending payments
  //       final pending = rawList.where((item) {
  //         final status = item['status']?.toString().toLowerCase();
  //         return status == 'pending' ||
  //             status == 'paid' ||
  //             status == 'cancelled';
  //       }).toList();
  //
  //       // Sort by createdAt (oldest first)
  //       pending.sort((b, a) {
  //         final aTime =
  //             DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
  //         final bTime =
  //             DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
  //         return bTime.compareTo(aTime);
  //       });
  //
  //       return pending;
  //     } else {
  //       throw Exception('Failed to fetch payments: ${response.body}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error fetching payments: $e');
  //   }
  // }

  Future<List<dynamic>> getAllPendingLimitedFees({
    required int page,
    required int limit,
  }) async {
    try {
      final hospitalId = await getHospitalId();

      final uri =
          Uri.parse(
            '$baseUrl/payments/all/limited/pendingFee/$hospitalId',
          ).replace(
            queryParameters: {
              'page': page.toString(),
              'limit': limit.toString(),
            },
          );

      final response = await http.get(uri);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          return decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'];
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  Future<List<dynamic>> getAllPendingNewTestFees() async {
    try {
      final hospitalId = await getHospitalId();
      final response = await http.get(
        Uri.parse('$baseUrl/payments/all/pendingTestFee/$hospitalId'),
      );

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
          return status == 'pending' ||
              status == 'paid' ||
              status == 'cancelled';
        }).toList();

        // Sort by createdAt (oldest first)
        pending.sort((b, a) {
          final aTime =
              DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final bTime =
              DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          return bTime.compareTo(aTime);
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
        Uri.parse('$baseUrl/payments/all/paidFee/$hospitalId'),
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

  Future<Map<String, dynamic>> getAllPaidAccountsFilterData({
    String? day,
    int? month,
    int? year,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final hospitalId = await getHospitalId();

      final Uri uri =
          Uri.parse(
            '$baseUrl/payments/all/paid/Accounts/filterData/$hospitalId',
          ).replace(
            queryParameters: {
              if (day != null) 'day': day,
              if (month != null) 'month': month.toString(),
              if (year != null) 'year': year.toString(),
              if (fromDate != null) 'fromDate': fromDate,
              if (toDate != null) 'toDate': toDate,
            },
          );

      final response = await http.get(uri);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return decoded['data'] as Map<String, dynamic>;
        } else {
          throw Exception('Unexpected response format. Expected data object.');
        }
      } else {
        throw Exception('Failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }
}
