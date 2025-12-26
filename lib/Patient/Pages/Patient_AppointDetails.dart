import 'package:flutter/material.dart';

import '../../Pages/NotificationsPage.dart';

// PRIMARY THEME COLOR
const Color primaryColor = Color(0xFFBF955E);

class PatientAppointDetails extends StatelessWidget {
  final Map<String, dynamic> consultation;
  final Map<String, dynamic> hospitalData;

  const PatientAppointDetails({
    super.key,
    required this.consultation,
    required this.hospitalData,
  });

  @override
  Widget build(BuildContext context) {
    int cid = consultation["id"];

    // -------------------- MATCH DOCTOR WITH ADMINS --------------------
    final doctor = hospitalData["Admins"]?.firstWhere(
      (d) => d["admin_Id"] == consultation["doctor_Id"],
      orElse: () => null,
    );

    final doctorName = doctor?["adminName"] ?? "Doctor";

    // -------------------- FILTER RELATED LISTS --------------------
    List meds = (hospitalData["MedicinePatients"] ?? [])
        .where((m) => m["consultation_Id"] == cid)
        .toList();

    List injections = (hospitalData["InjectionPatients"] ?? [])
        .where((m) => m["consultation_Id"] == cid)
        .toList();

    List tonics = (hospitalData["TonicPatients"] ?? [])
        .where((m) => m["consultation_Id"] == cid)
        .toList();

    List tests = (hospitalData["TestingAndScannings"] ?? [])
        .where((m) => m["consultation_Id"] == cid)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: PreferredSize(
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
                  const Spacer(),
                  const Text(
                    "Appointment Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
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
                ],
              ),
            ),
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(doctorName),

          const SizedBox(height: 22),

          // ------------------ Medicines ------------------
          if (meds.isNotEmpty) _sectionTitle("Medicines Provided"),
          ...meds.map((m) => _medicineCard(m)),

          // ------------------ Injections ------------------
          if (injections.isNotEmpty) _sectionTitle("Injections Provided"),
          ...injections.map((i) => _injectionCard(i)),

          // ------------------ Tonics ------------------
          if (tonics.isNotEmpty) _sectionTitle("Tonics Provided"),
          ...tonics.map((t) => _tonicCard(t)),

          // ------------------ Tests ------------------
          if (tests.isNotEmpty) _sectionTitle("Tests & Scanning"),
          ...tests.map((t) => _testCard(t)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER CARD
  // ---------------------------------------------------------------------------
  Widget _headerCard(String doctorName) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.person, "Doctor", doctorName, isLight: false),
          const SizedBox(height: 10),
          _infoRow(
            Icons.assignment,
            "Purpose",
            consultation["purpose"],
            isLight: false,
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.flag,
            "Status",
            consultation["status"],
            isLight: false,
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.calendar_today,
            "Date",
            consultation["createdAt"],
            isLight: false,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value, {
    bool isLight = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: isLight ? Colors.white : primaryColor, size: 22),
        const SizedBox(width: 12),
        Text(
          "$title: ",
          style: TextStyle(
            color: isLight ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isLight ? Colors.white.withOpacity(0.9) : Colors.black87,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION TITLE
  // ---------------------------------------------------------------------------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ITEM CARDS
  // ---------------------------------------------------------------------------

  Widget _medicineCard(m) {
    return _itemCard(
      Icons.medication,
      m["Medician"]["medicianName"],
      "Quantity: ${m["quantityNeeded"]}",
    );
  }

  Widget _injectionCard(i) {
    return _itemCard(
      Icons.local_hospital,
      i["Injection"]["injectionName"],
      "Dose: ${i["quantity"]}",
    );
  }

  Widget _tonicCard(t) {
    return _itemCard(
      Icons.local_drink,
      t["Tonic"]["tonicName"],
      "Quantity: ${t["quantity"]} ml",
    );
  }

  Widget _testCard(t) {
    return _itemCard(
      Icons.science,
      t["title"],
      "Result: ${t["result"] ?? "N/A"}",
    );
  }

  // ---------------------------------------------------------------------------
  // UNIVERSAL ITEM CARD
  // ---------------------------------------------------------------------------
  Widget _itemCard(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: primaryColor.withOpacity(0.15),
          child: Icon(icon, color: primaryColor, size: 22),
        ),

        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),

        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ),
    );
  }
}
