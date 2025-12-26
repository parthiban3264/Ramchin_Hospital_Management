import 'package:flutter/material.dart';
import '../../Pages/NotificationsPage.dart';
import 'Patient_medicationDetails.dart';

class PatientMedication extends StatefulWidget {
  final Map<String, dynamic> hospitalData;
  const PatientMedication({super.key, required this.hospitalData});

  @override
  State<PatientMedication> createState() => _PatientMedicationState();
}

class _PatientMedicationState extends State<PatientMedication> {
  Map<String, dynamic> grouped = {};

  @override
  void initState() {
    super.initState();
    final data = widget.hospitalData["data"] ?? widget.hospitalData;

    _groupData(
      data["MedicinePatients"] ?? [],
      data["TonicPatients"] ?? [],
      data["InjectionPatients"] ?? [],
    );
  }

  // ---------------- GROUP DATA ----------------
  void _groupData(List med, List tonic, List inj) {
    grouped = {};

    void addItem(dynamic item, String type) {
      final cid = item["consultation_Id"].toString();

      if (!grouped.containsKey(cid)) {
        grouped[cid] = {
          "consultation_Id": cid,
          "status": item["status"] ?? "Unknown",
          "patient_Id": item["patient_Id"],
          "Medicine": 0,
          "Tonic": 0,
          "Injection": 0,
        };
      }

      grouped[cid][type] += 1;
    }

    for (var i in med) addItem(i, "Medicine");
    for (var i in tonic) addItem(i, "Tonic");
    for (var i in inj) addItem(i, "Injection");

    setState(() {});
  }

  // ---------------- UI BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: _buildAppBar(),
      body: grouped.isEmpty
          ? _emptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: grouped.values
                  .map((g) => _consultationCard(g))
                  .toList(),
            ),
    );
  }

  // ---------------- EMPTY STATE ----------------
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            "No Medication Records Found",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CARD ----------------
  Widget _consultationCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        final hospitalData = widget.hospitalData["data"] ?? widget.hospitalData;

        String cid = item["consultation_Id"];

        // FILTER MEDICINES for this consultation
        final meds = (hospitalData["MedicinePatients"] ?? [])
            .where((m) => m["consultation_Id"].toString() == cid)
            .toList();

        // FILTER INJECTIONS
        final injections = (hospitalData["InjectionPatients"] ?? [])
            .where((m) => m["consultation_Id"].toString() == cid)
            .toList();

        // FILTER TONICS
        final tonics = (hospitalData["TonicPatients"] ?? [])
            .where((m) => m["consultation_Id"].toString() == cid)
            .toList();

        // SEND FULL DATA
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicationDetailPage(
              title: "Medication Details",
              data: {
                "consultation_Id": cid,
                "status": item["status"],
                "purpose": item["purpose"],
                "createdAt": item["createdAt"],
                "patient_Id": item["patient_Id"],
                "MedicinePatients": meds,
                "InjectionPatients": injections,
                "TonicPatients": tonics,
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Consultation #${item['consultation_Id']}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
                _statusChip(item["status"]),
              ],
            ),

            const SizedBox(height: 16),

            // Medication Summary
            _buildSectionTitle("Summary"),

            const SizedBox(height: 8),

            _summaryBadge(
              Icons.medication_outlined,
              "Medicines",
              item["Medicine"],
              Colors.blue,
            ),

            if (item["Injection"] > 0)
              _summaryBadge(
                Icons.vaccines,
                "Injections",
                item["Injection"],
                Colors.orange,
              ),

            if (item["Tonic"] > 0)
              _summaryBadge(
                Icons.science_outlined,
                "Tonic",
                item["Tonic"],
                Colors.green,
              ),

            const SizedBox(height: 10),
            const Divider(thickness: 1, color: Color(0xffe8e8e8)),
            const SizedBox(height: 10),

            // Button
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "View Details  →",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TITLE ----------------
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ---------------- SUMMARY BADGE ----------------
  Widget _summaryBadge(IconData icon, String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 17,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- STATUS CHIP ----------------
  Widget _statusChip(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case "completed":
        color = Colors.green;
        break;
      case "pending":
        color = Colors.orange;
        break;
      case "active":
        color = Colors.blue;
        break;
      case "cancelled":
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------- APP BAR ----------------
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Color(0xFFBF955E),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Spacer(),
                const Text(
                  "Medication History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 12),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationPage(),
                      ),
                    );
                  },
                ),
                // IconButton(
                //   icon: const Icon(Icons.home, color: Colors.white),
                //   onPressed: () {
                //     int count = 0;
                //     Navigator.popUntil(context, (route) => count++ >= 2);
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
