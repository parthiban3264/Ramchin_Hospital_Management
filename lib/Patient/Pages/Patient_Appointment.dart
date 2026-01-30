import 'package:flutter/material.dart';

import '../../Pages/NotificationsPage.dart';
import 'Patient_AppointDetails.dart';

class PatientAppointmentHistory extends StatefulWidget {
  final Map<String, dynamic> hospitalData;

  const PatientAppointmentHistory({super.key, required this.hospitalData});

  @override
  State<PatientAppointmentHistory> createState() =>
      _PatientAppointmentHistoryState();
}

class _PatientAppointmentHistoryState extends State<PatientAppointmentHistory> {
  late List<Map<String, dynamic>> consultations;

  @override
  void initState() {
    super.initState();
    loadConsultations();
  }

  // Convert date string → DateTime
  DateTime parseDate(String? date) {
    if (date == null) return DateTime.now();
    try {
      return DateTime.parse(date.replaceAll(" ", "T"));
    } catch (_) {
      return DateTime.now();
    }
  }

  // Load and sort latest-first
  void loadConsultations() {
    consultations = List<Map<String, dynamic>>.from(
      widget.hospitalData["Consultation"] ?? [],
    );

    consultations.sort(
      (a, b) => parseDate(b["createdAt"]).compareTo(parseDate(a["createdAt"])),
    );
  }

  Color getStatusColor(String? status) {
    switch ((status ?? "").toUpperCase()) {
      case "COMPLETED":
        return Colors.green;
      case "ONGOING":
        return Colors.orange;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Fetch doctor name
  String getDoctorName(String id) {
    var list = widget.hospitalData["Doctors"] ?? [];
    var d = list.firstWhere(
      (doc) => doc["doctor_Id"] == id,
      orElse: () => null,
    );
    return d?["doctorName"] ?? "Doctor";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ----------------------- CUSTOM GOLD APPBAR -----------------------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFBF955E), // gold
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),

                  const Spacer(),

                  const Text(
                    "Appointment History",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

      // ----------------------- BODY -----------------------
      body: consultations.isEmpty
          ? Center(
              child: Text(
                "No Appointments Found",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: consultations.length,
              itemBuilder: (_, i) => _consultationCard(consultations[i]),
            ),
    );
  }

  // ----------------------- APPOINTMENT CARD -----------------------

  Widget _consultationCard(Map<String, dynamic> c) {
    Color statusColor = getStatusColor(c["status"]);

    String doctorName = getDoctorName(c["doctor_Id"]);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientAppointDetails(
              consultation: c,
              hospitalData: widget.hospitalData,
            ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black12, width: 0.15),

          boxShadow: [
            BoxShadow(
              color: Colors.black12.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //---------------- TOP ROW ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  c["purpose"].toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    c["status"],
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            //---------------- DOCTOR ----------------
            Row(
              children: [
                const Icon(Icons.person, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  doctorName,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            //---------------- DATE ----------------
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.teal, size: 20),
                const SizedBox(width: 6),
                Text(
                  c["createdAt"],
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),

                const Spacer(),

                _iconText(
                  c["paymentStatus"] == true
                      ? Icons.verified
                      : Icons.warning_amber,
                  c["paymentStatus"] == true ? "Paid" : "Not Paid",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ICON + TEXT ----------------

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 18),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
