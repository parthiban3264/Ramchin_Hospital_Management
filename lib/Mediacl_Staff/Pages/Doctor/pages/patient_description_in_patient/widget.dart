import 'package:flutter/material.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/Doctor/pages/patient_description_in_patient/patient_description_page.dart';

import '../../../../../Admin/Pages/AdminEditProfilePage.dart';
import '../../../../../Services/admin_service.dart';
import 'doctor_prescription_page.dart';
import 'scanning_page.dart';
import 'testing_page.dart';

bool hasAnyVital({
  String? temperature,
  String? bloodPressure,
  String? sugar,
  String? height,
  String? weight,
  String? bmi,
  String? pk,
  String? spo2,
}) {
  return isValid(temperature) ||
      isValid(bloodPressure) ||
      isValid(sugar) ||
      isValid(height) ||
      isValid(weight) ||
      isValid(bmi) ||
      isValid(pk) ||
      isValid(spo2);
}

bool isValid(String? value) {
  return value != null &&
      value.trim() != 'null' &&
      value.trim().isNotEmpty &&
      value.trim() != '0' &&
      value.trim() != 'N/A' &&
      value.trim() != '-' &&
      value.trim() != '_' &&
      value.trim() != '-mg/dL';
}

int calculateAge(DateTime dob) {
  final today = DateTime.now();
  int age = today.year - dob.year;
  if (today.month < dob.month ||
      (today.month == dob.month && today.day < dob.day)) {
    age--;
  }
  return age;
}

Future<String?> getStaffNameByUserId(String userId) async {
  final staffList = await AdminService().getMedicalStaff();

  for (final staff in staffList) {
    if (staff['user_Id'] == userId) {
      return staff['name'];
    }
  }
  return null;
}

// Future<void> loadNames(String userId) async {
//   final labName = await AdminService().getLabProfile(userId);
//
//   setState(() {
//     _labName = labName as String;
//   });
// }
// Extract AppBar builder for reuse
// Extract AppBar builder for reuse
PreferredSizeWidget buildAppBar(bool isButtonEnabled, BuildContext context) {
  return PreferredSize(
    preferredSize: Size.fromHeight(80),
    child: Column(
      children: [
        // ---- Existing AppBar UI ----
        Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryColor, primaryColor]),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    "Doctor Description",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ---- TABS ONLY FOR ASSISTANT DOCTOR ----
        // if (isAssistantDoctor)
        //   Column(
        //     children: [
        //       const SizedBox(height: 8), // gap below AppBar
        //       TabBar(
        //         controller: _tabController,
        //         indicatorColor: primaryColor,
        //         labelColor: Colors.black,
        //         unselectedLabelColor: Colors.grey,
        //         tabs: const [
        //           Tab(text: 'Home'),
        //           Tab(text: 'Edit'),
        //         ],
        //       ),
        //       const SizedBox(height: 2), // small bottom gap
        //     ],
        //   ),
      ],
    ),
  );
}

// Widget _buildExitButton(bool isButtonEnabled) {
//   return ElevatedButton(
//     onPressed: (!isButtonEnabled && !isLoadingStatus)
//         ? () async {
//             setState(() => isLoadingStatus = true);
//             await _completedStatus();
//             setState(() => isLoadingStatus = false);
//           }
//         : null,
//     style: ElevatedButton.styleFrom(
//       backgroundColor: !isButtonEnabled ? Colors.green : Colors.grey,
//       foregroundColor: Colors.white,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 4,
//       shadowColor: Colors.greenAccent,
//     ),
//     child: isLoadingStatus
//         ? const SizedBox(
//             width: 24,
//             height: 24,
//             child: CircularProgressIndicator(
//               color: Colors.white,
//               strokeWidth: 2.5,
//             ),
//           )
//         : const Text(
//             'Exit',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 1.2,
//             ),
//           ),
//   );
// }

// 🟢 Test Result Card

Widget buildExpandableCard({
  required String title,
  required IconData icon,
  required bool expanded,
  required Function(bool) onExpand,
  required Widget child,
  required BuildContext context,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
    margin: const EdgeInsets.only(bottom: 0, left: 2, right: 2),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(5, 2, 5, 10),

          // Smooth rounded shape
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          initiallyExpanded: expanded,
          onExpansionChanged: (v) {
            onExpand(v);
          },

          // ------------ HEADER UI ------------
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E3B7D), Color(0xFF467BD4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 24),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0E3B7D),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),

          trailing: AnimatedRotation(
            duration: const Duration(milliseconds: 250),
            turns: expanded ? 0.5 : 0,
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 32,
              color: Color(0xFF0E3B7D),
            ),
          ),

          // ------------ BODY CONTENT ------------
          children: [
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: child,
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label :',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : "-",
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildVitalsDetailsCards({
  String? temperature,
  String? bloodPressure,
  String? sugar,
  String? height,
  String? weight,
  String? bmi,
  String? pk,
  String? spo2,
}) {
  return Card(
    elevation: 4,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monitor_heart, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                "Vitals",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade400),

          /// Vitals Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (isValid(temperature))
                _vitalTile(
                  icon: Icons.thermostat,
                  label: "Temperature",
                  value: "$temperature °F",
                ),
              if (isValid(bloodPressure))
                _vitalTile(
                  icon: Icons.favorite,
                  label: "BP",
                  value: bloodPressure!,
                ),
              if (isValid(sugar))
                _vitalTile(
                  icon: Icons.opacity,
                  label: "Sugar",
                  value: "$sugar mg/dL",
                ),
              if (isValid(weight))
                _vitalTile(
                  icon: Icons.monitor_weight,
                  label: "Weight",
                  value: "$weight kg",
                ),
              if (isValid(height))
                _vitalTile(
                  icon: Icons.height,
                  label: "Height",
                  value: "$height cm",
                ),
              if (isValid(bmi))
                _vitalTile(
                  icon: Icons.calculate,
                  label: "BMI",
                  value: "$bmi BMI",
                ),
              if (isValid(pk))
                _vitalTile(icon: Icons.science, label: "PR", value: "$pk bpm"),
              if (isValid(spo2))
                _vitalTile(
                  icon: Icons.monitor_heart,
                  label: "SpO₂",
                  value: "$spo2 %",
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _vitalTile({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 10),

        /// Label (fixed width for alignment)
        SizedBox(
          width: 120,
          child: Text(
            "$label :",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),

        /// Value (wraps automatically)
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildSectionCard({
  required String title,
  required String patientStatus,
  required dynamic firstTest,
  required BuildContext context,
  required dynamic consultation,
  required String role,
  required List<Map<String, dynamic>> allTestsReportTable,
}) {
  final showOnlyPrescription =
      patientStatus == 'endprocessing' && firstTest != null;

  return Card(
    elevation: 6,
    shadowColor: primaryColor.withValues(alpha: 0.25),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFBF955E), Color(0xFFD7B980)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.medical_services_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Consultation Actions',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (showOnlyPrescription)
            Center(
              child: buildActionButton(
                context,
                title: 'Prescription',
                icon: Icons.receipt_long_rounded,
                color: primaryColor,
                route: DoctorsPrescriptionPage(consultation: consultation),
              ),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: buildActionButton(
                        context,
                        title: 'Tests',
                        icon: Icons.science_rounded,
                        color: primaryColor,
                        route: TestingPage(
                          consultation: consultation,
                          testOptionName: allTestsReportTable,
                          role: role,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: buildActionButton(
                        context,
                        title: 'Scans',
                        icon: Icons.document_scanner_rounded,
                        color: primaryColor,
                        route: ScanningPage(
                          consultation: consultation,
                          role: role,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),
                    Expanded(
                      child: buildActionButton(
                        context,
                        title: 'Prescription',
                        icon: Icons.receipt_long_rounded,
                        color: primaryColor,
                        route: DoctorsPrescriptionPage(
                          consultation: consultation,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

Widget buildActionButton(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Color color,
  Widget? route,
}) {
  return Column(
    children: [
      GestureDetector(
        onTap: () async {
          if (route != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => route),
            );

            if (result == true) {
              PatientDescriptionInState.onSetStated(
                true,
                true,
                false,
                false,
                false,
                false,
              );
              // setState(() => scanningTesting = true);
            } else if (result is Map<String, dynamic>) {
              final medicine = result['medicine'] == true;
              final tonic = result['tonic'] == true;
              final inject = result['injection'] == true;
              PatientDescriptionInState.onSetStated(
                false,
                false,
                medicine || tonic || inject,
                true,
                false,
                false,
              );
              PatientDescriptionInState.onSetStated(
                false,
                false,
                false,
                false,
                inject,
                true,
              );

              // setState(() {
              //   medicineTonicInjection = medicine || tonic || inject;
              //   injection = inject;
              // });
            }
          }
        },
        child: Column(
          children: [
            Container(
              height: 75,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),

                /// ★ NEW GOLD GRADIENT BACKGROUND
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFCECCF), // light gold
                    const Color(0xFFF3D9AF), // deeper gold
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                /// ★ GOLD BORDER
                border: Border.all(color: const Color(0xFFBF955E), width: 1.4),

                /// ★ SOFT SHADOW
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withValues(alpha: 0.15),

                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: const Color(0xFF836028), // deep gold icon
                  size: 34,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.brown.shade800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Future<bool> showExitConfirmation(BuildContext context) async {
  return await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),

          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                "Confirm Exit",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          content: const Text(
            "Are you sure you want to go back?",
            style: TextStyle(fontSize: 16, height: 1.4, color: Colors.black87),
          ),

          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                foregroundColor: Colors.grey.shade700,
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Yes, Exit", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ) ??
      false;
}
