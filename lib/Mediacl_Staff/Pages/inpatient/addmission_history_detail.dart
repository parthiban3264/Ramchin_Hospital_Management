import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../Pages/NotificationsPage.dart';

const Color royal = Color(0xFFBF955E);

class AdmissionDetailPage extends StatelessWidget {
  final Map admission;

  const AdmissionDetailPage({super.key, required this.admission});

  String formatDate(String? date) {
    if (date == null) return "-";
    return DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.parse(date));
  }

  @override
  @override
  Widget build(BuildContext context) {
    final patient = admission['patient'];
    final doctor = admission['doctor'];
    final nurse = admission['nurse'];
    final oldDetail = admission['oldDoctorDetail'] ?? {};
    final charges = admission['charges'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: royal,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
                  const Text(
                    "Admission Details",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== PATIENT HEADER =====
            _patientHeader(patient),

            const SizedBox(height: 18),

            _sectionCard(
              title: "Admission Info",
              children: [
                _info("Reason", admission['reason']),
                _info("Status", admission['status']),
                _info("Admitted On", formatDate(admission['admitTime'])),
                _info("Discharge Time", formatDate(admission['dischargeTime'])),
              ],
            ),

            _sectionCard(
              title: "Current Assignment",
              children: [
                _info("Doctor", doctor?['name']),
                _info("Nurse", nurse?['name']),
              ],
            ),

            _historySection(
              title: "Ward History",
              list: oldDetail['wardHistory'],
              builder: (w) => _timelineCard(
                title: w['ward']['wardName'],
                subtitle:
                    "Bed ${w['ward']['bedNo']} • ${formatDate(w['from'])}",
              ),
            ),

            _historySection(
              title: "Doctor History",
              list: oldDetail['doctorHistory'],
              builder: (d) => _timelineCard(
                title: d['doctor']['doctorName'],
                subtitle: "From ${formatDate(d['from'])}",
              ),
            ),

            _historySection(
              title: "Nurse History",
              list: oldDetail['nurseHistory'],
              builder: (n) => _timelineCard(
                title: n['nurse']['nurseName'],
                subtitle: "From ${formatDate(n['from'])}",
              ),
            ),

            _sectionCard(
              title: "Charges",
              children: charges.isEmpty
                  ? [_empty("No charges")]
                  : charges.map<Widget>((c) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['description'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _statusChip(c['status']),
                                ],
                              ),
                            ),
                            Text(
                              "₹${c['amount']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: royal,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= UI HELPERS =================
  Widget _patientHeader(Map patient) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: royal),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: royal.withValues(alpha: 0.15),
              child: const Icon(Icons.person, color: royal, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: royal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${patient['gender']} • ${patient['bldGrp']}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(patient['phone']?['mobile'] ?? "-"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'paid':
        bgColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green;
        break;
      case 'unpaid':
        bgColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red;
        break;
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange;
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      backgroundColor: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: royal),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: royal,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _historySection({
    required String title,
    required List? list,
    required Widget Function(dynamic) builder,
  }) {
    return _sectionCard(
      title: title,
      children: (list == null || list.isEmpty)
          ? [_empty("No records")]
          : list.map<Widget>(builder).toList(),
    );
  }

  Widget _timelineCard({required String title, required String subtitle}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.timeline, color: royal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
    );
  }

  Widget _info(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value ?? "-")),
        ],
      ),
    );
  }

  // Widget _card({required String title, required String subtitle}) {
  //   return Card(
  //     margin: const EdgeInsets.only(bottom: 8),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //       side: BorderSide(color: royal.withValues(alpha:0.4)),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             title,
  //             style: const TextStyle(
  //                 fontWeight: FontWeight.bold, color: royal),
  //           ),
  //           const SizedBox(height: 4),
  //           Text(subtitle),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _empty(String msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(msg, style: const TextStyle(color: Colors.grey)),
    );
  }
}
