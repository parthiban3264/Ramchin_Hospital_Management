import 'package:flutter/material.dart';

import '../../Mediacl_Staff/Pages/OutPatient/Report/ReportCard.dart';
import '../../Pages/NotificationsPage.dart';

class ViewReportPage extends StatelessWidget {
  final List<Map<String, dynamic>> reportTable;
  final Map<String, String> optionResults;
  final Map<String, dynamic> patient;
  final String testTitle;

  const ViewReportPage({
    super.key,
    required this.reportTable,
    required this.optionResults,
    required this.patient,
    required this.testTitle,
  });

  @override
  Widget build(BuildContext context) {
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
                    "View Report",
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
        child: ReportCardWidget(
          record: patient,
          doctorName: 'Parthiban',
          staffName: "Karthik",
          hospitalPhotoBase64: '',
          optionResults: optionResults,
          testTable: reportTable,
          mode: 1,
          showButtons: false,
        ),
      ),
    );
  }
}
