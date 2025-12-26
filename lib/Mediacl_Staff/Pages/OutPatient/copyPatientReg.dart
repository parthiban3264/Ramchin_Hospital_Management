//import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:intl/intl.dart';
// import '../../../Services/Doctor/doctor_service.dart';
// import '../../../Services/consultation_service.dart';
// import '../../../Services/fees_Service.dart';
// import '../../../Services/patient_service.dart';
// import '../../../Services/payment_service.dart';
// import '../../../Widgets/AgeDobField.dart';
// import '../../../Pages/NotificationsPage.dart';
//
// const Color customGold = Color(0xFFBF955E);
// const Color backgroundColor = Color(0xFFF9F7F2);
//
// const List<String> genders = ['Male', 'Female', 'Other'];
// const List<String> bloodTypes = [
//   'A+',
//   'A-',
//   'B+',
//   'B-',
//   'AB+',
//   'AB-',
//   'O+',
//   'O-',
// ];
//
// const List<String> currentProblemSuggestions = [
//   'Fever with chills and body pain',
//   'Abdominal pain with vomiting',
//   'Cough and difficulty in breathing',
//   'Chest pain and dizziness',
//   'Headache and weakness',
//   'High blood sugar',
//   'Hypertension',
//   'Acute injury/fracture',
//   'Urinary infection symptoms',
//   'Rashes on skin',
// ];
//
// class IndianPhoneNumberFormatter extends TextInputFormatter {
//   static const String prefix = '+91 ';
//
//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
//
//     if (digitsOnly.startsWith('91')) digitsOnly = digitsOnly.substring(2);
//     if (digitsOnly.length > 10) digitsOnly = digitsOnly.substring(0, 10);
//
//     final formatted = digitsOnly.isEmpty ? '' : '$prefix$digitsOnly';
//
//     int cursorPosition = formatted.length;
//     if (cursorPosition < prefix.length) cursorPosition = prefix.length;
//
//     return TextEditingValue(
//       text: formatted,
//       selection: TextSelection.collapsed(offset: cursorPosition),
//     );
//   }
// }
//
// class PatientRegistrationPage extends StatefulWidget {
//   const PatientRegistrationPage({super.key});
//   @override
//   State<PatientRegistrationPage> createState() =>
//       _PatientRegistrationPageState();
// }
//
// class _PatientRegistrationPageState extends State<PatientRegistrationPage> {
//   final PatientService patientService = PatientService();
//   final doctorService = DoctorService();
//   final consultationService = ConsultationService();
//   final paymentService = PaymentService();
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController AccompanierNameController =
//       TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController guardianEmailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController emergencyController = TextEditingController();
//   final TextEditingController AddressController = TextEditingController();
//   final TextEditingController cityController = TextEditingController();
//   final TextEditingController zipController = TextEditingController();
//   final TextEditingController dobController = TextEditingController();
//   final TextEditingController ageController = TextEditingController();
//   final TextEditingController doctorIdController = TextEditingController();
//   final TextEditingController doctorNameController = TextEditingController();
//   final TextEditingController departmentController = TextEditingController();
//   final TextEditingController ComplaintController = TextEditingController();
//   final TextEditingController DataTimeController = TextEditingController();
//   final TextEditingController currentProblemController =
//       TextEditingController();
//   final TextEditingController medicalHistoryController =
//       TextEditingController();
//
//   String? _dateTime;
//   String? selectedGender;
//   String? selectedBloodType;
//   bool showGuardianEmail = false;
//   String? medicalHistoryChoice; // 'Yes' or 'No'
//   bool isSubmitting = false;
//   bool formValidated = false;
//   bool phoneValid = true;
//   bool emergencyValid = true;
//   bool isLoadingDoctors = false;
//   bool showDoctorSection = false;
//   bool _ignorePhoneListener = false;
//   List<Map<String, dynamic>> allDoctors = [];
//   List<Map<String, dynamic>> filteredDoctors = [];
//   Map<String, dynamic>? selectedDoctor;
//   List<String> filteredProblemSuggestions = [];
//
//   // New fields for checking/existing user
//   bool isExistingUser = false;
//   String? lastCheckedUserId;
//   bool isCheckingUser = false;
//   Map<String, dynamic>? existingPatient;
//
//   void _showSnackBar(String msg) =>
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//
//   @override
//   void initState() {
//     super.initState();
//
//     _fetchDoctors();
//     currentProblemController.addListener(_filterCurrentProblemSuggestions);
//     phoneController.addListener(_onPhoneControllerChanged);
//     _updateTime();
//     Timer.periodic(const Duration(seconds: 60), (Timer t) => _updateTime());
//   }
//
//   @override
//   void dispose() {
//     currentProblemController.removeListener(_filterCurrentProblemSuggestions);
//     phoneController.removeListener(_onPhoneControllerChanged);
//     super.dispose();
//   }
//
//   void _updateTime() {
//     setState(() {
//       _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
//     });
//   }
//
//   void _filterCurrentProblemSuggestions() {
//     String input = currentProblemController.text.toLowerCase();
//     if (input.isEmpty) {
//       setState(() => filteredProblemSuggestions = []);
//       return;
//     }
//     final filtered = currentProblemSuggestions
//         .where((suggestion) => suggestion.toLowerCase().startsWith(input))
//         .toList();
//     setState(() => filteredProblemSuggestions = filtered);
//   }
//
//   void _onPhoneChanged(String value, void Function(bool) setValidity) {
//     String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
//     if (digitsOnly.startsWith('91')) digitsOnly = digitsOnly.substring(2);
//     setValidity(digitsOnly.length == 10);
//   }
//
//   void _onPhoneControllerChanged() {
//     if (_ignorePhoneListener) return; // 🚫 skip when updating programmatically
//
//     final raw = phoneController.text;
//     String digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
//     if (digitsOnly.startsWith('91')) digitsOnly = digitsOnly.substring(2);
//
//     // Trigger API check when exactly 10 digits entered
//     if (digitsOnly.length == 10) {
//       final userId = digitsOnly;
//       if (lastCheckedUserId != userId && !isCheckingUser) {
//         _checkUserExists(userId);
//       }
//     } else {
//       // Reset if user edits to <10 digits
//       if (isExistingUser || existingPatient != null) {
//         setState(() {
//           isExistingUser = false;
//           existingPatient = null;
//           lastCheckedUserId = null;
//           // Optional: clear other fields too
//         });
//       }
//       setState(() => phoneValid = digitsOnly.length == 10);
//     }
//   }
//
//   Future<String> loadFees() async {
//     try {
//       final getFees = await FeesService().getFeesByHospital();
//       print('getFees $getFees'); // get all fees as List<dynamic>
//
//       // Calculate totals
//       double regAmount = 0;
//       double appointAmount = 0;
//       double doctorAmount = 0;
//
//       for (var fee in getFees) {
//         if (fee['type'] == 'REGISTRATIONFEE') {
//           regAmount = (fee['amount'] ?? 0).toDouble();
//         }
//         if (fee['type'] == 'APPOINTMENTFEE') {
//           appointAmount = (fee['amount'] ?? 0).toDouble();
//         }
//         if (fee['doctorAmount'] != null) {
//           doctorAmount = (fee['doctorAmount'] ?? 0).toDouble();
//         }
//       }
//
//       // Check if both fees missing
//       if (regAmount == 0 && appointAmount == 0) {
//         return "⚠️ Registration Fee or Appointment Fee is not set! Please assign fees.";
//       }
//
//       return "Registration Fee: $regAmount, Appointment Fee: $appointAmount, Doctor Amount: $doctorAmount";
//     } catch (e) {
//       return "Error fetching fees: $e";
//     }
//   }
//
//   Future<void> _checkUserExists(String userId) async {
//     setState(() => isCheckingUser = true);
//
//     try {
//       final exists = await patientService.checkUserIdExists(userId);
//       lastCheckedUserId = userId;
//
//       if (exists == true) {
//         final fetched = await patientService.getPatientById(userId);
//         print('✅ Patient fetched: $fetched');
//
//         // ✅ Check if the patient already has ongoing consultation(s)
//         final consultations = fetched['Consultation'] as List<dynamic>? ?? [];
//         final hasOngoing = consultations.any((c) {
//           final status = c['status']?.toString().toUpperCase() ?? '';
//           return status != 'COMPLETED';
//         });
//
//         if (hasOngoing) {
//           // 🚫 Patient already has an active consultation
//           setState(() {
//             isExistingUser = true;
//             existingPatient = fetched;
//           });
//
//           _showSnackBar(
//             'Your consultation is already ongoing. Please complete it before creating a new one.',
//           );
//           return; // Stop here — don’t populate form further or allow submit
//         }
//
//         // ✅ No active consultations — safe to continue
//         setState(() {
//           isExistingUser = true;
//           existingPatient = fetched;
//
//           _ignorePhoneListener = true; // 🚫 stop triggering listener
//           phoneController.text = '+91 ${fetched['user_Id']}';
//           _ignorePhoneListener = false; // ✅ re-enable it
//
//           fullNameController.text = fetched['name'] ?? '';
//           AddressController.text =
//               fetched['address']?['Address'] ?? fetched['address'] ?? '';
//           dobController.text = fetched['dob'] != null
//               ? DateFormat(
//                   'yyyy-MM-dd',
//                 ).format(DateTime.parse(fetched['dob']).toLocal())
//               : '';
//           selectedGender = fetched['gender'];
//           selectedBloodType = fetched['bldGrp'];
//           emailController.text = fetched['email']?['personal'] ?? '';
//           guardianEmailController.text = fetched['email']?['guardian'] ?? '';
//
//           // Compute age
//           if (fetched['dob'] != null) {
//             final dob = DateTime.parse(fetched['dob']);
//             final today = DateTime.now();
//             final age =
//                 today.year -
//                 dob.year -
//                 ((today.month < dob.month ||
//                         (today.month == dob.month && today.day < dob.day))
//                     ? 1
//                     : 0);
//             ageController.text = age.toString();
//           }
//         });
//
//         _showSnackBar('Existing patient found.');
//       } else {
//         // 🆕 New patient registration
//         setState(() {
//           isExistingUser = false;
//           existingPatient = null;
//
//           fullNameController.clear();
//           AddressController.clear();
//           dobController.clear();
//           emailController.clear();
//           guardianEmailController.clear();
//           ageController.clear();
//           selectedGender = null;
//           selectedBloodType = null;
//
//           _ignorePhoneListener = true;
//           phoneController.text = '+91 $userId';
//           _ignorePhoneListener = false;
//         });
//
//         _showSnackBar('New patient registration.');
//       }
//     } catch (e) {
//       print('❌ Error fetching patient: $e');
//       _showSnackBar('Error: $e');
//     } finally {
//       if (mounted) setState(() => isCheckingUser = false);
//     }
//   }
//
//   Future<void> _fetchDoctors() async {
//     setState(() => isLoadingDoctors = true);
//     try {
//       final docs = await doctorService.getDoctors();
//       setState(() {
//         allDoctors = docs;
//         filteredDoctors = List.from(docs); // show all by default
//         showDoctorSection = true; // always show doctor list
//       });
//     } catch (e) {
//       _showSnackBar('Error loading doctors: $e');
//     } finally {
//       setState(() => isLoadingDoctors = false);
//     }
//   }
//
//   // Unified submit - behaves differently for new vs existing user
//   void _submitPatient() async {
//     setState(() {
//       formValidated = true;
//
//       String phoneDigits = phoneController.text.replaceAll(
//         RegExp(r'[^0-9]'),
//         '',
//       );
//       if (phoneDigits.startsWith('91')) phoneDigits = phoneDigits.substring(2);
//       phoneValid = phoneDigits.length == 10;
//     });
//
//     List<String> missingFields = [];
//     if (fullNameController.text.trim().isEmpty) missingFields.add("Full Name");
//     if (dobController.text.trim().isEmpty) missingFields.add("Date of Birth");
//     if (!phoneValid) missingFields.add("Phone Number (must be 10 digits)");
//     if (AddressController.text.trim().isEmpty) missingFields.add("Address");
//     if (ComplaintController.text.trim().isEmpty) {
//       missingFields.add("Current Problem");
//     }
//     if (selectedGender == null) missingFields.add("Gender");
//     if (doctorIdController.text.isEmpty) {
//       missingFields.add("Select Doctor");
//     }
//
//     if (missingFields.isNotEmpty) {
//       String msg =
//           "Please fill/complete the following required fields:\n• ${missingFields.join("\n• ")}";
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
//       );
//       return;
//     }
//
//     setState(() => isSubmitting = true);
//     try {
//       //loadFees();
//       // normalize phone to userId
//       final cleanedMobile = phoneController.text.trim().replaceAll(
//         RegExp(r'^\+?91[\s-]*'),
//         '',
//       );
//       final userId = cleanedMobile;
//
//       // Build patient data object
//       DateTime dob =
//           DateTime.tryParse(dobController.text) ?? DateTime(1990, 1, 1);
//
//       final patientData = {
//         "name": fullNameController.text.trim(),
//         "ac_name": AccompanierNameController.text.trim(),
//         "staff_Id": await secureStorage.read(key: 'userId'),
//         "phone": {
//           "mobile": phoneController.text.trim(),
//           "emergency": emergencyController.text.trim(),
//         },
//         "email": {
//           "personal": emailController.text.trim(),
//           "guardian": guardianEmailController.text.trim(),
//         },
//         "address": {"Address": AddressController.text.trim()},
//         "dob": dob.toUtc().toIso8601String(),
//         "gender": selectedGender,
//         "bldGrp": selectedBloodType,
//         "currentProblem": currentProblemController.text.trim(),
//         "createdAt": _dateTime.toString(),
//         "tempCreatedAt": DateTime.now().toUtc().toIso8601String(),
//       };
//
//       // If existing user => update patient if changed, then create consultation
//       if (isExistingUser) {
//         // ✅ Step 1: Check existing consultations for ongoing ones
//         final consultations =
//             existingPatient?['Consultation'] as List<dynamic>? ?? [];
//
//         final hasOngoing = consultations.any((c) {
//           final status = c['status']?.toString()?.toUpperCase() ?? '';
//           // not completed or endprocessed means it's still active
//           return status != 'COMPLETED'; // && status != 'ENDPROCESSING'
//         });
//
//         if (hasOngoing) {
//           _showSnackBar(
//             'Your consultation is already ongoing. Please complete it before creating a new one.',
//           );
//           setState(() => isSubmitting = false);
//           return; // 🚫 stop here — do NOT create new consultation
//         }
//
//         // ✅ Step 2: Proceed normally if no ongoing consultations exist
//         try {
//           await patientService.updatePatient(userId, patientData);
//         } catch (e) {
//           _showSnackBar('Failed to update patient: $e');
//         }
//
//         final hospitalId = await doctorService.getHospitalId();
//         final result = await consultationService.createConsultation({
//           "hospital_Id": hospitalId,
//           "patient_Id": userId,
//           "doctor_Id": doctorIdController.text,
//           "name": doctorNameController.text,
//           "purpose": ComplaintController.text,
//           "temperature": 0,
//           "createdAt": _dateTime.toString(),
//         });
//         if (result['status'] == 'failed') {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(SnackBar(content: Text(result['message'])));
//           return;
//         }
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('New Appointment created')),
//         );
//         Navigator.pop(context, true);
//       } else {
//         // New user: create patient then create consultation
//         final results = await patientService.createPatient(patientData);
//
//         if (results['status'] == 'failed') {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(SnackBar(content: Text(results['message'])));
//           return;
//         }
//
//         final hospitalId = await doctorService.getHospitalId();
//         final result = await consultationService.createConsultation({
//           "hospital_Id": hospitalId,
//           "patient_Id": userId,
//           "doctor_Id": doctorIdController.text,
//           "name": doctorNameController.text,
//           "purpose": ComplaintController.text,
//           "temperature": 0,
//           "createdAt": _dateTime.toString(),
//         });
//         if (result['status'] == 'failed') {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(SnackBar(content: Text(result['message'])));
//           return;
//         }
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Patient registered and created Appointment')),
//         );
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//       print('Error: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     } finally {
//       if (mounted) setState(() => isSubmitting = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: _overviewAppBar(context),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Center(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 700),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 16,
//                     horizontal: 12,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(14),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.08),
//                         blurRadius: 12,
//                         offset: const Offset(2, 6),
//                       ),
//                     ],
//                   ),
//                   child: Wrap(
//                     spacing: 16,
//                     runSpacing: 16,
//                     children: [
//                       _buildInput(
//                         "Cell No *",
//                         phoneController,
//                         hint: "+911234567890",
//                         errorText: formValidatedErrorText(
//                           formValidated: formValidated,
//                           valid: phoneValid,
//                           errMsg: 'Enter valid 10 digit number',
//                         ),
//                         keyboardType: TextInputType.phone,
//                         onChanged: (val) => _onPhoneChanged(
//                           val,
//                           (valid) => setState(() => phoneValid = valid),
//                         ),
//                         inputFormatters: [
//                           FilteringTextInputFormatter.digitsOnly,
//                           IndianPhoneNumberFormatter(),
//                         ],
//                         suffix: AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 250),
//                           transitionBuilder: (child, anim) =>
//                               ScaleTransition(scale: anim, child: child),
//                           child: phoneController.text.isEmpty
//                               ? const SizedBox.shrink(
//                                   key: ValueKey('empty'),
//                                 ) // 👈 no icon when empty
//                               : isCheckingUser
//                               ? const SizedBox(
//                                   key: ValueKey('loader'),
//                                   width: 20,
//                                   height: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                   ),
//                                 )
//                               : (phoneValid
//                                     ? Icon(
//                                         isExistingUser
//                                             ? Icons
//                                                   .person // existing patient found
//                                             : Icons
//                                                   .check_circle, // new number valid
//                                         color: isExistingUser
//                                             ? Colors.orange
//                                             : Colors.green,
//                                         key: ValueKey('valid'),
//                                       )
//                                     : const SizedBox.shrink(
//                                         key: ValueKey('no-valid'),
//                                       )),
//                         ),
//                       ),
//
//                       _buildInput(
//                         "Name *",
//                         fullNameController,
//                         hint: "Enter full name",
//                       ),
//                       AgeDobField(
//                         dobController: dobController,
//                         ageController: ageController,
//                       ),
//                       _sectionLabel("Gender *"),
//                       Container(
//                         width: 320,
//                         margin: const EdgeInsets.only(bottom: 2),
//                         child: Row(
//                           children: genders
//                               .map(
//                                 (e) => _buildSelectionCard(
//                                   label: e,
//                                   selected: selectedGender == e,
//                                   onTap: () =>
//                                       setState(() => selectedGender = e),
//                                 ),
//                               )
//                               .toList(),
//                         ),
//                       ),
//                       _sectionLabel("Blood Type ( optional )"),
//                       Container(
//                         width: MediaQuery.of(context).size.width,
//                         margin: const EdgeInsets.only(bottom: 8),
//                         child: Wrap(
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: bloodTypes.map((type) {
//                             final selected = selectedBloodType == type;
//                             return GestureDetector(
//                               onTap: () =>
//                                   setState(() => selectedBloodType = type),
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 14,
//                                   vertical: 8,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: selected ? customGold : Colors.white,
//                                   borderRadius: BorderRadius.circular(10),
//                                   border: Border.all(
//                                     color: selected
//                                         ? customGold
//                                         : Colors.grey.shade300,
//                                     width: 1.5,
//                                   ),
//                                   boxShadow: [
//                                     if (selected)
//                                       const BoxShadow(
//                                         color: Colors.black12,
//                                         blurRadius: 3,
//                                         offset: Offset(0, 1),
//                                       ),
//                                   ],
//                                 ),
//                                 child: Text(
//                                   type,
//                                   style: TextStyle(
//                                     color: selected
//                                         ? Colors.white
//                                         : Colors.black87,
//                                     fontWeight: FontWeight.w800,
//                                     fontSize: 18,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ),
//                       _buildInput(
//                         "Address *",
//                         AddressController,
//                         maxLines: 3,
//                         hint: "Street address",
//                       ),
//                       _buildInput(
//                         "Chief Complaint *",
//                         ComplaintController,
//                         hint: "Enter complaint",
//                       ),
//
//                       _sectionLabel(
//                         isExistingUser
//                             ? "Create Appointment"
//                             : "Available Doctors *",
//                       ),
//                       if (showDoctorSection) ...[_buildDoctorList()],
//
//                       // 🔹 Blood Type Section
//                       const SizedBox(height: 16),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 28),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: isSubmitting ? null : _submitPatient,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: customGold,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       elevation: 1,
//                     ),
//                     child: isSubmitting
//                         ? const CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           )
//                         : Text(
//                             isExistingUser
//                                 ? "Create Appointment"
//                                 : "Register Patient",
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   String? formValidatedErrorText({
//     required bool formValidated,
//     required bool valid,
//     required String errMsg,
//   }) {
//     if (!formValidated) return null;
//     return valid ? null : errMsg;
//   }
//
//   Widget _buildInput(
//     String label,
//     TextEditingController controller, {
//     int maxLines = 1,
//     String? hint,
//     String? errorText,
//     TextInputType keyboardType = TextInputType.text,
//     void Function(String)? onChanged,
//     List<TextInputFormatter>? inputFormatters,
//     Widget? suffix, // 👈 added this line
//   }) {
//     return SizedBox(
//       width: 320,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 6),
//           TextField(
//             cursorColor: customGold,
//             controller: controller,
//             maxLines: maxLines,
//             keyboardType: keyboardType,
//             onChanged: onChanged,
//             inputFormatters: inputFormatters,
//             decoration: InputDecoration(
//               filled: true,
//               fillColor: Colors.grey[50],
//               hintText: hint,
//               hintStyle: TextStyle(color: Colors.grey[400]),
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 12,
//                 vertical: 13,
//               ),
//               suffixIcon:
//                   suffix, // 👈 this allows us to show the loader or icon
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(
//                   color: errorText != null ? Colors.red : Colors.grey.shade300,
//                 ),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(
//                   color: errorText != null ? Colors.red : customGold,
//                   width: 1.5,
//                 ),
//               ),
//               errorText: errorText,
//               errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
//             ),
//             style: const TextStyle(fontSize: 15),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDoctorList() {
//     if (isLoadingDoctors) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     if (filteredDoctors.isEmpty) {
//       return const Text('No available doctors for this complaint');
//     }
//
//     return SizedBox(
//       height: 100,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: filteredDoctors.length,
//         itemBuilder: (_, i) {
//           final doc = filteredDoctors[i];
//           final isSelected =
//               selectedDoctor != null && selectedDoctor!['id'] == doc['id'];
//
//           return GestureDetector(
//             onTap: () {
//               setState(() {
//                 selectedDoctor = doc;
//                 doctorIdController.text = doc['id'].toString(); // ✅ added
//                 doctorNameController.text = doc['name']; // ✅ added
//                 departmentController.text = doc['department']; // ✅ optional
//               });
//             },
//             child: Container(
//               width: 120,
//               margin: const EdgeInsets.all(8),
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: isSelected ? customGold.withOpacity(0.25) : Colors.white,
//                 border: Border.all(
//                   color: isSelected ? customGold : Colors.grey.shade300,
//                   width: isSelected ? 2 : 1,
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.1),
//                     blurRadius: 4,
//                     offset: const Offset(1, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     doc['name'],
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     doc['department'],
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildDatePickerField(
//     BuildContext context,
//     String label,
//     TextEditingController controller,
//   ) {
//     return SizedBox(
//       width: 320,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 6),
//           GestureDetector(
//             onTap: () async {
//               DateTime? pickedDate = await showDatePicker(
//                 context: context,
//                 initialDate: DateTime(1990),
//                 firstDate: DateTime(1900),
//                 lastDate: DateTime.now(),
//               );
//               if (pickedDate != null) {
//                 controller.text =
//                     "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
//               }
//             },
//             child: AbsorbPointer(
//               child: TextField(
//                 controller: controller,
//                 decoration: InputDecoration(
//                   hintText: "YYYY-MM-DD",
//                   suffixIcon: const Icon(Icons.calendar_today, size: 20),
//                   filled: true,
//                   fillColor: Colors.grey[50],
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 12,
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: BorderSide(color: Colors.grey.shade300),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.all(Radius.circular(8)),
//                     borderSide: BorderSide(color: customGold, width: 1.5),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSelectionCard({
//     required String label,
//     required bool selected,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 5),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: selected ? customGold : Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: selected ? customGold : Colors.grey.shade300,
//             width: 1.5,
//           ),
//           boxShadow: [
//             if (selected)
//               const BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 3,
//                 offset: Offset(0, 1),
//               ),
//           ],
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: selected ? Colors.white : Colors.black87,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _sectionLabel(String text) => Padding(
//     padding: const EdgeInsets.only(top: 12, bottom: 2),
//     child: Text(
//       text,
//       style: TextStyle(
//         fontWeight: FontWeight.w600,
//         color: Colors.grey[800],
//         fontSize: 18,
//         letterSpacing: 0.1,
//       ),
//     ),
//   );
//
//   PreferredSize _overviewAppBar(BuildContext context) => PreferredSize(
//     preferredSize: const Size.fromHeight(100),
//     child: Container(
//       height: 100,
//       decoration: const BoxDecoration(
//         color: customGold,
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(12),
//           bottomRight: Radius.circular(12),
//         ),
//         boxShadow: [
//           BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
//         ],
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: Row(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                 onPressed: () => Navigator.pop(context),
//               ),
//               const Text(
//                 'Patient Registration',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 24,
//                 ),
//               ),
//               const Spacer(),
//               IconButton(
//                 icon: const Icon(Icons.notifications, color: Colors.white),
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const NotificationPage()),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }
