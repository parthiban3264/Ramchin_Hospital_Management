import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../Services/consultation_service.dart';

const primaryColor = Color(0xFFBF955E);

class InjectionPage extends StatefulWidget {
  final Map<String, dynamic> consultation;
  const InjectionPage({super.key, required this.consultation});

  @override
  State<InjectionPage> createState() => _InjectionPageState();
}

class _InjectionPageState extends State<InjectionPage> {
  bool showAll = false;
  bool isLoading = false;
  late List<bool> injectionChecks;

  String? _dateTime;

  @override
  void initState() {
    super.initState();
    _updateTime();

    final injectionList = widget.consultation['InjectionPatient'] ?? [];
    injectionChecks = List.generate(injectionList.length, (_) => false);
  }

  void _updateTime() {
    _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
  }

  bool get allChecked =>
      injectionChecks.isNotEmpty && injectionChecks.every((e) => e == true);

  Future<void> handleFinished() async {
    if (!allChecked) return;

    setState(() => isLoading = true);

    final consultationId = widget.consultation['id'];
    // final queuestatus = widget.consultation['queueStatus'];
    final bool scanningTesting =
        widget.consultation['scanningTesting'] ?? false;
    String newStatus = scanningTesting ? 'ENDPROCESSING' : 'COMPLETED';

    try {
      await ConsultationService().updateConsultation(consultationId, {
        'status': newStatus,
        'Injection': false,
        'updatedAt': _dateTime.toString(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Injection completed successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update status: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultation = widget.consultation;
    final patient = consultation['Patient'] ?? {};

    // ----------------------
    // SAFE DOB + AGE LOGIC
    // ----------------------
    String dobRaw = (patient['dob'] ?? "").toString();
    String dobDisplay = "-";
    String ageDisplay = "-";

    try {
      if (dobRaw.isNotEmpty) {
        DateTime dob = DateTime.parse(dobRaw);
        dobDisplay = dob.toIso8601String().split('T').first;

        DateTime now = DateTime.now();
        int age = now.year - dob.year;

        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }

        ageDisplay = age.toString();
      }
    } catch (e) {
      dobDisplay = dobRaw; // fallback
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // pass dobDisplay & ageDisplay into the patient card
          _buildPatientCard(patient, consultation, dobDisplay, ageDisplay),
          const SizedBox(height: 16),
          _buildMedicalInfoCard(consultation),
          const SizedBox(height: 16),
          _buildInjectionCard(consultation),
          const SizedBox(height: 40),
          _buildFinishButton(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // APP BAR
  // --------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 100,
        decoration: const BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "Injection",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  int count = 0;
                  Navigator.popUntil(context, (route) => count++ >= 2);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // MEDICAL INFO CARD (Doctor, Purpose)
  // --------------------------------------------------------------
  Widget _buildMedicalInfoCard(Map<String, dynamic> consultation) {
    return Card(
      elevation: 5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Medical Information",
              style: TextStyle(
                color: primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow(
              "Doctor Name",
              consultation['Doctor']?['name'] ?? "Unknown",
            ),
            _buildInfoRow(
              "Purpose",
              consultation['purpose'] ?? "Not specified",
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // PATIENT CARD
  // Note: dobDisplay & ageDisplay are passed from build()
  // --------------------------------------------------------------
  Widget _buildPatientCard(
    Map<String, dynamic> patient,
    Map<String, dynamic> consultation,
    String dobDisplay,
    String ageDisplay,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  patient['name'] ?? "Patient",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => showAll = !showAll),
                  child: Text(
                    showAll ? "Hide" : "Show All",
                    style: const TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),
            _buildInfoRow("Patient ID", consultation['patient_Id'].toString()),
            _buildInfoRow("Phone", patient['phone']?['mobile'] ?? "-"),
            _buildInfoRow("Address", patient['address']?['Address'] ?? "-"),

            // Always show DOB & Age (you can move outside if you want shown only when expanded)
            if (showAll) ...[
              const Divider(),
              _buildInfoRow("DOB", dobDisplay),
              _buildInfoRow("Age", ageDisplay),
              _buildInfoRow("Blood Group", patient['bldGrp'] ?? "-"),
              // add other extra info here
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // ALL INJECTIONS INSIDE ONE CARD WITH CHECKBOXES
  // --------------------------------------------------------------
  Widget _buildInjectionCard(Map<String, dynamic> consultation) {
    final injectionList = consultation['InjectionPatient'] ?? [];

    // Ensure injectionChecks length matches list length (in case consultation changed)
    if (injectionChecks.length != injectionList.length) {
      injectionChecks = List.generate(
        injectionList.length,
        (i) => injectionChecks.length > i ? injectionChecks[i] : false,
      );
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Injection List",
              style: TextStyle(
                color: primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            if (injectionList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text("No injections found"),
              ),

            ...List.generate(injectionList.length, (index) {
              final injData = injectionList[index];
              final inj = injData['Injection'] ?? {};

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inj['injectionName'] ?? 'Unknown Injection',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Dose: ${injData['quantity']}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            // Text(
                            //   "Total: ${injData['total'] ?? '-'}",
                            //   style: const TextStyle(
                            //     fontSize: 13,
                            //     color: Colors.black54,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: injectionChecks[index],
                        activeColor: primaryColor,
                        onChanged: (val) {
                          setState(() => injectionChecks[index] = val ?? false);
                        },
                      ),
                    ],
                  ),
                  if (index != injectionList.length - 1)
                    const Divider(height: 15),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // FINISHED BUTTON (ENABLED ONLY WHEN ALL CHECKED)
  // --------------------------------------------------------------
  Widget _buildFinishButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: allChecked ? primaryColor : Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: (isLoading || !allChecked) ? null : handleFinished,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Finished",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
      ),
    );
  }

  // --------------------------------------------------------------
  // REUSABLE ROW
  // --------------------------------------------------------------
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
