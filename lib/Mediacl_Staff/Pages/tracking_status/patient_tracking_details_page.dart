import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color primaryColor = Color(0xFFBF955E);
const Color bgColor = Color(0xFFF4F6FA);
const Color cardBg = Colors.white;

class PatientTrackingDetailsPage extends StatelessWidget {
  final Map<String, dynamic> consultation;

  const PatientTrackingDetailsPage({super.key, required this.consultation});

  int currentStep(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 0;
      case 'ONGOING':
        return 1;
      case 'ENDPROCESSING':
        return 2;
      case 'COMPLETED':
        return 3;
      case 'CANCELLED':
        return 4;
      default:
        return 0;
    }
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ONGOING':
        return Colors.blue;
      case 'ENDPROCESSING':
        return Color(0xEC19A6B3);
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";
    return DateFormat("dd MMM yyyy • hh:mm a").format(DateTime.parse(date));
  }

  String calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return "-";
    final birthDate = DateTime.parse(dob);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age.toString();
  }

  @override
  Widget build(BuildContext context) {
    final hospital = consultation['Hospital'] ?? {};
    final patient = consultation['Patient'] ?? {};
    final doctor = consultation['Doctor'] ?? {};
    final status = consultation['status'] ?? 'PENDING';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
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
                    "Tracking Patient Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
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
          children: [
            /// 👤 PATIENT CARD
            _patientCard(patient, status),

            const SizedBox(height: 16),

            /// 📝 PATIENT INFO CARD
            _infoCard(
              title: "Patient Details",
              children: [
                _infoRow(
                  Icons.phone,
                  "Phone",
                  patient['phone']['mobile'] ?? "-",
                ),
                _infoRow(
                  Icons.location_on,
                  "Address",
                  patient['address']['Address'] ?? "-",
                ),
                _infoRow(
                  Icons.confirmation_number,
                  "Token No",
                  consultation['token_no']?.toString() ?? "-",
                ),
                _infoRow(Icons.cake, "Age", calculateAge(patient['dob'])),
              ],
            ),

            const SizedBox(height: 16),

            /// 👨‍⚕️ DOCTOR CARD
            _infoCard(
              title: "Doctor",
              children: [
                _infoRow(
                  Icons.medical_services,
                  "Doctor Name",
                  doctor['name'] ?? "-",
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 🏥 HOSPITAL CARD
            _infoCard(
              title: "Hospital",
              children: [
                _infoRow(
                  Icons.local_hospital,
                  "Hospital Name",
                  hospital['name'] ?? "-",
                ),
                _infoRow(
                  Icons.location_city,
                  "Address",
                  hospital['address'] ?? "-",
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 📍 STATUS CARD
            _infoCard(
              title: "Treatment Status",
              children: [
                _statusTimeline(currentStep(status), status),
                if (status.toUpperCase() == 'CANCELLED')
                  const SizedBox(height: 12),
                if (status.toUpperCase() == 'CANCELLED')
                  _cancelReason(consultation['cancelReason']),
              ],
            ),

            const SizedBox(height: 16),

            /// ⏱ UPDATED TIME
            _infoCard(
              title: "Last Updated",
              children: [
                _infoRow(
                  Icons.update,
                  "Updated At",
                  formatDate(consultation['updated_at']),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ❤️ VITALS CARD
            _infoCard(
              title: "Vitals",
              children: [
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  children: [
                    _vital("BP", consultation['bp'], "mmHg"),
                    _vital("Temp", consultation['temperature'], "°F"),
                    _vital("Sugar", consultation['sugar'], "mg/dL"),
                    _vital("BMI", consultation['BMI'], ""),
                    _vital("SpO₂", consultation['SPO2'], "%"),
                    _vital("Pulse", consultation['PK'], "bpm"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 PATIENT CARD
  Widget _patientCard(Map patient, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryColor.withValues(alpha: 0.15),
            child: const Icon(Icons.person, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient['name'] ?? "Patient Name",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _statusChip(status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 STATUS CHIP
  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// 🔹 INFO CARD
  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// 🔹 INFO ROW
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text("$label: $value", style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  /// 🔹 STATUS TIMELINE
  Widget _statusTimeline(int activeStep, String status) {
    final steps = [
      "Pending",
      "Ongoing",
      "End Processing",
      "Completed",
      "Cancelled",
    ];
    final stepColors = {
      "Pending": Color(0xFFEF9D06), // Orange
      "Ongoing": Color(0xFF0D6EFD), // Blue
      "End Processing": Color(0xEC19A6B3), // Green
      "Completed": Colors.green, // Green
      "Cancelled": Color(0xFFDC3545), // Red
    };

    final stepMessages = {
      "Pending": "Waiting for consultation",
      "Ongoing": "Treatment is ongoing",
      "End Processing": "Final-stage testing and scanning in progress.",
      "Completed": "Treatment completed successfully",
      "Cancelled": "Treatment was cancelled",
    };

    final isCancelled = status.toUpperCase() == 'CANCELLED';

    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isCompleted =
            !isCancelled &&
            (i < activeStep ||
                (status.toUpperCase() == 'COMPLETED' && step == "Completed"));
        final isActive = i == activeStep;

        // Circle color
        Color circleColor;
        if (isCancelled && isActive) {
          circleColor = stepColors["Cancelled"]!;
        } else if (isCompleted) {
          circleColor = stepColors["Completed"]!;
        } else if (isActive) {
          circleColor = stepColors[step]!;
        } else {
          circleColor = Colors.grey.shade300;
        }

        // Line color below circle
        Color lineColor;
        if (i < activeStep) {
          lineColor = isCancelled
              ? stepColors["Cancelled"]!.withValues(alpha: 0.6)
              : stepColors["Completed"]!;
        } else {
          lineColor = Colors.grey.shade300;
        }

        // Circle child
        Widget circleChild;
        if (isCancelled && isActive) {
          circleChild = const Icon(Icons.close, color: Colors.white, size: 14);
        } else if (isCompleted) {
          circleChild = const Icon(Icons.check, color: Colors.white, size: 14);
        } else {
          circleChild = Text(
            "${i + 1}",
            style: const TextStyle(fontSize: 10, color: Colors.white),
          );
        }

        // Message color for pending/ongoing: only active steps colored, others grey
        Color messageColor;
        if ((step == "Pending" ||
                step == "Ongoing" ||
                step == 'End Processing') &&
            !isActive) {
          messageColor = Colors.grey; // disabled color
        } else {
          messageColor = stepColors[step]!;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive && !isCancelled
                          ? stepColors[step]!
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: circleChild,
                ),
                if (i != steps.length - 1)
                  Container(width: 3, height: 50, color: lineColor),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step,
                    style: TextStyle(
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                      color: circleColor,
                    ),
                  ),
                  // Status message
                  if ((step == "Cancelled" && isCancelled) ||
                      (step == "Completed" && isCompleted) ||
                      step == "Pending" ||
                      step == "Ongoing" ||
                      step == "End Processing")
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        stepMessages[step]!,
                        style: TextStyle(
                          color: messageColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  /// ❌ CANCEL REASON
  Widget _cancelReason(String? reason) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason ?? "No reason provided",
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 VITAL
  Widget _vital(String title, dynamic value, String unit) {
    final display = (value == null || value.toString().isEmpty) ? "-" : value;
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            "$display $unit",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
