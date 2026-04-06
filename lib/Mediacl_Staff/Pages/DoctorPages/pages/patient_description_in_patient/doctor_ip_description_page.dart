import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../Services/admin_service.dart';
import '../../../../../Services/consultation_service.dart';
import '../../../../../Services/prescription_service.dart';
import '../../../../../Services/socket_service.dart';
import '../../../../../utils/utils.dart';
import '../../../OutPatient/Report/ReportCard.dart';
import '../../../OutPatient/Report/ScanReportPage.dart';
import '../../widgets/patient_histroy_in_doctor.dart';
import './scanning_page.dart';
import './testing_page.dart';
import 'doctor_prescription_page.dart';
import 'treatment_progress_widget.dart';
import 'widget.dart';

class PatientDescriptionIn extends StatefulWidget {
  final Map<String, dynamic> consultation;
  //final int mode; // Tests or Scan or empty
  final String role;
  final String patientType;
  const PatientDescriptionIn({
    super.key,
    required this.consultation,
    //required this.mode,
    required this.role,
    required this.patientType,
  });

  @override
  State<PatientDescriptionIn> createState() => PatientDescriptionInState();
}

class PatientDescriptionInState extends State<PatientDescriptionIn>
    with TickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFBA8C50);
  bool _showSelectedOptions = false;
  bool _isPatientExpanded = false;
  String? dateTime;
  final socketService = SocketService();

  static bool scanningTesting = false;
  static bool medicineTonicInjection = false;
  static bool injection = false;
  bool isLoading = false; // Declare in your State class

  bool isLoadingStatus = false;
  String? logo;
  bool showTestReport = false;
  bool showScanReport = false;
  late AnimationController _controller;
  late Animation<double> expandAnimation;
  String _labName = '';
  TabController? _tabController;
  bool get isAssistantDoctor => widget.role == 'assistant doctor';
  int currentTabIndex = 0;

  static Map<String, Map<String, dynamic>> savedTests = {};
  static Map<String, Map<String, dynamic>> savedScans = {};
  static List<Map<String, dynamic>> submittedMedicines = [];

  /// Selection states
  Map<String, bool> selectedTests = {};
  Map<String, bool> selectedScans = {};
  Map<String, bool> selectedMedicines = {};

  /// Options selection
  Map<String, Map<String, bool>> selectedTestOptions = {};
  Map<String, Map<String, bool>> selectedScanOptions = {};

  static VoidCallback? onUpdated;

  static void onSavedTests(Map<String, Map<String, dynamic>> savedTest) {
    savedTests = savedTest;
    // print(savedTests);
    //{Blood Test: {options: {Dengue, RBC Count, VDRL, WBC Count}, selectedOptionsAmount: {Dengue: 150, RBC Count: 100, VDRL: 1000, WBC Count: 200}, description: , totalAmount: 1450}, Vitamin B12: {options: {Serum B12}, selectedOptionsAmount: {Serum B12: 250}, description: , totalAmount: 250}}
    onUpdated?.call();
  }

  static void onSavedScans(Map<String, Map<String, dynamic>> savedScan) {
    savedScans = savedScan;
    // print(savedScans);
    //{CT-Scan: {options: {Brain, Chest}, selectedOptionsAmount: {Brain: 100, Chest: 150}, description: , totalAmount: 250}, ECG: {options: {E.C.G}, selectedOptionsAmount: {E.C.G: 200}, description: , totalAmount: 200}, OBSTETRICS: {options: {Detailed Anomaly Scan / TIFFA (20–24 Weeks), Fetal Echocardiography}, selectedOptionsAmount: {Detailed Anomaly Scan / TIFFA (20–24 Weeks): 100, Fetal Echocardiography: 108}, description: , totalAmount: 208}, X-Ray: {options: {Foot}, selectedOptionsAmount: {Foot: 150}, description: , totalAmount: 150}}
    onUpdated?.call();
  }

  static void onSavedPrescriptions({
    required List<Map<String, dynamic>> submittedMedicine,
  }) {
    submittedMedicines = submittedMedicine;
    // print(submittedMedicines);

    onUpdated?.call();
  }

  static void onSetStated(
    bool scanningTestings,
    bool isScanningTesting,
    bool medicineTonicInjections,
    bool isMedicineTonicInjection,
    bool injections,
    bool isInjection,
  ) {
    if (isScanningTesting) scanningTesting = scanningTestings;
    if (isMedicineTonicInjection) {
      medicineTonicInjection = medicineTonicInjections;
    }
    if (isInjection) injection = injections;
    onUpdated?.call();
  }

  List<dynamic> nurseList = [];
  List<dynamic> doctorList = [];

  Future<void> loadStaff(String doctorId, String nurseId) async {
    final data = await AdminService().getMedicalStaff();

    final nurses = data
        .where(
          (s) =>
              s["role"]?.toString().toLowerCase() == "nurse" &&
              s['user_Id']?.toString() == nurseId,
        )
        .toList();

    final doctors = data
        .where(
          (s) =>
              s["role"]?.toString().toLowerCase() == "doctor" &&
              s['user_Id']?.toString() == doctorId,
        )
        .toList();

    if (!mounted) return;

    setState(() {
      nurseList = nurses;
      doctorList = doctors;
    });
  }

  @override
  Widget build(BuildContext context) {
    onUpdated = () {
      if (mounted) {
        setState(() {});
      }
    };
    final consultation = widget.consultation;
    final patient = consultation['Patient'] ?? {};
    final patientStatus = (consultation['status'] ?? '')
        .toString()
        .toLowerCase();

    // --- DOB and Age Handling ---
    final dobString = patient['dob']?.toString();
    String formattedDob = '_';
    int? age;

    if (dobString != null && dobString.isNotEmpty && dobString != 'null') {
      try {
        final dob = DateTime.parse(dobString);
        formattedDob = dob
            .toIso8601String()
            .split('T')
            .first; // e.g. "1995-06-10"
        age = calculateAge(dob);
      } catch (e) {
        setState(() {});
      }
    }

    // --- Other patient info ---
    final name = patient['name'] ?? 'Unknown';

    final id = consultation['patient_Id'].toString();

    final complaint = consultation['purpose'] ?? '_';
    final tokenNo =
        (consultation['tokenNo'] == null || consultation['tokenNo'] == 0)
        ? '-'
        : consultation['tokenNo'].toString();
    final phone = patient['phone'] ?? '_';
    final address = patient['address']?['Address'] ?? '-';
    final gender = patient['gender'] ?? '_';
    final bloodGroup = patient['bldGrp'] ?? '_';
    final createdAt = consultation['createdAt'] ?? '';
    final doctorName = consultation['Doctor']?['name'] ?? '_';
    // ----------------Admission-----------------
    // final admitId = consultation['Admission'][0]['id'].toString();
    // final admission = consultation['Admission']?[0];
    //
    // // wardChange list
    // final wardChanges = admission?['wardChange'] as List? ?? [];
    //
    // // take last ward change if exists
    // final lastWardChange = wardChanges.isNotEmpty ? wardChanges.last : null;
    //
    // // ---------- FINAL VALUES ----------
    // final wardName =
    //     lastWardChange?['toWard']?['wardName']?.toString() ??
    //     admission?['bed']?['ward']?['name']?.toString() ??
    //     '-';
    //
    // final wardType = admission?['bed']?['ward']?['type']?.toString() ?? '-';
    //
    // final bedId =
    //     lastWardChange?['toWard']?['bedId']?.toString() ??
    //     admission?['bed']?['id']?.toString() ??
    //     '-';
    //
    // final bedNo =
    //     lastWardChange?['toWard']?['bedNo']?.toString() ??
    //     admission?['bed']?['bedNo']?.toString() ??
    //     '-';
    //
    // // final wardName = consultation['Admission'][0]['bed']['ward']['name']
    // //     .toString();
    // // final wardType = consultation['Admission'][0]['bed']['ward']['type']
    // //     .toString();
    // // final bedId = consultation['Admission'][0]['bed']['id'].toString();
    // // final bedNo = consultation['Admission'][0]['bed']['bedNo'].toString();
    // final admitDate = consultation['Admission'][0]['admitTime']
    //     .toString()
    //     .split('T')
    //     .first;
    // final staffChanges =
    //     consultation['Admission']?[0]?['staffChange'] as List? ?? [];
    //
    // final lastChange = staffChanges.isNotEmpty ? staffChanges.last : null;
    //
    // final assignDoctorId = lastChange?['doctor']?.toString() ?? '';
    // final assignNurseId = lastChange?['nurse']?.toString() ?? '';
    // // Removed loadStaff call here to prevent setState during build
    //
    // final assignDoctor = doctorList.isNotEmpty
    //     ? '${doctorList[0]['name']} * ${doctorList[0]['specialist']}'
    //     : '-';
    //
    // final assignNurse = nurseList.isNotEmpty
    //     ? nurseList[0]['name'].toString()
    //     : '-';

    final List admissions = consultation['Admission'] ?? [];
    final admission = admissions.isNotEmpty ? admissions.first : null;

    final String admitId = admission?['id']?.toString() ?? '';

    // wardChange list
    final List wardChanges = admission?['wardChange'] as List? ?? [];
    final lastWardChange = wardChanges.isNotEmpty ? wardChanges.last : null;

    // ---------- FINAL VALUES ----------
    final wardName =
        lastWardChange?['toWard']?['wardName']?.toString() ??
        admission?['bed']?['ward']?['name']?.toString() ??
        '-';

    final wardType = admission?['bed']?['ward']?['type']?.toString() ?? '-';

    final bedId =
        lastWardChange?['toWard']?['bedId']?.toString() ??
        admission?['bed']?['id']?.toString() ??
        '-';

    final bedNo =
        lastWardChange?['toWard']?['bedNo']?.toString() ??
        admission?['bed']?['bedNo']?.toString() ??
        '-';

    final admitDate =
        admission?['admitTime']?.toString().split('T').first ?? '-';

    // staff changes
    final List staffChanges = admission?['staffChange'] as List? ?? [];
    final lastChange = staffChanges.isNotEmpty ? staffChanges.last : null;

    final assignDoctorId = lastChange?['doctor']?.toString() ?? '';
    final assignNurseId = lastChange?['nurse']?.toString() ?? '';

    if (assignDoctorId.isNotEmpty || assignNurseId.isNotEmpty) {
      loadStaff(assignDoctorId, assignNurseId);
    }

    final assignDoctor = doctorList.isNotEmpty
        ? '${doctorList[0]['name']} * ${doctorList[0]['specialist']}'
        : '-';

    final assignNurse = nurseList.isNotEmpty
        ? nurseList[0]['name'].toString()
        : '-';

    // final temperature = consultation['temperature'].toString();
    // final bloodPressure = consultation['bp'] ?? '_';
    // final sugar = consultation['sugar'] ?? '_';
    // final height = consultation['height'].toString();
    // final weight = consultation['weight'].toString();
    // final bmi = consultation['BMI'].toString();
    // final pk = consultation['PK'].toString();
    // final spo2 = consultation['SPO2'].toString();

    // final LabId = consultation['Teat ing AndScanningPatient'][0]['staff_Id'];

    // loadNames(LabId);

    // Your hospital photo base64

    // Set testing and medicine states for enabling Finished button
    final bool isButtonEnabled = scanningTesting || medicineTonicInjection;

    // Build widgets for mode 1 or 2 (Scan or Tests)
    return PopScope(
      canPop: false, // block default back pop
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (scanningTesting || medicineTonicInjection) {
          bool confirm = await showExitConfirmation(context);
          if (confirm && context.mounted) Navigator.pop(context);
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: buildAppBar(
          isButtonEnabled,
          context,
        ), // Extracted reusable AppBar

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // Show only report card and actions and button for modes 1, 2
              // if (widget.mode == 1)
              //   ReportCardWidget(
              //     record: widget.consultation,
              //     doctorName: doctorName,
              //
              //     staffName: _labName,
              //
              //     hospitalPhotoBase64: logo ?? '',
              //     optionResults: allTestsOptionResults,
              //     testTable: allTestsReportTable,
              //     mode: widget.mode,
              //     showButtons: false,
              //   ),
              // if (widget.mode == 2)
              //   ScanReportCard(
              //     scanData: widget.consultation,
              //     hospitalLogo: logo,
              //     mode: 1,
              //   ),

              // if (widget.mode == 3) ...[
              //   // ==========================
              //   //       TEST REPORT CARD
              //   // ==========================
              //   buildExpandableCard(
              //     title: "Test Report",
              //     icon: Icons.medical_services_rounded,
              //     expanded: showTestReport,
              //     onExpand: (v) => setState(() => showTestReport = v),
              //     child: ReportCardWidget(
              //       record: widget.consultation,
              //       doctorName: doctorName,
              //       staffName: _labName,
              //       hospitalPhotoBase64: logo ?? '',
              //       optionResults: allTestsOptionResults,
              //       testTable: allTestsReportTable,
              //       mode: widget.mode,
              //       showButtons: false,
              //     ),
              //     context: context,
              //   ),
              //
              //   const SizedBox(height: 18),
              //
              //   // ==========================
              //   //       SCAN REPORT CARD
              //   // ==========================
              //   buildExpandableCard(
              //     title: "Scan Report",
              //     icon: Icons.document_scanner,
              //     expanded: showScanReport,
              //     onExpand: (v) => setState(() => showScanReport = v),
              //     child: ScanReportCard(
              //       scanData: widget.consultation,
              //       hospitalLogo: logo,
              //       mode: 1,
              //     ),
              //     context: context,
              //   ),
              // ],
              //const SizedBox(height: 10),
              //const SizedBox(height: 4),
              _buildPatientDetailsCard(
                name: name,
                id: id,
                phone: phone,
                complaint: complaint,
                tokenNo: tokenNo,
                address: address,
                gender: gender,
                dob: formattedDob,
                age: age.toString(),
                bloodGroup: bloodGroup,
                createdAt: createdAt,
              ),
              const SizedBox(height: 6),
              _buildPatientAdmissionDetailsCard(
                wardName: wardName,
                admitId: admitId,
                wardType: wardType,
                bedNo: bedNo,
                bedId: bedId,
                admitDate: admitDate,
                assignDoctor: assignDoctor,
                assignNurse: assignNurse,
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.history, color: Colors.white),
                  label: const Text(
                    "View Patient History",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientHistoryInDoctor(patientId: id),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              TreatmentProgressWidget(
                consultation: consultation,
                role: widget.role,
                mode: 0,
              ),
              const SizedBox(height: 10),
              buildSectionCard(
                title: 'Consultation Actions',
                patientStatus: patientStatus,
                firstTest: null,
                context: context,
                consultation: consultation,
                role: widget.role,
                allTestsReportTable: allTestsReportTable,
              ),

              // const SizedBox(height: 12),
              // _buildExitButton(isButtonEnabled),
              const SizedBox(height: 10),
              buildSavedTestsSection(),
              const SizedBox(height: 10),

              buildSavedScansSection(),
              const SizedBox(height: 10),

              buildSubmittedMedicinesSection(),
              const SizedBox(height: 16),
              _buildFinishedButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
        // : EditTestScanTab(),
      ),
    );

    // For mode 4 (normal full view)
    // return Scaffold(
    //   backgroundColor: Colors.grey.shade100,
    //   appBar: buildAppBar(isButtonEnabled, context),
    //   body:
    //       // _currentTabIndex == 0
    //       //     ?
    //       SingleChildScrollView(
    //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.stretch,
    //           children: [
    //             if (patientStatus == 'endprocessing' &&
    //                 consultation['TeatingAndScanningPatient'] != null)
    //               _buildTestResultCard(
    //                 (consultation['TeatingAndScanningPatient'] as List)
    //                         .isNotEmpty
    //                     ? consultation['TeatingAndScanningPatient'][0]
    //                     : null,
    //               ),
    //             const SizedBox(height: 4),
    //             _buildPatientDetailsCard(
    //               name: name,
    //               id: id,
    //               phone: phone,
    //               complaint: complaint,
    //               tokenNo: tokenNo,
    //               address: address,
    //               gender: gender,
    //               dob: formattedDob,
    //               age: age.toString(),
    //               bloodGroup: bloodGroup,
    //               createdAt: createdAt,
    //             ),
    //             const SizedBox(height: 6),
    //             _buildPatientAdmissionDetailsCard(
    //               wardName: wardName,
    //               admitId: admitId,
    //               wardType: wardType,
    //               bedNo: bedNo,
    //               bedId: bedId,
    //               admitDate: admitDate,
    //               assignDoctor: assignDoctor,
    //               assignNurse: assignNurse,
    //             ),
    //             if (hasAnyVital(
    //               temperature: temperature,
    //               bloodPressure: bloodPressure,
    //               sugar: sugar,
    //               height: height,
    //               weight: weight,
    //               bmi: bmi,
    //               pk: pk,
    //               spo2: spo2,
    //             ))
    //               buildVitalsDetailsCards(
    //                 temperature: temperature,
    //                 bloodPressure: bloodPressure,
    //                 sugar: sugar,
    //                 height: height,
    //                 weight: weight,
    //                 bmi: bmi,
    //                 pk: pk,
    //                 spo2: spo2,
    //               ),
    //             const SizedBox(height: 10),
    //             TreatmentProgressWidget(
    //               consultation: consultation,
    //               role: widget.role,
    //             ),
    //             const SizedBox(height: 10),
    //             Container(
    //               width: double.infinity,
    //               decoration: BoxDecoration(
    //                 borderRadius: BorderRadius.circular(12),
    //                 gradient: LinearGradient(
    //                   colors: [Colors.blue.shade600, Colors.blue.shade400],
    //                   begin: Alignment.topLeft,
    //                   end: Alignment.bottomRight,
    //                 ),
    //                 boxShadow: [
    //                   BoxShadow(
    //                     color: Colors.blue.shade200.withValues(alpha: 0.4),
    //                     blurRadius: 6,
    //                     offset: const Offset(0, 3),
    //                   ),
    //                 ],
    //               ),
    //               child: ElevatedButton.icon(
    //                 icon: const Icon(Icons.history, color: Colors.white),
    //                 label: const Text(
    //                   "View Patient History",
    //                   style: TextStyle(
    //                     color: Colors.white,
    //                     fontWeight: FontWeight.bold,
    //                   ),
    //                 ),
    //                 style: ElevatedButton.styleFrom(
    //                   backgroundColor: Colors.transparent,
    //                   shadowColor: Colors.transparent,
    //                   padding: const EdgeInsets.symmetric(vertical: 16),
    //                   shape: RoundedRectangleBorder(
    //                     borderRadius: BorderRadius.circular(12),
    //                   ),
    //                 ),
    //                 onPressed: () {
    //                   Navigator.push(
    //                     context,
    //                     MaterialPageRoute(
    //                       builder: (_) => PatientHistoryInDoctor(patientId: id),
    //                     ),
    //                   );
    //                 },
    //               ),
    //             ),
    //
    //             const SizedBox(height: 10),
    //             buildSectionCard(
    //               title: 'Consultation Actions',
    //               patientStatus: patientStatus,
    //               firstTest: null,
    //               context: context,
    //               consultation: consultation,
    //               role: widget.role,
    //               allTestsReportTable: allTestsReportTable,
    //             ),
    //
    //             // const SizedBox(height: 12),
    //             // _buildExitButton(isButtonEnabled),
    //             const SizedBox(height: 10),
    //             buildSavedTestsSection(),
    //             const SizedBox(height: 10),
    //
    //             buildSavedScansSection(),
    //             const SizedBox(height: 10),
    //
    //             buildSubmittedMedicinesSection(),
    //             const SizedBox(height: 16),
    //             _buildFinishedButton(),
    //
    //             const SizedBox(height: 30),
    //           ],
    //         ),
    //       ),
    //   // : EditTestScanTab(),
    // );
  }

  Widget buildSavedTestsSection() {
    if (PatientDescriptionInState.savedTests.isEmpty) {
      return const SizedBox();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saved Tests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            ...PatientDescriptionInState.savedTests.entries.toList().map((
              entry,
            ) {
              final String testName = entry.key;
              final Map<String, dynamic> data = entry.value;

              final Map<String, int> optionAmounts = Map<String, int>.from(
                data['selectedOptionsAmount'] ?? {},
              );

              /// init parent checkbox
              selectedTests.putIfAbsent(testName, () => true);

              /// init option checkboxes from SOURCE OF TRUTH
              selectedTestOptions.putIfAbsent(
                testName,
                () => {for (final o in optionAmounts.keys) o: true},
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 TEST LEVEL CHECKBOX
                  CheckboxListTile(
                    activeColor: primaryColor,
                    value: selectedTests[testName],
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      testName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onChanged: (val) {
                      setState(() {
                        selectedTests[testName] = val!;

                        if (!val) {
                          /// ❌ REMOVE TEST COMPLETELY
                          PatientDescriptionInState.savedTests.remove(testName);
                          selectedTestOptions.remove(testName);
                          selectedTests.remove(testName);
                        } else {
                          /// ✅ RESTORE TEST
                          PatientDescriptionInState.savedTests[testName] = {
                            'options': optionAmounts.keys.toSet(),
                            'selectedOptionsAmount': optionAmounts,
                            'description': data['description'] ?? '',
                            'totalAmount': optionAmounts.values.fold<int>(
                              0,
                              (a, b) => a + b,
                            ),
                          };
                          selectedTestOptions[testName] = {
                            for (final o in optionAmounts.keys) o: true,
                          };
                        }

                        PatientDescriptionInState.onUpdated?.call();
                      });
                    },
                  ),

                  /// 🔹 OPTION LEVEL CHECKBOXES
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Column(
                      children: optionAmounts.entries.map((optEntry) {
                        final String opt = optEntry.key;
                        final int price = optEntry.value;

                        return CheckboxListTile(
                          dense: true,
                          activeColor: primaryColor,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: selectedTestOptions[testName]?[opt] ?? false,
                          title: Text(
                            opt,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            "₹ $price",
                            style: const TextStyle(fontSize: 12),
                          ),
                          onChanged: selectedTests[testName] == true
                              ? (val) {
                                  setState(() {
                                    selectedTestOptions[testName]![opt] = val!;

                                    final Map<String, int> updatedAmounts =
                                        Map<String, int>.from(optionAmounts);

                                    if (val) {
                                      updatedAmounts[opt] = price;
                                    } else {
                                      updatedAmounts.remove(opt);
                                    }

                                    if (updatedAmounts.isEmpty) {
                                      /// ❌ REMOVE TEST IF NO OPTIONS
                                      PatientDescriptionInState.savedTests
                                          .remove(testName);
                                      selectedTests.remove(testName);
                                      selectedTestOptions.remove(testName);
                                    } else {
                                      /// ✅ UPDATE TEST CLEANLY
                                      PatientDescriptionInState
                                          .savedTests[testName] = {
                                        'options': updatedAmounts.keys.toSet(),
                                        'selectedOptionsAmount': updatedAmounts,
                                        'description':
                                            data['description'] ?? '',
                                        'totalAmount': updatedAmounts.values
                                            .fold<int>(0, (a, b) => a + b),
                                      };
                                    }

                                    PatientDescriptionInState.onUpdated?.call();
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 4),
                    child: Text(
                      "Total Amount: ₹${data['totalAmount']}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),

                  const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildSavedScansSection() {
    if (PatientDescriptionInState.savedScans.isEmpty) {
      return const SizedBox();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saved Scans',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            ...PatientDescriptionInState.savedScans.entries.toList().map((
              entry,
            ) {
              final String scanName = entry.key;
              final Map<String, dynamic> scanData = entry.value;

              final Set<String> options =
                  (scanData['options'] ?? <String>{}) as Set<String>;

              final Map<String, int> optionAmounts = Map<String, int>.from(
                scanData['selectedOptionsAmount'] ?? {},
              );

              /// default checked
              selectedScans.putIfAbsent(scanName, () => true);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 SCAN LEVEL CHECKBOX
                  CheckboxListTile(
                    activeColor: primaryColor,
                    value: selectedScans[scanName],
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,

                    onChanged: (val) {
                      setState(() {
                        selectedScans[scanName] = val!;

                        if (!val) {
                          /// ❌ REMOVE SCAN COMPLETELY
                          PatientDescriptionInState.savedScans.remove(scanName);
                        } else {
                          /// ✅ ADD BACK (safe)
                          if (!PatientDescriptionInState.savedScans.containsKey(
                            scanName,
                          )) {
                            PatientDescriptionInState.savedScans[scanName] =
                                scanData;
                          }
                        }

                        PatientDescriptionInState.onUpdated?.call();
                      });
                    },

                    title: Text(
                      scanName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  /// 🔹 OPTION LEVEL CHECKBOXES
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Column(
                      children: optionAmounts.entries.map((optEntry) {
                        final String optionName = optEntry.key;
                        final int price = optEntry.value;

                        return CheckboxListTile(
                          activeColor: primaryColor,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,

                          value: options.contains(optionName),

                          onChanged: selectedScans[scanName] == true
                              ? (val) {
                                  setState(() {
                                    final Map<String, int> updatedAmounts =
                                        Map<String, int>.from(optionAmounts);

                                    if (val == true) {
                                      updatedAmounts[optionName] = price;
                                    } else {
                                      updatedAmounts.remove(optionName);
                                    }

                                    if (updatedAmounts.isEmpty) {
                                      /// ❌ REMOVE SCAN IF NO OPTIONS
                                      PatientDescriptionInState.savedScans
                                          .remove(scanName);
                                    } else {
                                      /// ✅ UPDATE SCAN
                                      PatientDescriptionInState
                                          .savedScans[scanName] = {
                                        'options': updatedAmounts.keys.toSet(),
                                        'selectedOptionsAmount': updatedAmounts,
                                        'description':
                                            scanData['description'] ?? '',
                                        'totalAmount': updatedAmounts.values
                                            .fold<int>(0, (a, b) => a + b),
                                      };
                                    }

                                    PatientDescriptionInState.onUpdated?.call();
                                  });
                                }
                              : null,

                          title: Text(
                            optionName,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            "₹ $price",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  /// 🔹 TOTAL
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 4),
                    child: Text(
                      "Total Amount: ₹${scanData['totalAmount'] ?? 0}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildSubmittedMedicinesSection() {
    if (PatientDescriptionInState.submittedMedicines.isEmpty) {
      return const SizedBox();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prescribed Medicines',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            ...PatientDescriptionInState.submittedMedicines.toList().map((med) {
              final String medName = med['name'];

              /// Initialize checkbox state (default checked)
              selectedMedicines.putIfAbsent(medName, () => true);

              return CheckboxListTile(
                activeColor: primaryColor,
                value: selectedMedicines[medName],
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,

                onChanged: (val) {
                  setState(() {
                    selectedMedicines[medName] = val!;

                    if (!val) {
                      /// ❌ REMOVE medicine globally
                      PatientDescriptionInState.submittedMedicines.removeWhere(
                        (m) => m['name'] == medName,
                      );
                    } else {
                      /// ✅ ADD BACK if re-selected (avoid duplicates)
                      final exists = PatientDescriptionInState
                          .submittedMedicines
                          .any((m) => m['name'] == medName);

                      if (!exists) {
                        PatientDescriptionInState.submittedMedicines.add(med);
                      }
                    }

                    /// Notify listeners
                    PatientDescriptionInState.onUpdated?.call();
                  });
                },

                title: Text(
                  medName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Route: ${med['route']} | Qty: ${med['quantity']} | Days: ${med['days']}",
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      "Total: ₹${med['total']}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishedButton() {
    final bool hasSelectedTests =
        PatientDescriptionInState.savedTests.isNotEmpty;

    final bool hasSelectedScans =
        PatientDescriptionInState.savedScans.isNotEmpty;

    final bool hasSelectedMedicines =
        PatientDescriptionInState.submittedMedicines.isNotEmpty;

    final bool hasAnySelection =
        hasSelectedTests || hasSelectedScans || hasSelectedMedicines;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity, // or fixed width like 220
        height: 52, // 👈 fixed height
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  setState(() => isLoading = true);

                  if (hasAnySelection) {
                    await _updateStatus();
                  } else {
                    Navigator.pop(context);
                  }

                  if (mounted) {
                    setState(() => isLoading = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: hasAnySelection ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _getButtonText(
                      hasSelectedTests,
                      hasSelectedScans,
                      hasSelectedMedicines,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
      ),
    );
    ;
  }

  String _getButtonText(bool hasTest, bool hasScan, bool hasMedicine) {
    if (hasTest && hasScan && hasMedicine) return 'Submit All';
    if (hasTest && hasScan) return 'Submit Test & Scan';
    if (hasTest && hasMedicine) return 'Submit Test & Prescription';
    if (hasScan && hasMedicine) return 'Submit Scan & Prescription';
    if (hasTest) return 'Submit Test';
    if (hasScan) return 'Submit Scan';
    if (hasMedicine) return 'Submit Prescription';
    return 'Exit';
  }

  @override
  void initState() {
    savedTests = {};
    savedScans = {};
    submittedMedicines = [];
    scanningTesting = false;
    medicineTonicInjection = false;
    injection = false;
    DoctorsPrescriptionPageState.submittedMedicines = [];
    ScanningPageState.savedScans = {};
    TestingPageState.savedTests = {};
    super.initState();
    _updateTime();
    _loadHospitalLogo();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    if (isAssistantDoctor) {
      _tabController = TabController(length: 2, vsync: this);

      _tabController!.addListener(() {
        if (_tabController!.indexIsChanging) return;
        setState(() {
          currentTabIndex = _tabController!.index;
        });
      });
    }
    expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // final labId =
    //     widget.consultation['TeatingAndScanningPatient'][0]['staff_Id'] ?? [];
    //
    //loadNames(labId);
    final List testingPatients =
        widget.consultation['TeatingAndScanningPatient'] as List? ?? [];

    if (testingPatients.isNotEmpty) {
      final dynamic staffIdRaw = testingPatients[0]?['staff_Id'];

      String labId = '';

      if (staffIdRaw is String) {
        labId = staffIdRaw;
      } else if (staffIdRaw is List && staffIdRaw.isNotEmpty) {
        labId = staffIdRaw.first.toString();
      }

      if (labId.isNotEmpty) {
        loadNames(labId);
      }
    }

    // async, updates state when done
    // final staffChanges =
    //     widget.consultation['Admission']?[0]?['staffChange'] as List? ?? [];
    List staffChanges = [];
    final List admissionList = widget.consultation['Admission'] as List? ?? [];

    if (admissionList.isNotEmpty) {
      staffChanges = admissionList.first?['staffChange'] as List? ?? [];
    }

    final lastChange = staffChanges.isNotEmpty ? staffChanges.last : null;

    ///final lastChange = staffChanges.isNotEmpty ? staffChanges.last : null;

    final assignDoctorId = lastChange?['doctor']?.toString() ?? '';
    final assignNurseId = lastChange?['nurse']?.toString() ?? '';

    if (assignDoctorId.isNotEmpty || assignNurseId.isNotEmpty) {
      loadStaff(assignDoctorId, assignNurseId);
    }
  }

  Future<void> loadNames(String userId) async {
    final labProfile = await AdminService().getLabProfile(userId);

    setState(() {
      _labName = labProfile?['name'] ?? '';
    });
  }

  void _loadHospitalLogo() async {
    final prefs = await SharedPreferences.getInstance();

    logo = prefs.getString('hospitalPhoto');

    setState(() {});
  }

  void _updateTime() {
    setState(() {
      dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  double calculateDays({
    required double allocatedQty,
    required double qtyPerDose,
    required int sessionsPerDay,
  }) {
    if (allocatedQty <= 0 || qtyPerDose <= 0 || sessionsPerDay <= 0) {
      return 0;
    }
    return allocatedQty / (qtyPerDose * sessionsPerDay);
  }

  Future<void> _handleSubmitPrescription() async {
    if (submittedMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one item!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      for (var m in submittedMedicines) {
        final List allocatedBatches = m['allocated_batches'] ?? [];
        Future<void> submitBatch(
          Map<String, dynamic> medicineData, {
          dynamic bId,
          dynamic dispensedQty,
          dynamic bTotal,
        }) async {
          final double qtyPerDose =
              (medicineData['qtyPerDose'] == 0.5 ||
                  medicineData['qtyPerDose'] == 1 / 2)
              ? 0.5
              : double.parse(medicineData['qtyPerDose'].toString());

          /// ✅ sessions per day
          int sessionsPerDay = 0;
          if (medicineData['morning'] == true) sessionsPerDay++;
          if (medicineData['afternoon'] == true) sessionsPerDay++;
          if (medicineData['night'] == true) sessionsPerDay++;

          // /// 🔴 SAFETY CHECK
          // if (sessionsPerDay == 0) {
          //   throw Exception("No session selected (morning/afternoon/night)");
          // }

          final double allocatedQty = dispensedQty != null
              ? double.parse(dispensedQty.toString())
              : double.parse(medicineData['dosage'].toString());

          final double batchDays = calculateDays(
            allocatedQty: allocatedQty,
            qtyPerDose: qtyPerDose,
            sessionsPerDay: sessionsPerDay,
          );

          /// ✅ DEBUG (KEEP THIS TEMPORARILY)
          debugPrint(
            'Batch $bId → qty=$allocatedQty, dose=$qtyPerDose, sessions=$sessionsPerDay, days=$batchDays',
          );

          final Map<String, dynamic> singlePrescriptionData = {
            'hospital_Id': widget.consultation['hospital_Id'],
            'patient_Id': widget.consultation['patient_Id'].toString(),
            'doctor_Id': widget.consultation['Doctor']?['doctorId'].toString(),
            'consultation_Id': widget.consultation['id'],
            'createdAt': dateTime.toString(),
            'batch_No': m['batch_no'],
            "pharmacist_Id": userId,
            'medicines': [
              {
                'medicine_Id': int.parse(medicineData['medicineId'].toString()),
                'consultation_Id': widget.consultation['id'],
                'route': medicineData['route'].toString().toUpperCase(),
                'quantity': qtyPerDose,
                'afterEat': medicineData['afterEat'],
                'morning': medicineData['morning'],
                'afternoon': medicineData['afternoon'],
                'night': medicineData['night'],
                'days': batchDays, // ✅ CORRECT VALUE
                'batch_No': m['batch_no'],
                'total_quantity': allocatedQty,
                'dosage': medicineData['qtyPerDose'].toString(),
                'total': bTotal ?? medicineData['total'],
              },
            ],
          };

          final prescription = await PrescriptionService().createPrescription(
            singlePrescriptionData,
          );
        }

        if (allocatedBatches.isNotEmpty) {
          for (var batch in allocatedBatches) {
            await submitBatch(
              m,
              bId: batch['batch_no'],
              dispensedQty: batch['allocated_qty'],
              bTotal: batch['batch_total'],
            );
          }
        } else {
          await submitBatch(m);
        }
      }

      // await PrescriptionService().createPrescriptionDispense(prescriptionData);
      final consultationId = widget.consultation['id'];
      if (consultationId == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation ID not found')),
        );
        return;
      }
      setState(() {
        // // permanent flag for injection
        // if (submittedInjections.isNotEmpty) {
        //   injection = true; // once true, stays true
        // }

        // permanent flag for medicine/tonic/injection combined
        if (submittedMedicines.isNotEmpty) {
          medicineTonicInjection = true; // once true, stays true
        }
        for (final med in submittedMedicines) {
          if (med['route']?.toString().toLowerCase() == 'injections') {
            injection = true;
            break; // once true, stop checking
          }
        }
      });

      await ConsultationService().updateConsultation(consultationId, {
        'status': 'ADMITTED',
        // 'scanningTesting': scanningTesting,
        'medicineTonic': medicineTonicInjection,
        'Injection': injection,
        'queueStatus': 'ONGOING', //change
        'updatedAt': dateTime.toString(),
      });
      if (mounted) {
        // Navigator.pop(context, {
        //   'medicine': submittedMedicines.isNotEmpty,
        //   // 'tonic': submittedTonics.isNotEmpty,
        //   // 'injection': submittedInjections.isNotEmpty,
        // });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Prescription submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitAllTests() async {
    if (savedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No tests selected."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final doctorId = widget.role == 'doctor'
          ? prefs.getString('userId') ?? ''
          : prefs.getString('assistantDoctorId') ?? '';
      final hospitalId = widget.consultation['hospital_Id'];
      final patientId = widget.consultation['patient_Id'];
      final consultationId = widget.consultation['id'];
      if (consultationId == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation ID not found')),
        );
        return;
      }

      for (var entry in savedTests.entries) {
        final testName = entry.key;
        final testData = entry.value;

        final data = {
          "hospital_Id": hospitalId,
          "patient_Id": patientId,
          "doctor_Id": doctorId,
          "staff_Id": [],
          "title": testName,
          "consultation_Id": consultationId,
          "type": 'Tests',
          "scheduleDate": DateTime.now().toIso8601String(),
          "status": "PENDING",
          "paymentStatus": false,
          'reason': testData['description'],
          "result": '',
          "amount": testData['totalAmount'],
          "selectedOptions": testData['options'].toList(),
          "selectedOptionAmounts": testData['selectedOptionsAmount'],
          "createdAt": dateTime.toString(),
        };

        await http.post(
          Uri.parse('$baseUrl/testing_and_scanning_patient/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
      }
      setState(() {
        scanningTesting = true;
      });
      await ConsultationService().updateConsultation(consultationId, {
        'status': 'ADMITTED',
        'scanningTesting': scanningTesting,
        // 'medicineTonic': medicineTonicInjection,
        // 'Injection': injection,
        'queueStatus': 'ONGOING',
        'updatedAt': dateTime.toString(),
      });

      if (mounted) {
        //Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('tests submitted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
      //setState(() => scanningTesting = false);
    }
  }

  Future<void> _submitAllScans() async {
    if (savedScans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No scans selected!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = widget.role == 'doctor'
          ? prefs.getString('userId') ?? ''
          : prefs.getString('assistantDoctorId') ?? '';
      final hospitalId = widget.consultation['hospital_Id'];
      final patientId = widget.consultation['patient_Id'];
      final consultationId = widget.consultation['id'];

      for (var entry in savedScans.entries) {
        final scanName = entry.key;
        final scanData = entry.value;

        // 🔥 SKIP IF options list is empty
        if (scanData['options'] == null || scanData['options'].isEmpty) {
          continue; // Skip this scan
        }

        final payload = {
          "hospital_Id": hospitalId,
          "patient_Id": patientId,
          "doctor_Id": doctorId,
          "consultation_Id": consultationId,
          "staff_Id": [],
          "title": scanName,
          "type": scanName,
          "reason": scanData['description'],
          "scheduleDate": DateTime.now().toIso8601String(),
          "status": "PENDING",
          "paymentStatus": false,
          "result": '',
          "amount": scanData['totalAmount'],
          "selectedOptions": scanData['options'].toList(),
          "selectedOptionAmounts": scanData['selectedOptionsAmount'],
          "createdAt": dateTime,
        };

        await http.post(
          Uri.parse('$baseUrl/testing_and_scanning_patient/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }
      setState(() {
        scanningTesting = true;
      });
      // final consultation =
      await ConsultationService().updateConsultation(consultationId, {
        'status': 'ADMITTED',
        'scanningTesting': scanningTesting,
        // 'medicineTonic': medicineTonicInjection,
        // 'Injection': injection,
        'queueStatus': 'ONGOING',
        'updatedAt': dateTime.toString(),
      });
      if (mounted) {
        //Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Scan submitted!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting scans: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
      //setState(() => scanningTesting = false);
    }
  }

  // Future<void> _updateStatus() async {
  //   final consultationId = widget.consultation['id'];
  //   if (consultationId == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Consultation ID not found')),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     setState(() => isLoading = true);
  //
  //     /// 🔥 COLLECT & STORE SELECTED ITEMS
  //     _storeSelectedItems();
  //
  //     final bool hasSelectedTests =
  //         PatientDescriptionInState.savedTests.isNotEmpty;
  //
  //     final bool hasSelectedScans =
  //         PatientDescriptionInState.savedScans.isNotEmpty;
  //
  //     final bool hasSelectedMedicines =
  //         PatientDescriptionInState.submittedMedicines.isNotEmpty;
  //
  //     if (hasSelectedTests) await _submitAllTests();
  //     if (hasSelectedScans) await _submitAllScans();
  //     if (hasSelectedMedicines) await _handleSubmitPrescription();
  //
  //     // await ConsultationService.updateQueueStatus(consultationId, 'COMPLETED');
  //
  //     setState(() => isLoading = false);
  //
  //     // if (mounted) Navigator.pop(context, true);
  //   } catch (e) {
  //     setState(() => isLoading = false);
  //
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
  //     }
  //   }
  // }

  Future<void> _updateStatus() async {
    final consultationId = widget.consultation['id'];

    try {
      setState(() => isLoading = true);

      _storeSelectedItems();

      final hasTests = savedTests.isNotEmpty;
      final hasScans = savedScans.isNotEmpty;
      final hasMedicines = submittedMedicines.isNotEmpty;

      // ✅ Run all submissions WITHOUT navigation
      if (hasTests) await _submitAllTests();
      if (hasScans) await _submitAllScans();
      if (hasMedicines) await _handleSubmitPrescription();

      // ✅ Update status AFTER all done
      await ConsultationService.updateQueueStatus(consultationId, 'COMPLETED');

      setState(() => isLoading = false);

      // ✅ NOW navigate once
      if (mounted) {
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All data submitted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _storeSelectedItems() {
    /// 🔹 MEDICINES (already filtered by checkbox logic)
    PatientDescriptionInState.submittedMedicines = PatientDescriptionInState
        .submittedMedicines
        .where((m) => m.isNotEmpty)
        .toList();

    /// 🔹 TESTS (🔥 FIXED)
    final Map<String, Map<String, dynamic>> cleanedTests = {};

    PatientDescriptionInState.savedTests.forEach((testName, testData) {
      final Map<String, int> optionAmounts = Map<String, int>.from(
        testData['selectedOptionsAmount'] ?? {},
      );

      if (optionAmounts.isEmpty) return; // ❌ remove test completely

      cleanedTests[testName] = {
        'options': optionAmounts.keys.toSet(), // ✅ derived from amounts
        'selectedOptionsAmount': optionAmounts,
        'description': testData['description'] ?? '',
        'totalAmount': optionAmounts.values.fold<int>(0, (a, b) => a + b),
      };
    });

    PatientDescriptionInState.savedTests = cleanedTests;

    /// 🔹 SCANS (already correct)
    final Map<String, Map<String, dynamic>> cleanedScans = {};

    PatientDescriptionInState.savedScans.forEach((scanName, scanData) {
      final Map<String, int> optionAmounts = Map<String, int>.from(
        scanData['selectedOptionsAmount'] ?? {},
      );

      if (optionAmounts.isEmpty) return;

      cleanedScans[scanName] = {
        'options': optionAmounts.keys.toSet(),
        'selectedOptionsAmount': optionAmounts,
        'description': scanData['description'] ?? '',
        'totalAmount': optionAmounts.values.fold<int>(0, (a, b) => a + b),
      };
    });

    PatientDescriptionInState.savedScans = cleanedScans;

    /// 🔔 Notify listeners
    PatientDescriptionInState.onUpdated?.call();
  }

  Map<String, String> get allTestsOptionResults {
    final Map<String, String> results = {};

    final patient = widget.consultation['Patient'];
    if (patient == null) return results;

    final testingAndScanning =
        widget.consultation['TeatingAndScanningPatient'] as List<dynamic>? ??
        [];

    for (final testGroup in testingAndScanning) {
      final selectedOptions =
          testGroup['selectedOptions'] as List<dynamic>? ?? [];

      for (final opt in selectedOptions) {
        final name = opt['name']?.toString() ?? '';
        final result = (opt['result']?.toString() ?? '').trim();
        final selectedOption = opt['selectedOption']?.toString() ?? '';

        if (selectedOption == '-' || result.isEmpty) continue;

        results[name] = result;
      }
    }

    return results;
  }

  List<Map<String, dynamic>> get allTestsReportTable {
    final List<Map<String, dynamic>> formattedResults = [];

    final patient = widget.consultation['Patient'];
    if (patient == null) return formattedResults;

    final testingAndScanning =
        widget.consultation['TeatingAndScanningPatient'] as List<dynamic>? ??
        [];

    for (final testGroup in testingAndScanning) {
      final type = testGroup['type']?.toString().toLowerCase() ?? '';

      // Only handle tests, skip scans
      if (!type.contains('test')) continue;

      final String title =
          (testGroup['title']?.toString().trim().isNotEmpty ?? false)
          ? testGroup['title'].toString()
          : '-';

      final String impression =
          (testGroup['results']?.toString().trim().isNotEmpty ?? false)
          ? testGroup['results'].toString()
          : '-';

      final selectedOptions =
          testGroup['selectedOptions'] as List<dynamic>? ?? [];

      final List<Map<String, String>> results = [];

      for (final opt in selectedOptions) {
        final name = opt['name']?.toString().trim() ?? '';
        final result = opt['result']?.toString().trim() ?? '';
        final unit = opt['unit']?.toString().trim() ?? '';
        final reference = opt['reference']?.toString().trim() ?? '';
        final selectedOption = opt['selectedOption']?.toString().trim() ?? '';

        // Skip empty results or N/A
        if (selectedOption == 'N/A' || name.isEmpty || result.isEmpty) continue;

        results.add({
          'Test': name,
          'Result': result,
          'Unit': unit.isEmpty || unit == 'N/A' ? '-' : unit,
          'Range': reference.isEmpty || reference == 'N/A' ? '-' : reference,
        });
      }

      formattedResults.add({
        'title': title,
        'impression': impression,
        'results': results,
      });
    }

    return formattedResults;
  }

  // Widget _buildTestResultCard(dynamic firstTest) {
  //   return Card(
  //     color: Colors.white,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     elevation: 4,
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         children: [
  //           Text(
  //             firstTest?['title']?.toString().isNotEmpty == true
  //                 ? firstTest['title']
  //                 : "${firstTest?['type'] ?? 'UNKNOWN'}",
  //             textAlign: TextAlign.center,
  //             style: const TextStyle(
  //               fontWeight: FontWeight.bold,
  //               fontSize: 20,
  //               color: Colors.black87,
  //             ),
  //           ),
  //           const SizedBox(height: 6),
  //           Divider(color: Colors.grey.shade400, thickness: 1),
  //           Text(
  //             "${firstTest?['type'] ?? 'UNKNOWN'}",
  //             textAlign: TextAlign.center,
  //             style: const TextStyle(
  //               fontWeight: FontWeight.w600,
  //               fontSize: 16,
  //               color: Colors.black87,
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           Card(
  //             color: Colors.grey.shade50,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             elevation: 2,
  //             child: Container(
  //               width: double.infinity,
  //               padding: const EdgeInsets.symmetric(
  //                 vertical: 14,
  //                 horizontal: 12,
  //               ),
  //               child: Center(
  //                 child: Text(
  //                   (firstTest?['result'] != null &&
  //                           firstTest['result'].toString().isNotEmpty)
  //                       ? firstTest['result'].toString()
  //                       : 'No Result',
  //                   style: TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 16,
  //                     color:
  //                         (firstTest?['result'] != null &&
  //                             firstTest['result'].toString().isNotEmpty)
  //                         ? Colors.black
  //                         : Colors.grey,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(height: 6),
  //           TextButton.icon(
  //             onPressed: () {
  //               setState(() {
  //                 _showSelectedOptions = !_showSelectedOptions;
  //               });
  //             },
  //             icon: Icon(
  //               _showSelectedOptions ? Icons.expand_less : Icons.expand_more,
  //               color: Colors.blueAccent,
  //             ),
  //             label: Text(
  //               _showSelectedOptions
  //                   ? "Hide Selected Options"
  //                   : "View Selected Options",
  //               style: const TextStyle(
  //                 color: Colors.blueAccent,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //           AnimatedCrossFade(
  //             duration: const Duration(milliseconds: 250),
  //             crossFadeState: _showSelectedOptions
  //                 ? CrossFadeState.showFirst
  //                 : CrossFadeState.showSecond,
  //             firstChild: Padding(
  //               padding: const EdgeInsets.only(top: 6),
  //               child: Wrap(
  //                 spacing: 8,
  //                 runSpacing: 8,
  //                 children:
  //                     (firstTest?['selectedOptions'] as List<dynamic>? ?? [])
  //                         .map(
  //                           (option) => Chip(
  //                             label: Text(option.toString()),
  //                             backgroundColor: Colors.blue.shade50,
  //                             side: const BorderSide(color: Colors.blueAccent),
  //                           ),
  //                         )
  //                         .toList(),
  //               ),
  //             ),
  //             secondChild: const SizedBox.shrink(),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPatientDetailsCard({
    required String name,
    required String id,
    required String phone,
    required String tokenNo,
    required String complaint,
    required String address,
    required String gender,
    required String dob,
    required String age,
    required String bloodGroup,
    required String createdAt,
  }) {
    IconData genderIcon;
    Color genderColor;

    switch (gender.toLowerCase()) {
      case 'male':
        genderIcon = Icons.male;
        genderColor = Colors.blue;
        break;
      case 'female':
        genderIcon = Icons.female;
        genderColor = Colors.pink;
        break;
      default:
        genderIcon = Icons.transgender;
        genderColor = Colors.purple;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isPatientExpanded = !_isPatientExpanded;
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black26,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header Row (Gender Icon + Name + Expand Icon)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: genderColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(genderIcon, color: genderColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    _isPatientExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: primaryColor,
                    size: 26,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                //crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Token No: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    tokenNo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Divider(color: Colors.grey.shade300),

              /// 🔹 Always Visible Info
              infoRow("Purpose", complaint),
              infoRow("Patient ID", id),
              infoRow("Cell No", phone),
              infoRow("Address", address),

              /// 🔹 Expandable Section
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isPatientExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300),
                    // _infoRow("Gender", gender),
                    infoRow("Blood Group", bloodGroup),
                    infoRow("Age", age),
                    infoRow("DOB", dob),
                    infoRow("Created At", createdAt),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientAdmissionDetailsCard({
    required String admitId,
    required String wardName,
    required String wardType,
    required String bedId,
    required String bedNo,
    required String admitDate,
    required String assignDoctor,
    required String assignNurse,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPatientExpanded = !_isPatientExpanded;
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black26,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header Row (Gender Icon + Name + Expand Icon,
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Admission Details',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Divider(color: Colors.grey.shade300),

              /// 🔹 Always Visible Info
              infoRow("Admission Id", admitId),
              infoRow("ward", wardName),
              infoRow("ward type", wardType),
              infoRow("bed No", bedNo),

              /// 🔹 Expandable Section
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isPatientExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300),
                    // _infoRow("Gender", gender),
                    infoRow("Bed Id", bedId),
                    infoRow("Admit Date", admitDate),
                    infoRow("Allotted Dr", assignDoctor),
                    infoRow("Allotted Nurse", assignNurse),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
