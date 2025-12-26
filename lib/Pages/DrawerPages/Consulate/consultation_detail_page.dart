import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../NotificationsPage.dart';

const Color customGold = Color(0xFFBF955E);

class ConsultationDetailPage extends StatelessWidget {
  final Map<String, dynamic> consultation;
  final Map<String, dynamic> patient;

  const ConsultationDetailPage({
    super.key,
    required this.consultation,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final appointDate = DateTime.tryParse(consultation['appointdate'] ?? '');
    final formattedTime = appointDate != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(appointDate)
        : '-';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: const BoxDecoration(
            color: customGold,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Consultation Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationPage(),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    (consultation['patientPhoto'] != null &&
                        consultation['patientPhoto'].toString().isNotEmpty)
                    ? NetworkImage(consultation['patientPhoto'])
                    : null,
                child:
                    (consultation['patientPhoto'] == null ||
                        consultation['patientPhoto'].toString().isEmpty)
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _infoTile('Patient Name', consultation['patientName']),
            _infoTile('Gender', consultation['gender']),
            _infoTile(
              'DOB',
              consultation['dob'] != null
                  ? consultation['dob'].toString().split("T").first
                  : '-',
            ),
            _infoTile('Doctor', consultation['doctorName']),
            _infoTile('Hospital', consultation['hospitalName']),
            _infoTile('Purpose', consultation['purpose']),
            _infoTile('Appointment', formattedTime),
            _infoTile(
              'Payment Status',
              (consultation['paymentStatus'] == true) ? 'Paid' : 'Pending',
            ),
            _infoTile('Treatment', consultation['treatment'] ?? '-'),
            _infoTile('Medicine', consultation['medicineInjection'] ?? '-'),
            _infoTile(
              'Testing / Scanning',
              consultation['scanningTesting'] ?? '-',
            ),
            _infoTile('Notes', consultation['notes'] ?? '-'),
            _infoTile('Diagnosis', consultation['diagnosis'] ?? '-'),
            _infoTile('Access', consultation['access'] ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              value?.toString() ?? '-',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
