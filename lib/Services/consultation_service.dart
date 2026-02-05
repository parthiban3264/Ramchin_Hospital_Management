import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class ConsultationService {
  static Future<String> getHospitalId() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  // Create a consultation
  Future<Map<String, dynamic>> createConsultation(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/consultations/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create consultation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating consultation: $e');
    }
  }

  // Process payment for consultation
  Future<void> processPayment(
    String patientId,
    String type,
    double registrationFee,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patient_Id': patientId, 'paymentType': type}),
      );

      if (response.statusCode != 200) {
        throw Exception('Payment failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error processing payment: $e');
    }
  }

  // Fetch consultations for a patient (optional)
  Future<List<dynamic>> getAllConsultations() async {
    try {
      final hospitalId = await getHospitalId();
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/all/$hospitalId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Decode JSON response first
        final decoded = jsonDecode(response.body);

        // ✅ FIX: Extract list safely from JSON object
        final List<dynamic> rawList;
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          rawList = decoded['data']; // data key contains list
        } else if (decoded is List) {
          rawList = decoded; // already a list
        } else {
          throw Exception('Unexpected JSON structure: $decoded');
        }

        return rawList;
      } else {
        throw Exception('Failed to fetch consultations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching consultations: $e');
    }
  }

  Future<List<dynamic>> getAllConsultationsHistory(String patientId) async {
    try {
      final hospitalId = await getHospitalId();
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/history/$hospitalId/$patientId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Decode JSON response first
        final decoded = jsonDecode(response.body);

        // ✅ FIX: Extract list safely from JSON object
        final List<dynamic> rawList;
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          rawList = decoded['data']; // data key contains list
        } else if (decoded is List) {
          rawList = decoded; // already a list
        } else {
          throw Exception('Unexpected JSON structure: $decoded');
        }

        return rawList;
      } else {
        throw Exception('Failed to fetch consultations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching consultations: $e');
    }
  }

  Future<Map<String, dynamic>> updateConsultation(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/consultations/updateById/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "failed",
          "message": "Server returned ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "failed", "message": e.toString()};
    }
  }

  //getAllReceptionConsultations
  static Future<List<dynamic>> getAllReceptionConsultations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/consultations/all'));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> rawList;
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          rawList = decoded['data'];
        } else if (decoded is List) {
          rawList = decoded;
        } else {
          throw Exception('Unexpected JSON structure: $decoded');
        }

        // ✅ Filter only Pending consultations
        final pending = rawList.where((item) {
          final status = item['status']?.toString().toLowerCase();
          return status == 'pending' || status == 'ongoing';
        }).toList();

        // ✅ Sort by appointment or created time
        pending.sort((a, b) {
          final aTime =
              DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final bTime =
              DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          return aTime.compareTo(bTime);
        });

        return pending;
      } else {
        throw Exception('Failed to fetch consultations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching consultations: $e');
    }
  }

  // Future<List<dynamic>> getAllConsultation() async {
  //   try {
  //     final hospitalId = await getHospitalId();
  //
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/consultations/all/$hospitalId'),
  //     );
  //
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       final decoded = jsonDecode(response.body);
  //
  //       final List<dynamic> rawList;
  //       if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
  //         rawList = decoded['data'];
  //       } else if (decoded is List) {
  //         rawList = decoded;
  //       } else {
  //         throw Exception('Unexpected JSON structure: $decoded');
  //       }
  //
  //       final symptoms = rawList.where((item) {
  //         final symptom = item['symptoms']?.toString().toLowerCase();
  //         final status = item['status']?.toString().toLowerCase();
  //         final paymentStatus = item['paymentStatus']?.toString().toLowerCase();
  //         // final queueStatus = item['queueStatus']?.toString().toLowerCase();
  //
  //         final isPendingOrOngoing =
  //             status == 'pending' || status == 'endprocessing';
  //
  //         return (symptom == 'true' && isPendingOrOngoing) ||
  //             (isPendingOrOngoing && paymentStatus == 'true');
  //       }).toList();
  //
  //       // ✅ Sort by created date or due date (optional) - oldest first
  //       symptoms.sort((a, b) {
  //         final aTime =
  //             DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
  //         final bTime =
  //             DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
  //         return bTime.compareTo(aTime); // oldest first
  //       });
  //
  //       return symptoms;
  //     } else {
  //
  //       throw Exception('Failed to fetch symptoms: ${response.body}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error fetching fees: $e');
  //   }
  // }
  Future<List<dynamic>> getAllConsultation() async {
    try {
      final hospitalId = await getHospitalId();
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/all/$hospitalId'),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to fetch consultations: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> rawList =
          (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : (decoded is List ? decoded : []);

      final result = <dynamic>[];

      for (var item in rawList) {
        final symptom = item['symptoms']?.toString().toLowerCase() == 'true';
        final status = item['status']?.toString().toUpperCase();
        final paymentStatus =
            item['paymentStatus']?.toString().toLowerCase() == 'true';

        if (status == 'ENDPROCESSING') {
          // Include only if all tests completed
          final testingList = item['Patient']?['TestingAndScanning'] ?? [];
          if (testingList.isEmpty) continue;

          final allCompleted = testingList.every(
            (t) => t['status']?.toString().toUpperCase() == "COMPLETED",
          );
          if (!allCompleted) continue;

          result.add(item);
        } else {
          // PENDING or ONGOING
          final isPendingOrOngoing =
              status == 'PENDING' || status == 'CANCELLED';

          final baseCondition =
              (symptom && isPendingOrOngoing) ||
              (isPendingOrOngoing && paymentStatus);
          // final baseCondition =
          //     (paymentStatus && symptom && isPendingOrOngoing);

          if (!baseCondition) continue;

          result.add(item);
        }
      }

      // Sort by createdAt, newest first
      result.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return result;
    } catch (e) {
      throw Exception('Error fetching consultations: $e');
    }
  }

  Future<List<dynamic>> getAllDrConsultation() async {
    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse('$baseUrl/consultations/all/$hospitalId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> rawList;
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          rawList = decoded['data'];
        } else if (decoded is List) {
          rawList = decoded;
        } else {
          throw Exception('Unexpected JSON structure: $decoded');
        }

        final symptoms = rawList.where((item) {
          final symptom = item['symptoms']?.toString().toLowerCase();
          final status = item['status']?.toString().toLowerCase();
          final paymentStatus = item['paymentStatus']?.toString().toLowerCase();
          final queueStatus = item['queueStatus']?.toString().toLowerCase();

          final isPendingOrOngoing =
              status == 'pending' || status == 'endprocessing';

          final isOngoingOrDrQueue =
              queueStatus == 'ongoing' || queueStatus == 'drqueue';

          return (symptom == 'true' &&
                  isPendingOrOngoing &&
                  isOngoingOrDrQueue) ||
              (isPendingOrOngoing &&
                  paymentStatus == 'true' &&
                  isOngoingOrDrQueue);
        }).toList();

        // ✅ Sort by created date or due date (optional) - oldest first
        symptoms.sort((a, b) {
          final aTime =
              DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final bTime =
              DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          return aTime.compareTo(bTime); // oldest first
        });

        return symptoms;
      } else {
        throw Exception('Failed to fetch symptoms: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching fees: $e');
    }
  }

  Future<List<dynamic>> getAllDrConsultationDrQueue({String? doctorId}) async {
    try {
      final hospitalId = await getHospitalId();
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/all/drqueue/$hospitalId'),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to fetch consultations: ${response.body}');
      }

      final decoded = jsonDecode(response.body);

      // Step 1: Handle nested "data" properly
      final List<dynamic> rawList;
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        final innerData = decoded['data'];
        if (innerData is Map<String, dynamic> &&
            innerData.containsKey('data')) {
          rawList = innerData['data'];
        } else if (innerData is List) {
          rawList = innerData;
        } else {
          throw Exception('Unexpected inner JSON structure: $innerData');
        }
      } else if (decoded is List) {
        rawList = decoded;
      } else {
        throw Exception('Unexpected JSON structure: $decoded');
      }

      // Step 2: Filter consultations
      final filtered = rawList.where((item) {
        if (item is! Map<String, dynamic>) return false;

        final symptom = item['symptoms']?.toString().toLowerCase() == 'true';
        final status = item['status']?.toString().toLowerCase();
        final paymentStatus =
            item['paymentStatus']?.toString().toLowerCase() == 'true';
        final queueStatus = item['queueStatus']?.toString().toLowerCase();

        final isPendingOrEndProcessing =
            status == 'pending' || status == 'endprocessing';
        final isOngoingOrDrQueue =
            queueStatus == 'ongoing' || queueStatus == 'drqueue';

        final statusCheck =
            (symptom && isPendingOrEndProcessing && isOngoingOrDrQueue) ||
            (isPendingOrEndProcessing && paymentStatus && isOngoingOrDrQueue);

        // Optional: filter by doctorId if provided
        if (doctorId != null && item.containsKey('Doctor')) {
          final doctorMap = item['Doctor'] as Map<String, dynamic>?;
          final docId = doctorMap?['doctorId']?.toString() ?? '';
          return statusCheck && docId == doctorId;
        }

        return statusCheck;
      }).toList();

      // Step 3: Sort by createdAt (oldest first)
      filtered.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return filtered;
    } catch (e) {
      throw Exception('Error fetching consultations: $e');
    }
  }

  Future<List<dynamic>> getAllDrConsultationDrQueueIP({
    String? doctorId,
  }) async {
    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse('$baseUrl/consultations/all/drqueueIP/$hospitalId'),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to fetch consultations: ${response.body}');
      }

      final decoded = jsonDecode(response.body);

      /// -----------------------------
      /// STEP 1: Extract consultation list safely
      /// -----------------------------
      List<dynamic> rawList = [];

      if (decoded is Map<String, dynamic> &&
          decoded['data'] is Map<String, dynamic> &&
          decoded['data']['data'] is List) {
        rawList = decoded['data']['data'];
      } else if (decoded is List) {
        rawList = decoded;
      } else {
        throw Exception('Unexpected JSON structure');
      }

      /// -----------------------------
      /// STEP 2: Apply correct filters
      /// -----------------------------
      final filtered = rawList.where((item) {
        if (item is! Map<String, dynamic>) return false;

        final status = item['patientType']?.toString().toLowerCase();
        final queueStatus = item['queueStatus']?.toString().toLowerCase();

        // API uses ADMITTED + DRQUEUE / PENDING
        final validStatus = status == 'ip';
        final validQueue =
            queueStatus == 'drqueue' ||
            queueStatus == 'pending' ||
            queueStatus == 'ongoing';

        if (!validStatus || !validQueue) return false;

        // Optional doctor filter
        if (doctorId != null && item['Doctor'] != null) {
          final docId = item['Doctor']['doctorId']?.toString();
          return docId == doctorId;
        }

        return true;
      }).toList();

      /// -----------------------------
      /// STEP 3: Sort by createdAt (oldest first)
      /// API format: "2026-01-27 10:45 AM"
      /// -----------------------------
      DateTime parseCreatedAt(String? value) {
        if (value == null) return DateTime.now();
        try {
          return DateFormat('yyyy-MM-dd hh:mm a').parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }

      filtered.sort((a, b) {
        final aTime = parseCreatedAt(a['createdAt']);
        final bTime = parseCreatedAt(b['createdAt']);
        return aTime.compareTo(bTime);
      });

      return filtered;
    } catch (e) {
      throw Exception('Error fetching consultations: $e');
    }
  }

  Future<List<dynamic>> getAllSugarConsultation() async {
    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse('$baseUrl/consultations/all/$hospitalId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['data'] is List) {
          return decoded['data'] as List<dynamic>;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<void> updateQueueStatus(int id, String queueStatus) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/consultations/$id/queue-status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'queueStatus': queueStatus}),
    );

    if (response.statusCode == 200) {
    } else {}
  }

  static Future<List<dynamic>> getAllConsultationByMedical(int? mode) async {
    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse('$baseUrl/consultations/all/ByMedical/$hospitalId/$mode'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> rawList;
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          rawList = decoded['data'];
        } else if (decoded is List) {
          rawList = decoded;
        } else {
          throw Exception('Unexpected JSON structure: $decoded');
        }

        return rawList;
      } else {
        throw Exception('Failed to fetch symptoms: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching fees: $e');
    }
  }

  Future<Map<String, dynamic>> getConsultationByID({required int id}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/getById/$id'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        return decoded;
      } else {
        throw Exception('Failed to fetch symptoms: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching fees: $e');
    }
  }

  static Future<List<dynamic>> getDispense(int medicineId) async {
    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse(
          '$baseUrl/testing_and_scanning_patient/all/prescriptionDispense/$hospitalId/$medicineId',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        return decoded;
      } else {
        throw Exception('Failed to fetch dispense: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching dispense: $e');
    }
  }
}
