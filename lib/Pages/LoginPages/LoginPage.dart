// // // import 'dart:async';
// // //
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter/services.dart';
// // // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// // // import 'package:intl/intl.dart';
// // // import '../../../Services/Doctor/doctor_service.dart';
// // // import '../../../Services/consultation_service.dart';
// // // import '../../../Services/patient_service.dart';
// // // import '../../../Services/payment_service.dart';
// // // import '../../../Widgets/AgeDobField.dart';
// // // import '../../../Pages/NotificationsPage.dart';
// // //
// // // const Color customGold = Color(0xFFBF955E);
// // // const Color backgroundColor = Color(0xFFF9F7F2);
// // //
// // // const List<String> genders = ['Male', 'Female', 'Other'];
// // // const List<String> bloodTypes = [
// // //   'A+',
// // //   'A-',
// // //   'B+',
// // //   'B-',
// // //   'AB+',
// // //   'AB-',
// // //   'O+',
// // //   'O-',
// // // ];
// // //
// // // const List<String> currentProblemSuggestions = [
// // //   'Fever with chills and body pain',
// // //   'Abdominal pain with vomiting',
// // //   'Cough and difficulty in breathing',
// // //   'Chest pain and dizziness',
// // //   'Headache and weakness',
// // //   'High blood sugar',
// // //   'Hypertension',
// // //   'Acute injury/fracture',
// // //   'Urinary infection symptoms',
// // //   'Rashes on skin',
// // // ];
// // //
// // // class IndianPhoneNumberFormatter extends TextInputFormatter {
// // //   static const String prefix = '+91 ';
// // //
// // //   @override
// // //   TextEditingValue formatEditUpdate(
// // //       TextEditingValue oldValue,
// // //       TextEditingValue newValue,
// // //       ) {
// // //     String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
// // //
// // //     if (digitsOnly.startsWith('91')) digitsOnly = digitsOnly.substring(2);
// // //     if (digitsOnly.length > 10) digitsOnly = digitsOnly.substring(0, 10);
// // //
// // //     final formatted = digitsOnly.isEmpty ? '' : '$prefix$digitsOnly';
// // //
// // //     int cursorPosition = formatted.length;
// // //     if (cursorPosition < prefix.length) cursorPosition = prefix.length;
// // //
// // //     return TextEditingValue(
// // //       text: formatted,
// // //       selection: TextSelection.collapsed(offset: cursorPosition),
// // //     );
// // //   }
// // // }
// // //
// // // class PatientRegistrationPage extends StatefulWidget {
// // //   const PatientRegistrationPage({super.key});
// // //   @override
// // //   State<PatientRegistrationPage> createState() =>
// // //       _PatientRegistrationPageState();
// // // }
// // //
// // // class _PatientRegistrationPageState extends State<PatientRegistrationPage> {
// // //   final PatientService patientService = PatientService();
// // //   final doctorService = DoctorService();
// // //   final consultationService = ConsultationService();
// // //   final paymentService = PaymentService();
// // //   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
// // //
// // //   final TextEditingController fullNameController = TextEditingController();
// // //   final TextEditingController AccompanierNameController =
// // //   TextEditingController();
// // //   final TextEditingController emailController = TextEditingController();
// // //   final TextEditingController guardianEmailController = TextEditingController();
// // //   final TextEditingController phoneController = TextEditingController();
// // //   final TextEditingController emergencyController = TextEditingController();
// // //   final TextEditingController AddressController = TextEditingController();
// // //   final TextEditingController cityController = TextEditingController();
// // //   final TextEditingController zipController = TextEditingController();
// // //   final TextEditingController dobController = TextEditingController();
// // //   final TextEditingController ageController = TextEditingController();
// // //   final TextEditingController doctorIdController = TextEditingController();
// // //   final TextEditingController doctorNameController = TextEditingController();
// // //   final TextEditingController departmentController = TextEditingController();
// // //   final TextEditingController ComplaintController = TextEditingController();
// // //   final TextEditingController DataTimeController = TextEditingController();
// // //   final TextEditingController currentProblemController =
// // //   TextEditingController();
// // //   final TextEditingController medicalHistoryController =
// // //   TextEditingController();
// // //   String? _dateTime;
// // //   String? selectedGender;
// // //   String? selectedBloodType;
// // //   bool showGuardianEmail = false;
// // //   String? medicalHistoryChoice; // 'Yes' or 'No'
// // //   bool isSubmitting = false;
// // //   bool formValidated = false;
// // //   bool phoneValid = true;
// // //   bool emergencyValid = true;
// // //   bool isLoadingDoctors = false;
// // //   bool showDoctorSection = false;
// // //   List<Map<String, dynamic>> allDoctors = [];
// // //   List<Map<String, dynamic>> filteredDoctors = [];
// // //   Map<String, dynamic>? selectedDoctor;
// // //   List<String> filteredProblemSuggestions = [];
// // //   void _showSnackBar(String msg) =>
// // //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchDoctors();
// // //     currentProblemController.addListener(_filterCurrentProblemSuggestions);
// // //     _updateTime();
// // //     Timer.periodic(const Duration(seconds: 60), (Timer t) => _updateTime());
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     currentProblemController.removeListener(_filterCurrentProblemSuggestions);
// // //     super.dispose();
// // //   }
// // //
// // //   void _updateTime() {
// // //     setState(() {
// // //       _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
// // //     });
// // //   }
// // //
// // //   void _filterCurrentProblemSuggestions() {
// // //     String input = currentProblemController.text.toLowerCase();
// // //     if (input.isEmpty) {
// // //       setState(() => filteredProblemSuggestions = []);
// // //       return;
// // //     }
// // //     final filtered = currentProblemSuggestions
// // //         .where((suggestion) => suggestion.toLowerCase().startsWith(input))
// // //         .toList();
// // //     setState(() => filteredProblemSuggestions = filtered);
// // //   }
// // //
// // //   void _onPhoneChanged(String value, void Function(bool) setValidity) {
// // //     String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
// // //     if (digitsOnly.startsWith('91')) digitsOnly = digitsOnly.substring(2);
// // //     setValidity(digitsOnly.length == 10);
// // //   }
// // //
// // //   Future<void> _fetchDoctors() async {
// // //     setState(() => isLoadingDoctors = true);
// // //     try {
// // //       final docs = await doctorService.getDoctors();
// // //       setState(() {
// // //         allDoctors = docs;
// // //         filteredDoctors = List.from(docs); // show all by default
// // //         showDoctorSection = true; // always show doctor list
// // //       });
// // //     } catch (e) {
// // //       _showSnackBar('Error loading doctors: $e');
// // //     } finally {
// // //       setState(() => isLoadingDoctors = false);
// // //     }
// // //   }
// // //
// // //   void _submitPatient() async {
// // //     setState(() {
// // //       formValidated = true;
// // //
// // //       String phoneDigits = phoneController.text.replaceAll(
// // //         RegExp(r'[^0-9]'),
// // //         '',
// // //       );
// // //       if (phoneDigits.startsWith('91')) phoneDigits = phoneDigits.substring(2);
// // //       phoneValid = phoneDigits.length == 10;
// // //     });
// // //
// // //     List<String> missingFields = [];
// // //     if (fullNameController.text.trim().isEmpty) missingFields.add("Full Name");
// // //     if (dobController.text.trim().isEmpty) missingFields.add("Date of Birth");
// // //     if (!phoneValid) missingFields.add("Phone Number (must be 10 digits)");
// // //     if (AddressController.text.trim().isEmpty) missingFields.add("Address");
// // //     if (selectedGender == null) missingFields.add("Gender");
// // //     if (doctorIdController.text.isEmpty) {
// // //       missingFields.add("Select Doctor");
// // //     }
// // //
// // //     if (missingFields.isNotEmpty) {
// // //       String msg =
// // //           "Please fill/complete the following required fields:\n• ${missingFields.join("\n• ")}";
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
// // //       );
// // //       return;
// // //     }
// // //     setState(() => isSubmitting = true);
// // //     try {
// // //       DateTime dob =
// // //           DateTime.tryParse(dobController.text) ?? DateTime(1990, 1, 1);
// // //
// // //       final cleanedMobile = phoneController.text.trim().replaceAll(
// // //         RegExp(r'^\+?91[\s-]*'),
// // //         '',
// // //       );
// // //
// // //       final userId = cleanedMobile;
// // //       final staffId = await secureStorage.read(key: 'userId');
// // //       final patientData = {
// // //         "name": fullNameController.text.trim(),
// // //         "ac_name": AccompanierNameController.text.trim(),
// // //         "staff_Id": staffId,
// // //         "phone": {
// // //           "mobile": phoneController.text.trim(),
// // //           "emergency": emergencyController.text.trim(),
// // //         },
// // //         "email": {
// // //           "personal": emailController.text.trim(),
// // //           "guardian": guardianEmailController.text.trim(),
// // //         },
// // //         "address": {"Address": AddressController.text.trim()},
// // //         "dob": dob.toUtc().toIso8601String(),
// // //         "gender": selectedGender,
// // //         "bldGrp": selectedBloodType,
// // //         "currentProblem": currentProblemController.text.trim(),
// // //         "createdAt": _dateTime.toString(),
// // //         "tempCreatedAt": DateTime.now().toUtc().toIso8601String(),
// // //       };
// // //
// // //       await patientService.createPatient(patientData);
// // //
// // //       final hospitalId = await doctorService.getHospitalId();
// // //       await consultationService.createConsultation({
// // //         "hospital_Id": hospitalId,
// // //         "patient_Id": userId,
// // //         "doctor_Id": doctorIdController.text,
// // //         "name": doctorNameController.text,
// // //         "purpose": ComplaintController.text,
// // //         "temperature": "NaN",
// // //         "createdAt": _dateTime.toString(),
// // //       });
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(SnackBar(content: Text('Patient Register Successfully!')));
// // //       Navigator.pop(context, true);
// // //     } catch (e) {
// // //
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(SnackBar(content: Text('Error: $e')));
// // //     } finally {
// // //       if (mounted) setState(() => isSubmitting = false);
// // //     }
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: backgroundColor,
// // //       appBar: _overviewAppBar(context),
// // //       body: SingleChildScrollView(
// // //         padding: const EdgeInsets.all(16),
// // //         child: Center(
// // //           child: ConstrainedBox(
// // //             constraints: const BoxConstraints(maxWidth: 700),
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 Container(
// // //                   padding: const EdgeInsets.symmetric(
// // //                     vertical: 16,
// // //                     horizontal: 12,
// // //                   ),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.white,
// // //                     borderRadius: BorderRadius.circular(14),
// // //                     boxShadow: [
// // //                       BoxShadow(
// // //                         color: Colors.grey.withOpacity(0.08),
// // //                         blurRadius: 12,
// // //                         offset: const Offset(2, 6),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   child: Wrap(
// // //                     spacing: 16,
// // //                     runSpacing: 16,
// // //                     children: [
// // //                       _buildInput(
// // //                         "Cell No *",
// // //                         phoneController,
// // //                         hint: "+911234567890",
// // //                         errorText: formValidatedErrorText(
// // //                           formValidated: formValidated,
// // //                           valid: phoneValid,
// // //                           errMsg: 'Enter valid 10 digit number',
// // //                         ),
// // //                         keyboardType: TextInputType.phone,
// // //                         onChanged: (val) => _onPhoneChanged(
// // //                           val,
// // //                               (valid) => setState(() => phoneValid = valid),
// // //                         ),
// // //                         inputFormatters: [
// // //                           FilteringTextInputFormatter.digitsOnly,
// // //                           IndianPhoneNumberFormatter(),
// // //                         ],
// // //                       ),
// // //                       _buildInput(
// // //                         "Name *",
// // //                         fullNameController,
// // //                         hint: "Enter full name",
// // //                       ),
// // //                       AgeDobField(
// // //                         dobController: dobController,
// // //                         ageController: ageController,
// // //                       ),
// // //                       _sectionLabel("Gender *"),
// // //                       Container(
// // //                         width: 320,
// // //                         margin: const EdgeInsets.only(bottom: 2),
// // //                         child: Row(
// // //                           children: genders
// // //                               .map(
// // //                                 (e) => _buildSelectionCard(
// // //                               label: e,
// // //                               selected: selectedGender == e,
// // //                               onTap: () =>
// // //                                   setState(() => selectedGender = e),
// // //                             ),
// // //                           )
// // //                               .toList(),
// // //                         ),
// // //                       ),
// // //                       _buildInput(
// // //                         "Address *",
// // //                         AddressController,
// // //                         maxLines: 3,
// // //                         hint: "Street address",
// // //                       ),
// // //                       _buildInput(
// // //                         "Chief Complaint *",
// // //                         ComplaintController,
// // //                         hint: "Enter full name",
// // //                       ),
// // //
// // //                       _sectionLabel("Available Doctors *"),
// // //                       if (showDoctorSection) ...[_buildDoctorList()],
// // //                     ],
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 28),
// // //                 SizedBox(
// // //                   width: double.infinity,
// // //                   height: 50,
// // //                   child: ElevatedButton(
// // //                     onPressed: isSubmitting ? null : _submitPatient,
// // //                     style: ElevatedButton.styleFrom(
// // //                       backgroundColor: customGold,
// // //                       shape: RoundedRectangleBorder(
// // //                         borderRadius: BorderRadius.circular(10),
// // //                       ),
// // //                       elevation: 1,
// // //                     ),
// // //                     child: isSubmitting
// // //                         ? const CircularProgressIndicator(
// // //                       color: Colors.white,
// // //                       strokeWidth: 2,
// // //                     )
// // //                         : const Text(
// // //                       "Register Patient",
// // //                       style: TextStyle(
// // //                         fontSize: 16,
// // //                         fontWeight: FontWeight.w600,
// // //                         color: Colors.white,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   String? formValidatedErrorText({
// // //     required bool formValidated,
// // //     required bool valid,
// // //     required String errMsg,
// // //   }) {
// // //     if (!formValidated) return null;
// // //     return valid ? null : errMsg;
// // //   }
// // //
// // //   Widget _buildInput(
// // //       String label,
// // //       TextEditingController controller, {
// // //         int maxLines = 1,
// // //         String? hint,
// // //         String? errorText,
// // //         TextInputType keyboardType = TextInputType.text,
// // //         void Function(String)? onChanged,
// // //         List<TextInputFormatter>? inputFormatters,
// // //       }) {
// // //     return SizedBox(
// // //       width: 320,
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Text(
// // //             label,
// // //             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
// // //           ),
// // //           const SizedBox(height: 6),
// // //           TextField(
// // //             controller: controller,
// // //             maxLines: maxLines,
// // //             keyboardType: keyboardType,
// // //             onChanged: onChanged,
// // //             inputFormatters: inputFormatters,
// // //             decoration: InputDecoration(
// // //               filled: true,
// // //               fillColor: Colors.grey[50],
// // //               hintText: hint,
// // //               hintStyle: TextStyle(color: Colors.grey[400]),
// // //               contentPadding: const EdgeInsets.symmetric(
// // //                 horizontal: 12,
// // //                 vertical: 13,
// // //               ),
// // //               enabledBorder: OutlineInputBorder(
// // //                 borderRadius: BorderRadius.circular(8),
// // //                 borderSide: BorderSide(
// // //                   color: errorText != null ? Colors.red : Colors.grey.shade300,
// // //                 ),
// // //               ),
// // //               focusedBorder: OutlineInputBorder(
// // //                 borderRadius: BorderRadius.circular(8),
// // //                 borderSide: BorderSide(
// // //                   color: errorText != null ? Colors.red : customGold,
// // //                   width: 1.5,
// // //                 ),
// // //               ),
// // //               errorText: errorText,
// // //               errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
// // //             ),
// // //             style: const TextStyle(fontSize: 15),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildDoctorList() {
// // //     if (isLoadingDoctors) {
// // //       return const Center(child: CircularProgressIndicator());
// // //     }
// // //
// // //     if (filteredDoctors.isEmpty) {
// // //       return const Text('No available doctors for this complaint');
// // //     }
// // //
// // //     return SizedBox(
// // //       height: 100,
// // //       child: ListView.builder(
// // //         scrollDirection: Axis.horizontal,
// // //         itemCount: filteredDoctors.length,
// // //         itemBuilder: (_, i) {
// // //           final doc = filteredDoctors[i];
// // //           final isSelected =
// // //               selectedDoctor != null && selectedDoctor!['id'] == doc['id'];
// // //
// // //           return GestureDetector(
// // //             onTap: () {
// // //               setState(() {
// // //                 selectedDoctor = doc;
// // //                 doctorIdController.text = doc['id'].toString(); // ✅ added
// // //                 doctorNameController.text = doc['name']; // ✅ added
// // //                 departmentController.text = doc['department']; // ✅ optional
// // //               });
// // //             },
// // //             child: Container(
// // //               width: 120,
// // //               margin: const EdgeInsets.all(8),
// // //               padding: const EdgeInsets.all(10),
// // //               decoration: BoxDecoration(
// // //                 color: isSelected ? customGold.withOpacity(0.25) : Colors.white,
// // //                 border: Border.all(
// // //                   color: isSelected ? customGold : Colors.grey.shade300,
// // //                   width: isSelected ? 2 : 1,
// // //                 ),
// // //                 borderRadius: BorderRadius.circular(12),
// // //                 boxShadow: [
// // //                   BoxShadow(
// // //                     color: Colors.grey.withOpacity(0.1),
// // //                     blurRadius: 4,
// // //                     offset: const Offset(1, 2),
// // //                   ),
// // //                 ],
// // //               ),
// // //               child: Column(
// // //                 mainAxisAlignment: MainAxisAlignment.center,
// // //                 children: [
// // //                   Text(
// // //                     doc['name'],
// // //                     textAlign: TextAlign.center,
// // //                     style: const TextStyle(
// // //                       fontWeight: FontWeight.w600,
// // //                       fontSize: 14,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 6),
// // //                   Text(
// // //                     doc['department'],
// // //                     textAlign: TextAlign.center,
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
// // //   Widget _buildDatePickerField(
// // //       BuildContext context,
// // //       String label,
// // //       TextEditingController controller,
// // //       ) {
// // //     return SizedBox(
// // //       width: 320,
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Text(
// // //             label,
// // //             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
// // //           ),
// // //           const SizedBox(height: 6),
// // //           GestureDetector(
// // //             onTap: () async {
// // //               DateTime? pickedDate = await showDatePicker(
// // //                 context: context,
// // //                 initialDate: DateTime(1990),
// // //                 firstDate: DateTime(1900),
// // //                 lastDate: DateTime.now(),
// // //               );
// // //               if (pickedDate != null) {
// // //                 controller.text =
// // //                 "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
// // //               }
// // //             },
// // //             child: AbsorbPointer(
// // //               child: TextField(
// // //                 controller: controller,
// // //                 decoration: InputDecoration(
// // //                   hintText: "YYYY-MM-DD",
// // //                   suffixIcon: const Icon(Icons.calendar_today, size: 20),
// // //                   filled: true,
// // //                   fillColor: Colors.grey[50],
// // //                   contentPadding: const EdgeInsets.symmetric(
// // //                     horizontal: 12,
// // //                     vertical: 12,
// // //                   ),
// // //                   enabledBorder: OutlineInputBorder(
// // //                     borderRadius: BorderRadius.circular(8),
// // //                     borderSide: BorderSide(color: Colors.grey.shade300),
// // //                   ),
// // //                   focusedBorder: OutlineInputBorder(
// // //                     borderRadius: BorderRadius.all(Radius.circular(8)),
// // //                     borderSide: BorderSide(color: customGold, width: 1.5),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildSelectionCard({
// // //     required String label,
// // //     required bool selected,
// // //     required VoidCallback onTap,
// // //   }) {
// // //     return GestureDetector(
// // //       onTap: onTap,
// // //       child: Container(
// // //         margin: const EdgeInsets.symmetric(horizontal: 5),
// // //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// // //         decoration: BoxDecoration(
// // //           color: selected ? customGold : Colors.white,
// // //           borderRadius: BorderRadius.circular(10),
// // //           border: Border.all(
// // //             color: selected ? customGold : Colors.grey.shade300,
// // //             width: 1.5,
// // //           ),
// // //           boxShadow: [
// // //             if (selected)
// // //               const BoxShadow(
// // //                 color: Colors.black12,
// // //                 blurRadius: 3,
// // //                 offset: Offset(0, 1),
// // //               ),
// // //           ],
// // //         ),
// // //         child: Text(
// // //           label,
// // //           style: TextStyle(
// // //             color: selected ? Colors.white : Colors.black87,
// // //             fontWeight: FontWeight.w600,
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _sectionLabel(String text) => Padding(
// // //     padding: const EdgeInsets.only(top: 12, bottom: 2),
// // //     child: Text(
// // //       text,
// // //       style: TextStyle(
// // //         fontWeight: FontWeight.w600,
// // //         color: Colors.grey[800],
// // //         fontSize: 18,
// // //         letterSpacing: 0.1,
// // //       ),
// // //     ),
// // //   );
// // //
// // //   PreferredSize _overviewAppBar(BuildContext context) => PreferredSize(
// // //     preferredSize: const Size.fromHeight(100),
// // //     child: Container(
// // //       height: 100,
// // //       decoration: const BoxDecoration(
// // //         color: customGold,
// // //         borderRadius: BorderRadius.only(
// // //           bottomLeft: Radius.circular(12),
// // //           bottomRight: Radius.circular(12),
// // //         ),
// // //         boxShadow: [
// // //           BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
// // //         ],
// // //       ),
// // //       child: SafeArea(
// // //         child: Padding(
// // //           padding: const EdgeInsets.symmetric(horizontal: 12),
// // //           child: Row(
// // //             children: [
// // //               IconButton(
// // //                 icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
// // //                 onPressed: () => Navigator.pop(context),
// // //               ),
// // //               const Text(
// // //                 'Patient Registration',
// // //                 style: TextStyle(
// // //                   color: Colors.white,
// // //                   fontWeight: FontWeight.w600,
// // //                   fontSize: 24,
// // //                 ),
// // //               ),
// // //               const Spacer(),
// // //               IconButton(
// // //                 icon: const Icon(Icons.notifications, color: Colors.white),
// // //                 onPressed: () => Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(builder: (_) => const NotificationPage()),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     ),
// // //   );
// // // }
// // // import 'package:flutter/material.dart';
// // // import '../../../../Pages/NotificationsPage.dart';
// // // import 'doctor_scan_page.dart';
// // // import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// // //
// // // class ScanningPage extends StatelessWidget {
// // //   final Map<String, dynamic> consultation;
// // //   const ScanningPage({super.key, required this.consultation});
// // //
// // //   final Color primaryColor = const Color(0xFFBF955E);
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final scans = [
// // //       {'name': 'X-Ray', 'icon': FontAwesomeIcons.xRay, 'color': Colors.indigo},
// // //       {
// // //         'name': 'CT-Scan',
// // //         'icon': FontAwesomeIcons.brain,
// // //         'color': Colors.deepOrange,
// // //       },
// // //       {
// // //         'name': 'MRI-Scan',
// // //         'icon': FontAwesomeIcons.diagnoses,
// // //         'color': Colors.purple,
// // //       },
// // //       {
// // //         'name': 'EEG',
// // //         'icon': FontAwesomeIcons.waveSquare,
// // //         'color': Colors.green,
// // //       },
// // //       {'name': 'Bone Scan', 'icon': FontAwesomeIcons.bone, 'color': Colors.red},
// // //       {
// // //         'name': 'PET Scan',
// // //         'icon': FontAwesomeIcons.radiation,
// // //         'color': Colors.teal,
// // //       },
// // //     ];
// // //
// // //     return Scaffold(
// // //       appBar: PreferredSize(
// // //         preferredSize: const Size.fromHeight(100),
// // //         child: Container(
// // //           height: 100,
// // //           decoration: BoxDecoration(
// // //             color: primaryColor,
// // //             borderRadius: const BorderRadius.only(
// // //               bottomLeft: Radius.circular(18),
// // //               bottomRight: Radius.circular(18),
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
// // //                     "View Scanning",
// // //                     style: TextStyle(
// // //                       color: Colors.white,
// // //                       fontSize: 22,
// // //                       fontWeight: FontWeight.bold,
// // //                       letterSpacing: 0.5,
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
// // //       body: Padding(
// // //         padding: const EdgeInsets.all(16.0),
// // //         child: GridView.builder(
// // //           itemCount: scans.length,
// // //           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// // //             crossAxisCount: 2,
// // //             crossAxisSpacing: 16,
// // //             mainAxisSpacing: 16,
// // //             childAspectRatio: 1,
// // //           ),
// // //           itemBuilder: (context, index) {
// // //             final scan = scans[index];
// // //             return InkWell(
// // //               onTap: () {
// // //                 Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(
// // //                     builder: (_) => DoctorScanPage(
// // //                       consultation: consultation,
// // //                       scanName: scan['name'] as String,
// // //                     ),
// // //                   ),
// // //                 );
// // //               },
// // //               child: Container(
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.white,
// // //                   borderRadius: BorderRadius.circular(16),
// // //                   boxShadow: [
// // //                     BoxShadow(
// // //                       color: (scan['color'] as Color).withOpacity(0.2),
// // //                       blurRadius: 6,
// // //                       offset: const Offset(0, 3),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 child: Column(
// // //                   mainAxisAlignment: MainAxisAlignment.center,
// // //                   children: [
// // //                     Container(
// // //                       decoration: BoxDecoration(
// // //                         shape: BoxShape.circle,
// // //                         color: (scan['color'] as Color).withOpacity(0.1),
// // //                       ),
// // //                       padding: const EdgeInsets.all(20),
// // //                       child: Icon(
// // //                         scan['icon'] as IconData,
// // //                         size: 35,
// // //                         color: scan['color'] as Color,
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 12),
// // //                     Text(
// // //                       scan['name'] as String,
// // //                       textAlign: TextAlign.center,
// // //                       style: const TextStyle(
// // //                         fontSize: 16,
// // //                         fontWeight: FontWeight.w600,
// // //                         color: Color(0xFF333333),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             );
// // //           },
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // // finance_page.dart
// //
// // import 'package:flutter/material.dart';
// // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// // import 'package:intl/intl.dart';
// //
// // import '../../../Mediacl_Staff/Pages/OutPatient/Page/InjectionPage.dart';
// // import '../../../Pages/NotificationsPage.dart';
// // import '../../../Services/payment_service.dart';
// // import '../../Widgets/AccountSummeryCard.dart';
// // import '../../Widgets/AccountsLIstview.dart';
// //
// // enum FinanceFilter { all, register, medical, test, scan }
// //
// // class FinancePage extends StatefulWidget {
// //   const FinancePage({super.key});
// //
// //   @override
// //   State<FinancePage> createState() => _FinancePageState();
// // }
// //
// // class _FinancePageState extends State<FinancePage> {
// //   final secureStorage = const FlutterSecureStorage();
// //   final PaymentService _api = PaymentService();
// //
// //   String? hospitalName;
// //   String? hospitalPlace;
// //   String? hospitalPhoto;
// //
// //   bool _loading = false;
// //   String? _error;
// //
// //   List<Map<String, dynamic>> _allPayments = [];
// //   List<Map<String, dynamic>> _visiblePayments = [];
// //
// //   FinanceFilter _selectedFilter = FinanceFilter.all;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadHospitalInfo();
// //     _fetchTodaysPayments();
// //   }
// //
// //   // ------------------------------
// //   // LOAD HOSPITAL FROM STORAGE
// //   Future<void> _loadHospitalInfo() async {
// //     hospitalName = await secureStorage.read(key: 'hospitalName') ?? "Unknown";
// //     hospitalPlace = await secureStorage.read(key: 'hospitalPlace') ?? "Unknown";
// //     hospitalPhoto =
// //         await secureStorage.read(key: 'hospitalPhoto') ??
// //             "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
// //
// //     setState(() {});
// //   }
// //
// //   // ------------------------------
// //   // FETCH TODAY PAYMENTS ONLY
// //   Future<void> _fetchTodaysPayments() async {
// //     setState(() {
// //       _loading = true;
// //       _error = null;
// //     });
// //
// //     try {
// //       final list = await _api.getAllPaidShowAccounts();
// //
// //       final today = DateFormat("yyyy-MM-dd").format(DateTime.now());
// //
// //       _allPayments = list
// //           .where((p) {
// //         final created = p['createdAt']?.toString() ?? "";
// //         return created.contains(today);
// //       })
// //           .map((e) => Map<String, dynamic>.from(e))
// //           .toList();
// //
// //       _applyFilter();
// //     } catch (e) {
// //       _error = e.toString();
// //     }
// //
// //     setState(() {
// //       _loading = false;
// //     });
// //   }
// //
// //   // ------------------------------
// //   // FILTER LOGIC
// //   void _applyFilter() {
// //     List<Map<String, dynamic>> filtered = [];
// //
// //     switch (_selectedFilter) {
// //       case FinanceFilter.all:
// //         filtered = _allPayments;
// //         break;
// //
// //       case FinanceFilter.register:
// //         filtered = _allPayments
// //             .where(
// //               (p) => (p['type']?.toString().toUpperCase() == "REGISTRATIONFEE"),
// //         )
// //             .toList();
// //         break;
// //
// //       case FinanceFilter.medical:
// //         filtered = _allPayments
// //             .where(
// //               (p) =>
// //           p['type']?.toString().toUpperCase() ==
// //               "MEDICINETONICINJECTIONFEES",
// //         )
// //             .toList();
// //         break;
// //
// //       case FinanceFilter.test:
// //         filtered = _allPayments.where((p) {
// //           if (p['type']?.toString().toUpperCase() !=
// //               "TESTINGFEESANDSCANNINGFEE")
// //             return false;
// //
// //           final items = p['TestingAndScanningPatients'] ?? [];
// //           return items.any(
// //                 (it) =>
// //             it['type']?.toString().toLowerCase() == "tests" ||
// //                 it['type']?.toString().toLowerCase() == "test",
// //           );
// //         }).toList();
// //         break;
// //
// //       case FinanceFilter.scan:
// //         filtered = _allPayments.where((p) {
// //           if (p['type']?.toString().toUpperCase() !=
// //               "TESTINGFEESANDSCANNINGFEE")
// //             return false;
// //
// //           final items = p['TestingAndScanningPatients'] ?? [];
// //           return items.any(
// //                 (it) =>
// //             it['type']?.toString().toLowerCase() == "scan" ||
// //                 it['type']?.toString().toLowerCase() == "scans",
// //           );
// //         }).toList();
// //         break;
// //     }
// //
// //     setState(() => _visiblePayments = filtered);
// //   }
// //
// //   // ------------------------------
// //   // UI BUILD
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFFFF7E6),
// //       appBar: _buildAppBar(),
// //       body: RefreshIndicator(
// //         onRefresh: _fetchTodaysPayments,
// //         child: SingleChildScrollView(
// //           physics: const AlwaysScrollableScrollPhysics(),
// //           padding: const EdgeInsets.all(16),
// //           child: Column(
// //             children: [
// //               _buildHospitalCard(),
// //               const SizedBox(height: 14),
// //               _buildFilterRow(),
// //               const SizedBox(height: 14),
// //               buildSummaryCard(allPayments: _visiblePayments),
// //               const SizedBox(height: 14),
// //
// //               if (_loading)
// //                 const Padding(
// //                   padding: EdgeInsets.all(20),
// //                   child: CircularProgressIndicator(),
// //                 ),
// //
// //               if (_error != null) _buildErrorCard(),
// //
// //               if (!_loading && _error == null)
// //                 buildPaymentsList(visiblePayments: _visiblePayments),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ------------------------------
// //   PreferredSizeWidget _buildAppBar() {
// //     return PreferredSize(
// //       preferredSize: const Size.fromHeight(100),
// //       child: Container(
// //         height: 100,
// //         decoration: BoxDecoration(
// //           color: primaryColor,
// //           borderRadius: const BorderRadius.only(
// //             bottomLeft: Radius.circular(18),
// //             bottomRight: Radius.circular(18),
// //           ),
// //           boxShadow: [
// //             BoxShadow(
// //               color: Colors.black.withOpacity(0.15),
// //               blurRadius: 6,
// //               offset: const Offset(0, 3),
// //             ),
// //           ],
// //         ),
// //         child: SafeArea(
// //           child: Padding(
// //             padding: const EdgeInsets.symmetric(horizontal: 16),
// //             child: Row(
// //               children: [
// //                 IconButton(
// //                   icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
// //                   onPressed: () => Navigator.pop(context),
// //                 ),
// //                 const Text(
// //                   " Accounts",
// //                   style: TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 22,
// //                     fontWeight: FontWeight.bold,
// //                     letterSpacing: 0.5,
// //                   ),
// //                 ),
// //                 const Spacer(),
// //                 // IconButton(
// //                 //   icon: const Icon(Icons.notifications, color: Colors.white),
// //                 //   onPressed: () {
// //                 //     Navigator.push(
// //                 //       context,
// //                 //       MaterialPageRoute(
// //                 //         builder: (_) => const NotificationPage(),
// //                 //       ),
// //                 //     );
// //                 //   },
// //                 // ),
// //                 IconButton(
// //                   icon: const Icon(Icons.home, color: Colors.white),
// //                   onPressed: () {
// //                     Navigator.push(
// //                       context,
// //                       MaterialPageRoute(
// //                         builder: (_) => const NotificationPage(),
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ------------------------------
// //   Widget _buildHospitalCard() {
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         gradient: const LinearGradient(
// //           colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
// //         ),
// //         borderRadius: BorderRadius.circular(20),
// //       ),
// //       child: Row(
// //         children: [
// //           ClipRRect(
// //             borderRadius: BorderRadius.circular(50),
// //             child: Image.network(
// //               hospitalPhoto ?? "",
// //               height: 60,
// //               width: 60,
// //               fit: BoxFit.cover,
// //               errorBuilder: (_, __, ___) => const Icon(
// //                 Icons.local_hospital,
// //                 color: Colors.white,
// //                 size: 55,
// //               ),
// //             ),
// //           ),
// //           const SizedBox(width: 12),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   hospitalName ?? "",
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 18,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   hospitalPlace ?? "",
// //                   style: const TextStyle(color: Colors.white70),
// //                 ),
// //                 // const SizedBox(height: 4),
// //                 // const Text(
// //                 //   "Showing today's payments",
// //                 //   style: TextStyle(color: Colors.white70, fontSize: 12),
// //                 // ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ------------------------------
// //   Widget _buildFilterRow() {
// //     final row1 = {
// //       FinanceFilter.all: "All",
// //       FinanceFilter.register: "Registration",
// //       FinanceFilter.medical: "Medical",
// //     };
// //
// //     final row2 = {FinanceFilter.test: "Test", FinanceFilter.scan: "Scan"};
// //
// //     Widget buildChip(FinanceFilter key, String label) {
// //       final selected = _selectedFilter == key;
// //
// //       return AnimatedContainer(
// //         duration: const Duration(milliseconds: 250),
// //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //         decoration: BoxDecoration(
// //           gradient: selected
// //               ? const LinearGradient(
// //             colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
// //           )
// //               : null,
// //           color: selected ? null : Colors.white,
// //           borderRadius: BorderRadius.circular(30),
// //           boxShadow: [
// //             if (selected)
// //               BoxShadow(
// //                 color: Colors.brown.withOpacity(0.3),
// //                 blurRadius: 6,
// //                 offset: const Offset(0, 3),
// //               ),
// //           ],
// //           border: Border.all(
// //             color: selected ? Colors.transparent : Colors.brown.shade300,
// //           ),
// //         ),
// //         child: Center(
// //           child: Text(
// //             label,
// //             style: TextStyle(
// //               fontWeight: FontWeight.w600,
// //               color: selected ? Colors.white : Colors.brown,
// //             ),
// //           ),
// //         ),
// //       );
// //     }
// //
// //     return Column(
// //       children: [
// //         // ---------- FIRST ROW ----------
// //         Row(
// //           children: row1.entries.map((e) {
// //             return Expanded(
// //               child: Padding(
// //                 padding: const EdgeInsets.only(right: 8.0),
// //                 child: GestureDetector(
// //                   onTap: () {
// //                     setState(() {
// //                       _selectedFilter = e.key;
// //                       _applyFilter();
// //                     });
// //                   },
// //                   child: buildChip(e.key, e.value),
// //                 ),
// //               ),
// //             );
// //           }).toList(),
// //         ),
// //
// //         const SizedBox(height: 12),
// //
// //         // ---------- SECOND ROW (Equal width) ----------
// //         Row(
// //           children: row2.entries.map((e) {
// //             return Expanded(
// //               child: Padding(
// //                 padding: const EdgeInsets.only(right: 8.0),
// //                 child: GestureDetector(
// //                   onTap: () {
// //                     setState(() {
// //                       _selectedFilter = e.key;
// //                       _applyFilter();
// //                     });
// //                   },
// //                   child: buildChip(e.key, e.value),
// //                 ),
// //               ),
// //             );
// //           }).toList(),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   // ------------------------------
// //   //Error card
// //   Widget _buildErrorCard() {
// //     return Container(
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: Colors.red.shade50,
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Row(
// //         children: [
// //           const Icon(Icons.error, color: Colors.red),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: Text(_error!, style: const TextStyle(color: Colors.red)),
// //           ),
// //           TextButton(
// //             onPressed: _fetchTodaysPayments,
// //             child: const Text("Retry"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import '../Pages/Accounts/FinancePage.dart';
//
// String getDisplayType(Map<String, dynamic> payment) {
//   if (payment['type'] != null) {
//     final type = payment['type'].toString().toUpperCase();
//     if (type == "TESTINGFEESANDSCANNINGFEE") {
//       final patients = payment['TestingAndScanningPatients'] as List? ?? [];
//       final typesSet = patients.map((e) => e['type'].toString().toUpperCase()).toSet();
//       if (typesSet.length == 1) return typesSet.first;  // "TEST" or "SCAN"
//       if (typesSet.length > 1) return "TEST + SCAN";
//     }
//     return type;
//   }
//   return "UNKNOWN";
// }
//
// Widget buildSummaryCard({
//   FinanceFilter? filter,
//   required List<Map<String, dynamic>> allPayments,
// }) {
//   const breakdownData = {
//     "register": {
//       "type": "REGISTRATIONFEE",
//       "color": Color(0xFFD6F5D6),
//       "icon": Icons.how_to_reg,
//     },
//     "medical": {
//       "type": "MEDICINETONICINJECTIONFEES",
//       "color": Color(0xFFFFD6E7),
//       "icon": Icons.medical_services,
//     },
//     "test": {
//       "type": "TEST",
//       "color": Color(0xFFD6E8FF),
//       "icon": Icons.science,
//     },
//     "scan": {
//       "type": "SCAN",
//       "color": Color(0xFFD6FFFF),
//       "icon": Icons.scanner,
//     },
//   };
//
//   double getTotal(List<Map<String, dynamic>> payments) {
//     return payments.fold(0.0, (sum, p) {
//       final amount = p['amount'];
//       if (amount is num) return sum + amount.toDouble();
//       if (amount is String) return sum + (double.tryParse(amount) ?? 0.0);
//       return sum;
//     });
//   }
//
//   String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
//
//   List<Widget> categoryCards = [];
//   if (filter == null || filter == FinanceFilter.all) {
//     // Show all categories
//     breakdownData.forEach((key, data) {
//       final payments = allPayments.where(
//             (p) => getDisplayType(p).toLowerCase() == (data['type'] as String).toLowerCase(),
//       ).toList();
//       final total = getTotal(payments);
//       if (total > 0) {
//         categoryCards.add(_buildCollectionCard(
//           capitalize(key),
//           total,
//           data['color'] as Color,
//           data['icon'] as IconData,
//         ));
//       }
//     });
//   } else {
//     // Show only selected category full width
//     final typeKey = filter.name.toLowerCase();
//     if (breakdownData.containsKey(typeKey)) {
//       final data = breakdownData[typeKey]!;
//       final payments = allPayments.where(
//             (p) => getDisplayType(p).toLowerCase() == (data['type'] as String).toLowerCase(),
//       ).toList();
//       final total = getTotal(payments);
//       if (total > 0) {
//         categoryCards.add(_buildCollectionCard(
//           capitalize(typeKey),
//           total,
//           data['color'] as Color,
//           data['icon'] as IconData,
//           fullWidth: true,
//         ));
//       }
//     }
//   }
//
//   final totalCollection = getTotal(allPayments);
//
//   return Container(
//     width: double.infinity,
//     padding: const EdgeInsets.all(20),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(20),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.08),
//           blurRadius: 16,
//           offset: const Offset(0, 6),
//         ),
//       ],
//       border: Border.all(
//         color: const Color(0xFFC59A62).withOpacity(0.25),
//         width: 1.2,
//       ),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
//             ),
//             borderRadius: BorderRadius.circular(14),
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.assessment, color: Colors.white, size: 24),
//               const SizedBox(width: 10),
//               Text(
//                 filter == null || filter == FinanceFilter.all
//                     ? "Today's Summary"
//                     : "${capitalize(filter.name)} Collection",
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w700,
//                   color: Colors.white,
//                   fontSize: 15,
//                 ),
//               ),
//               const Spacer(),
//               CircleAvatar(
//                 radius: 14,
//                 backgroundColor: Colors.white.withOpacity(0.2),
//                 child: Text(
//                   "${categoryCards.length + ((filter == null || filter == FinanceFilter.all) ? 1 : 0)}",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 20),
//         // Total collection card shown only in "all" tab
//         if (filter == null || filter == FinanceFilter.all) ...[
//           _buildCollectionCard(
//             "Total Collection",
//             totalCollection,
//             Colors.green,
//             Icons.currency_rupee,
//             fullWidth: true,
//           ),
//           const SizedBox(height: 16),
//         ],
//         // Category cards
//         if (categoryCards.isNotEmpty) ...[
//           LayoutBuilder(
//             builder: (context, constraints) {
//               final cardWidth = (filter == null || filter == FinanceFilter.all)
//                   ? (constraints.maxWidth - 12) / 2
//                   : double.infinity;
//               return Wrap(
//                 spacing: 12,
//                 runSpacing: 12,
//                 children: categoryCards
//                     .map((card) => SizedBox(width: cardWidth, child: card))
//                     .toList(),
//               );
//             },
//           ),
//         ],
//       ],
//     ),
//   );
// }
//
// // Single collection card widget
// Widget _buildCollectionCard(
//     String title,
//     double amount,
//     Color color,
//     IconData icon, {
//       bool fullWidth = false,
//     }) {
//   return Container(
//     width: fullWidth ? double.infinity : 160,
//     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//     decoration: BoxDecoration(
//       color: color.withOpacity(0.3),
//       borderRadius: BorderRadius.circular(16),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.05),
//           blurRadius: 8,
//           offset: const Offset(0, 3),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(icon, color: Colors.white, size: 18),
//         ),
//         const SizedBox(width: 10),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey.shade700,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               "₹ ${amount.toStringAsFixed(1)}",
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// final DateFormat backendFormat = DateFormat("yyyy-MM-dd hh:mm a");
// // ------------------------------
// // DATE PARSER HANDLER
// DateTime? parseDate(String raw) {
//   try {
//     return backendFormat.parse(raw);
//   } catch (_) {
//     try {
//       return DateTime.parse(raw);
//     } catch (_) {}
//   }
//   return null;
// }
//
// // ------------------------------
// Widget buildPaymentsList({
//   required List<Map<String, dynamic>> visiblePayments,
// }) {
//   if (visiblePayments.isEmpty) {
//     return const Padding(
//       padding: EdgeInsets.all(20),
//       child: Text(
//         "No Payments Found Today",
//         style: TextStyle(color: Colors.black45),
//       ),
//     );
//   }
//
//   // FULL CARD BACKGROUND COLOR
//   Color getCardColor(String type) {
//     switch (type) {
//       case "REGISTRATIONFEE":
//         return const Color(0xFFE8FBE8); // light green
//       case "MEDICINETONICINJECTIONFEES":
//         return const Color(0xFFFFE6F1); // soft pink
//       case "TEST":
//         return const Color(0xFFE9F1FF); // soft light blue
//       case "SCAN":
//         return const Color(0xFFE6FFFF); // light cyan
//       case "TEST + SCAN":
//         return const Color(0xFFE6F7FF); // soft dual tone
//       default:
//         return Colors.grey.shade100;
//     }
//   }
//
//   String getDisplayType(dynamic p) {
//     String type = p['type'] ?? "";
//
//     if (type == "TESTINGFEESANDSCANNINGFEE") {
//       if (p['TestingAndScanningPatients'] != null &&
//           p['TestingAndScanningPatients'].isNotEmpty) {
//         final set = p['TestingAndScanningPatients']
//             .map((e) => e['type'].toString().toUpperCase())
//             .toSet();
//
//         if (set.length == 1) return set.first;
//         return "TEST + SCAN";
//       }
//     }
//
//     return type;
//   }
//
//   return ListView.separated(
//     shrinkWrap: true,
//     physics: const NeverScrollableScrollPhysics(),
//     itemCount: visiblePayments.length,
//     separatorBuilder: (_, __) => const SizedBox(height: 14),
//     itemBuilder: (context, i) {
//       final p = visiblePayments[i];
//
//       final dt = parseDate(p['createdAt'] ?? "");
//       final time = dt != null
//           ? DateFormat("hh:mm a").format(dt)
//           : p['createdAt'];
//
//       final patient = p['Patient']?['name'] ?? '-';
//       final patientId = p['Patient']?['user_Id'] ?? '-';
//       final displayType = getDisplayType(p);
//       final bgColor = getCardColor(displayType);
//
//       final double amount = (p['amount'] is num)
//           ? p['amount'].toDouble()
//           : double.tryParse("${p['amount']}") ?? 0.0;
//
//       return Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: bgColor,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.06),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // ---------- Left Section: Patient Info ----------
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Patient Name
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.person_outline,
//                         size: 18,
//                         color: Colors.grey.shade800,
//                       ),
//                       const SizedBox(width: 6),
//                       Expanded(
//                         child: Text(
//                           patient,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 15,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   // Patient ID
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.perm_identity,
//                         size: 16,
//                         color: Colors.grey.shade700,
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         patientId,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   // Time
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.access_time,
//                         size: 16,
//                         color: Colors.grey.shade700,
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         time,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           color: Colors.black54,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(width: 12),
//
//             // ---------- Right Section: Amount + Type Badge ----------
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.7),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     displayType,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 13,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   "₹ ${amount.toStringAsFixed(1)}",
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 22,
//                     color: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// import '../../Admin/Appbar/admin_appbar_desktop.dart';
// import '../../Admin/Pages/AddingPage.dart';
// import '../../Admin/Pages/AdminDashboardPage.dart';
// import '../../Admin/Pages/AdminOverviewPage.dart';
// import '../../Drawer/MedicalStaffDrawer.dart';
// import '../../Mediacl_Staff/Appbar/MedicalStaffAppbarMobile.dart';
//
// // === Doctor Pages ===
// import '../../Mediacl_Staff/Pages/Doctor/pages/DoctorOverviewPage.dart';
// import '../../Mediacl_Staff/Pages/Doctor/pages/DrOpDashboard/AssistantDrOpDashboard.dart';
// import '../../Mediacl_Staff/Pages/Doctor/pages/DrOpDashboard/DrOpDashboardPage.dart';
//
// // === Other Roles ===
// import '../../Mediacl_Staff/Pages/Dashboard/OpDashboard.dart';
// import '../../Mediacl_Staff/Pages/Dashboard/CashierDashboard.dart';
// import '../../Mediacl_Staff/Pages/Dashboard/LabDashboard.dart';
// import '../../Mediacl_Staff/Pages/Dashboard/MedicalDashboard.dart';
//
// // === Overview Pages ===
// import '../../Mediacl_Staff/Pages/Doctor/pages/DrOpOverview/AssistantDrOpOverview.dart';
// import '../../Mediacl_Staff/Pages/Overview/CashierOverview.dart';
// import '../../Mediacl_Staff/Pages/Overview/LabOverview.dart';
// import '../../Mediacl_Staff/Pages/Overview/MedicalOverview.dart';
// import '../../Mediacl_Staff/Pages/Overview/Overviewpage.dart';
// import '../../Services/admin_service.dart';
//
// class MedicalStaffDashboardPage extends StatefulWidget {
//   final String designation;
//   final String hospitalName;
//   final String staffName;
//   final String staffPhoto;
//
//   const MedicalStaffDashboardPage({
//     super.key,
//     required this.designation,
//     required this.hospitalName,
//     required this.staffName,
//     required this.staffPhoto,
//   });
//
//   @override
//   State<MedicalStaffDashboardPage> createState() =>
//       _MedicalStaffDashboardPageState();
// }
//
// class _MedicalStaffDashboardPageState extends State<MedicalStaffDashboardPage> {
//   int selectedIndex = 0;
//   late final List<Widget> pages;
//
//   Future<bool> onWillPop() async => false; // Disable back navigation
//   final FlutterSecureStorage storage = const FlutterSecureStorage();
//
//   bool accessAdmin = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _initializePages();
//     getAccessAdminRole();
//   }
//
//   Future<void> getAccessAdminRole() async {
//     final storedUserId = await storage.read(key: 'userId');
//     if (storedUserId == null) return;
//
//     // Call API
//     final doctorData = await AdminService().getMedicalStaff();
//
//     // Example: doctorData is a List
//     final admin = doctorData.firstWhere(
//       (e) => e['user_Id'].toString() == storedUserId,
//       orElse: () => null,
//     );
//
//     if (admin == null) return;
//
//     // Extract role / access
//     final accessAdminRole = admin['accessAdminRole'];
//
//     setState(() {
//       accessAdmin = accessAdminRole;
//     });
//
//     // Store role securely
//     await storage.write(
//       key: 'accessAdminRole',
//       value: accessAdminRole.toString(),
//     );
//   }
//
//   void _initializePages() {
//     final designation = widget.designation.trim().toLowerCase();
//
//     switch (designation) {
//       case "doctor":
//         if (accessAdmin == true) {
//           // pages = const [
//           //   DrOverviewPage(), // Index 0: Overview
//           //   DrOpDashboardPage(), // Index 1: Dashboard
//           //   AssistantDrOpDashboardPage(),
//           // ];
//           pages = const [
//             AdminOpDashboardPage(),
//             AdminOverviewPage(),
//             AdminAddingPage(),
//           ];
//         } else {
//           pages = const [
//             DrOverviewPage(), // Index 0: Overview
//             DrOpDashboardPage(), // Index 1: Dashboard
//           ];
//         }
//
//         break;
//
//       case "nurse":
//         pages = const [OverviewPage(), OpDashboardPage()];
//         break;
//
//       case "cashier":
//         pages = const [CashierOverviewPage(), CashierDashboardPage()];
//         break;
//
//       case "medical staff":
//         pages = const [MedicalOverviewPage(), MedicalDashboardPage()];
//         break;
//
//       case "lab technician":
//         pages = const [LabOverviewPage(), LabDashboardPage()];
//         break;
//       case "assistant doctor":
//         pages = const [
//           AssistantDrOverviewPage(), // Index 0: Overview
//           AssistantDrOpDashboardPage(),
//         ]; // Index 1: Dashboard];
//         break;
//
//       default:
//         pages = const [OverviewPage(), OverviewPage()];
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double screenWidth = MediaQuery.sizeOf(context).width;
//     final bool isMobile = screenWidth < 600;
//     final bool isSmallDesktop = screenWidth >= 600 && screenWidth < 800;
//
//     return WillPopScope(
//       onWillPop: onWillPop,
//       child: Scaffold(
//         appBar: PreferredSize(
//           preferredSize: Size(screenWidth, 100),
//           child: isMobile
//               ? MedicalStaffAppbarMobile(
//                   title: widget.staffName,
//                   isBackEnable: false,
//                   isNotificationEnable: true,
//                   isDrawerEnable: true,
//                   isNotSettingEnable: true,
//                 )
//               : const AdminAppbarDesktop(
//                   title: 'Medical Staff Dashboard',
//                   isBackEnable: false,
//                   isNotificationEnable: true,
//                   isDrawerEnable: true,
//                 ),
//         ),
//         drawer: MedicalStaffMobileDrawer(
//           title: widget.staffName,
//           staffPhoto: widget.staffPhoto,
//           width: isMobile
//               ? MediaQuery.of(context).size.width * 0.75
//               : isSmallDesktop
//               ? MediaQuery.of(context).size.width / 2
//               : MediaQuery.of(context).size.width / 3,
//           designation: widget.designation,
//         ),
//         body: IndexedStack(index: selectedIndex, children: pages),
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: selectedIndex,
//           selectedItemColor: Colors.pink,
//           unselectedItemColor: Colors.grey,
//           elevation: 10,
//           onTap: (index) => setState(() => selectedIndex = index),
//
//           items: accessAdmin == true
//               ? const [
//                   BottomNavigationBarItem(
//                     icon: Icon(Icons.miscellaneous_services),
//                     label: 'Service',
//                   ),
//                   BottomNavigationBarItem(
//                     icon: Icon(Icons.home),
//                     label: 'Home',
//                   ),
//                   BottomNavigationBarItem(
//                     icon: Icon(Icons.miscellaneous_services),
//                     label: 'Manage',
//                   ),
//                 ]
//               : const [
//                   BottomNavigationBarItem(
//                     icon: Icon(Icons.home),
//                     label: 'Home',
//                   ),
//                   BottomNavigationBarItem(
//                     icon: Icon(Icons.miscellaneous_services),
//                     label: 'Service',
//                   ),
//                 ],
//         ),
//       ),
//     );
//   }
// }
