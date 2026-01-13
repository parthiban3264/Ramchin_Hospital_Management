import 'dart:async';

import 'package:flutter/material.dart';

import '../../../Pages/NotificationsPage.dart';
import '../../../services/consultation_service.dart';
import 'medicalFeePage.dart';

class MedicalQueuePage extends StatefulWidget {
  const MedicalQueuePage({super.key});

  @override
  State<MedicalQueuePage> createState() => _MedicalQueuePageState();
}

class _MedicalQueuePageState extends State<MedicalQueuePage>
    with TickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFBF955E);

  late Future<List<dynamic>> consultationsFuture;
  List<dynamic> consultationsCache = [];
  bool firstLoad = true;

  Timer? refreshTimer;
  late TabController topTabController;
  late TabController bottomTabController;

  int bottomTabIndex = 0; // Track selected bottom tab

  @override
  void initState() {
    super.initState();
    topTabController = TabController(length: 2, vsync: this);
    bottomTabController = TabController(length: 3, vsync: this);
    consultationsFuture = _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    topTabController.dispose();
    bottomTabController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _loadData() async {
    final data = await ConsultationService.getAllConsultationByMedical(0);
    consultationsCache = data;
    print('consultationsCache $consultationsCache');
    return data;
  }

  void _startAutoRefresh() {
    refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final freshData = await ConsultationService.getAllConsultationByMedical(
          0,
        );
        if (mounted) {
          setState(() {
            consultationsCache = freshData;
          });
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _buildAppBar(),
      ),

      // ── BODY ──
      body: Column(
        children: [
          // TOP TABS → Today / Previous
          Material(
            color: Colors.white,
            elevation: 1,
            child: TabBar(
              controller: topTabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: "Today"),
                Tab(text: "Previous"),
              ],
            ),
          ),

          // CONTENT AREA → patient list filtered by bottom tab
          Expanded(
            child: TabBarView(
              controller: topTabController,
              children: [
                _patientListView(isToday: true),
                _patientListView(isToday: false),
              ],
            ),
          ),
        ],
      ),

      // ── BOTTOM TABS (Queue / Paid / History) FIXED ──
      bottomNavigationBar: Material(
        color: Colors.white,
        elevation: 10,
        child: TabBar(
          controller: bottomTabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          onTap: (index) {
            setState(() => bottomTabIndex = index);
          },
          tabs: const [
            Tab(text: "Queue"),
            Tab(text: "Paid"),
            Tab(text: "History"),
          ],
        ),
      ),
    );
  }

  /// ── Patient List filtered by bottom tab ──
  // Widget _patientListView({required bool isToday}) {
  //   List<dynamic> filteredList = consultationsCache;
  //
  //   if (bottomTabIndex == 1) {
  //     // Paid
  //     filteredList = consultationsCache.where((c) {
  //       final meds = c['MedicinePatient'] ?? [];
  //       final tonics = c['TonicPatient'] ?? [];
  //       final injections = c['InjectionPatient'] ?? [];
  //       return meds.any((m) => m['paymentStatus'] == true) ||
  //           tonics.any((t) => t['paymentStatus'] == true) ||
  //           injections.any((i) => i['paymentStatus'] == true);
  //     }).toList();
  //   } else if (bottomTabIndex == 2) {
  //     // History
  //     filteredList = consultationsCache
  //         .where((c) => c['status'] == 'COMPLETED')
  //         .toList();
  //   }
  //
  //   if (firstLoad) {
  //     return FutureBuilder<List<dynamic>>(
  //       future: consultationsFuture,
  //       builder: (context, snapshot) {
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return const Center(
  //             child: CircularProgressIndicator(color: Color(0xFFBF955E)),
  //           );
  //         }
  //         if (snapshot.hasError) {
  //           return Center(
  //             child: Text(
  //               'Error: ${snapshot.error}',
  //               style: const TextStyle(color: Colors.red, fontSize: 16),
  //             ),
  //           );
  //         }
  //         firstLoad = false;
  //         return _buildList(snapshot.data ?? []);
  //       },
  //     );
  //   }
  //
  //   if (filteredList.isEmpty) {
  //     return Center(
  //       child: Text(
  //         bottomTabIndex == 0
  //             ? 'No patients in queue.'
  //             : bottomTabIndex == 1
  //             ? 'No Paid Records'
  //             : 'No History Records',
  //         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  //       ),
  //     );
  //   }
  //
  //   return _buildList(filteredList);
  // }

  Widget _patientListView({required bool isToday}) {
    DateTime now = DateTime.now();

    List<dynamic> dateFilteredList = consultationsCache.where((c) {
      final dateString = c['updatedAt'] ?? c['createdAt']; // adjust field
      if (dateString == null) return false;

      // Parse date manually (format: "2025-12-16 09:45 PM")
      DateTime? consultationDate;
      try {
        final parts = dateString.split(' '); // ["2025-12-16", "09:45", "PM"]
        if (parts.length < 3) return false;

        final datePart = parts[0]; // "2025-12-16"
        final timePart = parts[1]; // "09:45"
        final ampm = parts[2]; // "PM"

        final timeParts = timePart.split(':');
        int hour = int.parse(timeParts[0]);
        final int minute = int.parse(timeParts[1]);

        if (ampm.toUpperCase() == 'PM' && hour != 12) hour += 12;
        if (ampm.toUpperCase() == 'AM' && hour == 12) hour = 0;

        final dateParts = datePart.split('-');
        consultationDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          hour,
          minute,
        );
      } catch (e) {
        return false;
      }

      if (isToday) {
        return consultationDate.year == now.year &&
            consultationDate.month == now.month &&
            consultationDate.day == now.day;
      } else {
        // Previous: before today
        final todayStart = DateTime(now.year, now.month, now.day);
        return consultationDate.isBefore(todayStart);
      }
    }).toList();

    // Filter by bottom tab
    List<dynamic> filteredList = dateFilteredList;
    if (bottomTabIndex == 1) {
      filteredList = dateFilteredList.where((c) {
        final meds = c['MedicinePatient'] ?? [];
        final tonics = c['TonicPatient'] ?? [];
        final injections = c['InjectionPatient'] ?? [];
        return meds.any((m) => m['paymentStatus'] == true) ||
            tonics.any((t) => t['paymentStatus'] == true) ||
            injections.any((i) => i['paymentStatus'] == true);
      }).toList();
    } else if (bottomTabIndex == 2) {
      filteredList = dateFilteredList
          .where((c) => c['status'] == 'COMPLETED')
          .toList();
    }

    // Loader for first load
    if (firstLoad) {
      return FutureBuilder<List<dynamic>>(
        future: consultationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFBF955E)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }
          firstLoad = false;
          return _buildList(snapshot.data ?? []);
        },
      );
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          bottomTabIndex == 0
              ? 'No patients in queue.'
              : bottomTabIndex == 1
              ? 'No Paid Records'
              : 'No History Records',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return _buildList(filteredList);
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, const Color(0xFFD9B57A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "Medical Queue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTabs({required bool isToday}) {
    return Column(
      children: [
        // 🔻 BOTTOM TABS
        Material(
          color: Colors.white,
          elevation: 1,
          child: TabBar(
            controller: bottomTabController,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: "Queue"),
              Tab(text: "Paid"),
              Tab(text: "History"),
            ],
          ),
        ),

        // 🔻 CONTENT
        Expanded(
          child: TabBarView(
            controller: bottomTabController,
            children: [
              _queueView(isToday),
              _paidView(isToday),
              _historyView(isToday),
            ],
          ),
        ),
      ],
    );
  }

  Widget _queueView(bool isToday) {
    return firstLoad
        ? FutureBuilder<List<dynamic>>(
            future: consultationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFBF955E)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                );
              }

              firstLoad = false;
              return _buildList(snapshot.data ?? []);
            },
          )
        : _buildList(consultationsCache);
  }

  Widget _paidView(bool isToday) {
    final paidList = consultationsCache.where((c) {
      final meds = c['MedicinePatient'] ?? [];
      final tonics = c['TonicPatient'] ?? [];
      final injections = c['InjectionPatient'] ?? [];

      return meds.any((m) => m['paymentStatus'] == true) ||
          tonics.any((t) => t['paymentStatus'] == true) ||
          injections.any((i) => i['paymentStatus'] == true);
    }).toList();

    if (paidList.isEmpty) {
      return const Center(child: Text("No Paid Records"));
    }

    return _buildList(paidList);
  }

  Widget _historyView(bool isToday) {
    final historyList = consultationsCache
        .where((c) => c['status'] == 'COMPLETED')
        .toList();

    if (historyList.isEmpty) {
      return const Center(child: Text("No History Records"));
    }

    return _buildList(historyList);
  }

  /// 🔹 UI LIST (unchanged)
  Widget _buildList(List<dynamic> consultations) {
    if (consultations.isEmpty) {
      return const Center(
        child: Text(
          'No patients in queue.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final c = consultations[index];
        final patient = c['Patient'];
        final name = patient?['name'] ?? 'Unknown';
        final patientId = c['patient_Id'].toString();
        final address = patient?['address']?['Address'] ?? 'N/A';
        final cell = patient?['phone']?['mobile'] ?? 'N/A';
        final doctor = c['Doctor']?['name'] ?? 'Unknown Doctor';

        final List<dynamic> medicineList = c['MedicinePatient'] ?? [];
        final List<dynamic> tonicList = c['TonicPatient'] ?? [];
        final List<dynamic> injectionList = c['InjectionPatient'] ?? [];

        bool hasPaid =
            medicineList.any((m) => m['paymentStatus'] == true) ||
            tonicList.any((t) => t['paymentStatus'] == true) ||
            injectionList.any((i) => i['paymentStatus'] == true);

        final bool medicineTonic =
            c['medicineTonic'] == true || c['Injection'] == true;

        int passIndexRow = (medicineTonic && hasPaid) ? 1 : 0;

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MedicalFeePage(consultation: c, index: passIndexRow),
              ),
            );

            if (result == true) {
              final data =
                  await ConsultationService.getAllConsultationByMedical(0);
              setState(() {
                consultationsCache = data;
              });
            }
          },
          child: _buildCard(
            name,
            patientId,
            cell,
            address,
            doctor,
            passIndexRow,
          ),
        );
      },
    );
  }

  /// 🔹 CARD UI (unchanged)
  Widget _buildCard(
    String name,
    String patientId,
    String cell,
    String address,
    String doctor,
    int passIndexRow,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                gradient: LinearGradient(
                  colors: [primaryColor, const Color(0xFFD9B57A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "#$patientId",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone_outlined, "Cell", cell),
                _buildInfoRow(Icons.home_outlined, "Address", address),
                _buildInfoRow(Icons.local_hospital_outlined, "Doctor", doctor),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (passIndexRow == 1) ...[
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Text("Paid", style: TextStyle(color: Colors.black)),
                      const Spacer(),
                    ],
                    const Text(
                      "Tap to view details →",
                      style: TextStyle(
                        color: Color(0xFFBF955E),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
