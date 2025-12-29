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

class _MedicalQueuePageState extends State<MedicalQueuePage> {
  final Color primaryColor = const Color(0xFFBF955E);

  late Future<List<dynamic>> consultationsFuture;

  List<dynamic> consultationsCache = []; // data stored for UI
  bool firstLoad = true;

  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();

    consultationsFuture = _loadData();
    _startAutoRefresh();
  }

  /// 🔄 Load data into cache
  Future<List<dynamic>> _loadData() async {
    final data = await ConsultationService.getAllConsultationByMedical(0);
    consultationsCache = data;
    return data;
  }

  /// 🔄 Auto refresh every 5 seconds silently
  void _startAutoRefresh() {
    refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final freshData = await ConsultationService.getAllConsultationByMedical(
          0,
        );

        if (mounted) {
          setState(() {
            consultationsCache = freshData; // refresh UI without loader
          });
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
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

      /// FIRST TIME → use FutureBuilder (loader visible once)
      /// LATER → use cached list (instant, no loader)
      body: firstLoad
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

                firstLoad = false; // disable loader forever

                return _buildList(snapshot.data ?? []);
              },
            )
          : _buildList(consultationsCache), // no loader, live refresh
    );
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
