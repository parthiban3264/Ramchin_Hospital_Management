import 'package:flutter/material.dart';
import '../../Pages/NotificationsPage.dart';
import 'Test_View_Report.dart';

class PatientTests extends StatefulWidget {
  final Map<String, dynamic> hospitalData;
  const PatientTests({super.key, required this.hospitalData});

  @override
  State<PatientTests> createState() => _PatientTestsState();
}

class _PatientTestsState extends State<PatientTests> {
  late Map<String, List<Map<String, dynamic>>> groupedTests;

  @override
  void initState() {
    super.initState();

    final rawList = widget.hospitalData["TestingAndScannings"] ?? [];

    final testRecords = rawList
        .where((e) => (e["type"] ?? "") == "Tests")
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    groupedTests = {};
    for (final test in testRecords) {
      final cid = test["consultationID"]?.toString() ?? "Unknown";
      groupedTests[cid] ??= [];
      groupedTests[cid]!.add(test);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cidList = groupedTests.keys.toList();

    return Scaffold(
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
                  const Spacer(),
                  const Text(
                    "Test Report",
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: cidList.isEmpty
          ? const Center(
              child: Text(
                "No Test Reports Found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cidList.length,
              itemBuilder: (context, index) {
                final cid = cidList[index];
                final tests = groupedTests[cid]!;
                return _buildConsultationCard(cid, tests);
              },
            ),
    );
  }

  // ----------------------------------------------------------------------
  // CONSULTATION CARD
  // ----------------------------------------------------------------------

  Widget _buildConsultationCard(String cid, List<Map<String, dynamic>> tests) {
    return GestureDetector(
      onTap: () {
        final List<Map<String, dynamic>> mergedTable = [];
        final Map<String, String> mergedOptions = {};

        for (final test in tests) {
          mergedTable.addAll(extractReportTable(test));
          mergedOptions.addAll(extractOptionResults(test));
        }

        final patient = tests.first["Patient"] ?? {};

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewReportPage(
              reportTable: mergedTable,
              optionResults: mergedOptions,
              patient: Map<String, dynamic>.from(patient),
              testTitle: " Reports",
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: Colors.blue,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "Consultation",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // TEST LIST
              ...tests.map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t["title"] ?? "Test",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // STATUS TAG
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (t["status"] == "COMPLETED")
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t["status"] ?? "PENDING",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: (t["status"] == "COMPLETED")
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // EXTRACT FUNCTIONS (NO CHANGE)
  // ----------------------------------------------------------------------

  Map<String, String> extractOptionResults(Map<dynamic, dynamic> testItem) {
    final Map<String, String> results = {};
    final details = testItem["testDetails"] as List<dynamic>? ?? [];

    for (var d in details) {
      final options = d["options"] as List<dynamic>? ?? [];

      for (var opt in options) {
        final result = opt["result"]?.toString() ?? "";
        final selected = opt["selectedOption"]?.toString() ?? "";

        if (result == "N/A" ||
            selected == "N/A" ||
            result.isEmpty ||
            selected.isEmpty) {
          continue;
        }

        results[opt["name"].toString()] = result;
      }
    }
    return results;
  }

  List<Map<String, dynamic>> extractReportTable(
    Map<dynamic, dynamic> testItem,
  ) {
    final List<Map<String, dynamic>> formatted = [];
    final details = testItem["testDetails"] as List<dynamic>? ?? [];

    for (var d in details) {
      final List<Map<String, dynamic>> rows = [];
      final opts = d["options"] as List<dynamic>? ?? [];

      for (var opt in opts) {
        final name = opt["name"]?.toString() ?? "";
        final result = opt["result"]?.toString() ?? "";
        final selected = opt["selectedOption"]?.toString() ?? "";

        if (name.isEmpty ||
            result.isEmpty ||
            selected == "N/A" ||
            result == "N/A") {
          continue;
        }

        rows.add({
          "Test": name,
          "Result": result,
          "Unit": _formatValue(opt["unit"]),
          "Range": _formatValue(opt["reference"]),
        });
      }

      formatted.add({
        "title": d["title"],
        "impression": "good",
        "results": rows,
      });
    }
    return formatted;
  }

  String _formatValue(dynamic v) {
    if (v == null) return "-";
    if (v.toString().trim().isEmpty) return "-";
    if (v.toString() == "N/A") return "-";
    return v.toString();
  }
}
