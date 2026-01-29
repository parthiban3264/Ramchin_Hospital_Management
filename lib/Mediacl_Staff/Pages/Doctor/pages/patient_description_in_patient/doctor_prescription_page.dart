import 'package:flutter/material.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/Doctor/pages/patient_description_in_patient/patient_description_page.dart';
import 'package:intl/intl.dart';

import '../../../../../Pages/NotificationsPage.dart';
import '../../../../../Services/Injection_Service.dart';
import '../../../../../Services/Medicine_Service.dart';
import '../../../../../Services/Tonic_service.dart';
import '../../../../../Services/socket_service.dart';
import '../../widgets/medicine_card.dart';

class DoctorsPrescriptionPage extends StatefulWidget {
  final Map<String, dynamic> consultation;

  const DoctorsPrescriptionPage({super.key, required this.consultation});

  @override
  State<DoctorsPrescriptionPage> createState() =>
      DoctorsPrescriptionPageState();
}

class DoctorsPrescriptionPageState extends State<DoctorsPrescriptionPage> {
  final Color primaryColor = const Color(0xFFB68A51);
  final socketService = SocketService();

  late MedicineService medicineService;
  late TonicService tonicService;
  late InjectionService injectionService;
  bool medicineTonicInjection = false;
  bool injection = false;

  static List<Map<String, dynamic>> submittedMedicines = [];
  List<Map<String, dynamic>> submittedTonics = [];
  List<Map<String, dynamic>> submittedInjections = [];
  bool isLoading = false;
  String? dateTime;
  List<Map<String, dynamic>> allMedicines = [];
  bool medicinesLoaded = false;
  List<Map<String, dynamic>> allTonics = [];
  bool tonicsLoaded = false;
  List<Map<String, dynamic>> allInjection = [];
  bool injectionsLoaded = false;

  List<Map<String, dynamic>> persistentMedicineEntries = [];
  // List<Map<String, dynamic>> persistentTonicsEntries = [];
  // List<Map<String, dynamic>> persistentInjectionEntries = [];

  @override
  void initState() {
    super.initState();

    medicineService = MedicineService();
    tonicService = TonicService();
    injectionService = InjectionService();

    submittedMedicines = PatientDescriptionInState.submittedMedicines
        .map(
          (m) => {
            ...m,
            'days': m['days'] ?? m['day'] ?? '0',
            // 'days': m['days'] ?? m['day'] ?? '0',
          },
        )
        .toList();

    //I/flutter ( 9484): [{name: paracetamol , price: 1.96, qtyPerDose: 1.0, afterEat: true, morning: true, afternoon: false, night: true, days: 10, weeks: 0, months: 0, total: 39.2, medicineId: 4, route: Tablet, batch_No: 01, medicine_Id: 4, batch_Id: 01, dosage: 1 tablet, frequency: once, total_quantity: 20, after_food: true, instructions: , quantityNeeded: 20.0, quantity: 20}]
    persistentMedicineEntries = List<Map<String, dynamic>>.from(
      submittedMedicines,
    );

    _loadAllMedicines();
    _loadAllTonics();
    _loadAllInjections();
    _updateTime();
  }

  void _updateTime() {
    dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
  }

  Future<void> _loadAllMedicines() async {
    try {
      if (!medicinesLoaded) {
        final results = await medicineService.getAllMedicines();

        if (mounted) {
          setState(() {
            allMedicines = results;
            medicinesLoaded = true;
          });
        }
      }
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _loadAllTonics() async {
    try {
      if (!tonicsLoaded) {
        final results = await tonicService.getAllTonics();
        if (mounted) {
          setState(() {
            allTonics = results;
            tonicsLoaded = true;
          });
        }
      }
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _loadAllInjections() async {
    try {
      if (!injectionsLoaded) {
        final results = await injectionService.getAllInjection();
        if (mounted) {
          setState(() {
            allInjection = results;
            injectionsLoaded = true;
          });
        }
      }
    } catch (e) {
      setState(() {});
    }
  }

  void _onAddMedicine(List<Map<String, dynamic>> meds) {
    setState(() {
      submittedMedicines = meds.map((m) {
        return {
          ...m,
          'days': m['days'] ?? '0', // ✅ preserve days
        };
      }).toList();

      persistentMedicineEntries = List<Map<String, dynamic>>.from(
        submittedMedicines,
      );
    });
  }

  Future<void> _handleSubmitPrescription() async {
    PatientDescriptionInState.onSavedPrescriptions(
      submittedMedicine: submittedMedicines,
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _handleSubmitPrescription(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: PreferredSize(
          preferredSize: Size(MediaQuery.of(context).size.width, 110),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // AppBar Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                          onPressed: () => _handleSubmitPrescription(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Doctor Prescription ",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        body: _buildMedicineTab(),

        // <-- Your submit button goes here
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primaryColor,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onPressed: isLoading ? null : _handleSubmitPrescription,
          label: isLoading
              ? Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Submitting...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: const [
                    Icon(Icons.done_all, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Submit Prescription",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMedicineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          MedicineCard(
            primaryColor: primaryColor,
            medicineService: medicineService,
            allMedicines: allMedicines,
            medicinesLoaded: medicinesLoaded,
            onAdd: _onAddMedicine,
            expanded: true,
            onExpandToggle: () {},
            initialSavedMedicines: persistentMedicineEntries, // ✅ restored data
          ),

          const SizedBox(height: 16),
          if (submittedMedicines.isNotEmpty ||
              submittedTonics.isNotEmpty ||
              submittedInjections.isNotEmpty)
            _buildCombinedSummaryCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCombinedSummaryCard() {
    if (submittedMedicines.isEmpty &&
        submittedTonics.isEmpty &&
        submittedInjections.isEmpty) {
      return const SizedBox.shrink();
    }

    // double parseTotal(dynamic total) {
    //   return double.tryParse(total?.toString() ?? '0') ?? 0.0;
    // }
    //
    // double totalSum = 0.0;
    // totalSum += submittedMedicines.fold(
    //   0.0,
    //   (sum, item) => sum + parseTotal(item['total']),
    // );
    // totalSum += submittedTonics.fold(
    //   0.0,
    //   (sum, item) => sum + parseTotal(item['total']),
    // );
    // totalSum += submittedInjections.fold(
    //   0.0,
    //   (sum, item) => sum + parseTotal(item['total']),
    // );

    Widget buildSection(String title, List<Map<String, dynamic>> items) {
      if (items.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 👈 left align
          children: [
            // 🔹 Section Title
            Text(
              title,
              style: TextStyle(
                color: primaryColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            // 🔹 Item List
            ...items.map((item) {
              final name = item['name']?.toString().trim() ?? '';
              // final qty = item['qtyPerDose']?.toString().trim() ?? '0';
              final qtyPerDose =
                  item['qtyPerDose']?.toString().split('.').first ?? '0';
              final day = item['days']?.toString().trim() ?? '0';

              final qty = item['quantity']?.toString().trim() ?? '0';
              final morning = item['morning'] == true ? qtyPerDose : 0;
              final afternoon = item['afternoon'] == true ? qtyPerDose : 0;
              final night = item['night'] == true ? qtyPerDose : 0;
              final qtyI =
                  RegExp(
                    r'\d+',
                  ).firstMatch(item['quantity']?.toString() ?? '')?.group(0) ??
                  '0';

              final mn = item['morning'] == true ? qtyI : 0;
              final af = item['afternoon'] == true ? qtyI : 0;
              final nt = item['night'] == true ? qtyI : 0;
              // final total = item['total']?.toString().trim() ?? '';
              final afterEat = item['afterEat'] == true
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orangeAccent.withValues(alpha: 0.2);
              // String getDays(String day) {
              //   if (day.isEmpty || day == "0") return qty;
              //   return "${day}d";
              // }
              String getDays(String day, String qty) {
                if (day.isEmpty || day == "0") {
                  return qty; // show qty when day is empty
                }
                return "${day}d"; // show days only
              }

              if (name.isEmpty && qty.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    // Medicine Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 6),
                    title != 'Injections'
                        ? Text(
                            "( $qty )", //x
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            "( ${getDays(day, qty)} )", //x
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    const SizedBox(width: 4),
                    Spacer(),

                    // Dosage (M-A-N)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: afterEat,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title == 'Medicines')
                            Text(
                              "$morning - $afternoon - $night",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),

                          if (title == 'Tonics')
                            Text(
                              "$morning - $afternoon - $night",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          if (title == 'Injections')
                            Text(
                              "$mn - $af - $nt",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            Text(
              "Prescription Summary",
              style: TextStyle(
                color: primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(thickness: 2, color: Colors.grey, height: 24),
            buildSection("Medicines", submittedMedicines),
            buildSection("Tonics", submittedTonics),
            buildSection("Injections", submittedInjections),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// Widget _buildTonicTab() {
//   return SingleChildScrollView(
//     padding: const EdgeInsets.all(4),
//     child: Column(
//       children: [
//         TonicCard(
//           primaryColor: primaryColor,
//           tonicService: tonicService,
//           allTonics: allTonics,
//           tonicsLoaded: tonicsLoaded,
//           onAdd: _onAddTonic,
//           expanded: true,
//           onExpandToggle: () {},
//           initialSavedTonics: persistentTonicsEntries,
//         ),
//         const SizedBox(height: 16),
//         if (submittedMedicines.isNotEmpty ||
//             submittedTonics.isNotEmpty ||
//             submittedInjections.isNotEmpty)
//           _buildCombinedSummaryCard(),
//         const SizedBox(height: 80),
//       ],
//     ),
//   );
// }
//
// Widget _buildInjectionTab() {
//   return SingleChildScrollView(
//     padding: const EdgeInsets.all(4),
//     child: Column(
//       children: [
//         InjectionCard(
//           primaryColor: primaryColor,
//           injectionService: injectionService,
//           allInjection: allInjection,
//           injectionsLoaded: injectionsLoaded,
//           onAdd: _onAddInjection,
//           expanded: true,
//           onExpandToggle: () {},
//           initialSavedInjection: persistentInjectionEntries,
//         ),
//         const SizedBox(height: 16),
//         if (submittedMedicines.isNotEmpty ||
//             submittedTonics.isNotEmpty ||
//             submittedInjections.isNotEmpty)
//           _buildCombinedSummaryCard(),
//         const SizedBox(height: 80),
//       ],
//     ),
//   );
// }
//
// Widget _buildOthersTab() {
//   return Column(
//     children: [
//       // 🟢 Takes available height
//       Expanded(child: OtherCard(onAdd: (othersList) {})),
//
//       // 🔽 Summary Card (Fixed at bottom)
//       _buildCombinedSummaryCard(),
//
//       const SizedBox(height: 80),
//     ],
//   );
// }

// void _onAddTonic(List<Map<String, dynamic>> tonics) {
//   setState(() {
//     // Replace entire summary list with the latest from MedicineCard
//     submittedTonics = List<Map<String, dynamic>>.from(tonics);
//   });
// }
//
// void _onAddInjection(List<Map<String, dynamic>> injections) {
//   setState(() {
//     // Replace entire summary list with the latest from MedicineCard
//     submittedInjections = List<Map<String, dynamic>>.from(injections);
//   });
// }

// Future<void> _handleSubmitPrescription() async {
//   if (submittedMedicines.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Please add at least one item!")),
//     );
//     return;
//   }
//
//   setState(() => _isLoading = true);
//
//   final List<Map<String, dynamic>> medicineList = submittedMedicines.map((m) {
//     final qtyPerDose = m['qtyPerDose'] == 1 / 2 ? 0.5 : m['qtyPerDose'];
//     return {
//       'medicine_Id': int.parse(m['medicineId'].toString()),
//       'consultation_Id': widget.consultation['id'],
//       'route': m['route'].toString().toUpperCase(),
//       'quantity': qtyPerDose,
//       'afterEat': m['afterEat'],
//       'morning': m['morning'],
//       'afternoon': m['afternoon'],
//       'night': m['night'],
//       'days': m['days'],
//       //'quantityNeeded': m['quantity'],
//       'total_quantity': m['quantity'],
//       'dosage': m['qtyPerDose'].toString(),
//       'total': m['total'],
//     };
//   }).toList();
//
//   final Map<String, dynamic> prescriptionData = {
//     'hospital_Id': widget.consultation['hospital_Id'],
//     'patient_Id': widget.consultation['patient_Id'].toString(),
//     'doctor_Id': widget.consultation['Doctor']?['doctorId'].toString(),
//     'consultation_Id': widget.consultation['id'],
//     'createdAt': _dateTime.toString(),
//     'medicines': medicineList,
//     // 'tonics': tonicList,
//     // 'injections': injectionList,
//   };
//
//   try {
//     // await PrescriptionService().createPrescription(prescriptionData);
//     final prescription = await PrescriptionService().createPrescription(
//       prescriptionData,
//     );
//     final prefs = await SharedPreferences.getInstance();
//     final userId = prefs.getString('userId');
//
//     final firstMedicine = submittedMedicines[0];
//     await PrescriptionService().createPrescriptionDispense({
//       "hospital_Id": widget.consultation['hospital_Id'],
//       "prescription_medicine_Id": prescription['medicines'][0]['id'],
//       "batch_Id": firstMedicine['batch_Id'],
//       "dispensed_quantity": firstMedicine['quantity'],
//       "pharmacist_Id": userId,
//     });
//
//     // await PrescriptionService().createPrescriptionDispense(prescriptionData);
//     final consultationId = widget.consultation['id'];
//     if (consultationId == null && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Consultation ID not found')),
//       );
//       return;
//     }
//     setState(() {
//       // permanent flag for injection
//       if (submittedInjections.isNotEmpty) {
//         injection = true; // once true, stays true
//       }
//
//       // permanent flag for medicine/tonic/injection combined
//       if (submittedMedicines.isNotEmpty) {
//         medicineTonicInjection = true; // once true, stays true
//       }
//     });
//
//     await ConsultationService().updateConsultation(consultationId, {
//       'status': 'ONGOING',
//       // 'scanningTesting': scanningTesting,
//       'medicineTonic': medicineTonicInjection,
//       'Injection': injection,
//       'queueStatus': 'COMPLETED', //change
//       'updatedAt': _dateTime.toString(),
//     });
//     if (mounted) {
//       Navigator.pop(context, {
//         'medicine': submittedMedicines.isNotEmpty,
//         // 'tonic': submittedTonics.isNotEmpty,
//         // 'injection': submittedInjections.isNotEmpty,
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Prescription submitted successfully!"),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Failed to submit: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   } finally {
//     setState(() {
//       _isLoading = false;
//     });
//   }
// }
