import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/Injection_Service.dart';
import '../../../../Services/Medi_Tonic_Injection_service.dart';
import '../../../../Services/Medicine_Service.dart';
import '../../../../Services/Tonic_service.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/socket_service.dart';
import '../widgets/injection_card.dart';
import '../widgets/medicine_card.dart';
import '../widgets/other_card.dart';
import '../widgets/tonic_card.dart';

class DoctorsPrescriptionPage extends StatefulWidget {
  final Map<String, dynamic> consultation;

  const DoctorsPrescriptionPage({super.key, required this.consultation});

  @override
  State<DoctorsPrescriptionPage> createState() =>
      _DoctorsPrescriptionPageState();
}

class _DoctorsPrescriptionPageState extends State<DoctorsPrescriptionPage>
    with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFB68A51);
  final socketService = SocketService();

  late MedicineService medicineService;
  late TonicService tonicService;
  late InjectionService injectionService;
  late TabController _tabController;
  bool medicineTonicInjection = false;
  bool injection = false;

  List<Map<String, dynamic>> submittedMedicines = [];
  List<Map<String, dynamic>> submittedTonics = [];
  List<Map<String, dynamic>> submittedInjections = [];
  bool _isLoading = false;
  String? _dateTime;
  List<Map<String, dynamic>> allMedicines = [];
  bool medicinesLoaded = false;
  List<Map<String, dynamic>> allTonics = [];
  bool tonicsLoaded = false;
  List<Map<String, dynamic>> allInjection = [];
  bool injectionsLoaded = false;

  List<Map<String, dynamic>> persistentMedicineEntries = [];
  List<Map<String, dynamic>> persistentTonicsEntries = [];
  List<Map<String, dynamic>> persistentInjectionEntries = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    medicineService = MedicineService();
    tonicService = TonicService();
    injectionService = InjectionService();
    _loadAllMedicines();
    _updateTime();
    _loadAllTonics();
    _loadAllInjections();
  }

  void _updateTime() {
    _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
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

  // void _onAddMedicine(List<Map<String, dynamic>> meds) {
  //   setState(() {
  //     for (var m in meds) {
  //       final existingIndex = submittedMedicines.indexWhere(
  //         (e) => e['medicineId'].toString() == m['medicineId'].toString(),
  //       );
  //       if (existingIndex != -1) {
  //         submittedMedicines[existingIndex] = {
  //           ...submittedMedicines[existingIndex],
  //           ...m,
  //         };
  //       } else {
  //         submittedMedicines.add(m);
  //       }
  //     }
  //   });
  // }
  void _onAddMedicine(List<Map<String, dynamic>> meds) {
    setState(() {
      // Replace entire summary list with the latest from MedicineCard
      submittedMedicines = List<Map<String, dynamic>>.from(meds);
    });
  }

  // void _onAddTonic(List<Map<String, dynamic>> tonics) {
  //   setState(() {
  //     for (var t in tonics) {
  //       final existingIndex = submittedTonics.indexWhere(
  //         (e) => e['tonic_Id'].toString() == t['tonic_Id'].toString(),
  //       );
  //       if (existingIndex != -1) {
  //         submittedTonics[existingIndex] = {
  //           ...submittedTonics[existingIndex],
  //           ...t,
  //         };
  //       } else {
  //         submittedTonics.add(t);
  //       }
  //     }
  //   });
  // }
  void _onAddTonic(List<Map<String, dynamic>> tonics) {
    setState(() {
      // Replace entire summary list with the latest from MedicineCard
      submittedTonics = List<Map<String, dynamic>>.from(tonics);
    });
  }

  // void _onAddInjection(List<Map<String, dynamic>> injections) {
  //   setState(() {
  //     for (var i in injections) {
  //       final existingIndex = submittedInjections.indexWhere(
  //         (e) => e['injection_Id'].toString() == i['injection_Id'].toString(),
  //       );
  //       if (existingIndex != -1) {
  //         submittedInjections[existingIndex] = {
  //           ...submittedInjections[existingIndex],
  //           ...i,
  //         };
  //       } else {
  //         submittedInjections.add(i);
  //       }
  //     }
  //   });
  // }
  void _onAddInjection(List<Map<String, dynamic>> injections) {
    setState(() {
      // Replace entire summary list with the latest from MedicineCard
      submittedInjections = List<Map<String, dynamic>>.from(injections);
    });
  }

  Future<void> _handleSubmitPrescription() async {
    if (submittedMedicines.isEmpty &&
        submittedTonics.isEmpty &&
        submittedInjections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one item!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final List<Map<String, dynamic>> medicineList = submittedMedicines.map((m) {
      final qtyPerDose = m['qtyPerDose'] == 1 / 2 ? 0.5 : m['qtyPerDose'];
      return {
        'medicine_Id': int.parse(m['medicineId'].toString()),
        'consultation_Id': widget.consultation['id'],
        'quantity': qtyPerDose,
        'afterEat': m['afterEat'],
        'morning': m['morning'],
        'afternoon': m['afternoon'],
        'night': m['night'],
        'days': m['days'],
        'quantityNeeded': m['quantity'],
        'total': m['total'],
      };
    }).toList();

    final List<Map<String, dynamic>> tonicList = submittedTonics.map((t) {
      final quantityStr = t['quantity'].toString().trim().toLowerCase();
      final quantityValue =
          double.tryParse(quantityStr.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0.0;
      return {
        'tonic_Id': int.parse(t['tonic_Id'].toString()),
        'consultation_Id': widget.consultation['id'],
        'quantity': quantityValue,
        'Doase': t['qtyPerDose'].toString(),
        'afterEat': t['afterEat'],
        'morning': t['morning'],
        'afternoon': t['afternoon'],
        'night': t['night'],
        'total': int.parse(t['total']),
      };
    }).toList();

    final List<Map<String, dynamic>> injectionList = submittedInjections.map((
      i,
    ) {
      final quantityStr = i['quantity'].toString().trim().toLowerCase();
      final quantityValue =
          double.tryParse(quantityStr.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0.0;
      return {
        'injection_Id': int.parse(i['injection_Id'].toString()),
        'consultation_Id': widget.consultation['id'],
        'quantity': quantityValue,
        'Doase': i['quantity'].toString(),
        'morning': i['morning'] ?? false,
        'afternoon': i['afternoon'] ?? false,
        'night': i['night'] ?? false,
        'total': int.parse(i['total']),
      };
    }).toList();

    final Map<String, dynamic> prescriptionData = {
      'hospital_Id': widget.consultation['hospital_Id'],
      'patient_Id': widget.consultation['patient_Id'].toString(),
      'doctor_Id': widget.consultation['Doctor']?['doctorId'].toString(),
      'consultation_Id': widget.consultation['id'],
      'createdAt': _dateTime.toString(),
      'medicines': medicineList,
      'tonics': tonicList,
      'injections': injectionList,
    };

    try {
      await MedicineTonicInjectionService().createMediTonicInj(
        prescriptionData,
      );
      final consultationId = widget.consultation['id'];
      if (consultationId == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation ID not found')),
        );
        return;
      }
      setState(() {
        // permanent flag for injection
        if (submittedInjections.isNotEmpty) {
          injection = true; // once true, stays true
        }

        // permanent flag for medicine/tonic/injection combined
        if (submittedMedicines.isNotEmpty ||
            submittedTonics.isNotEmpty ||
            submittedInjections.isNotEmpty) {
          medicineTonicInjection = true; // once true, stays true
        }
      });

      await ConsultationService().updateConsultation(consultationId, {
        'status': 'ONGOING',
        // 'scanningTesting': scanningTesting,
        'medicineTonic': medicineTonicInjection,
        'Injection': injection,
        'queueStatus': 'COMPLETED', //change
        'updatedAt': _dateTime.toString(),
      });
      if (mounted) {
        Navigator.pop(context, {
          'medicine': submittedMedicines.isNotEmpty,
          'tonic': submittedTonics.isNotEmpty,
          'injection': submittedInjections.isNotEmpty,
        });

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
        _isLoading = false;
        // medicineTonicInjection = false;
        // injection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: Size(MediaQuery.of(context).size.width, 110),
        child: Container(
          // height: 150,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Doctor Prescription",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
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

                // Modern TabBar Container
                // const SizedBox(height: 2),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: SizedBox(
                    height: 35, // 👈 make TabBar shorter (try 30–38)
                    child: TabBar(
                      // padding: EdgeInsets.symmetric(horizontal: 12),
                      controller: _tabController,
                      dividerColor: Colors.transparent,

                      // only ONE indicator – the pill style
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),

                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ), // tighter
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16, // 👈 slightly smaller text
                      ),

                      tabs: const [
                        Tab(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ), // 👈 padding inside pill

                            child: Text(
                              "Medicine",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Tab(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(" Tonic "),
                          ),
                        ),
                        Tab(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),

                            child: Text(
                              "Injection",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Tab(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("Others"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMedicineTab(),
                _buildTonicTab(),
                _buildInjectionTab(),

                _buildOthersTab(),
              ],
            ),
          ),
        ],
      ),

      // <-- Your submit button goes here
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onPressed: _isLoading ? null : _handleSubmitPrescription,
        label: _isLoading
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
            initialSavedMedicines: persistentMedicineEntries,
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

  Widget _buildTonicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          TonicCard(
            primaryColor: primaryColor,
            tonicService: tonicService,
            allTonics: allTonics,
            tonicsLoaded: tonicsLoaded,
            onAdd: _onAddTonic,
            expanded: true,
            onExpandToggle: () {},
            initialSavedTonics: persistentTonicsEntries,
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

  Widget _buildInjectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          InjectionCard(
            primaryColor: primaryColor,
            injectionService: injectionService,
            allInjection: allInjection,
            injectionsLoaded: injectionsLoaded,
            onAdd: _onAddInjection,
            expanded: true,
            onExpandToggle: () {},
            initialSavedInjection: persistentInjectionEntries,
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

  // Widget _buildOthersTab() {
  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(4),
  //     child: Column(
  //       children: [
  //         OtherCard(
  //           onAdd: (othersList) {
  //
  //           },
  //         ),
  //
  //         // const SizedBox(height: 16),
  //         // if (submittedMedicines.isNotEmpty ||
  //         //     submittedTonics.isNotEmpty ||
  //         //     submittedInjections.isNotEmpty)
  //         _buildCombinedSummaryCard(),
  //         const SizedBox(height: 80),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildOthersTab() {
    return Column(
      children: [
        // 🟢 Takes available height
        Expanded(child: OtherCard(onAdd: (othersList) {})),

        // 🔽 Summary Card (Fixed at bottom)
        _buildCombinedSummaryCard(),

        const SizedBox(height: 80),
      ],
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
            // Divider(color: Colors.grey.shade300),
            // Text(
            //   "Total: ₹${totalSum.toStringAsFixed(2)}",
            //   style: const TextStyle(
            //     fontSize: 16,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.black87,
            //   ),
            //   textAlign: TextAlign.right,
            // ),
          ],
        ),
      ),
    );
  }
}
