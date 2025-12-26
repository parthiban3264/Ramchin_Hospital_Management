// import 'package:flutter/material.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
//
// class PdfPreviewCustomPage extends StatelessWidget {
//   final Future<pw.Document> Function() buildPdf;
//   final String title;
//   final String fileName;
//   const PdfPreviewCustomPage({
//     super.key,
//     required this.buildPdf,
//     required this.title,
//     required this.fileName,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final Color themeColor = Color(0xFF2B7CA8);
//     final Color backgroundCard = Colors.grey[50]!; // softer white
//
//     return Scaffold(
//       backgroundColor: themeColor.withOpacity(0.95), // slightly transparent
//       appBar: AppBar(
//         backgroundColor: themeColor,
//         elevation: 4, // subtle shadow
//         toolbarHeight: 60, // taller AppBar
//         title: Text(
//           title,
//           style: TextStyle(
//             fontWeight: FontWeight.w700,
//             fontSize: 28,
//             color: Colors.white,
//             letterSpacing: 0.5,
//           ),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Center(
//               child: Container(
//                 constraints: BoxConstraints(
//                   maxWidth: 480,
//                 ), // responsive max width
//                 decoration: BoxDecoration(
//                   color: backgroundCard,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       blurRadius: 12,
//                       color: Colors.black.withOpacity(0.1),
//                       offset: Offset(0, 6),
//                     ),
//                   ],
//                 ),
//                 margin: const EdgeInsets.symmetric(
//                   vertical: 24,
//                   horizontal: 12,
//                 ),
//                 padding: const EdgeInsets.all(16),
//                 child: PdfPreview(
//                   allowPrinting: false,
//                   allowSharing: false,
//                   canChangePageFormat: false,
//                   canChangeOrientation: false,
//                   build: (format) async => (await buildPdf()).save(),
//                 ),
//               ),
//             ),
//           ),
//           Container(
//             color: themeColor,
//             padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: themeColor,
//                     backgroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 40,
//                       vertical: 16,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(36),
//                     ),
//                     elevation: 4,
//                   ),
//                   icon: const Icon(
//                     Icons.print,
//                     size: 28,
//                     color: Colors.black87,
//                   ),
//                   label: const Text(
//                     "Print",
//                     style: TextStyle(
//                       fontSize: 15,
//                       color: Colors.black87,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   onPressed: () async {
//                     final pdfDoc = await buildPdf();
//                     await Printing.layoutPdf(
//                       onLayout: (format) async => pdfDoc.save(),
//                     );
//                   },
//                 ),
//                 const SizedBox(width: 24), // spacing between buttons
//                 ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: themeColor,
//                     backgroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 40,
//                       vertical: 16,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(36),
//                     ),
//                     elevation: 4,
//                   ),
//                   icon: const Icon(
//                     Icons.share,
//                     size: 28,
//                     color: Colors.black87,
//                   ),
//                   label: const Text(
//                     "Share",
//                     style: TextStyle(
//                       fontSize: 15,
//                       color: Colors.black87,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   onPressed: () async {
//                     final pdfDoc = await buildPdf();
//                     await Printing.sharePdf(
//                       bytes: await pdfDoc.save(),
//                       filename: '$fileName.pdf',
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 40),
//         ],
//       ),
//     );
//   }
// }
// Future<void> _generateBillPdf() async {
//   final pdf = pw.Document();
//
//   // Load fonts
//   final ttf = await PdfGoogleFonts.notoSansRegular();
//   final ttfBold = await PdfGoogleFonts.notoSansBold();
//
//   final patient = consultation['Patient'] ?? {};
//   final hospital = consultation['Hospital'] ?? {};
//   pw.Widget buildHeader() {
//     return pw.Column(
//       children: [
//         pw.Row(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Padding(
//               padding: pw.EdgeInsets.only(top: 10),
//               child: pw.Expanded(
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.center,
//                   children: [
//                     pw.Text(
//                       "schoolName",
//                       textAlign: pw.TextAlign.center,
//                       softWrap: true,
//                       style: pw.TextStyle(
//                         color: PdfColors.blue900,
//                         fontSize: 16,
//                         fontWeight: pw.FontWeight.bold,
//                       ),
//                     ),
//                     pw.Text(
//                       "schoolAddress",
//                       textAlign: pw.TextAlign.center,
//                       style: const pw.TextStyle(
//                         fontSize: 12,
//                         color: PdfColors.blue900,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         pw.Divider(),
//
//         pw.Text(
//           "Daily Student Attendance Report",
//           style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
//         ),
//       ],
//     );
//   }
//
//   pdf.addPage(
//     pw.MultiPage(
//       theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
//       pageFormat: PdfPageFormat.a4,
//       margin: const pw.EdgeInsets.all(24),
//       header: (context) => buildHeader(),
//       build: (context) => [
//         pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             // Title
//             pw.Center(
//               child: pw.Text(
//                 "CONSULTATION BILL",
//                 style: pw.TextStyle(
//                   fontSize: 22,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//             ),
//             pw.SizedBox(height: 15),
//
//             // Basic Info
//             pw.Text("Hospital: ${hospital['name'] ?? '—'}"),
//             pw.Text("Patient: ${patient['name'] ?? '—'}"),
//             pw.Text("Consultation ID: ${consultation['id'] ?? '—'}"),
//
//             pw.SizedBox(height: 10),
//             pw.Divider(),
//
//             // 💊 Medicines
//             _buildSection(
//               title: "MEDICINES",
//               items: medicines,
//               nameKey: 'Medician.medicianName',
//             ),
//
//             pw.SizedBox(height: 8),
//
//             // 🧃 Tonics
//             _buildSection(
//               title: "TONICS",
//               items: tonics,
//               nameKey: 'Tonic.tonicName',
//             ),
//
//             pw.SizedBox(height: 8),
//
//             // 💉 Injections
//             _buildSection(
//               title: "INJECTIONS",
//               items: injections,
//               nameKey: 'Injection.injectionName',
//             ),
//
//             pw.Divider(),
//             pw.SizedBox(height: 10),
//
//             // 💰 Total
//             pw.Text(
//               "TOTAL AMOUNT: ₹${totalCharges.toStringAsFixed(2)}",
//               style: pw.TextStyle(
//                 fontSize: 16,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//             pw.SizedBox(height: 10),
//             pw.Text(
//               "Payment Status: PAID",
//               style: pw.TextStyle(color: PdfColors.green),
//             ),
//             pw.SizedBox(height: 5),
//             pw.Text("Date: $_dateTime"),
//           ],
//         ),
//       ],
//     ),
//   );
//
//   await Printing.layoutPdf(
//     onLayout: (PdfPageFormat format) async => pdf.save(),
//   );
// }
//
// /// Helper for rendering sections cleanly
// pw.Widget _buildSection({
//   required String title,
//   required List<dynamic> items,
//   required String nameKey,
// }) {
//   return pw.Column(
//     crossAxisAlignment: pw.CrossAxisAlignment.start,
//     children: [
//       pw.Text(
//         " $title:",
//         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//       ),
//       if (items.isEmpty) pw.Text("— No $title prescribed."),
//       for (var item in items)
//         pw.Text(
//           "- ${_getNestedValue(item, nameKey) ?? title.substring(0, title.length - 1)}  | ₹${(item['total'] ?? 0)}",
//         ),
//     ],
//   );
// }

// final reportData = {
//   'hospital_address': hospital['address'] ?? 'N/A',
//   'patient_name': patient['name'] ?? 'N/A',
//   'pid': patient['user_Id'] ?? 'N/A',
//   'age': _calculateAge(patient['dob']),   // your age calculation function
//   'sex': patient['gender'] ?? 'N/A',
//   'apt_id': test['id']?.toString() ?? 'N/A',
//   'ref_by': (hospital['Admins'] != null && test['doctor_Id'] != null)
//       ? (hospital['Admins'] as List).firstWhere(
//         (a) => a['user_Id'].toString() == test['doctor_Id'].toString(),
//     orElse: () => {'name': 'N/A'},
//   )['name']
//       : 'N/A',
//   'date': test['createdAt'] ?? 'N/A',
//   'test_title': test['title'] ?? 'N/A',
//   'selected_options':
//   (test['selectedOptions'] as List<dynamic>? ?? []).join(', '),
//   'result': test['result'] ?? '',
//   'impression': test['result'] ?? '',
//   // Pass scan image path if you have saved the file locally
//   'sample_image_path': 'your_scan_image_path.jpg', // optional, replace with real path
// };
//
// // Then call your PDF function passing real-time data
// await generateAndShowLabReportPDF(context, reportData);
// // Do not wrap this in a Navigator call!

//
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:intl/intl.dart';
//
// import '../../../../Pages/NotificationsPage.dart';
// import '../../../../Services/consultation_service.dart';
// import '../../../../Services/testing&scanning_service.dart';
//
// class LabPage extends StatefulWidget {
//   final Map<String, dynamic> record;
//
//   const LabPage({Key? key, required this.record}) : super(key: key);
//
//   @override
//   State<LabPage> createState() => _LabPageState();
// }
//
// class _LabPageState extends State<LabPage> with SingleTickerProviderStateMixin {
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//   final Color primaryColor = const Color(0xFFBF955E);
//   bool _isPatientExpanded = false;
//   bool _isXrayExpanded = false;
//   bool _isLoading = false; // <-- Add this to your State class
//   String? _dateTime;
//
//   late final AnimationController _patientController;
//   late final Animation<double> _patientExpandAnimation;
//
//   final TextEditingController _descriptionController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _updateTime();
//     _patientController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//
//     _patientExpandAnimation = CurvedAnimation(
//       parent: _patientController,
//       curve: Curves.easeInOut,
//     );
//   }
//
//   @override
//   void dispose() {
//     _patientController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }
//
//   void _updateTime() {
//     setState(() {
//       _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
//     });
//   }
//
//   void _togglePatientExpand() {
//     setState(() {
//       _isPatientExpanded = !_isPatientExpanded;
//       _isPatientExpanded
//           ? _patientController.forward()
//           : _patientController.reverse();
//     });
//   }
//
//   void _toggleXrayExpand() {
//     setState(() {
//       _isXrayExpanded = !_isXrayExpanded;
//     });
//   }
//
//   String _formatDob(String? dob) {
//     if (dob == null || dob.isEmpty) return 'N/A';
//     try {
//       return DateFormat('dd-MM-yyyy').format(DateTime.parse(dob));
//     } catch (_) {
//       return dob;
//     }
//   }
//
//   String _calculateAge(String? dob) {
//     if (dob == null || dob.isEmpty) return 'N/A';
//     try {
//       final date = DateTime.parse(dob);
//       final now = DateTime.now();
//       int age = now.year - date.year;
//       if (now.month < date.month ||
//           (now.month == date.month && now.day < date.day)) {
//         age--;
//       }
//       return "$age yrs";
//     } catch (_) {
//       return 'N/A';
//     }
//   }
//
//   void _handleSubmit() async {
//     final description = _descriptionController.text.trim();
//
//     if (description.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter a description before submitting.'),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true); // <-- Start loading
//
//     try {
//       final Id = widget.record['id'];
//       final Staff_Id = await secureStorage.read(key: 'userId');
//       final patient = widget.record['Patient'] ?? {};
//       final consultationList = patient['Consultation'] ?? [];
//
//       final consultationId = (consultationList.isNotEmpty)
//           ? consultationList[0]['id']
//           : null;
//
//       print("Consultation ID: $consultationId");
//
//       // 🧾 Update Testing and Scanning record
//       await TestingScanningService().updateTestingAndScanning(Id, {
//         'result': description,
//         'status': 'COMPLETED',
//         'updatedAt': _dateTime.toString(),
//         'queueStatus': 'COMPLETED',
//         'staff_Id': Staff_Id,
//       });
//
//       // 🧾 Update Consultation record
//       if (consultationId != null) {
//         await ConsultationService().updateConsultation(consultationId, {
//           'status': 'ENDPROCESSING',
//           'scanningTesting': false,
//           'updatedAt': _dateTime.toString(),
//         });
//       }
//
//       // ✅ Show success snackbar
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('X-Ray marked as Completed ✅'),
//           backgroundColor: primaryColor,
//         ),
//       );
//
//       Navigator.pop(context, true);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
//       );
//     } finally {
//       setState(() => _isLoading = false); // <-- Stop loading
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final record = widget.record;
//     final patient = record['Patient'] ?? {};
//     final phone = patient['phone']?['mobile'] ?? 'N/A';
//     final patientId = patient['user_Id'] ?? 'N/A';
//     final address = patient['address']?['Address'] ?? 'N/A';
//     final hospitalAdmins = record['Hospital']?['Admins'];
//     List<Map<String, dynamic>> adminList = [];
//
//     if (hospitalAdmins is List) {
//       // only cast if it's really a List
//       adminList = hospitalAdmins.whereType<Map<String, dynamic>>().toList();
//     }
//
//     final doctorIdList = record['doctor_Id'];
//     String doctorId = '';
//
//     if (doctorIdList is List && doctorIdList.isNotEmpty) {
//       doctorId = doctorIdList.first.toString();
//     } else if (doctorIdList is String) {
//       doctorId = doctorIdList;
//     }
//
//     final doctor = adminList.firstWhere(
//           (a) => a['user_Id'].toString() == doctorId,
//       orElse: () => {'name': 'N/A'},
//     );
//
//     final doctorName = doctor['name']?.toString() ?? 'N/A';
//
//     final createdAt = record['createdAt'] ?? 'N/A';
//     final title = record['title'] ?? 'N/A';
//     final dob = _formatDob(patient['dob']);
//     final age = _calculateAge(patient['dob']);
//     final gender = patient['gender'] ?? 'N/A';
//     final bloodGroup = patient['bldGrp'] ?? 'N/A';
//
//     // 🩻 Selected X-Ray Options
//     final selectedOptions = List<String>.from(record['selectedOptions'] ?? []);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F4F4),
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(100),
//         child: Container(
//           height: 100,
//           decoration: BoxDecoration(
//             color: primaryColor,
//             borderRadius: const BorderRadius.only(
//               bottomLeft: Radius.circular(18),
//               bottomRight: Radius.circular(18),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.15),
//                 blurRadius: 6,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   Text(
//                     title,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                   const Spacer(),
//                   IconButton(
//                     icon: const Icon(Icons.notifications, color: Colors.white),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const NotificationPage(),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildPatientCard(
//               name: patient['name'] ?? 'Unknown',
//               id: patientId,
//               phone: phone,
//               address: address,
//               dob: dob,
//               age: age,
//               gender: gender,
//               bloodGroup: bloodGroup,
//               createdAt: createdAt,
//             ),
//             const SizedBox(height: 20),
//             _buildMedicalCard(
//               title: title,
//               doctorName: doctorName,
//               doctorId: doctorId,
//               selectedOptions: selectedOptions,
//             ),
//             const SizedBox(height: 30),
//
//             // 📝 Description Input Box
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(18),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 8,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Description",
//                     style: TextStyle(
//                       color: primaryColor,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: _descriptionController,
//                     maxLines: 4,
//                     decoration: InputDecoration(
//                       hintText: "Enter Lab Test report or notes...",
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: BorderSide(color: primaryColor, width: 1.5),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       onPressed: _isLoading
//                           ? null
//                           : _handleSubmit, // Disable when loading
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryColor,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 4,
//                       ),
//                       icon: _isLoading
//                           ? const SizedBox(
//                         width: 22,
//                         height: 22,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2.5,
//                         ),
//                       )
//                           : const Icon(
//                         Icons.check_circle_outline,
//                         color: Colors.white,
//                       ),
//                       label: Text(
//                         _isLoading ? "Completed. . ." : "Completed",
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 17,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // 🧍 PATIENT CARD
//   Widget _buildPatientCard({
//     required String name,
//     required String id,
//     required String phone,
//     required String address,
//     required String dob,
//     required String age,
//     required String gender,
//     required String bloodGroup,
//     required String createdAt,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header Row
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 name,
//                 style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               GestureDetector(
//                 onTap: _togglePatientExpand,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: primaryColor.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     children: [
//                       Text(
//                         _isPatientExpanded ? "Hide" : "View All",
//                         style: TextStyle(
//                           color: primaryColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Icon(
//                         _isPatientExpanded
//                             ? Icons.expand_less
//                             : Icons.expand_more,
//                         color: primaryColor,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Divider(color: Colors.grey.shade300),
//           _infoRow("Patient ID", id),
//           _infoRow("Cell No", phone),
//           _infoRow("Address", address),
//           // Expandable Section
//           SizeTransition(
//             sizeFactor: _patientExpandAnimation,
//             axisAlignment: -1.0,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Divider(height: 30, color: Colors.grey),
//                 _sectionHeader("Patient Information"),
//                 const SizedBox(height: 8),
//                 _infoRow("DOB", dob),
//                 _infoRow("Age", age),
//                 _infoRow("Gender", gender),
//                 _infoRow("Blood Type", bloodGroup),
//                 _infoRow("Created At", createdAt),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // 🏥 MEDICAL CARD
//   Widget _buildMedicalCard({
//     required String title,
//     required String doctorName,
//     required String doctorId,
//     required List<String> selectedOptions,
//   }) {
//     final showList = _isXrayExpanded
//         ? selectedOptions
//         : (selectedOptions.length > 2
//         ? selectedOptions.sublist(0, 2)
//         : selectedOptions);
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           Center(
//             child: Text(
//               title.isEmpty ? "Medical Information" : title,
//               style: TextStyle(
//                 color: primaryColor,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 0.3,
//               ),
//             ),
//           ),
//           const Divider(height: 25, color: Colors.grey),
//           _infoRow("Doctor Name", doctorName),
//           _infoRow("Doctor ID", doctorId),
//           const Divider(height: 30, color: Colors.grey),
//           _sectionHeader("Selected Options"),
//           const SizedBox(height: 10),
//           if (selectedOptions.isEmpty)
//             const Text(
//               "No Options Selected",
//               style: TextStyle(color: Colors.grey, fontSize: 15),
//             )
//           else
//             Column(
//               children: [
//                 ...showList.map(
//                       (option) => Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 4),
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.check_circle_outline,
//                           size: 18,
//                           color: Colors.green,
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             option,
//                             style: const TextStyle(
//                               color: Colors.black87,
//                               fontSize: 15,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 if (selectedOptions.length > 2)
//                   TextButton.icon(
//                     onPressed: _toggleXrayExpand,
//                     icon: Icon(
//                       _isXrayExpanded ? Icons.expand_less : Icons.expand_more,
//                       color: primaryColor,
//                     ),
//                     label: Text(
//                       _isXrayExpanded ? "Hide" : "View All",
//                       style: TextStyle(
//                         color: primaryColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _infoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               "$label :",
//               style: TextStyle(
//                 color: Colors.grey[800],
//                 fontWeight: FontWeight.w600,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 color: Colors.black87,
//                 fontSize: 15,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _sectionHeader(String text) {
//     return Center(
//       child: Text(
//         text,
//         style: TextStyle(
//           color: primaryColor,
//           fontSize: 16,
//           fontWeight: FontWeight.w700,
//           letterSpacing: 0.3,
//         ),
//       ),
//     );
//   }
//}
