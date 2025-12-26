// // // import 'dart:convert';
// // // import 'package:flutter/material.dart';
// // // import '../../Services/patient_service.dart';
// // // import '../../Services/consultation_service.dart';
// // // import '../../Services/Doctor/doctor_service.dart';
// // // import '../NotificationsPage.dart';
// // // import '../payment_modal.dart';
// // // import 'package:intl/intl.dart';
// // //
// // // const Color customGold = Color(0xFFBF955E);
// // // const Color cardBackground = Color(0xFFF9F9F9);
// // //
// // // class ReceptionDeskPage extends StatefulWidget {
// // //   final String UserId;
// // //
// // //   const ReceptionDeskPage({super.key, required this.UserId});
// // //
// // //   @override
// // //   _ReceptionDeskPageState createState() => _ReceptionDeskPageState();
// // // }
// // //
// // // class _ReceptionDeskPageState extends State<ReceptionDeskPage> {
// // //   final _formKey = GlobalKey<FormState>();
// // //   final PatientService patientService = PatientService();
// // //   final ConsultationService consultationService = ConsultationService();
// // //   final DoctorService doctorService = DoctorService();
// // //   DateTime? appointmentDateTime; // store full date + time
// // //
// // //   Map<String, dynamic> patientData = {};
// // //
// // //   final TextEditingController heightController = TextEditingController();
// // //   final TextEditingController weightController = TextEditingController();
// // //   final TextEditingController bpController = TextEditingController();
// // //   final TextEditingController sugarController = TextEditingController();
// // //   final TextEditingController medicalHistoryController =
// // //       TextEditingController();
// // //   final TextEditingController customController = TextEditingController();
// // //
// // //   final TextEditingController doctorIdController = TextEditingController();
// // //   final TextEditingController doctorNameController = TextEditingController();
// // //   final TextEditingController departmentController = TextEditingController();
// // //   final TextEditingController purposeController = TextEditingController();
// // //   final TextEditingController temperatureController = TextEditingController();
// // //   final TextEditingController symptomsController = TextEditingController();
// // //   final TextEditingController notesController = TextEditingController();
// // //   final TextEditingController patientIdController = TextEditingController();
// // //
// // //   TimeOfDay? appointmentTime;
// // //
// // //   bool _isFetching = false;
// // //   bool _isSubmitting = false;
// // //   bool _isLoadingDoctors = false;
// // //
// // //   double registrationFee = 10.0;
// // //   bool showDoctorSection = false;
// // //
// // //   List<Map<String, dynamic>> _doctors = [];
// // //
// // //   // ------------------------- HELPERS -------------------------
// // //   dynamic _parseIfJson(dynamic input) {
// // //     if (input == null) return {};
// // //     if (input is Map) return input;
// // //     try {
// // //       return jsonDecode(input.toString());
// // //     } catch (_) {
// // //       return {};
// // //     }
// // //   }
// // //
// // //   String getEmail() {
// // //     final emailData = _parseIfJson(patientData['email']);
// // //     if (emailData is Map && emailData.isNotEmpty) {
// // //       final personal = emailData['personal']?.toString() ?? '-';
// // //       final guardian = emailData['guardian']?.toString() ?? '';
// // //       return guardian.isNotEmpty
// // //           ? 'Personal: $personal\nGuardian: $guardian'
// // //           : personal;
// // //     }
// // //     return '-';
// // //   }
// // //
// // //   String getPhone() {
// // //     final phoneData = _parseIfJson(patientData['phone']);
// // //     if (phoneData is Map && phoneData.isNotEmpty) {
// // //       final mobile = phoneData['mobile']?.toString() ?? '-';
// // //       final emergency = phoneData['emergency']?.toString() ?? '';
// // //       return emergency.isNotEmpty ? '$mobile (Emergency: $emergency)' : mobile;
// // //     }
// // //     return '-';
// // //   }
// // //
// // //   String getAddress() {
// // //     final addr = _parseIfJson(patientData['address']);
// // //     if (addr is Map && addr.isNotEmpty) {
// // //       if (addr['full'] != null && addr['full'].toString().isNotEmpty) {
// // //         return addr['full'].toString();
// // //       }
// // //       final parts = [
// // //         addr['street']?.toString() ?? '',
// // //         addr['city']?.toString() ?? '',
// // //         addr['zip']?.toString() ?? '',
// // //       ].where((e) => e.isNotEmpty).toList();
// // //       return parts.isNotEmpty ? parts.join(', ') : '-';
// // //     }
// // //     return '-';
// // //   }
// // //
// // //   String getDOB() {
// // //     if (patientData['dob'] != null) {
// // //       return DateTime.tryParse(
// // //             patientData['dob'].toString(),
// // //           )?.toLocal().toString().split(' ')[0] ??
// // //           '-';
// // //     }
// // //     return '-';
// // //   }
// // //
// // //   // ------------------------- FETCH PATIENT -------------------------
// // //   void _fetchPatient() async {
// // //     final userId = patientIdController.text.trim();
// // //     if (userId.isEmpty) return;
// // //
// // //     setState(() => _isFetching = true);
// // //     try {
// // //       final response = await patientService.getPatientByUserId(userId);
// // //       if (response != null && response['status'] == 'success') {
// // //         final data = response['data'];
// // //         setState(() {
// // //           patientData = data;
// // //           medicalHistoryController.text =
// // //               data['medicalHistory']?.toString() ?? '';
// // //           customController.text = data['custom']?.toString() ?? '';
// // //           heightController.text = data['height']?.toString() ?? '';
// // //           weightController.text = data['weight']?.toString() ?? '';
// // //           bpController.text = data['bp']?.toString() ?? '';
// // //           sugarController.text = data['sugar']?.toString() ?? '';
// // //         });
// // //       } else {
// // //         ScaffoldMessenger.of(
// // //           context,
// // //         ).showSnackBar(const SnackBar(content: Text('Patient not found')));
// // //       }
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(SnackBar(content: Text('Error fetching patient: $e')));
// // //     } finally {
// // //       setState(() => _isFetching = false);
// // //     }
// // //   }
// // //
// // //   // ------------------------- FETCH DOCTORS -------------------------
// // //   void _fetchDoctors() async {
// // //     setState(() => _isLoadingDoctors = true);
// // //     try {
// // //       final fetchedDoctors = await doctorService.getDoctors();
// // //       setState(() => _doctors = fetchedDoctors);
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(SnackBar(content: Text('Error loading doctors: $e')));
// // //     } finally {
// // //       setState(() => _isLoadingDoctors = false);
// // //     }
// // //   }
// // //
// // //   // ------------------------- SUBMIT CONSULTATION -------------------------
// // //   void _submitConsultation() async {
// // //     if (!_formKey.currentState!.validate()) return;
// // //
// // //     if (patientData.isEmpty) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('Please fetch a patient first')),
// // //       );
// // //       return;
// // //     }
// // //
// // //     if (doctorIdController.text.isEmpty) {
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(const SnackBar(content: Text('Please select a doctor')));
// // //       return;
// // //     }
// // //
// // //     if (appointmentDateTime == null) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('Please select appointment time')),
// // //       );
// // //       return;
// // //     }
// // //
// // //     setState(() => _isSubmitting = true);
// // //
// // //     try {
// // //       // Open Payment Modal and get payment result
// // //       final paymentResult = await showDialog<Map<String, dynamic>>(
// // //         context: context,
// // //         barrierDismissible: false, // prevent accidental dismiss
// // //         builder: (_) => PaymentModal(registrationFee: registrationFee),
// // //       );
// // //
// // //       if (paymentResult == null) {
// // //         ScaffoldMessenger.of(
// // //           context,
// // //         ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
// // //         return;
// // //       }
// // //
// // //       final bool paymentStatus = paymentResult['paymentStatus'] ?? false;
// // //       final String paymentMode = paymentResult['paymentMode'] ?? 'unknown';
// // //
// // //       // Prepare consultation data
// // //       final hospitalId = await doctorService.getHospitalId();
// // //       final consultationData = {
// // //         "hospital_Id": hospitalId,
// // //         "patient_Id": patientData['user_Id']?.toString() ?? '',
// // //         "doctor_Id": doctorIdController.text.trim(),
// // //         "name": doctorNameController.text.trim(),
// // //         "purpose": purposeController.text.trim(),
// // //         "temperature": double.tryParse(temperatureController.text.trim()) ?? 0,
// // //         "height": double.tryParse(heightController.text.trim()) ?? 0,
// // //         "weight": double.tryParse(weightController.text.trim()) ?? 0,
// // //         "bp": bpController.text.trim(),
// // //         "sugar": sugarController.text.trim(),
// // //         "symptoms": symptomsController.text.trim(),
// // //         "notes": jsonEncode(notesController.text.trim()),
// // //         "appointdate": appointmentDateTime!.toString(),
// // //         "paymentStatus": paymentStatus,
// // //         "paymentMode": paymentMode,
// // //       };
// // //
// // //       // Create consultation
// // //       final consultationResponse = await consultationService.createConsultation(
// // //         consultationData,
// // //       );
// // //
// // //       if (consultationResponse['status'] == 'success') {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text(
// // //               'Consultation created successfully! Payment: '
// // //               '${paymentStatus ? "Done ✅" : "Pending ⏳"} ($paymentMode)',
// // //             ),
// // //           ),
// // //         );
// // //
// // //         _formKey.currentState?.reset();
// // //         setState(() {
// // //           patientData = {};
// // //           appointmentDateTime = null;
// // //           doctorIdController.clear();
// // //           doctorNameController.clear();
// // //           departmentController.clear();
// // //           purposeController.clear();
// // //           temperatureController.clear();
// // //           heightController.clear();
// // //           weightController.clear();
// // //           bpController.clear();
// // //           sugarController.clear();
// // //           symptomsController.clear();
// // //           notesController.clear();
// // //         });
// // //       } else {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text('Failed to create consultation')),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(SnackBar(content: Text('Error: $e')));
// // //     } finally {
// // //       setState(() => _isSubmitting = false);
// // //     }
// // //   }
// // //
// // //   // ------------------------- UI COMPONENTS -------------------------
// // //   Widget _buildEditableField(
// // //     String label,
// // //     TextEditingController controller, {
// // //     int maxLines = 1,
// // //     TextInputType? keyboardType,
// // //     VoidCallback? onTap,
// // //   }) {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(vertical: 6),
// // //       child: TextFormField(
// // //         controller: controller,
// // //         maxLines: maxLines,
// // //         keyboardType: keyboardType,
// // //         onTap: onTap,
// // //         decoration: InputDecoration(
// // //           labelText: label,
// // //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
// // //         ),
// // //         validator: (v) => v == null || v.isEmpty ? 'Enter $label' : null,
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildPatientInfoCard() {
// // //     if (patientData.isEmpty) return const SizedBox();
// // //     final info = {
// // //       'Name': patientData['name'] ?? '-',
// // //       'DOB': getDOB(),
// // //       'Gender': patientData['gender'] ?? '-',
// // //       'Blood Group': patientData['bldGrp'] ?? '-',
// // //       'Email': getEmail(),
// // //       'Phone': getPhone(),
// // //       'Address': getAddress(),
// // //     };
// // //
// // //     return Card(
// // //       color: cardBackground,
// // //       elevation: 4,
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(16),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: info.entries.map((entry) {
// // //             return Padding(
// // //               padding: const EdgeInsets.symmetric(vertical: 4),
// // //               child: Row(
// // //                 children: [
// // //                   Expanded(
// // //                     flex: 2,
// // //                     child: Text(
// // //                       "${entry.key}:",
// // //                       style: const TextStyle(fontWeight: FontWeight.bold),
// // //                     ),
// // //                   ),
// // //                   Expanded(flex: 3, child: Text(entry.value.toString())),
// // //                 ],
// // //               ),
// // //             );
// // //           }).toList(),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildDoctorList() {
// // //     if (_isLoadingDoctors) {
// // //       return const Center(child: CircularProgressIndicator());
// // //     }
// // //     if (_doctors.isEmpty) {
// // //       return const Center(child: Text("No doctors found"));
// // //     }
// // //
// // //     return SizedBox(
// // //       height: 120,
// // //       child: ListView.builder(
// // //         scrollDirection: Axis.horizontal,
// // //         itemCount: _doctors.length,
// // //         itemBuilder: (context, index) {
// // //           final doc = _doctors[index];
// // //           final isSelected = doctorIdController.text == doc['id'];
// // //           return GestureDetector(
// // //             onTap: () {
// // //               setState(() {
// // //                 doctorIdController.text = doc['id'];
// // //                 doctorNameController.text = doc['name'];
// // //                 departmentController.text = doc['department'];
// // //               });
// // //             },
// // //             child: Container(
// // //               width: 120,
// // //               margin: const EdgeInsets.all(8),
// // //               decoration: BoxDecoration(
// // //                 color: isSelected ? customGold.withOpacity(0.2) : Colors.white,
// // //                 border: Border.all(
// // //                   color: isSelected ? customGold : Colors.grey.shade300,
// // //                 ),
// // //                 borderRadius: BorderRadius.circular(12),
// // //               ),
// // //               child: Column(
// // //                 mainAxisAlignment: MainAxisAlignment.center,
// // //                 children: [
// // //                   CircleAvatar(
// // //                     backgroundImage: NetworkImage(doc['photo']),
// // //                     radius: 25,
// // //                   ),
// // //                   const SizedBox(height: 6),
// // //                   Text(
// // //                     doc['name'],
// // //                     textAlign: TextAlign.center,
// // //                     style: const TextStyle(
// // //                       fontSize: 13,
// // //                       fontWeight: FontWeight.w600,
// // //                     ),
// // //                   ),
// // //                   Text(
// // //                     doc['department'],
// // //                     style: const TextStyle(fontSize: 12, color: Colors.grey),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ------------------------- BUILD -------------------------
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: _overviewAppBar(context),
// // //       backgroundColor: const Color(0xFFF5F5F5),
// // //       body: SingleChildScrollView(
// // //         padding: const EdgeInsets.all(16),
// // //         child: Form(
// // //           key: _formKey,
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               Row(
// // //                 children: [
// // //                   Expanded(
// // //                     child: _buildEditableField(
// // //                       "Patient ID",
// // //                       patientIdController,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(width: 8),
// // //                   ElevatedButton(
// // //                     onPressed: _isFetching ? null : _fetchPatient,
// // //                     style: ElevatedButton.styleFrom(
// // //                       backgroundColor: customGold,
// // //                     ),
// // //                     child: _isFetching
// // //                         ? const CircularProgressIndicator(color: Colors.white)
// // //                         : const Text("Fetch"),
// // //                   ),
// // //                 ],
// // //               ),
// // //               const SizedBox(height: 16),
// // //               _buildPatientInfoCard(),
// // //               const SizedBox(height: 16),
// // //               _buildEditableField(
// // //                 "Complaint",
// // //                 purposeController,
// // //                 onTap: () {
// // //                   setState(() => showDoctorSection = true);
// // //                   _fetchDoctors();
// // //                 },
// // //               ),
// // //               const SizedBox(height: 10),
// // //               if (showDoctorSection) ...[
// // //                 const Text(
// // //                   "Select Doctor",
// // //                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
// // //                 ),
// // //                 _buildDoctorList(),
// // //                 _buildEditableField("Doctor Name", doctorNameController),
// // //                 _buildEditableField("Department", departmentController),
// // //               ],
// // //
// // //               ElevatedButton.icon(
// // //                 onPressed: () async {
// // //                   // Pick date
// // //                   final date = await showDatePicker(
// // //                     context: context,
// // //                     initialDate: DateTime.now(),
// // //                     firstDate: DateTime.now(),
// // //                     lastDate: DateTime.now().add(const Duration(days: 365)),
// // //                   );
// // //                   if (date == null) return;
// // //
// // //                   // Pick time
// // //                   final time = await showTimePicker(
// // //                     context: context,
// // //                     initialTime: TimeOfDay.now(),
// // //                   );
// // //                   if (time == null) return;
// // //
// // //                   // Combine date + time into one DateTime
// // //                   setState(() {
// // //                     appointmentDateTime = DateTime(
// // //                       date.year,
// // //                       date.month,
// // //                       date.day,
// // //                       time.hour,
// // //                       time.minute,
// // //                     );
// // //                   });
// // //                 },
// // //                 icon: const Icon(Icons.access_time),
// // //                 label: Text(
// // //                   appointmentDateTime == null
// // //                       ? "Select Appointment Date & Time"
// // //                       : "Appointment: ${DateFormat('yyyy-MM-dd hh:mm a').format(appointmentDateTime!.toLocal())}",
// // //                 ),
// // //                 style: ElevatedButton.styleFrom(backgroundColor: customGold),
// // //               ),
// // //
// // //               const SizedBox(height: 20),
// // //               const Text(
// // //                 "Consultation",
// // //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //               ),
// // //               _buildEditableField(
// // //                 "Temperature",
// // //                 temperatureController,
// // //                 keyboardType: TextInputType.number,
// // //               ),
// // //               _buildEditableField(
// // //                 "Height",
// // //                 heightController,
// // //                 keyboardType: TextInputType.number,
// // //               ),
// // //               _buildEditableField(
// // //                 "Weight",
// // //                 weightController,
// // //                 keyboardType: TextInputType.number,
// // //               ),
// // //               _buildEditableField("BP", bpController),
// // //               _buildEditableField(
// // //                 "Sugar",
// // //                 sugarController,
// // //                 keyboardType: TextInputType.number,
// // //               ),
// // //               _buildEditableField("Symptoms", symptomsController, maxLines: 2),
// // //               _buildEditableField("Notes", notesController, maxLines: 2),
// // //               const SizedBox(height: 30),
// // //               Center(
// // //                 child: ElevatedButton(
// // //                   onPressed: _isSubmitting ? null : _submitConsultation,
// // //                   style: ElevatedButton.styleFrom(
// // //                     backgroundColor: customGold,
// // //                     minimumSize: const Size(180, 48),
// // //                   ),
// // //                   child: _isSubmitting
// // //                       ? const CircularProgressIndicator(color: Colors.white)
// // //                       : const Text(
// // //                           "Submit Consultation",
// // //                           style: TextStyle(fontSize: 18),
// // //                         ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   PreferredSizeWidget _overviewAppBar(BuildContext context) {
// // //     return PreferredSize(
// // //       preferredSize: const Size.fromHeight(100),
// // //       child: Container(
// // //         height: 100,
// // //         decoration: const BoxDecoration(
// // //           color: customGold,
// // //           borderRadius: BorderRadius.only(
// // //             bottomLeft: Radius.circular(12),
// // //             bottomRight: Radius.circular(12),
// // //           ),
// // //           boxShadow: [
// // //             BoxShadow(
// // //               color: Colors.black26,
// // //               blurRadius: 4,
// // //               offset: Offset(0, 2),
// // //             ),
// // //           ],
// // //         ),
// // //         child: SafeArea(
// // //           child: Padding(
// // //             padding: const EdgeInsets.symmetric(horizontal: 12),
// // //             child: Row(
// // //               children: [
// // //                 IconButton(
// // //                   icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
// // //                   onPressed: () => Navigator.pop(context),
// // //                 ),
// // //                 const SizedBox(width: 8),
// // //                 const Text(
// // //                   'Reception Desk',
// // //                   style: TextStyle(
// // //                     color: Colors.white,
// // //                     fontWeight: FontWeight.w600,
// // //                     fontSize: 24,
// // //                   ),
// // //                 ),
// // //                 const Spacer(),
// // //                 IconButton(
// // //                   icon: const Icon(Icons.notifications, color: Colors.white),
// // //                   onPressed: () {
// // //                     Navigator.push(
// // //                       context,
// // //                       MaterialPageRoute(
// // //                         builder: (context) => const NotificationPage(),
// // //                       ),
// // //                     );
// // //                   },
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:intl/intl.dart';
// // // import '../../../Services/consultation_service.dart';
// // // import '../../NotificationsPage.dart';
// // // import 'doctor_consultation_page.dart';
// // //
// // // const Color customGold = Color(0xFFBF955E);
// // //
// // // class ConsultationQueuePage extends StatefulWidget {
// // //   const ConsultationQueuePage({Key? key}) : super(key: key);
// // //
// // //   @override
// // //   State<ConsultationQueuePage> createState() => _ConsultationQueuePageState();
// // // }
// // //
// // // class _ConsultationQueuePageState extends State<ConsultationQueuePage>
// // //     with SingleTickerProviderStateMixin {
// // //   List<Map<String, dynamic>> consultations = [];
// // //   bool _isLoading = false;
// // //
// // //   late final AnimationController _dotController;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _dotController = AnimationController(
// // //       vsync: this,
// // //       duration: const Duration(seconds: 1),
// // //     )..repeat();
// // //     _fetchAllConsultations();
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _dotController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   Future<void> _fetchAllConsultations() async {
// // //     setState(() => _isLoading = true);
// // //     try {
// // //       final response = await ConsultationService.getAllConsultations();
// // //       final List<dynamic> rawList = response;
// // //
// // //       consultations = rawList.map<Map<String, dynamic>>((item) {
// // //         final patient = item['Patient'] ?? {};
// // //         final doctor = item['Doctor'] ?? {};
// // //         final hospital = item['Hospital'] ?? {};
// // //
// // //         return {
// // //           'id': item['id'],
// // //           'appointdate': item['appointdate'],
// // //           'purpose': item['purpose'] ?? '-',
// // //           'status': item['status'] ?? 'WAITING',
// // //           'patientName': patient['name'] ?? '-',
// // //           'gender': patient['gender'] ?? '-',
// // //           'dob': patient['dob'] ?? '-',
// // //           'Blood Group': patient['bldGrp'] ?? '-',
// // //           'Bp': patient['bp'] ?? '-',
// // //           'Sugar': patient['sugar'] ?? '-',
// // //           'doctor_Id': item['doctor_Id'] ?? '-',
// // //           'doctorName': doctor['name'] ?? '-',
// // //           'hospitalName': hospital['name'] ?? '-',
// // //           'patient_Id': patient['user_Id'] ?? '-',
// // //           'hospital_Id': hospital['id'],
// // //         };
// // //       }).toList();
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('❌ Error fetching consultations: $e')),
// // //       );
// // //     } finally {
// // //       setState(() => _isLoading = false);
// // //     }
// // //   }
// // //
// // //   Future<void> _handleTap(Map<String, dynamic> consultation) async {
// // //     final status = consultation['status'].toString().toUpperCase();
// // //
// // //     if (status == 'PENDING' || status == 'WAITING') {
// // //       try {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text("⏳ Updating status to ONGOING...")),
// // //         );
// // //
// // //         final response = await ConsultationService().updateConsultation(
// // //           consultation['id'],
// // //           {"status": "ONGOING"},
// // //         );
// // //
// // //         if (response['status'] == 'success' ||
// // //             response['message']?.toString().toLowerCase().contains('updated') ==
// // //                 true) {
// // //           ScaffoldMessenger.of(context).showSnackBar(
// // //             const SnackBar(content: Text("✅ Status updated to ONGOING")),
// // //           );
// // //           await _fetchAllConsultations(); // Refresh page
// // //           consultation = consultations.firstWhere(
// // //             (c) => c['id'] == consultation['id'],
// // //             orElse: () => consultation,
// // //           );
// // //         } else {
// // //           ScaffoldMessenger.of(context).showSnackBar(
// // //             SnackBar(content: Text("⚠️ Update failed: ${response['message']}")),
// // //           );
// // //           return;
// // //         }
// // //       } catch (e) {
// // //         ScaffoldMessenger.of(
// // //           context,
// // //         ).showSnackBar(SnackBar(content: Text("❌ Error updating status: $e")));
// // //         return;
// // //       }
// // //     }
// // //
// // //     Navigator.push(
// // //       context,
// // //       MaterialPageRoute(
// // //         builder: (_) => DoctorConsultationPage(consultation: consultation),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Color _getStatusColor(String status) {
// // //     switch (status.toUpperCase()) {
// // //       case 'ONGOING':
// // //         return Colors.orange;
// // //       case 'COMPLETED':
// // //         return Colors.green;
// // //       default:
// // //         return Colors.grey;
// // //     }
// // //   }
// // //
// // //   Widget _buildStatusText(String status) {
// // //     if (status.toUpperCase() == 'ONGOING') {
// // //       return AnimatedBuilder(
// // //         animation: _dotController,
// // //         builder: (context, child) {
// // //           int dotCount = ((_dotController.value * 3).floor() % 3) + 1;
// // //           return Row(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: List.generate(
// // //               3,
// // //               (index) => Padding(
// // //                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
// // //                 child: CircleAvatar(
// // //                   radius: 4,
// // //                   backgroundColor: index < dotCount
// // //                       ? Colors.white
// // //                       : Colors.white24,
// // //                 ),
// // //               ),
// // //             ),
// // //           );
// // //         },
// // //       );
// // //     }
// // //     return Text(
// // //       status.toUpperCase(),
// // //       style: const TextStyle(
// // //         color: Colors.white,
// // //         fontSize: 12,
// // //         fontWeight: FontWeight.bold,
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildConsultationQueue() {
// // //     if (consultations.isEmpty) {
// // //       return const Center(
// // //         child: Text(
// // //           'No consultations found',
// // //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
// // //         ),
// // //       );
// // //     }
// // //
// // //     return RefreshIndicator(
// // //       onRefresh: _fetchAllConsultations,
// // //       child: ListView.builder(
// // //         shrinkWrap: true,
// // //         physics: const AlwaysScrollableScrollPhysics(),
// // //         itemCount: consultations.length,
// // //         itemBuilder: (context, index) {
// // //           final c = consultations[index];
// // //           final appointDate = DateTime.tryParse(c['appointdate'] ?? '');
// // //           final formattedTime = appointDate != null
// // //               ? DateFormat('MMM dd, yyyy • hh:mm a').format(appointDate)
// // //               : '-';
// // //
// // //           return GestureDetector(
// // //             onTap: () => _handleTap(c),
// // //             child: Card(
// // //               elevation: 4,
// // //               margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
// // //               shape: RoundedRectangleBorder(
// // //                 borderRadius: BorderRadius.circular(14),
// // //               ),
// // //               shadowColor: Colors.black26,
// // //               child: Container(
// // //                 decoration: BoxDecoration(
// // //                   gradient: LinearGradient(
// // //                     colors: [Colors.white, Colors.grey.shade100],
// // //                     begin: Alignment.topLeft,
// // //                     end: Alignment.bottomRight,
// // //                   ),
// // //                   borderRadius: BorderRadius.circular(14),
// // //                 ),
// // //                 padding: const EdgeInsets.all(14),
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     Row(
// // //                       children: [
// // //                         CircleAvatar(
// // //                           radius: 26,
// // //                           backgroundColor: customGold.withOpacity(0.2),
// // //                           child: const Icon(Icons.person, color: customGold),
// // //                         ),
// // //                         const SizedBox(width: 10),
// // //                         Expanded(
// // //                           child: Column(
// // //                             crossAxisAlignment: CrossAxisAlignment.start,
// // //                             children: [
// // //                               Text(
// // //                                 c['patientName'],
// // //                                 style: const TextStyle(
// // //                                   fontWeight: FontWeight.bold,
// // //                                   fontSize: 16,
// // //                                 ),
// // //                               ),
// // //                               Text(
// // //                                 "ID: ${c['patient_Id'] ?? '-'}",
// // //                                 style: const TextStyle(
// // //                                   color: Colors.grey,
// // //                                   fontSize: 13,
// // //                                 ),
// // //                               ),
// // //                             ],
// // //                           ),
// // //                         ),
// // //                         Container(
// // //                           padding: const EdgeInsets.symmetric(
// // //                             horizontal: 10,
// // //                             vertical: 4,
// // //                           ),
// // //                           decoration: BoxDecoration(
// // //                             color: _getStatusColor(c['status']),
// // //                             borderRadius: BorderRadius.circular(12),
// // //                           ),
// // //                           child: _buildStatusText(c['status']),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                     const SizedBox(height: 8),
// // //                     const Divider(thickness: 0.5, color: Colors.grey),
// // //                     const SizedBox(height: 6),
// // //                     _buildInfoRow(
// // //                       Icons.local_hospital,
// // //                       "Hospital",
// // //                       c['hospitalName'],
// // //                     ),
// // //                     _buildInfoRow(Icons.event, "Date & Time", formattedTime),
// // //                     _buildInfoRow(Icons.info_outline, "Purpose", c['purpose']),
// // //                     _buildInfoRow(Icons.person_outline, "Gender", c['gender']),
// // //                     const SizedBox(height: 6),
// // //                     Align(
// // //                       alignment: Alignment.centerRight,
// // //                       child: TextButton.icon(
// // //                         onPressed: () => _handleTap(c),
// // //                         icon: const Icon(
// // //                           Icons.arrow_forward_ios,
// // //                           size: 16,
// // //                           color: customGold,
// // //                         ),
// // //                         label: const Text(
// // //                           "Start Consultation",
// // //                           style: TextStyle(
// // //                             color: customGold,
// // //                             fontWeight: FontWeight.bold,
// // //                           ),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildInfoRow(IconData icon, String label, String value) {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(vertical: 2),
// // //       child: Row(
// // //         children: [
// // //           Icon(icon, size: 18, color: customGold),
// // //           const SizedBox(width: 8),
// // //           Text(
// // //             "$label: ",
// // //             style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
// // //           ),
// // //           Expanded(
// // //             child: Text(
// // //               value,
// // //               style: const TextStyle(fontSize: 13, color: Colors.black87),
// // //               overflow: TextOverflow.ellipsis,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: PreferredSize(
// // //         preferredSize: const Size.fromHeight(100),
// // //         child: Container(
// // //           height: 100,
// // //           decoration: BoxDecoration(
// // //             color: customGold,
// // //             borderRadius: const BorderRadius.only(
// // //               bottomLeft: Radius.circular(16),
// // //               bottomRight: Radius.circular(16),
// // //             ),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withOpacity(0.15),
// // //                 blurRadius: 6,
// // //                 offset: const Offset(0, 3),
// // //               ),
// // //             ],
// // //           ),
// // //           child: SafeArea(
// // //             child: Padding(
// // //               padding: const EdgeInsets.symmetric(horizontal: 16),
// // //               child: Row(
// // //                 children: [
// // //                   IconButton(
// // //                     icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
// // //                     onPressed: () => Navigator.pop(context),
// // //                   ),
// // //                   const Text(
// // //                     "Consultation Queue",
// // //                     style: TextStyle(
// // //                       color: Colors.white,
// // //                       fontSize: 22,
// // //                       fontWeight: FontWeight.bold,
// // //                     ),
// // //                   ),
// // //                   const Spacer(),
// // //                   IconButton(
// // //                     icon: const Icon(Icons.notifications, color: Colors.white),
// // //                     onPressed: () {
// // //                       Navigator.push(
// // //                         context,
// // //                         MaterialPageRoute(
// // //                           builder: (_) => const NotificationPage(),
// // //                         ),
// // //                       );
// // //                     },
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //       backgroundColor: const Color(0xFFF8F8F8),
// // //       body: _isLoading
// // //           ? const Center(child: CircularProgressIndicator(color: customGold))
// // //           : Padding(
// // //               padding: const EdgeInsets.all(12.0),
// // //               child: _buildConsultationQueue(),
// // //             ),
// // //     );
// // //   }
// // // }
// //
// // // showGuardianEmail
// // //     ? _buildInput(
// // //         "Guardian Phone Number",
// // //         guardianEmailController,
// // //         hint: "Parent/guardian's Phone",
// // //       )
// // //     : InkWell(
// // //         onTap: () =>
// // //             setState(() => showGuardianEmail = true),
// // //         child: Padding(
// // //           padding: const EdgeInsets.symmetric(
// // //             vertical: 8,
// // //             horizontal: 7,
// // //           ),
// // //           child: Row(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               Icon(
// // //                 Icons.add,
// // //                 color: customGold,
// // //                 size: 19,
// // //               ),
// // //               const SizedBox(width: 3),
// // //               Text(
// // //                 "Guardian Phone",
// // //                 style: TextStyle(
// // //                   color: customGold,
// // //                   fontWeight: FontWeight.w600,
// // //                   fontSize: 15,
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// //
// //
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:hospitrax/Admin/Pages/AdminEditProfilePage.dart';
// // import 'package:intl/intl.dart';
// // import '../../Services/patient_service.dart';
// // import '../../Services/consultation_service.dart';
// // import '../../Services/Doctor/doctor_service.dart';
// // import '../NotificationsPage.dart';
// // import '../payment_modal.dart';
// //
// // const Color customGold = Color(0xFFBF955E);
// // const Color cardBackground = Color(0xFFF9F9F9);
// //
// // class ReceptionDeskPage extends StatefulWidget {
// //   final String UserId;
// //   const ReceptionDeskPage({super.key, required this.UserId});
// //
// //   @override
// //   State<ReceptionDeskPage> createState() => _ReceptionDeskPageState();
// // }
// //
// // class _ReceptionDeskPageState extends State<ReceptionDeskPage> {
// //   final _formKey = GlobalKey<FormState>();
// //   final patientService = PatientService();
// //   final consultationService = ConsultationService();
// //   final doctorService = DoctorService();
// //
// //   Map<String, dynamic> patientData = {};
// //   // List<Map<String, dynamic>> allDoctors = [];
// //   // List<Map<String, dynamic>> filteredDoctors = [];
// //   List<Map<String, dynamic>> allDoctors = []; // Loaded once
// //   List<Map<String, dynamic>> filteredDoctors = [];
// //   Map<String, dynamic>? selectedDoctor; // Store full doctor data
// //
// //   final TextEditingController patientIdController = TextEditingController();
// //   final TextEditingController purposeController = TextEditingController();
// //   final TextEditingController doctorIdController = TextEditingController();
// //   final TextEditingController doctorNameController = TextEditingController();
// //   final TextEditingController departmentController = TextEditingController();
// //   final TextEditingController temperatureController = TextEditingController();
// //   final TextEditingController heightController = TextEditingController();
// //   final TextEditingController weightController = TextEditingController();
// //   final TextEditingController bpController = TextEditingController();
// //   final TextEditingController sugarController = TextEditingController();
// //   final TextEditingController symptomsController = TextEditingController();
// //   final TextEditingController notesController = TextEditingController();
// //
// //   final FocusNode bpFocus = FocusNode();
// //   final FocusNode sugarFocus = FocusNode();
// //
// //   DateTime? appointmentDateTime;
// //   bool isFetching = false;
// //   bool isLoadingDoctors = false;
// //   bool isSubmitting = false;
// //   bool showDoctorSection = false;
// //   bool showBpOptions = false;
// //   bool showSugarOptions = false;
// //   double registrationFee = 100;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     patientIdController.text = widget.UserId;
// //     _fetchPatient();
// //     _fetchDoctors();
// //     bpFocus.addListener(() {
// //       setState(() => showBpOptions = bpFocus.hasFocus);
// //     });
// //     sugarFocus.addListener(() {
// //       setState(() => showSugarOptions = sugarFocus.hasFocus);
// //     });
// //   }
// //
// //   @override
// //   void dispose() {
// //     bpFocus.dispose();
// //     sugarFocus.dispose();
// //     // _formKey.currentState?.dispose();
// //     super.dispose();
// //   }
// //
// //   // Fetch Patient Data
// //   Future<void> _fetchPatient() async {
// //     final userId = patientIdController.text.trim();
// //     if (userId.isEmpty) return;
// //     setState(() => isFetching = true);
// //     try {
// //       final res = await patientService.getPatientByUserId(userId);
// //       if (res != null && res['status'] == 'success') {
// //         setState(() => patientData = res['data'] ?? {});
// //       } else {
// //         _showSnackBar('Patient not found');
// //       }
// //     } catch (e) {
// //       _showSnackBar('Error fetching patient: $e');
// //     } finally {
// //       setState(() => isFetching = false);
// //     }
// //   }
// //
// //   void _filterDoctors() {
// //     final complaint = purposeController.text.toLowerCase();
// //     String filterDept = '';
// //     List<String> dermKeywords = ['skin', 'hair', 'nail', 'derma', 'rash'];
// //
// //     if (complaint.contains('heart') || complaint.contains('cardio')) {
// //       filterDept = 'Cardiology';
// //     } else if (dermKeywords.any((term) => complaint.contains(term))) {
// //       filterDept = 'Dermatology';
// //     }
// //
// //     setState(() {
// //       filteredDoctors = filterDept.isEmpty
// //           ? allDoctors
// //           : allDoctors
// //           .where(
// //             (d) =>
// //         d['department'].toString().toLowerCase() ==
// //             filterDept.toLowerCase(),
// //       )
// //           .toList();
// //     });
// //   }
// //
// //   // Fetch All doctors from DB
// //   Future<void> _fetchDoctors() async {
// //     setState(() => isLoadingDoctors = true);
// //     try {
// //       final docs = await doctorService.getDoctors();
// //       setState(() {
// //         allDoctors = docs;
// //       });
// //       _filterDoctors();
// //     } catch (e) {
// //       _showSnackBar('Error loading doctors: $e');
// //     } finally {
// //       setState(() => isLoadingDoctors = false);
// //     }
// //   }
// //
// //   // Filter doctors based on complaints
// //   // void _onComplaintChanged(String complaint) {
// //   //   setState(() => showDoctorSection = true);
// //   //
// //   //   _fetchDoctors().then((_) {
// //   //     final lowerComplaint = complaint.toLowerCase();
// //   //     String filterDept = '';
// //   //
// //   //     if (lowerComplaint.contains('heart') ||
// //   //         lowerComplaint.contains('arrhythmia') ||
// //   //         lowerComplaint.contains('failure') ||
// //   //         lowerComplaint.contains('congenital')) {
// //   //       filterDept = 'Cardiology';
// //   //     } else if (lowerComplaint.contains('skin') ||
// //   //         lowerComplaint.contains('hair') ||
// //   //         lowerComplaint.contains('nail') ||
// //   //         lowerComplaint.contains('rash') ||
// //   //         lowerComplaint.contains('derma')) {
// //   //       filterDept = 'Dermatology';
// //   //     }
// //   //
// //   //     setState(() {
// //   //       filteredDoctors = filterDept.isEmpty
// //   //           ? allDoctors
// //   //           : allDoctors
// //   //                 .where(
// //   //                   (d) =>
// //   //                       d['department'].toString().toLowerCase() ==
// //   //                       filterDept.toLowerCase(),
// //   //                 )
// //   //                 .toList();
// //   //     });
// //   //   });
// //   // }
// //
// //   void _onComplaintChanged(String value) {
// //     final complaint = value.toLowerCase();
// //     String filterDept = '';
// //     List<String> dermKeywords = ['skin', 'hair', 'nail', 'derma', 'rash'];
// //
// //     if (complaint.contains('heart') || complaint.contains('cardio')) {
// //       filterDept = 'Cardiology';
// //     } else if (dermKeywords.any((term) => complaint.contains(term))) {
// //       filterDept = 'Dermatology';
// //     }
// //
// //     setState(() {
// //       filteredDoctors = filterDept.isEmpty
// //           ? List.from(allDoctors) // show all if complaint empty
// //           : allDoctors
// //           .where(
// //             (d) =>
// //         d['department'].toString().toLowerCase() ==
// //             filterDept.toLowerCase(),
// //       )
// //           .toList();
// //     });
// //   }
// //
// //   // Future<void> _pickDateTime() async {
// //   //   final date = await showDatePicker(
// //   //     context: context,
// //   //     initialDate: appointmentDateTime ?? DateTime.now(),
// //   //     firstDate: DateTime.now(),
// //   //     lastDate: DateTime.now().add(const Duration(days: 365)),
// //   //   );
// //   //   if (date == null) return;
// //   //
// //   //   final time = await showTimePicker(
// //   //     context: context,
// //   //     initialTime: TimeOfDay.now(),
// //   //   );
// //   //   if (time == null) return;
// //   //
// //   //   setState(() {
// //   //     appointmentDateTime = DateTime(
// //   //       date.year,
// //   //       date.month,
// //   //       date.day,
// //   //       time.hour,
// //   //       time.minute,
// //   //     );
// //   //   });
// //   // }
// //
// //   Future<void> _submitConsultation() async {
// //     if (!_formKey.currentState!.validate()) return;
// //     if (patientData.isEmpty) {
// //       _showSnackBar('Please fetch a patient first');
// //       return;
// //     }
// //     if (doctorIdController.text.isEmpty) {
// //       _showSnackBar('Please select a doctor');
// //       return;
// //     }
// //
// //     setState(() => isSubmitting = true);
// //     try {
// //       final paymentResult = await showDialog<Map<String, dynamic>>(
// //         context: context,
// //         barrierDismissible: false, // prevent accidental dismiss
// //         builder: (_) => PaymentModal(registrationFee: registrationFee),
// //       );
// //
// //       if (paymentResult == null) {
// //         ScaffoldMessenger.of(
// //           context,
// //         ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
// //         return;
// //       }
// //
// //       final bool paymentStatus = paymentResult['paymentStatus'] ?? false;
// //       final String paymentMode = paymentResult['paymentMode'] ?? 'unknown';
// //       //
// //       final hospitalId = await doctorService.getHospitalId();
// //       final response = await consultationService.createConsultation({
// //         "hospital_Id": hospitalId,
// //         "patient_Id": patientData['user_Id'],
// //         "doctor_Id": doctorIdController.text,
// //         "name": doctorNameController.text,
// //         "purpose": purposeController.text,
// //         "temperature": temperatureController.text,
// //         "symptoms": symptomsController.text,
// //         // "notes": notesController.text,
// //         "notes": jsonEncode(notesController.text.trim()),
// //         "appointdate": appointmentDateTime.toString(),
// //         "paymentStatus": paymentStatus,
// //         "paymentMode": "Online",
// //       });
// //       final userId = patientData['user_Id'];
// //       print(userId);
// //       final patientUpdate = await patientService.updatePatient(userId, {
// //         "height": int.parse(heightController.text),
// //         "weight": int.parse(weightController.text),
// //         "bp": bpController.text,
// //         "sugar": sugarController.text,
// //       });
// //
// //       if (response['status'] == 'success' &&
// //           patientUpdate['status'] == 'success') {
// //         _showSnackBar('Consultation successfully created');
// //       } else {
// //         _showSnackBar('Failed to create consultation');
// //       }
// //     } catch (e) {
// //       _showSnackBar('Error: $e');
// //     } finally {
// //       setState(() => isSubmitting = false);
// //     }
// //   }
// //
// //   void _showSnackBar(String msg) =>
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
// //
// //   // UI Components
// //
// //   Widget _buildPatientInfoCard() {
// //     if (patientData.isEmpty) return const SizedBox.shrink();
// //
// //     return Card(
// //       color: Colors.white,
// //       elevation: 4,
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// //       shadowColor: Colors.grey.shade200,
// //       child: Padding(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Title
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 Icon(
// //                   Icons.personal_injury_rounded,
// //                   color: Colors.redAccent,
// //                   size: 26,
// //                 ),
// //                 const SizedBox(width: 8),
// //                 const Text(
// //                   'Patient Information',
// //                   style: TextStyle(
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 20,
// //                     color: Colors.black87,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const Divider(thickness: 1, height: 24),
// //
// //             // Patient Details Grid
// //             Wrap(
// //               runSpacing: 8,
// //               children: [
// //                 _infoRow(Icons.person, 'Name', patientData['name']),
// //                 _infoRow(Icons.cake, 'DOB', patientData['dob']),
// //                 _infoRow(Icons.wc, 'Gender', patientData['gender']),
// //                 _infoRow(
// //                   Icons.phone_android,
// //                   'Mobile',
// //                   patientData['phone']?['mobile'],
// //                 ),
// //                 // _infoRow(
// //                 //   Icons.local_phone,
// //                 //   'Emergency',
// //                 //   patientData['phone']?['emergency'],
// //                 // ),
// //                 _infoRow(
// //                   Icons.email,
// //                   'Email',
// //                   patientData['email']?['personal'],
// //                 ),
// //                 _infoRow(
// //                   Icons.location_on,
// //                   'Address',
// //                   patientData['address']?['Address'],
// //                 ),
// //                 _infoRow(Icons.bloodtype, 'Blood Group', patientData['bldGrp']),
// //                 // _infoRow(
// //                 //   Icons.history,
// //                 //   'Medical History',
// //                 //   patientData['medicalHistory '],
// //                 //),
// //                 // _infoRow(
// //                 //   Icons.history,
// //                 //   'Current Problem ',
// //                 //   patientData['currentProblem'],
// //                 // ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// Reusable info row widget with icon + label + value
// //   Widget _infoRow(IconData icon, String label, String? value) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 4),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Icon(icon, size: 20, color: customGold),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: RichText(
// //               text: TextSpan(
// //                 style: const TextStyle(
// //                   fontSize: 15,
// //                   color: Colors.black87,
// //                   height: 1.4,
// //                 ),
// //                 children: [
// //                   TextSpan(
// //                     text: '$label: ',
// //                     style: const TextStyle(fontWeight: FontWeight.w600),
// //                   ),
// //                   TextSpan(text: (value?.isNotEmpty ?? false) ? value : '---'),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // Widget _buildDoctorList() {
// //   //   if (isLoadingDoctors)
// //   //     return Center(child: const CircularProgressIndicator());
// //   //   if (filteredDoctors.isEmpty) {
// //   //     return const Text('No available doctors for this complaint');
// //   //   }
// //   //   return SizedBox(
// //   //     height: 120,
// //   //     child: ListView.builder(
// //   //       scrollDirection: Axis.horizontal,
// //   //       itemCount: filteredDoctors.length,
// //   //       itemBuilder: (_, i) {
// //   //         final doc = filteredDoctors[i];
// //   //         final selected = doctorIdController.text == doc['id'];
// //   //         return GestureDetector(
// //   //           onTap: () {
// //   //             setState(() {
// //   //               doctorIdController.text = doc['id'];
// //   //               doctorNameController.text = doc['name'];
// //   //               departmentController.text = doc['department'];
// //   //             });
// //   //           },
// //   //           child: Container(
// //   //             width: 130,
// //   //             margin: const EdgeInsets.all(8),
// //   //             decoration: BoxDecoration(
// //   //               color: selected ? customGold.withOpacity(0.25) : Colors.white,
// //   //               border: Border.all(
// //   //                 color: selected ? customGold : Colors.grey.shade400,
// //   //               ),
// //   //               borderRadius: BorderRadius.circular(12),
// //   //             ),
// //   //             child: Column(
// //   //               mainAxisAlignment: MainAxisAlignment.center,
// //   //               children: [
// //   //                 Text(
// //   //                   doc['name'],
// //   //                   textAlign: TextAlign.center,
// //   //                   style: const TextStyle(fontWeight: FontWeight.w600),
// //   //                 ),
// //   //                 Text(
// //   //                   doc['department'],
// //   //                   style: const TextStyle(fontSize: 12, color: Colors.grey),
// //   //                 ),
// //   //               ],
// //   //             ),
// //   //           ),
// //   //         );
// //   //       },
// //   //     ),
// //   //   );
// //   // }
// //   Widget _buildDoctorList() {
// //     if (isLoadingDoctors) {
// //       return const Center(child: CircularProgressIndicator());
// //     }
// //
// //     if (filteredDoctors.isEmpty) {
// //       return const Text('No available doctors for this complaint');
// //     }
// //
// //     return SizedBox(
// //       height: 100,
// //       child: ListView.builder(
// //         scrollDirection: Axis.horizontal,
// //         itemCount: filteredDoctors.length,
// //         itemBuilder: (_, i) {
// //           final doc = filteredDoctors[i];
// //           final isSelected =
// //               selectedDoctor != null && selectedDoctor!['id'] == doc['id'];
// //
// //           return GestureDetector(
// //             onTap: () {
// //               setState(() {
// //                 selectedDoctor = doc; // store full doctor data
// //               });
// //             },
// //             child: Container(
// //               width: 120,
// //               margin: const EdgeInsets.all(8),
// //               padding: const EdgeInsets.all(10),
// //               decoration: BoxDecoration(
// //                 color: isSelected ? customGold.withOpacity(0.25) : Colors.white,
// //                 border: Border.all(
// //                   color: isSelected ? customGold : Colors.grey.shade300,
// //                   width: isSelected ? 2 : 1,
// //                 ),
// //                 borderRadius: BorderRadius.circular(12),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.grey.withOpacity(0.1),
// //                     blurRadius: 4,
// //                     offset: const Offset(1, 2),
// //                   ),
// //                 ],
// //               ),
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Text(
// //                     doc['name'],
// //                     textAlign: TextAlign.center,
// //                     style: const TextStyle(
// //                       fontWeight: FontWeight.w600,
// //                       fontSize: 14,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 6),
// //                   Text(
// //                     doc['department'],
// //                     textAlign: TextAlign.center,
// //                     style: const TextStyle(fontSize: 12, color: Colors.grey),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   Widget _buildVitalInput(
// //       String label,
// //       TextEditingController controller,
// //       FocusNode focusNode,
// //       bool showOptions,
// //       ) {
// //     const List<String> options = ['Low', 'Normal', 'High'];
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 6),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           TextFormField(
// //             controller: controller,
// //             focusNode: focusNode,
// //             keyboardType: TextInputType.number,
// //             decoration: InputDecoration(
// //               labelText: label,
// //               border: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(10),
// //               ),
// //             ),
// //           ),
// //           AnimatedSwitcher(
// //             duration: const Duration(milliseconds: 200),
// //             child: showOptions
// //                 ? Padding(
// //               padding: const EdgeInsets.only(top: 6),
// //               child: SizedBox(
// //                 height: 45,
// //                 child: ListView(
// //                   scrollDirection: Axis.horizontal,
// //                   children: options.map((opt) {
// //                     final selected = controller.text == opt;
// //                     return GestureDetector(
// //                       onTap: () {
// //                         setState(() => controller.text = opt);
// //                       },
// //                       child: Container(
// //                         margin: const EdgeInsets.only(right: 8),
// //                         padding: const EdgeInsets.symmetric(
// //                           horizontal: 18,
// //                           vertical: 8,
// //                         ),
// //                         decoration: BoxDecoration(
// //                           color: selected
// //                               ? customGold.withOpacity(0.2)
// //                               : Colors.white,
// //                           border: Border.all(
// //                             color: selected
// //                                 ? customGold
// //                                 : Colors.grey[300]!,
// //                           ),
// //                           borderRadius: BorderRadius.circular(10),
// //                         ),
// //                         child: Text(
// //                           opt,
// //                           style: TextStyle(
// //                             fontWeight: FontWeight.w600,
// //                             color: selected ? customGold : Colors.black87,
// //                           ),
// //                         ),
// //                       ),
// //                     );
// //                   }).toList(),
// //                 ),
// //               ),
// //             )
// //                 : const SizedBox.shrink(),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: PreferredSize(
// //         preferredSize: const Size.fromHeight(100),
// //         child: Container(
// //           height: 100,
// //           decoration: BoxDecoration(
// //             color: customGold,
// //             borderRadius: const BorderRadius.only(
// //               bottomLeft: Radius.circular(16),
// //               bottomRight: Radius.circular(16),
// //             ),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.black.withOpacity(0.15),
// //                 blurRadius: 6,
// //                 offset: const Offset(0, 3),
// //               ),
// //             ],
// //           ),
// //           child: SafeArea(
// //             child: Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 16),
// //               child: Row(
// //                 children: [
// //                   IconButton(
// //                     icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
// //                     onPressed: () => Navigator.pop(context),
// //                   ),
// //                   const Text(
// //                     "Reception Desk",
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontSize: 22,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                   const Spacer(),
// //                   IconButton(
// //                     icon: const Icon(Icons.notifications, color: Colors.white),
// //                     onPressed: () {
// //                       Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder: (_) => const NotificationPage(),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(14),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Row(
// //                 children: [
// //                   Expanded(
// //                     child: TextFormField(
// //                       controller: patientIdController,
// //                       keyboardType: TextInputType.number,
// //                       decoration: const InputDecoration(
// //                         labelText: 'Patient ID',
// //                         border: OutlineInputBorder(),
// //                       ),
// //                       validator: (v) {
// //                         if (v == null || v.isEmpty) return 'Required';
// //                         if (!RegExp(r'^\d{10}$').hasMatch(v)) {
// //                           return 'Must be 10 digits';
// //                         }
// //                         return null;
// //                       },
// //                     ),
// //                   ),
// //                   const SizedBox(width: 8),
// //                   ElevatedButton(
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: customGold,
// //                     ),
// //                     onPressed: isFetching ? null : _fetchPatient,
// //                     child: isFetching
// //                         ? const SizedBox(
// //                       width: 15,
// //                       height: 15,
// //                       child: CircularProgressIndicator(strokeWidth: 2),
// //                     )
// //                         : const Text(
// //                       'Fetch',
// //                       style: TextStyle(
// //                         color: Colors.white,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 8),
// //               if (patientData.isNotEmpty) _buildPatientInfoCard(),
// //               const SizedBox(height: 8),
// //               Center(
// //                 child: Card(
// //                   color: customGold,
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                   elevation: 4,
// //                   child: Padding(
// //                     padding: const EdgeInsets.symmetric(
// //                       vertical: 12,
// //                       horizontal: 16,
// //                     ),
// //                     child: Row(
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         const Icon(Icons.access_time, color: Colors.white),
// //                         const SizedBox(width: 8),
// //                         Text(
// //                           DateFormat(
// //                             'yyyy-MM-dd hh:mm a',
// //                           ).format(DateTime.now()),
// //                           style: const TextStyle(
// //                             color: Colors.white,
// //                             fontSize: 16,
// //                             fontWeight: FontWeight.bold,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 12),
// //               TextFormField(
// //                 controller: purposeController,
// //                 decoration: const InputDecoration(
// //                   labelText: 'Complaint',
// //                   border: OutlineInputBorder(),
// //                 ),
// //                 onChanged: _onComplaintChanged,
// //               ),
// //               if (showDoctorSection) ...[
// //                 const SizedBox(height: 10),
// //                 const Text(
// //                   'Select Doctor',
// //                   style: TextStyle(fontWeight: FontWeight.bold),
// //                 ),
// //                 _buildDoctorList(),
// //               ],
// //               const SizedBox(height: 10),
// //               TextFormField(
// //                 controller: temperatureController,
// //                 keyboardType: TextInputType.number,
// //                 decoration: const InputDecoration(
// //                   labelText: 'Temperature (°F)',
// //                   border: OutlineInputBorder(),
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               TextFormField(
// //                 controller: heightController,
// //                 keyboardType: TextInputType.number,
// //                 decoration: const InputDecoration(
// //                   labelText: 'Height (cm)',
// //                   border: OutlineInputBorder(),
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               TextFormField(
// //                 controller: weightController,
// //                 keyboardType: TextInputType.number,
// //                 decoration: const InputDecoration(
// //                   labelText: 'Weight (kg)',
// //                   border: OutlineInputBorder(),
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               _buildVitalInput(
// //                 'Blood Pressure (BP)',
// //                 bpController,
// //                 bpFocus,
// //                 showBpOptions,
// //               ),
// //               _buildVitalInput(
// //                 'Sugar Level',
// //                 sugarController,
// //                 sugarFocus,
// //                 showSugarOptions,
// //               ),
// //               const SizedBox(height: 8),
// //               TextFormField(
// //                 controller: symptomsController,
// //                 maxLines: 3,
// //                 decoration: const InputDecoration(
// //                   labelText: 'Symptoms',
// //                   border: OutlineInputBorder(),
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               TextFormField(
// //                 controller: notesController,
// //                 maxLines: 3,
// //                 decoration: const InputDecoration(
// //                   labelText: 'Notes',
// //                   border: OutlineInputBorder(),
// //                 ),
// //               ),
// //               const SizedBox(height: 18),
// //               ElevatedButton(
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: customGold,
// //                   minimumSize: const Size(double.infinity, 48),
// //                 ),
// //                 onPressed: isSubmitting ? null : _submitConsultation,
// //                 child: isSubmitting
// //                     ? const CircularProgressIndicator(color: Colors.white)
// //                     : const Text(
// //                   'Book Appointment',
// //                   style: TextStyle(fontSize: 18, color: Colors.white),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// // const Icon(Icons.receipt_long, size: 100, color: Colors.grey),
// // const SizedBox(height: 20),
// // const Text(
// // 'No Pending Fees',
// // style: TextStyle(
// // fontSize: 22,
// // fontWeight: FontWeight.bold,
// // color: Colors.black87,
// // ),
// // ),
// // const SizedBox(height: 10),
// // const Text(
// // 'You are all caught up!',
// // style: TextStyle(color: Colors.black54),
// // ),
//  //////////////////////////////////////////////////////////rolebutton////////////////////
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import '../../../Services/admin_service.dart';
// import '../../../Services/Button_Service.dart';
// import 'package:http/http.dart' as http;
//
// // ------------------- MAIN SCREEN -------------------
// class AssignRoleButton extends StatefulWidget {
//   const AssignRoleButton({super.key});
//
//   @override
//   State<AssignRoleButton> createState() => _AssignRoleButtonState();
// }
//
// class _AssignRoleButtonState extends State<AssignRoleButton> {
//   bool loading = true;
//   List<dynamic> staff = [];
//   List<dynamic> doctor = [];
//   List<dynamic> permissions = [];
//
//   @override
//   void initState() {
//     super.initState();
//     loadData();
//   }
//
//   // ---------------- LOAD ALL STAFF + ALL PERMISSIONS + STAFF SAVED PERMISSIONS ----------------
//   Future<void> loadData() async {
//     try {
//       final staffData = await AdminService().getMedicalStaff();
//       final permData = await ButtonPermissionService().getAllByHospital();
//
//       // Remove Admin / Super Admin
//       final filteredStaff = (staffData ?? []).where((user) {
//         final role = (user["role"] ?? "").toString().toLowerCase();
//         final status = (user["status"] ?? "").toString().toLowerCase();
//         return status != "inactive";
//       }).toList();
//
//       final filteredDoctor = (staffData ?? []).where((user) {
//         final role = (user["role"] ?? "").toString().toLowerCase() == "doctor";
//         return role;
//       }).toList();
//       print('filteredDoctor $filteredDoctor');
//       // ✅ Assign permissions ID list for each staff
//       for (var user in filteredStaff) {
//         final List<dynamic> permList = user["permissions"] ?? [];
//
//         user["assignedPermissionIds"] = permList
//             .map<int>((e) => e as int)
//             .toList();
//         // ✅ ADD THIS
//         user["assignedDoctorId"] = user["assignDoctorId"];
//       }
//
//       setState(() {
//         staff = filteredStaff;
//         doctor = filteredDoctor;
//         permissions = permData ?? [];
//         loading = false;
//       });
//     } catch (e) {
//       print("❌ Error loading data: $e");
//       setState(() => loading = false);
//     }
//   }
//
//   // ---------------- GROUP STAFF BY DESIGNATION ----------------
//   Map<String, List<dynamic>> groupByDesignation() {
//     Map<String, List<dynamic>> map = {};
//     for (var user in staff) {
//       String des = (user["role"] ?? "").toString().toLowerCase();
//       if (!map.containsKey(des)) map[des] = [];
//       map[des]!.add(user);
//     }
//     return map;
//   }
//
//   // ---------------- SORT DESIGNATIONS ----------------
//   List<String> getSortedDesignations(Map<String, List<dynamic>> grouped) {
//     List<String> order = [
//       "admin",
//       "doctor",
//       "assistant doctor",
//       "nurse",
//       "cashier",
//       "medical staff",
//       "lab technician",
//       "non-medical staff",
//     ];
//     List<String> keys = grouped.keys
//         .map((k) => order.contains(k) ? k : "")
//         .toSet()
//         .toList();
//     keys.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
//     return keys;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final groupedStaff = groupByDesignation();
//     final sortedKeys = getSortedDesignations(groupedStaff);
//
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(100),
//         child: Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFFBF955E),
//             borderRadius: const BorderRadius.only(
//               bottomLeft: Radius.circular(12),
//               bottomRight: Radius.circular(12),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   const Text(
//                     "Assign Duty",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 0.3,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : staff.isEmpty
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.group_off_outlined,
//                 size: 64,
//                 color: Colors.grey.shade400,
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 "No Staff Found",
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF444444),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Please add staff members first to assign role buttons and permissions.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                   height: 1.4,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       )
//           : ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: sortedKeys.length,
//         itemBuilder: (context, index) {
//           String designation = sortedKeys[index];
//           List<dynamic> users = groupedStaff[designation] ?? [];
//
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(
//                   left: 8,
//                   top: 20,
//                   bottom: 8,
//                 ),
//                 child: designation != 'Lab'
//                     ? Text(
//                   designation.toUpperCase(),
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF444444),
//                   ),
//                 )
//                     : const Text(
//                   'LAB TECHNICIAN',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF444444),
//                   ),
//                 ),
//               ),
//
//               // ---------- STAFF LIST ----------
//               ...users.map((user) {
//                 final specialist = (user["specialist"] ?? "").toString();
//
//                 // final filteredPermissions = permissions
//                 //     .where(
//                 //       (p) =>
//                 //           (p["designation"] ?? "").toString() ==
//                 //           designation,
//                 //     )
//                 //     .toList();
//
//                 final filteredPermissions = designation == "admin"
//                     ? permissions
//                     .where(
//                       (p) =>
//                   (p["designation"] ?? "").toString() ==
//                       "doctor",
//                 )
//                     .toList()
//                     : permissions
//                     .where(
//                       (p) =>
//                   (p["designation"] ?? "").toString() ==
//                       designation,
//                 )
//                     .toList();
//                 final filteredAdmins = staff
//                     .where(
//                       (u) =>
//                   (u["role"] ?? "").toString().toLowerCase() ==
//                       "admin",
//                 )
//                     .toList();
//                 final anyAdminAccessDoctorRole = staff.any(
//                       (u) =>
//                   (u["role"] ?? "").toString().toLowerCase() ==
//                       "admin" &&
//                       (u["accessDoctorRole"] ?? false) == true,
//                 );
//
//                 return StaffPermissionTile(
//                   id: user["id"],
//                   name: user["fullName"] ?? user["name"] ?? "Unnamed",
//                   designation: designation,
//                   specialist: specialist,
//                   permissions: filteredPermissions,
//                   assignedPermissionIds:
//                   user["assignedPermissionIds"], // 🔥 FIX
//                   doctorList: doctor, // ✅ ADD THIS
//                   adminList: filteredAdmins, // ✅ pass admin list
//                   assignedDoctorId: user["assignedDoctorId"], // ✅ ADD
//                   accessDoctorRole: designation == "admin"
//                       ? (user["accessDoctorRole"] ??
//                       false) // ✅ use individual value
//                       : anyAdminAccessDoctorRole, // for assistant doctor
//                   onAdminAccessChanged: () {
//                     setState(() {
//                       // 🔥 Update local staff data immediately
//                       user["accessDoctorRole"] =
//                       !user["accessDoctorRole"];
//                     });
//                   },
//                   // onAdminAccessChanged: () async {
//                   //   setState(() => loading = true);
//                   //   await loadData(); // 🔥 FULL REFRESH
//                   // },
//                 );
//               }),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
//
// // ===========================================================
// //  STAFF TILE WITH SWITCHES + SAVED STATE
// // ===========================================================
//
// class StaffPermissionTile extends StatefulWidget {
//   final int id;
//   final String name;
//   final String designation;
//   final String specialist;
//   final List<dynamic> permissions;
//   final List<dynamic> doctorList;
//   final String? assignedDoctorId;
//   final bool accessDoctorRole;
//   final List<dynamic> adminList; // new field
//   final VoidCallback onAdminAccessChanged;
//
//   // NEW FIELD
//   final List<int> assignedPermissionIds;
//
//   const StaffPermissionTile({
//     super.key,
//     required this.id,
//     required this.name,
//     required this.designation,
//     required this.specialist,
//     required this.permissions,
//     required this.assignedPermissionIds,
//     required this.doctorList,
//     this.assignedDoctorId,
//     required this.accessDoctorRole,
//     required this.adminList,
//     required this.onAdminAccessChanged,
//   });
//
//   @override
//   State<StaffPermissionTile> createState() => _StaffPermissionTileState();
// }
//
// class _StaffPermissionTileState extends State<StaffPermissionTile>
//     with SingleTickerProviderStateMixin {
//   Map<int, bool> toggles = {};
//   bool expanded = false;
//   late final AnimationController _controller;
//   late final Animation<double> _animation;
//   String? selectedDoctorId;
//   bool accessDoctorRole = false;
//
//   @override
//   void initState() {
//     super.initState();
//     buildToggleMap(); // 🔥 LOAD SAVED PERMISSIONS
//     // ✅ THIS FIXES YOUR ISSUE
//     if (widget.designation == "assistant doctor") {
//       selectedDoctorId = widget.assignedDoctorId;
//     }
//     // ✅ FIX: load saved accessDoctorRole
//     if (widget.designation == "admin") {
//       accessDoctorRole = widget.accessDoctorRole;
//     }
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
//   }
//
//   void buildToggleMap() {
//     toggles = {
//       for (var perm in widget.permissions)
//         perm["id"] as int: widget.assignedPermissionIds.contains(
//           perm["id"],
//         ), // 🔥 FIX
//     };
//   }
//
//   Future<void> updateToggle(int permId, bool value) async {
//     setState(() => toggles[permId] = value);
//
//     try {
//       List<int> enabledIds = toggles.entries
//           .where((e) => e.value)
//           .map((e) => e.key)
//           .toList();
//
//       await AdminService().updateAdminAmount(widget.id, {
//         "permissions": enabledIds,
//       });
//
//       // 🔥 UPDATE LOCAL STAFF PERMISSION LIST
//       widget.assignedPermissionIds
//         ..clear()
//         ..addAll(enabledIds);
//     } catch (e) {
//       setState(() => toggles[permId] = !value);
//     }
//   }
//
//   Future<void> updateDoctorSelection(String doctorId) async {
//     setState(() => selectedDoctorId = doctorId.isEmpty ? null : doctorId);
//
//     try {
//       print('selectedDoctorId $selectedDoctorId');
//       print('widget.id ${widget.id}');
//       await AdminService().updateAdminAmount(widget.id, {
//         "assignDoctorId": doctorId.isEmpty ? null : doctorId,
//       });
//     } catch (e) {
//       print('error $e');
//       setState(() => selectedDoctorId = null);
//     }
//   }
//
//   Future<void> updateDoctorAccess(bool value) async {
//     setState(() => accessDoctorRole = value);
//     print('accessDoctorRole $accessDoctorRole');
//     try {
//       await AdminService().updateAdminAmount(widget.id, {
//         "accessDoctorRole": value,
//       });
//       widget.onAdminAccessChanged();
//     } catch (e) {
//       setState(() => accessDoctorRole = !value);
//     }
//   }
//
//   void toggleExpand() {
//     setState(() {
//       expanded = !expanded;
//
//       if (expanded) {
//         buildToggleMap(); // 🔥 Refresh state when opening
//         _controller.forward();
//       } else {
//         _controller.reverse();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Card(
//           margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           elevation: 5,
//           shadowColor: Colors.black26,
//           child: Column(
//             children: [
//               InkWell(
//                 onTap: toggleExpand,
//                 borderRadius: BorderRadius.circular(16),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 14,
//                   ),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.orange.shade50, Colors.orange.shade100],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(16),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 22,
//                         backgroundColor: Colors.orange.shade300,
//                         child: Text(
//                           widget.name.isNotEmpty
//                               ? widget.name[0].toUpperCase()
//                               : "?",
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 14),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.name,
//                               style: const TextStyle(
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.bold,
//                                 color: Color(0xFF222222),
//                               ),
//                             ),
//                             if (widget.specialist.isNotEmpty)
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 2),
//                                 child: Text(
//                                   widget.specialist,
//                                   style: const TextStyle(
//                                     fontSize: 13,
//                                     fontStyle: FontStyle.italic,
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                       AnimatedRotation(
//                         turns: expanded ? 0.5 : 0.0,
//                         duration: const Duration(milliseconds: 300),
//                         child: const Icon(
//                           Icons.keyboard_arrow_down,
//                           color: Colors.grey,
//                           size: 28,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // ------------- EXPANDED PERMISSION LIST -------------
//               SizeTransition(
//                 sizeFactor: _animation,
//                 axisAlignment: -1.0,
//                 child: Container(
//                   width: double.infinity,
//                   margin: const EdgeInsets.symmetric(
//                     horizontal: 6,
//                     vertical: 8,
//                   ),
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 10,
//                     horizontal: 16,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(14),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Colors.black12,
//                         blurRadius: 6,
//                         offset: Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   // child: widget.designation == "assistant doctor"
//                   //     ? buildDoctorSelector()
//                   //     : buildPermissionToggles(),
//                   child: widget.designation == "assistant doctor"
//                       ? buildDoctorSelector()
//                       : widget.designation == "admin"
//                       ? buildAdminDoctorAccess()
//                       : buildPermissionToggles(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Widget buildDoctorSelector() {
//   //   if (widget.doctorList.isEmpty) {
//   //     return const Text(
//   //       "No doctors available",
//   //       style: TextStyle(color: Colors.redAccent),
//   //     );
//   //   }
//   //
//   //   return Column(
//   //     children: widget.doctorList.map((doc) {
//   //       final String docId = doc["user_Id"];
//   //       final bool isSelected = selectedDoctorId == docId;
//   //
//   //       return Padding(
//   //         padding: const EdgeInsets.symmetric(vertical: 6),
//   //         child: Row(
//   //           children: [
//   //             Expanded(
//   //               child: Column(
//   //                 crossAxisAlignment: CrossAxisAlignment.start,
//   //                 children: [
//   //                   Text(
//   //                     doc["name"] ?? "Doctor",
//   //                     style: const TextStyle(
//   //                       fontSize: 15,
//   //                       fontWeight: FontWeight.w600,
//   //                     ),
//   //                   ),
//   //                   Text(
//   //                     doc["specialist"] ?? "Doctor",
//   //                     style: const TextStyle(
//   //                       color: Colors.black54,
//   //                       fontStyle: FontStyle.italic,
//   //                       fontSize: 15,
//   //                       fontWeight: FontWeight.w400,
//   //                     ),
//   //                   ),
//   //                 ],
//   //               ),
//   //             ),
//   //             Switch(
//   //               value: isSelected,
//   //               activeColor: Colors.green,
//   //               inactiveThumbColor: Colors.redAccent,
//   //               onChanged: (val) {
//   //                 if (val) {
//   //                   updateDoctorSelection(docId);
//   //                 } else {
//   //                   updateDoctorSelection(""); // 🔥 clear selection
//   //                 }
//   //               },
//   //             ),
//   //           ],
//   //         ),
//   //       );
//   //     }).toList(),
//   //   );
//   // }
//
//   Widget buildDoctorSelector() {
//     if (widget.doctorList.isEmpty && widget.adminList.isEmpty) {
//       return const Text(
//         "No doctors available",
//         style: TextStyle(color: Colors.redAccent),
//       );
//     }
//
//     // Combine admin + doctor list if any admin has accessDoctorRole
//     // final List<dynamic> selectableDoctors = [
//     //   if (widget.accessDoctorRole) ...widget.adminList,
//     //   ...widget.doctorList,
//     // ];
//     final List<dynamic> selectableDoctors = [
//       ...widget.adminList.where(
//             (a) => a["accessDoctorRole"] == true,
//       ), // only admins with access
//       ...widget.doctorList,
//     ];
//
//     return Column(
//       children: selectableDoctors.map((doc) {
//         final String docId = doc["user_Id"];
//         final bool isSelected = selectedDoctorId == docId;
//
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       doc["name"] ?? "Doctor",
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     Text(
//                       doc["specialist"] ?? "",
//                       style: const TextStyle(
//                         color: Colors.black54,
//                         fontStyle: FontStyle.italic,
//                         fontSize: 15,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Switch(
//                 value: isSelected,
//                 activeColor: Colors.green,
//                 inactiveThumbColor: Colors.redAccent,
//                 onChanged: (val) {
//                   if (val) {
//                     updateDoctorSelection(docId);
//                   } else {
//                     updateDoctorSelection(""); // clear selection
//                   }
//                 },
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   Widget buildPermissionToggles() {
//     if (widget.permissions.isEmpty) {
//       return const Text(
//         "No button assigned for this staff",
//         style: TextStyle(color: Colors.redAccent),
//       );
//     }
//
//     return Column(
//       children: toggles.entries.map((entry) {
//         final permId = entry.key;
//         final enabled = entry.value;
//
//         final permKey = widget.permissions
//             .firstWhere((p) => p["id"] == permId)["key"]
//             .toString()
//             .toUpperCase();
//
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6),
//           child: Row(
//             children: [
//               Expanded(child: Text(permKey)),
//               Switch(
//                 value: enabled,
//                 activeColor: Colors.green,
//                 inactiveThumbColor: Colors.redAccent,
//                 onChanged: (val) => updateToggle(permId, val),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   Widget buildAdminDoctorAccess() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // ✅ Access toggle
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6),
//           child: Row(
//             children: [
//               const Expanded(
//                 child: Text(
//                   "ACCESS DOCTOR ROLE",
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//               ),
//               Switch(
//                 value: accessDoctorRole,
//                 activeColor: Colors.green,
//                 inactiveThumbColor: Colors.redAccent,
//                 onChanged: updateDoctorAccess,
//               ),
//             ],
//           ),
//         ),
//
//         // ✅ Show doctor permissions only if enabled
//         if (accessDoctorRole) ...[const Divider(), buildPermissionToggles()],
//       ],
//     );
//   }
// }
