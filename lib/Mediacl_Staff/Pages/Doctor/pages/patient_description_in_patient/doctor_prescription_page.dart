import 'package:flutter/material.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/Doctor/pages/patient_description_in_patient/patient_description_page.dart';
import 'package:intl/intl.dart';

import '../../../../../Pages/NotificationsPage.dart';
import '../../../../../Services/Injection_Service.dart';
import '../../../../../Services/Medicine_Service.dart';
import '../../../../../Services/Tonic_service.dart';
import '../../../../../Services/consultation_service.dart';
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

  int _onAddCallCount = 0;

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

  Future<void> _onAddMedicine(List<Map<String, dynamic>> meds) async {
    final currentCall = ++_onAddCallCount;
    // Debounce: wait for user to stop typing
    await Future.delayed(const Duration(milliseconds: 300));
    if (currentCall != _onAddCallCount) return;

    // 1️⃣ Create a map of current allocations so we can "restore" them in our local calculation
    // without corrupting the base allMedicines data.
    Map<int, int> oldAllocMap = {};
    for (var oldMed in submittedMedicines) {
      final List allocated = oldMed['allocated_batches'] ?? [];
      if (allocated.isNotEmpty) {
        for (var alloc in allocated) {
          final bId = alloc['batch_id'];
          final aqty =
              int.tryParse(alloc['allocated_qty']?.toString() ?? '0') ?? 0;
          if (bId != null) {
            oldAllocMap[bId] = (oldAllocMap[bId] ?? 0) + aqty;
          }
        }
      } else {
        final bId = oldMed['batch_Id'];
        final qty = int.tryParse(oldMed['quantity']?.toString() ?? '0') ?? 0;
        if (bId != null) {
          oldAllocMap[bId] = (oldAllocMap[bId] ?? 0) + qty;
        }
      }
    }

    // 2️⃣ Group incoming meds by medicineId to prevent duplicate processing
    Map<int, Map<String, dynamic>> groupedMeds = {};
    for (var med in meds) {
      // Ensure we check both common keys
      int? id =
          int.tryParse(med['medicineId']?.toString() ?? '') ??
          int.tryParse(med['medicine_Id']?.toString() ?? '');
      if (id == null) continue;

      int qty = int.tryParse(med['quantity']?.toString() ?? '0') ?? 0;
      if (qty <= 0) continue;

      if (groupedMeds.containsKey(id)) {
        groupedMeds[id]!['quantity'] =
            (groupedMeds[id]!['quantity'] ?? 0) + qty;
      } else {
        groupedMeds[id] = Map<String, dynamic>.from(med);
        groupedMeds[id]!['quantity'] = qty;
      }
    }

    final List<Map<String, dynamic>> newlyAllocated = [];

    // 3️⃣ Rebuild from grouped data
    for (var medEntry in groupedMeds.values) {
      if (currentCall != _onAddCallCount) return;

      int finalQty = medEntry['quantity'];
      int medicineId =
          int.tryParse(medEntry['medicineId']?.toString() ?? '') ??
          int.tryParse(medEntry['medicine_Id']?.toString() ?? '') ??
          0;

      var selectedMed = allMedicines.firstWhere(
        (m) => m['id'] == medicineId,
        orElse: () => {},
      );
      if (selectedMed.isEmpty) continue;

      List batches = List.from(selectedMed['batches'] ?? []);

      // Fetch dispensed quantity
      Map<int, int> dispensedMapForMed = {};
      try {
        final List<dynamic> dispenseData =
            await ConsultationService.getDispense(medicineId);
        for (var item in dispenseData) {
          final bId = item['batch_Id'];
          final sum = item['_sum'];
          if (bId != null && sum != null) {
            dispensedMapForMed[bId] =
                int.tryParse(sum['dispensed_quantity']?.toString() ?? '0') ?? 0;
          }
        }
      } catch (e) {
        debugPrint("Error fetching dispense data: $e");
      }

      // Check Total True Available
      int totalTrueAvailable = 0;
      for (var b in batches) {
        int bId = b['id'];
        int totalOriginalStock =
            int.tryParse(b['total_stock']?.toString() ?? '0') ?? 0;
        // Adjusted Dispensed = DB Dispensed - Our Old Allocation (to restore it locally)
        int dbDispensed = dispensedMapForMed[bId] ?? 0;
        int ourOld = oldAllocMap[bId] ?? 0;
        int adjustedDispensed = (dbDispensed - ourOld).clamp(0, dbDispensed);

        int trueAvailable = (totalOriginalStock - adjustedDispensed).clamp(
          0,
          totalOriginalStock,
        );
        totalTrueAvailable += trueAvailable;
      }

      if (finalQty > totalTrueAvailable) {
        if (mounted && currentCall == _onAddCallCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Only $totalTrueAvailable stock available for ${medEntry['name']}",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      int remainingQty = finalQty;
      List<Map<String, dynamic>> batchesForThisMed = [];
      double actualTotalPrice = 0;

      for (var batch in batches) {
        if (remainingQty <= 0) break;

        int bId = batch['id'];
        int totalOriginalStock =
            int.tryParse(batch['total_stock']?.toString() ?? '0') ?? 0;
        int dbDispensed = dispensedMapForMed[bId] ?? 0;
        int ourOld = oldAllocMap[bId] ?? 0;
        int adjustedDispensed = (dbDispensed - ourOld).clamp(0, dbDispensed);

        int trueAvailable = (totalOriginalStock - adjustedDispensed).clamp(
          0,
          totalOriginalStock,
        );

        if (trueAvailable <= 0) continue;

        int usedQty = remainingQty <= trueAvailable
            ? remainingQty
            : trueAvailable;
        double unitPrice =
            double.tryParse(batch['selling_price_unit']?.toString() ?? '0') ??
            0;
        double batchTotal = double.parse(
          (usedQty * unitPrice).toStringAsFixed(2),
        );

        batchesForThisMed.add({
          'batch_id': bId,
          'batch_no': batch['batch_no'],
          'allocated_qty': usedQty,
          'unit_price': unitPrice,
          'batch_total': batchTotal,
        });

        actualTotalPrice += batchTotal;
        remainingQty -= usedQty;
      }

      if (batchesForThisMed.isNotEmpty) {
        newlyAllocated.add({
          ...medEntry,
          'quantity': finalQty,
          'total': double.parse(actualTotalPrice.toStringAsFixed(2)),
          'allocated_batches': batchesForThisMed,
          'batch_Id': batchesForThisMed[0]['batch_id'],
          'batch_no': batchesForThisMed[0]['batch_no'],
        });
      }
    }

    if (currentCall == _onAddCallCount) {
      if (mounted) {
        setState(() {
          submittedMedicines = newlyAllocated;
          persistentMedicineEntries = List<Map<String, dynamic>>.from(
            submittedMedicines,
          );
        });
      }
    }
  }

  Future<void> _handleSubmitPrescription() async {
    PatientDescriptionInState.onSavedPrescriptions(
      submittedMedicine: submittedMedicines,
    );
    Navigator.pop(context, true);
  }

  List<Map<String, dynamic>> allocateBatches(
    List<dynamic> batches,
    int requestedQty,
  ) {
    List<Map<String, dynamic>> allocated = [];
    int remainingQty = requestedQty;

    for (var batch in batches) {
      int available =
          int.tryParse(batch['total_stock']?.toString() ?? '0') ?? 0;

      if (remainingQty <= 0) break;

      if (available > 0) {
        int usedQty = remainingQty <= available ? remainingQty : available;

        double unitPrice =
            double.tryParse(batch['selling_price_unit']?.toString() ?? '0') ??
            0;

        allocated.add({
          'batch_id': batch['id'],
          'batch_no': batch['batch_no'],
          'allocated_qty': usedQty,
          'unit_price': unitPrice,
          'batch_total': usedQty * unitPrice,
        });

        remainingQty -= usedQty;
      }
    }

    return allocated;
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
    // print(allMedicines);
    //I/flutter ( 9099): [{id: 1, name: paracitamol, category: Tablets, batches: [{id: 28, hospital_Id: 1, medicine_id: 1, HSN: cd, batch_no: 02, expiry_date: 2026-02-03T00:00:00.000Z, manufacture_date: 2026-02-01T00:00:00.000Z, total_stock: 100, total_quantity: 100, quantity: 100, free_quantity: 0, unit: 1, rack_no: 1, mrp: 20, profit: 50, purchase_price_unit: 10.3, purchase_price_quantity: 10.3, selling_price_quantity: 15.45, selling_price_unit: 15.45, purchase_details: {base_amount: 1000, gst_percent: 3, purchase_date: 2026-02-01, purchase_price: 1030, gst_per_quantity: 0.3, total_gst_amount: 30, rate_per_quantity: 10}, supplier_id: 1, is_active: true, created_at: 2026-01-31T09:41:19.670Z}]}, {id: 3, name: anacin, category: Tablet, batches: [{id: 29, hospital_Id: 1, medicine_id: 3, HSN: null, batch_no: 1, expiry_date: 2026-03-31T00:00:00.000Z, manufacture_date: 2026-01-31T00:00:00.000Z, total_stock: 100, total_quantity: 100, quantity: 100, free_quantity: null, unit: 1, rack_no: 12, mrp: null, profit: null, purchase_price_unit: nu
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
    print(submittedMedicines);
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
            // buildSection("Tonics", submittedTonics),
            // buildSection("Injections", submittedInjections),
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
