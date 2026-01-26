import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/OutPatient/patient_registration/widget/voice.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/OutPatient/patient_registration/widget/widget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../../../../Admin/Pages/AdminEditProfilePage.dart';
import '../../../../Services/Doctor/doctor_service.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/patient_service.dart';
import '../../../../Services/payment_service.dart';
import '../../../../Widgets/AgeDobField.dart';
import '../../../../utils/utils.dart';
import 'scanning_page.dart';
import 'testing_page.dart';

class TestRegistration extends StatefulWidget {
  const TestRegistration({super.key});

  @override
  State<TestRegistration> createState() => TestRegistrationState();
}

class TestRegistrationState extends State<TestRegistration> {
  final consultationService = ConsultationService();
  final doctorService = DoctorService();
  final PatientService patientService = PatientService();
  final paymentService = PaymentService();
  final TextEditingController fullNameController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController referredByDoctorNameController =
      TextEditingController();

  String? selectedGender;
  String? selectedBloodType;
  bool isSubmitting = false;
  bool formValidated = false;
  bool phoneValid = true;
  bool showDoctorSection = false;

  String hospitalName = '';
  String hospitalPlace = '';
  String hospitalPhoto = '';
  bool isScanOpen = false;
  bool isTestOpen = false;
  // bool _isSubmitting = false;

  //bool scanningTesting = false;
  final Color primaryColor = const Color(0xFFBF955E);

  String? _dateTime;
  final FocusNode phoneFocus = FocusNode();
  final FocusNode nameFocus = FocusNode();
  final FocusNode dobFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();
  final FocusNode referralFocus = FocusNode();

  static Map<String, Map<String, dynamic>> savedTests = {};
  static Map<String, Map<String, dynamic>> savedScans = {};
  static VoidCallback? onUpdated;

  bool nameMicOpen = false;
  bool addressMicOpen = false;
  bool docMicOpen = false;
  static void onUpdate({
    Map<String, Map<String, dynamic>>? savedTest,
    Map<String, Map<String, dynamic>>? savedScan,
  }) {
    if (savedTest != null) savedTests = savedTest;
    if (savedScan != null) savedScans = savedScan;
    onUpdated?.call();
  }

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _updateTime();
  }

  void focusPhone() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(phoneFocus);
    });
  }

  void _clearLocalTestScanData() {
    savedTests.clear();
    savedScans.clear();
    onUpdated?.call(); // refresh UI if needed
  }

  @override
  void dispose() {
    phoneFocus.dispose();
    nameFocus.dispose();
    dobFocus.dispose();
    addressFocus.dispose();
    referralFocus.dispose();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('hospitalName');
    final place = prefs.getString('hospitalPlace');
    final photo = prefs.getString('hospitalPhoto');

    setState(() {
      hospitalName = name ?? "Unknown Hospital";
      hospitalPlace = place ?? "Unknown Place";
      hospitalPhoto =
          photo ??
          "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    });
  }

  bool _canSubmit() {
    return phoneController.text.trim().isNotEmpty &&
        fullNameController.text.trim().isNotEmpty &&
        selectedGender != null &&
        addressController.text.trim().isNotEmpty &&
        (savedScans.isNotEmpty || savedTests.isNotEmpty);
  }

  void _submitPatientData() async {
    try {
      setState(() => isSubmitting = true);

      final prefs = await SharedPreferences.getInstance();

      // ---- DOB ----
      DateTime dob =
          DateTime.tryParse(dobController.text) ?? DateTime(1990, 1, 1);

      // ---- Name formatting ----
      String name = fullNameController.text.trim();
      name = name.replaceFirst(
        RegExp(r'^(MR|MS)\s*\.?\s*', caseSensitive: false),
        '',
      );

      if (selectedGender.toString().toLowerCase() == 'male') {
        fullNameController.text = 'Mr. $name';
      } else if (selectedGender.toString().toLowerCase() == 'female') {
        fullNameController.text = 'Ms. $name';
      }

      // ---- Patient payload ----
      final patientData = {
        "name": fullNameController.text,
        "ac_name": '',
        "staff_Id": prefs.getString('userId'),
        "phone": {"mobile": phoneController.text.trim()},
        "email": {"personal": '', "guardian": ''},
        "address": {"Address": addressController.text.trim()},
        "dob":
            '${DateTime.parse(DateFormat('yyyy-MM-dd').format(dob)).toIso8601String()}Z',
        "gender": selectedGender,
        "bldGrp": selectedBloodType,
        "currentProblem": '',
        "createdAt": _dateTime.toString(),
        "tempCreatedAt": DateTime.now().toUtc().toIso8601String(),
      };

      // ---- Create patient ----
      final patientResult = await patientService.createPatient(patientData);

      if (patientResult['status'] == 'failed') {
        _showSnack(patientResult['message'] ?? 'Failed to register patient');
        return;
      }

      final int patientId = patientResult['data']['patient']['id'];

      // ---- Create consultation ----
      final hospitalId = await doctorService.getHospitalId();

      final consultationResult = await consultationService.createConsultation({
        "hospital_Id": int.parse(hospitalId),
        "patient_Id": patientId,
        "isTestOnly": true,
        "doctor_Id": prefs.getString('userId'),
        "name": '',
        "referredByDoctorName": referredByDoctorNameController.text.trim(),
        "purpose": '-',
        "temperature": 0,
        "createdAt": _dateTime.toString(),
      });

      if (consultationResult['status'] == 'failed') {
        _showSnack(
          consultationResult['message'] ?? 'Failed to create consultation',
        );
        return setState(() => isSubmitting = false);
      }

      final int consultationId = consultationResult['data']['consultationId'];

      // ---- Submit scans ----
      if (savedScans.isNotEmpty) {
        await _submitAllScans(
          hospitalId: hospitalId,
          patientId: patientId,
          consultationId: consultationId,
        );
      }

      if (savedTests.isNotEmpty) {
        await _submitAllTests(
          hospitalId: hospitalId,
          patientId: patientId,
          consultationId: consultationId,
        );
      }
      await ConsultationService().updateConsultation(consultationId, {
        'status': 'ONGOING',
        'scanningTesting': true,
        'queueStatus': 'COMPLETED',
        'updatedAt': _dateTime.toString(),
      });
      // ---- Success ----
      _showSnack(' test scan created ');
      _clearLocalTestScanData();

      phoneController.clear();
      fullNameController.clear();
      addressController.clear();
      dobController.clear();
      ageController.clear();

      selectedGender = null;
      selectedBloodType = null;

      setState(() {
        isSubmitting = false;
      });
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Something went wrong. Please try again.');
      debugPrint('Submit patient error: $e');
      setState(() => isSubmitting = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitAllScans({
    required String hospitalId,
    required int patientId,
    required int consultationId,
  }) async {
    if (savedScans.isEmpty) {
      _showSnacks("No scans selected!", isError: true);
      return;
    }

    if (!mounted) return;
    //setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = prefs.getString('userId') ?? '';

      for (var entry in savedScans.entries) {
        final String scanName = entry.key;
        final Map<String, dynamic> scanData = Map<String, dynamic>.from(
          entry.value,
        );

        final Map<String, dynamic> amounts = Map<String, dynamic>.from(
          scanData['amounts'] ?? {},
        );

        if (amounts.isEmpty) {
          continue;
        }

        final payload = {
          "hospital_Id": int.parse(hospitalId),
          "patient_Id": patientId,
          "doctor_Id": doctorId,
          "consultation_Id": consultationId,
          "staff_Id": [],
          "title": scanName,
          "type": scanName,
          "reason": scanData['description'] ?? '',
          "scheduleDate": DateTime.now().toIso8601String(),
          "status": "PENDING",
          "paymentStatus": false,
          "result": '',
          "amount": scanData['totalAmount'],
          "selectedOptions": amounts.keys.toList(),
          "selectedOptionAmounts": amounts,
          "createdAt": _dateTime,
          "isTestOnly": true,
        };

        await http.post(
          Uri.parse('$baseUrl/testing_and_scanning_patient/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }

      // ✅ DO NOT POP HERE
    } catch (e) {
      _showSnacks('Error submitting Test Scans', isError: true);
      debugPrint('Submit Test Scans error: $e');
      rethrow; // let parent handle navigation
    } finally {}
  }

  Future<void> _submitAllTests({
    required String hospitalId,
    required int patientId,
    required int consultationId,
  }) async {
    if (savedTests.isEmpty) {
      _showSnacks("No scans selected!", isError: true);
      return;
    }

    if (!mounted) return;
    //setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = prefs.getString('userId') ?? '';

      for (var entry in savedTests.entries) {
        final String testName = entry.key;
        final Map<String, dynamic> testData = Map<String, dynamic>.from(
          entry.value,
        );

        final Map<String, dynamic> amounts = Map<String, dynamic>.from(
          testData['amounts'] ?? testData['selectedOptionsAmount'] ?? {},
        );

        if (amounts.isEmpty) {
          debugPrint('Skipping test $testName — no amounts');
          continue;
        }

        final payload = {
          "hospital_Id": int.parse(hospitalId),
          "patient_Id": patientId,
          "doctor_Id": doctorId,
          "consultation_Id": consultationId,
          "staff_Id": [],
          "title": testName,
          "type": 'Tests',
          "reason": testData['description'] ?? '',
          "scheduleDate": DateTime.now().toIso8601String(),
          "status": "PENDING",
          "paymentStatus": false,
          "result": '',
          "amount": testData['totalAmount'],
          "selectedOptions": amounts.keys.toList(),
          "selectedOptionAmounts": amounts,
          "createdAt": _dateTime,
          "isTestOnly": true,
        };

        await http.post(
          Uri.parse('$baseUrl/testing_and_scanning_patient/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }

      // ✅ DO NOT POP HERE
    } catch (e) {
      _showSnacks('Error submitting Test Scans', isError: true);
      debugPrint('Submit Test Scans error: $e');
      rethrow; // let parent handle navigation
    } finally {}
  }

  void _showSnacks(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    onUpdated = () {
      if (mounted) {
        setState(() {});
      }
    };
    final double scWidth = MediaQuery.of(context).size.width;
    final bool isMobile = scWidth < 600;
    final bool isTablet = scWidth >= 600 && scWidth < 1024;
    final backgroundColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHospitalCard(
                hospitalName: hospitalName,
                hospitalPlace: hospitalPlace,
                hospitalPhoto: hospitalPhoto,
              ),
              const SizedBox(height: 18),

              /// 🔹 MAIN FORM CARD
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 14 : 20,
                  horizontal: isMobile ? 12 : 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(2, 6),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isMobile ? double.infinity : 520,
                      child: buildInput(
                        "Cell No *",
                        phoneController,
                        hint: "+911234567890",
                        focusNode: phoneFocus,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(nameFocus);
                        },
                        errorText: formValidatedErrorText(
                          formValidated: formValidated,
                          valid: phoneValid,
                          errMsg: 'Enter valid 10 digit number',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          IndianPhoneNumberFormatter(),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: isMobile ? double.infinity : 520,
                      child: Row(
                        children: [
                          buildInput(
                            "Name *",
                            fullNameController,
                            focusNode: nameFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(dobFocus);
                            },
                            hint: "Enter full name",
                            inputFormatters: [UpperCaseTextFormatter()],
                          ),
                          !nameMicOpen
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 30),
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        fullNameController.text = '';
                                        nameMicOpen = true;
                                      });
                                    },
                                    icon: Icon(Icons.mic),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(
                                    top: 30,
                                    left: 2,
                                  ),
                                  child: VoiceSearchDialog(
                                    onClose: () {
                                      setState(() {
                                        nameMicOpen = false;
                                      });
                                    },
                                    onResult: (text) {
                                      fullNameController.text = text
                                          .toUpperCase();
                                      fullNameController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset: fullNameController
                                                  .text
                                                  .length,
                                            ),
                                          );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),

                    /// 🔹 Age / DOB
                    SizedBox(
                      width: isMobile ? double.infinity : 520,
                      child: AgeDobField(
                        dobController: dobController,
                        ageController: ageController,
                        focusNode: dobFocus,
                        onSubmitted: () {
                          FocusScope.of(context).requestFocus(addressFocus);
                        },
                      ),
                    ),

                    isTablet || isMobile
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    sectionLabel("Gender *"),
                                    SizedBox(height: 10),
                                    Wrap(
                                      spacing: 12,
                                      children: genders
                                          .map(
                                            (e) => buildSelectionCard(
                                              label: e,
                                              selected: selectedGender == e,
                                              onTap: () => setState(
                                                () => selectedGender = e,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),

                              /// 🔹 Blood Type
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    sectionLabel("Blood Type (Optional)"),
                                    SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: bloodTypes.map((type) {
                                        final selected =
                                            selectedBloodType == type;
                                        return GestureDetector(
                                          onTap: () => setState(
                                            () => selectedBloodType = type,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? customGold
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: selected
                                                    ? customGold
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Text(
                                              type,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: selected
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// 🔹 Gender (LEFT)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    sectionLabel("Gender *"),
                                    Wrap(
                                      spacing: 12,
                                      children: genders
                                          .map(
                                            (e) => buildSelectionCard(
                                              label: e,
                                              selected: selectedGender == e,
                                              onTap: () => setState(
                                                () => selectedGender = e,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 4),

                              /// 🔹 Blood Type (RIGHT)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    sectionLabel("Blood Type (Optional)"),
                                    SizedBox(height: 5),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: bloodTypes.map((type) {
                                        final selected =
                                            selectedBloodType == type;
                                        return GestureDetector(
                                          onTap: () => setState(
                                            () => selectedBloodType = type,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? customGold
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: selected
                                                    ? customGold
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Text(
                                              type,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: selected
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                    /// 🔹 Address
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: buildInput(
                              "Address *",
                              addressController,
                              focusNode: addressFocus,
                              textInputAction: TextInputAction.next,
                              maxLines: 3,
                              onFieldSubmitted: (_) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(referralFocus);
                              },
                              inputFormatters: [UpperCaseTextFormatter()],
                            ),
                          ),
                          addressMicOpen
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: VoiceSearchDialog(
                                    onClose: () {
                                      setState(() => addressMicOpen = false);
                                    },
                                    onResult: (text) {
                                      addressController.text = text
                                          .toUpperCase();
                                      addressController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset:
                                                  addressController.text.length,
                                            ),
                                          );
                                    },
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: IconButton(
                                    icon: const Icon(Icons.mic),
                                    onPressed: () {
                                      setState(() {
                                        addressController.clear();
                                        addressMicOpen = true;
                                      });
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: buildInput(
                              "Doctor Referral ",
                              referredByDoctorNameController,
                              maxLines: 1,
                              focusNode: referralFocus,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                              inputFormatters: [UpperCaseTextFormatter()],
                            ),
                          ),
                          !docMicOpen
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 30),
                                  child: IconButton(
                                    icon: const Icon(Icons.mic),
                                    onPressed: () {
                                      setState(() {
                                        referredByDoctorNameController.clear();
                                        docMicOpen = true;
                                      });
                                    },
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(
                                    top: 30,
                                    left: 2,
                                  ),
                                  child: VoiceSearchDialog(
                                    onClose: () {
                                      setState(() {
                                        docMicOpen = false;
                                      });
                                    },
                                    onResult: (text) {
                                      referredByDoctorNameController.text = text
                                          .toUpperCase();
                                      referredByDoctorNameController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset:
                                                  referredByDoctorNameController
                                                      .text
                                                      .length,
                                            ),
                                          );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          context,
                          title: 'Scans',
                          icon: Icons.document_scanner_rounded,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          context,
                          title: 'Tests',
                          icon: Icons.science_rounded,
                          color: primaryColor,
                        ),
                      ],
                    ),
                    showTestsScans(
                      savedScans: savedScans,
                      savedTests: savedTests,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              /// 🔹 Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting || !_canSubmit()
                      ? null
                      : _submitPatientData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSubmitting || !_canSubmit()
                        ? Colors.grey
                        : customGold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Register Test",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            if (title == 'Scans') {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.85,
                    child: ScanningPage(mode: '0'),
                  );
                },
              );
            }

            if (title == 'Tests') {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.85,
                    child: TestingPage(mode: '0'),
                  );
                },
              );
            }
          },
          child: Column(
            children: [
              Container(
                height: 75,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),

                  /// 🌟 GOLD GRADIENT
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFCECCF), Color(0xFFF3D9AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  border: Border.all(color: Color(0xFFBF955E), width: 1.4),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: const Color(0xFF836028), size: 34),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.brown.shade800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
