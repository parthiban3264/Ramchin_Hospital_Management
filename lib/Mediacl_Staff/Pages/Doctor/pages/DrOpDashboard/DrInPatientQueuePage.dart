import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../Pages/NotificationsPage.dart';
import '../../../../../Services/admin_service.dart';
import '../../../../../Services/consultation_service.dart';
import '../../../../../Services/socket_service.dart';
import '../../widgets/doctor_description_edit.dart';
import '../patient_description_in_patient/patient_description_page.dart';

class DrInPatientQueuePage extends StatefulWidget {
  final String role;
  const DrInPatientQueuePage({super.key, required this.role});

  @override
  State<DrInPatientQueuePage> createState() => _DrInPatientQueuePageState();
}

class _DrInPatientQueuePageState extends State<DrInPatientQueuePage> {
  final Color primaryColor = const Color(0xFFBF955E);
  final Color maleBorderColor = Colors.lightBlue.shade400; // Accent blue
  final Color femaleBorderColor = const Color(0xFFF48FB1); // Pink
  final Color otherBorderColor = Colors.orange.shade400;
  final socketService = SocketService();

  List<dynamic> consultations = [];
  String? doctorId;
  int selectedIndex = 0; // 0 = Pending, 1 = Ongoing
  bool isInitialLoad = true;
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchConsultations(showLoading: true);

    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchConsultations(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _fetchConsultations({required bool showLoading}) async {
    if (showLoading) setState(() => isInitialLoad = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      if (widget.role == 'doctor') {
        doctorId = prefs.getString('userId');
      } else {
        final userId = prefs.getString('userId');
        final doctorData = await AdminService().getMedicalStaff();

        final matchedDoctor = doctorData.firstWhere(
          (item) => item['user_Id'] == userId,
          orElse: () => null,
        );

        doctorId = matchedDoctor?['assignDoctorId'];
      }
      final allConsultations = await ConsultationService()
          .getAllDrConsultationDrQueueIP(doctorId: doctorId);

      if (mounted) {
        setState(() {
          consultations = allConsultations;
          isInitialLoad = false;
        });
      }
    } on SocketException {
      if (showLoading && mounted) setState(() => isInitialLoad = false);
    } catch (_) {
      if (showLoading && mounted) setState(() => isInitialLoad = false);
    }
  }

  List<dynamic> _filteredConsultations() {
    if (consultations.isEmpty) return [];

    // Edit tab
    // if (selectedIndex == 1) {
    //   return [];
    // }

    return consultations.where((c) {
      //final status = (c['status'] ?? '').toString().toLowerCase();
      final paymentType = (c['patientType'] ?? '').toString().toLowerCase();
      final queueStatus = (c['queueStatus'] ?? '').toString().toLowerCase();

      // IP patients are always ADMITTED
      if (paymentType != 'ip') return false;

      if (selectedIndex == 0) {
        // 🟡 Pending Patients
        return queueStatus == 'pending' ||
            queueStatus == 'drqueue' ||
            queueStatus == 'ongoing';
      }
      //
      // if (selectedIndex == 1) {
      //   // 🟢 Consulting Patients
      //   return queueStatus == 'ongoing';
      // }

      return false;
    }).toList();
  }

  // Map<String, Map<String, dynamic>> _groupByWardAndRoom(List<dynamic> list) {
  //   final Map<String, Map<String, dynamic>> grouped = {};
  //
  //   for (final item in list) {
  //     final consultation = Map<String, dynamic>.from(item);
  //
  //     final admission = (consultation['Admission'] as List?)?.isNotEmpty == true
  //         ? consultation['Admission'][0]
  //         : null;
  //
  //     final wardName =
  //         admission?['bed']?['ward']?['name']?.toString() ?? 'Unknown Ward';
  //
  //     final wardType = admission?['bed']?['ward']?['type']?.toString() ?? '-';
  //
  //     final bedNo = admission?['bed']?['bedNo']?.toString() ?? 'Unknown Room';
  //
  //     // 🟢 Create ward if not exists
  //     grouped.putIfAbsent(wardName, () {
  //       return {
  //         'wardType': wardType,
  //         'rooms': <String, List<Map<String, dynamic>>>{},
  //       };
  //     });
  //
  //     final rooms =
  //         grouped[wardName]!['rooms']
  //             as Map<String, List<Map<String, dynamic>>>;
  //
  //     // 🟢 Create room if not exists
  //     rooms.putIfAbsent(bedNo, () => []);
  //
  //     rooms[bedNo]!.add(consultation);
  //   }
  //
  //   return grouped;
  // }

  Map<String, Map<String, dynamic>> _groupByWardAndRoom(List<dynamic> list) {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final item in list) {
      final consultation = Map<String, dynamic>.from(item);

      final admission = (consultation['Admission'] as List?)?.isNotEmpty == true
          ? consultation['Admission'][0]
          : null;

      // 🟡 wardChange list
      final wardChanges = admission?['wardChange'] as List? ?? [];
      final lastWardChange = wardChanges.isNotEmpty ? wardChanges.last : null;

      // ✅ FINAL ward & bed (last wardChange → fallback to admission)
      final wardName =
          lastWardChange?['toWard']?['wardName']?.toString() ??
          admission?['bed']?['ward']?['name']?.toString() ??
          'Unknown Ward';

      final wardType = admission?['bed']?['ward']?['type']?.toString() ?? '-';

      final bedNo =
          lastWardChange?['toWard']?['bedNo']?.toString() ??
          admission?['bed']?['bedNo']?.toString() ??
          'Unknown Room';

      // 🟢 Create ward if not exists
      grouped.putIfAbsent(wardName, () {
        return {
          'wardType': wardType,
          'rooms': <String, List<Map<String, dynamic>>>{},
        };
      });

      final rooms =
          grouped[wardName]!['rooms']
              as Map<String, List<Map<String, dynamic>>>;

      // 🟢 Create room if not exists
      rooms.putIfAbsent(bedNo, () => []);

      rooms[bedNo]!.add(consultation);
    }

    return grouped;
  }

  Color _getBorderColor(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
      case 'm':
        return maleBorderColor;
      case 'female':
      case 'f':
        return femaleBorderColor;
      default:
        return otherBorderColor;
    }
  }

  IconData _getGenderIcon(String? gender) {
    switch ((gender ?? "").toLowerCase()) {
      case 'male':
      case 'm':
        return Icons.male;
      case 'female':
      case 'f':
        return Icons.female;
      default:
        return Icons.transgender;
    }
  }

  Color _getGenderIconColor(String? gender) {
    switch ((gender ?? "").toLowerCase()) {
      case 'male':
      case 'm':
        return maleBorderColor;
      case 'female':
      case 'f':
        return femaleBorderColor;
      default:
        return otherBorderColor;
    }
  }

  int getModeFromType(dynamic list) {
    if (list == null || list is! List || list.isEmpty) return 4;

    bool hasTest = false;
    bool hasScan = false;

    for (var item in list) {
      final type = (item['type'] ?? '').toString().toLowerCase();

      if (type.contains('tests')) hasTest = true;
      if (type.contains('x-ray') ||
          type.contains('ct-scan') ||
          type.contains('pet scan') ||
          type.contains('mri-scan') ||
          type.contains('ultrasound') ||
          type.contains('ecg') ||
          type.contains('eeg')) {
        hasScan = true;
      }
    }

    if (hasTest && hasScan) return 3; // Both Test + Scan
    if (hasTest) return 1; // Only Test
    if (hasScan) return 2; // Only Scan
    return 4; // Default
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDoubleRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Left pair
          Expanded(
            child: Row(
              children: [
                Text(
                  leftLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    leftValue,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right pair
          Expanded(
            child: Row(
              children: [
                Text(
                  rightLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    rightValue,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> consultation) {
    final patient = consultation['Patient'] ?? {};
    final name = patient['name'] ?? 'Unknown';
    final tokenNo =
        (consultation['tokenNo'] == null || consultation['tokenNo'] == 0)
        ? '-'
        : consultation['tokenNo'].toString();
    final id = consultation['patient_Id'].toString();
    final admitDate =
        (consultation['Admission'] is List &&
            consultation['Admission'].isNotEmpty)
        ? consultation['Admission'][0]['admitTime'].toString().split('T').first
        : '-';
    final admitId =
        (consultation['Admission'] is List &&
            consultation['Admission'].isNotEmpty)
        ? consultation['Admission'][0]['id'].toString()
        : '-';
    final roomNo =
        (consultation['Admission'] is List &&
            consultation['Admission'].isNotEmpty)
        ? consultation['Admission'][0]['bed']['bedNo'].toString()
        : '-';
    final phone = patient['phone'] ?? '-';
    final address = patient['address']?['Address'] ?? '-';
    final gender = patient['gender'] ?? '';
    // final status = (consultation['status'] ?? 'Unknown').toString();
    final testingAndScanning = consultation['TeatingAndScanningPatient'];
    final type =
        (testingAndScanning is List &&
            testingAndScanning.isNotEmpty &&
            testingAndScanning[0]['type'] != null)
        ? (testingAndScanning[0]['type'])
        : '';

    // final mode = getModeFromType(type);
    final mode = getModeFromType(consultation['TeatingAndScanningPatient']);

    return GestureDetector(
      onTap: () async {
        final currentQueueStatus = (consultation['queueStatus'] ?? "")
            .toString()
            .toLowerCase();

        // 🔥 Only update the first time (Pending → Ongoing)
        if (currentQueueStatus == 'pending' ||
            currentQueueStatus == 'drqueue') {
          await ConsultationService.updateQueueStatus(
            consultation['id'],
            'ONGOING',
          );
        }

        dynamic result;
        if (mounted) {
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDescriptionIn(
                consultation: consultation,
                mode: mode,
                role: widget.role,
                patientType: 'IN',
              ),
            ),
          );
        }
        // await ConsultationService.updateQueueStatus(
        //   consultation['id'],
        //   'ONGOING',
        // );

        _fetchConsultations(showLoading: false);
        // If result returned TRUE → refresh again with loading
        if (result == true) {
          _fetchConsultations(showLoading: true);
        }
      },

      child: Card(
        color: type.toString().isEmpty
            ? Colors.white
            : Colors.lightGreen.shade50, // change card color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: type.toString().isEmpty
              ? BorderSide(color: _getBorderColor(gender), width: 2)
              : BorderSide.none,
        ),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getGenderIcon(gender),
                    color: _getGenderIconColor(gender),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (type.toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Chip(
                        label: Text(
                          mode == 1
                              ? "Test"
                              : mode == 2
                              ? "Scan"
                              : mode == 3
                              ? "Test+Scan"
                              : "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: primaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              const Divider(),

              // Row(
              //   //crossAxisAlignment: CrossAxisAlignment.center,
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Text(
              //       'Token No: ',
              //       style: TextStyle(
              //         fontSize: 16,
              //         fontWeight: FontWeight.w500,
              //         color: Colors.grey[700],
              //       ),
              //     ),
              //     Text(
              //       tokenNo,
              //       style: const TextStyle(
              //         fontSize: 18,
              //         fontWeight: FontWeight.bold,
              //         color: Colors.black,
              //       ),
              //     ),
              //   ],
              // ),
              //const SizedBox(height: 6),
              //_buildInfoSplitRow("PID:", id, "AId:", admitId),
              //_buildInfoRow(),
              _buildInfoDoubleRow(
                leftLabel: "PID:",
                leftValue: id,
                rightLabel: "AID:",
                rightValue: admitId,
              ),
              _buildInfoRow("Admitted Date:", admitDate.toString()),
              //_buildInfoRow("Cell No:", phone),
              //_buildInfoRow("Address:", address),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({String message = "No patients in queue"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/Lottie/NoData.json', width: 280, height: 280),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByWardAndRoom(_filteredConsultations());
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                  ),

                  const Text(
                    "Inpatient Queue",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.group_rounded, color: Colors.white),
                    tooltip: "Show All Patients",
                    onPressed: () => setState(() => selectedIndex = 0),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: isInitialLoad
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 2),

                // Header (only for Pending & Consulting)
                selectedIndex == 1
                    ? const SizedBox()
                    : Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_alt_rounded, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              selectedIndex == 0
                                  ? "Pending Patients"
                                  : "Edit Patients",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "( ${_filteredConsultations().length} )",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),

                Expanded(
                  child: RefreshIndicator(
                    color: primaryColor,
                    onRefresh: () => _fetchConsultations(showLoading: false),
                    child: selectedIndex == 1
                        ? EditTestScanTab(
                            patientType: 'inpatient',
                          ) // ✅ ALWAYS visible
                        : _filteredConsultations().isEmpty
                        ? _buildEmptyState(
                            message: selectedIndex == 0
                                ? "No pending patients"
                                : "No Edit patients",
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            children: grouped.entries.map((wardEntry) {
                              final wardName = wardEntry.key;
                              final wardType =
                                  wardEntry.value['wardType'] as String;
                              final rooms =
                                  wardEntry.value['rooms']
                                      as Map<
                                        String,
                                        List<Map<String, dynamic>>
                                      >;

                              return wardContainer(
                                wardName: wardName,
                                wardType: wardType,
                                roomWidgets: rooms.entries.map((roomEntry) {
                                  final patients = roomEntry.value;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _roomHeader(roomEntry.key),
                                      _roomPatients(
                                        patients
                                            .map(
                                              (e) =>
                                                  Map<String, dynamic>.from(e),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ],
            ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: primaryColor,
        currentIndex: selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (index) => setState(() => selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Pending'),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.run_circle_outlined),
          //   label: 'Consulting',
          // ),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Edit'),
        ],
      ),
    );
  }

  Widget _roomPatients(List<Map<String, dynamic>> patients) {
    return Padding(
      padding: const EdgeInsets.only(left: 1, right: 1),
      child: Column(
        children: patients
            .map(
              (consultation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPatientCard(consultation),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _roomHeader(String roomNo) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade600,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.bed, size: 18, color: Colors.blueGrey.shade700),
          const SizedBox(width: 6),
          Text(
            "Room - $roomNo",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget wardContainer({
    required String wardName,
    required String wardType,
    required List<Widget> roomWidgets,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        color: Colors.white,
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 6, right: 6, bottom: 12),
          title: Row(
            children: [
              Icon(Icons.local_hospital, color: Colors.blueGrey.shade700),
              const SizedBox(width: 8),
              Text(
                "Ward - $wardName * $wardType",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          children: roomWidgets,
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              "$label :",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
