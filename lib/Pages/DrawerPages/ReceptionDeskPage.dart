import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Services/Doctor/doctor_service.dart';
import '../../Services/consultation_service.dart';
import '../../Services/patient_service.dart';
import '../NotificationsPage.dart';
import '../payment_modal.dart';

const Color customGold = Color(0xFFBF955E);
const Color cardBackground = Color(0xFFF9F9F9);

class ReceptionDeskPage extends StatefulWidget {
  final String UserId;
  const ReceptionDeskPage({super.key, required this.UserId});

  @override
  State<ReceptionDeskPage> createState() => _ReceptionDeskPageState();
}

class _ReceptionDeskPageState extends State<ReceptionDeskPage> {
  final _formKey = GlobalKey<FormState>();
  final patientService = PatientService();
  final consultationService = ConsultationService();
  final doctorService = DoctorService();

  Map<String, dynamic> patientData = {};
  // List<Map<String, dynamic>> allDoctors = [];
  // List<Map<String, dynamic>> filteredDoctors = [];
  List<Map<String, dynamic>> allDoctors = []; // Loaded once
  List<Map<String, dynamic>> filteredDoctors = [];
  Map<String, dynamic>? selectedDoctor; // Store full doctor data

  final TextEditingController patientIdController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  final TextEditingController doctorIdController = TextEditingController();
  final TextEditingController doctorNameController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController heightController = TextEditingController(
    text: '0',
  );
  final TextEditingController weightController = TextEditingController(
    text: '0',
  );
  final TextEditingController bpController = TextEditingController();
  final TextEditingController sugarController = TextEditingController();
  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final FocusNode bpFocus = FocusNode();
  final FocusNode sugarFocus = FocusNode();

  DateTime? appointmentDateTime;
  bool isFetching = false;
  bool isLoadingDoctors = false;
  bool isSubmitting = false;
  bool showDoctorSection = false;
  bool showBpOptions = false;
  bool showSugarOptions = false;
  double registrationFee = 100;

  @override
  void initState() {
    super.initState();
    patientIdController.text = widget.UserId;
    _fetchPatient();
    _fetchDoctors();
    bpFocus.addListener(() {
      setState(() => showBpOptions = bpFocus.hasFocus);
    });
    sugarFocus.addListener(() {
      setState(() => showSugarOptions = sugarFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    bpFocus.dispose();
    sugarFocus.dispose();
    // _formKey.currentState?.dispose();
    super.dispose();
  }

  // Fetch Patient Data
  Future<void> _fetchPatient() async {
    final userId = patientIdController.text.trim();
    if (userId.isEmpty) return;
    setState(() => isFetching = true);
    try {
      final res = await patientService.getPatientByUserId(userId);
      if (res['status'] == 'success') {
        setState(() => patientData = res['data'] ?? {});
      } else {
        _showSnackBar('Patient not found');
      }
    } catch (e) {
      _showSnackBar('Error fetching patient: $e');
    } finally {
      setState(() => isFetching = false);
    }
  }

  // void _filterDoctors() {
  //   final complaint = purposeController.text.toLowerCase();
  //   String filterDept = '';
  //   List<String> dermKeywords = ['skin', 'hair', 'nail', 'derma', 'rash'];
  //
  //   if (complaint.contains('heart') || complaint.contains('cardio')) {
  //     filterDept = 'Cardiology';
  //   } else if (dermKeywords.any((term) => complaint.contains(term))) {
  //     filterDept = 'Dermatology';
  //   }
  //
  //   setState(() {
  //     filteredDoctors = filterDept.isEmpty
  //         ? allDoctors
  //         : allDoctors
  //               .where(
  //                 (d) =>
  //                     d['department'].toString().toLowerCase() ==
  //                     filterDept.toLowerCase(),
  //               )
  //               .toList();
  //   });
  // }

  // Fetch All doctors from DB
  Future<void> _fetchDoctors() async {
    setState(() => isLoadingDoctors = true);
    try {
      final docs = await doctorService.getDoctors();
      setState(() {
        allDoctors = docs;
        filteredDoctors = List.from(docs); // show all by default
        showDoctorSection = true; // always show doctor list
      });
    } catch (e) {
      _showSnackBar('Error loading doctors: $e');
    } finally {
      setState(() => isLoadingDoctors = false);
    }
  }

  void _onComplaintChanged(String value) {
    // Optional typing — doesn’t hide doctors
    setState(() {
      // nothing to filter, just keep all doctors visible
      filteredDoctors = List.from(allDoctors);
    });
  }

  Future<void> _submitConsultation() async {
    if (!_formKey.currentState!.validate()) return;
    if (patientData.isEmpty) {
      _showSnackBar('Please fetch a patient first');
      return;
    }
    if (doctorIdController.text.isEmpty) {
      _showSnackBar('Please select a doctor');
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final paymentResult = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false, // prevent accidental dismiss
        builder: (_) => PaymentModal(registrationFee: registrationFee),
      );

      if (paymentResult == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
        return;
      }

      final bool paymentStatus = paymentResult['paymentStatus'] ?? false;
      // final String paymentMode = paymentResult['paymentMode'] ?? 'unknown';
      //
      final hospitalId = await doctorService.getHospitalId();
      final response = await consultationService.createConsultation({
        "hospital_Id": hospitalId,
        "patient_Id": patientData['user_Id'],
        "doctor_Id": doctorIdController.text,
        "name": doctorNameController.text,
        "purpose": purposeController.text,
        "temperature": temperatureController.text,
        "symptoms": symptomsController.text,
        // "notes": notesController.text,
        "notes": jsonEncode(notesController.text.trim()),
        "appointdate": appointmentDateTime.toString(),
        "paymentStatus": paymentStatus,
        "paymentMode": "Online",
      });
      final userId = patientData['user_Id'];

      final patientUpdate = await patientService.updatePatient(userId, {
        "height": int.parse(heightController.text),
        "weight": int.parse(weightController.text),
        "bp": bpController.text,
        "sugar": sugarController.text,
      });

      // final a = {
      //   "height": int.parse(heightController.text),
      //   "weight": int.parse(weightController.text),
      //   "bp": bpController.text,
      //   "sugar": sugarController.text,
      // };

      if (response['status'] == 'success' &&
          patientUpdate['status'] == 'success') {
        _showSnackBar('Consultation successfully created');
      } else {
        _showSnackBar('Failed to create consultation');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSnackBar(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // UI Components

  Widget _buildPatientInfoCard() {
    if (patientData.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.personal_injury_rounded,
                  color: Colors.redAccent,
                  size: 26,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Patient Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(thickness: 1, height: 24),

            // Patient Details Grid
            Wrap(
              runSpacing: 8,
              children: [
                _infoRow(Icons.person, 'Name', patientData['name']),
                _infoRow(Icons.cake, 'DOB', patientData['dob']),
                _infoRow(Icons.wc, 'Gender', patientData['gender']),
                _infoRow(
                  Icons.phone_android,
                  'Mobile',
                  patientData['phone']?['mobile'],
                ),
                _infoRow(
                  Icons.email,
                  'Email',
                  patientData['email']?['personal'],
                ),
                _infoRow(
                  Icons.location_on,
                  'Address',
                  patientData['address']?['Address'],
                ),
                _infoRow(Icons.bloodtype, 'Blood Group', patientData['bldGrp']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable info row widget with icon + label + value
  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: customGold),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: (value?.isNotEmpty ?? false) ? value : '---'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList() {
    if (isLoadingDoctors) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredDoctors.isEmpty) {
      return const Text('No available doctors for this complaint');
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredDoctors.length,
        itemBuilder: (_, i) {
          final doc = filteredDoctors[i];
          final isSelected =
              selectedDoctor != null && selectedDoctor!['id'] == doc['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDoctor = doc;
                doctorIdController.text = doc['id'].toString(); // ✅ added
                doctorNameController.text = doc['name']; // ✅ added
                departmentController.text = doc['department']; // ✅ optional
              });
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? customGold.withValues(alpha: 0.25)
                    : Colors.white,
                border: Border.all(
                  color: isSelected ? customGold : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    doc['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doc['department'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVitalInput(
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    bool showOptions,
  ) {
    const List<String> options = ['Low', 'Normal', 'High'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: showOptions
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SizedBox(
                      height: 45,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: options.map((opt) {
                          final selected = controller.text == opt;
                          return GestureDetector(
                            onTap: () {
                              setState(() => controller.text = opt);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? customGold.withValues(alpha: 0.2)
                                    : Colors.white,
                                border: Border.all(
                                  color: selected
                                      ? customGold
                                      : Colors.grey[300]!,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                opt,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: selected ? customGold : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: customGold,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Reception Desk",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: patientIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Patient ID',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                          return 'Must be 10 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customGold,
                    ),
                    onPressed: isFetching ? null : _fetchPatient,
                    child: isFetching
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Fetch',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (patientData.isNotEmpty) _buildPatientInfoCard(),
              const SizedBox(height: 8),
              Center(
                child: Card(
                  color: customGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat(
                            'yyyy-MM-dd hh:mm a',
                          ).format(DateTime.now()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (showDoctorSection) ...[
                const SizedBox(height: 10),
                const Text(
                  'Available Doctors',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildDoctorList(),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: purposeController,
                decoration: const InputDecoration(
                  labelText: 'Complaint',
                  border: OutlineInputBorder(),
                ),
                onChanged: _onComplaintChanged,
              ),

              const SizedBox(height: 10),
              TextFormField(
                controller: temperatureController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Temperature (°F)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              _buildVitalInput(
                'Blood Pressure (BP)',
                bpController,
                bpFocus,
                showBpOptions,
              ),
              _buildVitalInput(
                'Sugar Level',
                sugarController,
                sugarFocus,
                showSugarOptions,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: symptomsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Symptoms',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: customGold,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: isSubmitting ? null : _submitConsultation,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Book Appointment',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
