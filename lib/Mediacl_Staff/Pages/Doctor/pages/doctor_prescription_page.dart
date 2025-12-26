// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// import '../appbar/doctor_appbar_mobile.dart';
// import '../service/doctor_service.dart';
// import 'patient_description_page.dart';
//
// class DoctorPrescriptionPage extends StatefulWidget {
//   final Map<String, dynamic> consultation;
//
//   const DoctorPrescriptionPage({Key? key, required this.consultation})
//     : super(key: key);
//
//   @override
//   State<DoctorPrescriptionPage> createState() => _DoctorPrescriptionPageState();
// }
//
// class _DoctorPrescriptionPageState extends State<DoctorPrescriptionPage> {
//   final _medicineNameController = TextEditingController();
//   final _medicineDosageController = TextEditingController();
//   final _medicineFrequencyController = TextEditingController();
//   final _medicineDurationController = TextEditingController();
//   final _medicineNotesController = TextEditingController();
//
//   final _injectionNameController = TextEditingController();
//   final _injectionDosageController = TextEditingController();
//   final _injectionDurationController = TextEditingController();
//   final _injectionNotesController = TextEditingController();
//
//   final List<Map<String, String>> medicines = [];
//   final List<Map<String, String>> injections = [];
//
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//   bool _isLoading = false;
//
//   Future<void> submit() async {
//     if (medicines.isEmpty && injections.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please add at least one medicine or injection.'),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final hospitalId = widget.consultation['hospital_Id'];
//       final patientId = widget.consultation['patient_Id'];
//       final doctorId = await secureStorage.read(key: 'userId') ?? '';
//
//       await DoctorServices.createMedicineInjection({
//         "hospital_Id": hospitalId,
//         "patient_Id": patientId,
//         "doctor_Id": doctorId,
//         "staff_Id": [],
//         "medicine_Id": medicines.map((m) => m['name']).toList(),
//         "dosageMedicine": medicines.map((m) => m['dosage']).toList(),
//         "medicineNotes": medicines.map((m) => m['notes']).toList(),
//         "frequencyMedicine": medicines
//             .map(
//               (m) => {
//                 "medicineId": m['name'],
//                 "timesPerDay": int.tryParse(m['frequency'] ?? '1') ?? 1,
//               },
//             )
//             .toList(),
//         "durationMedicine": medicines.map((m) => m['duration']).toList(),
//         "injection_Id": injections.map((i) => i['name']).toList(),
//         "dosageInjection": injections.map((i) => i['dosage']).toList(),
//         "injectionNotes": injections.map((i) => i['notes']).toList(),
//         "durationInjection": injections.map((i) => i['duration']).toList(),
//         "frequencyInjection": injections
//             .map((i) => {"injectionId": i['name'], "timesPerWeek": 1})
//             .toList(),
//         "status": "PENDING",
//         "paymentStatus": false,
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Prescription submitted successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//
//       Navigator.pop(context, true);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error submitting prescription: $e')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<bool> onWillPop() async {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             PatientDescriptionPage(consultation: widget.consultation),
//       ),
//     );
//     return false;
//   }
//
//   void _addMedicine() {
//     if (_medicineNameController.text.isEmpty ||
//         _medicineDosageController.text.isEmpty ||
//         _medicineFrequencyController.text.isEmpty ||
//         _medicineDurationController.text.isEmpty)
//       return;
//
//     setState(() {
//       medicines.add({
//         'name': _medicineNameController.text,
//         'dosage': _medicineDosageController.text,
//         'frequency': _medicineFrequencyController.text,
//         'duration': _medicineDurationController.text,
//         'notes': _medicineNotesController.text,
//       });
//       _medicineNameController.clear();
//       _medicineDosageController.clear();
//       _medicineFrequencyController.clear();
//       _medicineDurationController.clear();
//       _medicineNotesController.clear();
//     });
//   }
//
//   void _addInjection() {
//     if (_injectionNameController.text.isEmpty ||
//         _injectionDosageController.text.isEmpty ||
//         _injectionDurationController.text.isEmpty)
//       return;
//
//     setState(() {
//       injections.add({
//         'name': _injectionNameController.text,
//         'dosage': _injectionDosageController.text,
//         'duration': _injectionDurationController.text,
//         'notes': _injectionNotesController.text,
//       });
//       _injectionNameController.clear();
//       _injectionDosageController.clear();
//       _injectionDurationController.clear();
//       _injectionNotesController.clear();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.sizeOf(context).width;
//
//     return WillPopScope(
//       onWillPop: onWillPop,
//       child: Scaffold(
//         backgroundColor: Colors.grey.shade100,
//         appBar: PreferredSize(
//           preferredSize: Size(screenWidth, 100),
//           child: DoctorAppbarMobile(
//             title: 'Prescription Entry',
//             isDrawerEnable: false,
//             isBackEnable: true,
//             onBack: onWillPop,
//             isNotificationEnable: false,
//           ),
//         ),
//         body: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 20),
//                     _buildContainer(
//                       title: 'Medicines',
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           _buildThreeFieldRow(
//                             _medicineNameController,
//                             'Name',
//                             _medicineDosageController,
//                             'Dosage',
//                             _medicineDurationController,
//                             'Duration',
//                           ),
//                           const SizedBox(height: 8),
//                           _buildTextField(
//                             _medicineFrequencyController,
//                             'Frequency',
//                           ),
//                           const SizedBox(height: 8),
//                           _buildTextField(
//                             _medicineNotesController,
//                             'Additional Notes',
//                           ),
//                           const SizedBox(height: 10),
//                           Align(
//                             alignment: Alignment.centerRight,
//                             child: ElevatedButton.icon(
//                               onPressed: _addMedicine,
//                               icon: const Icon(Icons.add),
//                               label: const Text('Add Medicine'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.blue.shade700,
//                                 foregroundColor: Colors.white,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           _buildItemList(
//                             medicines,
//                             Colors.blue.shade50,
//                             isMedicine: true,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     _buildContainer(
//                       title: 'Injections',
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           _buildThreeFieldRow(
//                             _injectionNameController,
//                             'Name',
//                             _injectionDosageController,
//                             'Dosage',
//                             _injectionDurationController,
//                             'Duration',
//                           ),
//                           const SizedBox(height: 8),
//                           _buildTextField(
//                             _injectionNotesController,
//                             'Additional Notes',
//                           ),
//                           const SizedBox(height: 10),
//                           Align(
//                             alignment: Alignment.centerRight,
//                             child: ElevatedButton.icon(
//                               onPressed: _addInjection,
//                               icon: const Icon(Icons.add),
//                               label: const Text('Add Injection'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.green.shade700,
//                                 foregroundColor: Colors.white,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           _buildItemList(
//                             injections,
//                             Colors.green.shade50,
//                             isMedicine: false,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton.icon(
//                       onPressed: submit,
//                       icon: const Icon(Icons.save),
//                       label: const Text('Submit Prescription'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 30,
//                           vertical: 14,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
//
//   Widget _buildContainer({required String title, required Widget child}) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: const [
//           BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
//           child,
//         ],
//       ),
//     );
//   }
//
//   Widget _buildThreeFieldRow(
//     TextEditingController c1,
//     String label1,
//     TextEditingController c2,
//     String label2,
//     TextEditingController c3,
//     String label3,
//   ) {
//     return Row(
//       children: [
//         Expanded(child: _buildTextField(c1, label1)),
//         const SizedBox(width: 8),
//         Expanded(child: _buildTextField(c2, label2)),
//         const SizedBox(width: 8),
//         Expanded(child: _buildTextField(c3, label3)),
//       ],
//     );
//   }
//
//   Widget _buildTextField(
//     TextEditingController controller,
//     String label, {
//     int maxLines = 1,
//   }) {
//     return TextField(
//       controller: controller,
//       maxLines: maxLines,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//         filled: true,
//         fillColor: Colors.white,
//       ),
//     );
//   }
//
//   Widget _buildItemList(
//     List<Map<String, String>> items,
//     Color bgColor, {
//     required bool isMedicine,
//   }) {
//     if (items.isEmpty) {
//       return const Text(
//         'No items added yet.',
//         style: TextStyle(color: Colors.grey),
//       );
//     }
//     return Column(
//       children: items.map((item) {
//         return Card(
//           color: bgColor,
//           margin: const EdgeInsets.symmetric(vertical: 5),
//           child: ListTile(
//             title: Text(
//               item['name']!,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Dosage: ${item['dosage']}'),
//                 if (isMedicine) Text('Frequency: ${item['frequency']}'),
//                 Text('Duration: ${item['duration']}'),
//                 if (item['notes']!.isNotEmpty) Text('Notes: ${item['notes']}'),
//               ],
//             ),
//             trailing: IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red),
//               onPressed: () => setState(() => items.remove(item)),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }
