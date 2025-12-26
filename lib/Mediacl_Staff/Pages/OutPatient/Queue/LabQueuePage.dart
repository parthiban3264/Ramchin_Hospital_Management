import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/testing&scanning_service.dart';
import '../Page/LabPage.dart';

class LabQueuePage extends StatefulWidget {
  const LabQueuePage({super.key});

  @override
  State<LabQueuePage> createState() => _LabQueuePageState();
}

class _LabQueuePageState extends State<LabQueuePage> {
  late Future<List<dynamic>> futureXRayQueue;
  final Color primaryColor = const Color(0xFFBF955E);

  Map<String, List<dynamic>> groupedRecords = {};

  @override
  void initState() {
    super.initState();
    futureXRayQueue = TestingScanningService().getAllTestingAndScanning(
      'Tests',
    );
  }

  void _groupRecordsByPatient(List<dynamic> records) {
    groupedRecords.clear();
    for (var record in records) {
      String status = (record['status'] ?? '').toString().toUpperCase();
      String queueStatus = (record['queueStatus'] ?? '')
          .toString()
          .toUpperCase();

      // Include only relevant records
      if (status == 'PENDING' ||
          queueStatus == 'PENDING' ||
          queueStatus == 'COMPLETED') {
        String patientId =

            record['Patient']?['id']?.toString() ??

            record['patient_Id']?.toString() ??
            'unknown';
        if (!groupedRecords.containsKey(patientId)) {
          groupedRecords[patientId] = [];
        }
        groupedRecords[patientId]!.add(record);
      }
    }
  }

  Color _genderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Colors.lightBlue.shade400;
      case 'female':
        return Colors.pink.shade300;
      default:
        return Colors.orange.shade400;
    }
  }

  IconData _genderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.transgender;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  const Text(
                    "Lab Test Queue",
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
      body: FutureBuilder<List<dynamic>>(
        future: futureXRayQueue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Lottie.asset(
                'assets/Lottie/error404.json',
                width: 280,
                height: 280,
                fit: BoxFit.contain,
              ),
            );
          }

          final records = snapshot.data ?? [];
          _groupRecordsByPatient(records);

          if (groupedRecords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/Lottie/NoData.json',
                    width: 250,
                    height: 250,
                    repeat: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No Lab Test patients in queue",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "Waiting Patients ( ${groupedRecords.length} )",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groupedRecords.length,
                  itemBuilder: (context, index) {
                    String patientId = groupedRecords.keys.elementAt(index);
                    List<dynamic> tests = groupedRecords[patientId]!;
                    var patient = tests.first['Patient'] ?? {};
                    final gender = (patient['gender'] ?? 'other').toString();

                    return PatientTestCard(
                      patient: patient,
                      tests: tests,
                      genderColor: _genderColor(gender),
                      genderIcon: _genderIcon(gender),
                      onRefresh: () {
                        setState(() {
                          futureXRayQueue = TestingScanningService()
                              .getAllTestingAndScanning('Tests');
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PatientTestCard extends StatefulWidget {
  final Map<String, dynamic> patient;
  final List<dynamic> tests;
  final Color genderColor;
  final IconData genderIcon;
  final VoidCallback onRefresh;

  const PatientTestCard({
    Key? key,
    required this.patient,
    required this.tests,
    required this.genderColor,
    required this.genderIcon,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<PatientTestCard> createState() => _PatientTestCardState();
}

class _PatientTestCardState extends State<PatientTestCard> {
  final Set<int> _completedTestIds = {};

  bool get _isAllCompleted {
    if (widget.tests.isEmpty) return false;
    return widget.tests.every(
      (test) =>
          (test['queueStatus'] ?? '').toString().toUpperCase() == 'COMPLETED',
    );
  }

  @override
  Widget build(BuildContext context) {

    print(widget.patient);
    String patientName = widget.patient['name'] ?? 'Unknown';
    String patientId = widget.patient['id']?.toString() ?? 'N/A';

    String patientPhone = widget.patient['phone']?.toString() ?? 'N/A';
    String patientAddress = 'N/A';

    if (widget.patient['address'] != null) {
      if (widget.patient['address'] is Map) {
        patientAddress = widget.patient['address']['Address'] ?? 'N/A';
      } else if (widget.patient['address'] is String) {
        patientAddress = widget.patient['address'];
      }
    }

    Widget cardContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with patient gender icon and name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.genderIcon, size: 28, color: widget.genderColor),
              const SizedBox(width: 8),
              Text(
                patientName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.genderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            color: Colors.grey.shade400,
            thickness: 1.4,
            indent: 25,
            endIndent: 25,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              children: [
                _infoRow('Patient ID', patientId),
                const SizedBox(height: 6),
                _infoRow('Cell No', patientPhone),
                const SizedBox(height: 6),
                _infoRow('Address', patientAddress),
              ],
            ),
          ),
          Divider(
            color: Colors.grey.shade400,
            thickness: 1.4,
            indent: 25,
            endIndent: 25,
          ),

          // Always show all test titles (even if completed)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.tests.length,
            itemBuilder: (context, index) {
              final test = widget.tests[index];
              final testId = test['id'];
              final title = test['title'] ?? 'No Title';
              final queueStatus = (test['queueStatus'] ?? '')
                  .toString()
                  .toLowerCase();

              bool isCompletedLocal =
                  testId != null && _completedTestIds.contains(testId);
              bool isCompletedStatus = queueStatus == 'completed';

              Widget trailingIcon;
              if (isCompletedStatus) {
                trailingIcon = const Icon(Icons.done_all, color: Colors.blue);
              } else if (isCompletedLocal) {
                trailingIcon = const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                );
              } else {
                trailingIcon = const Icon(Icons.chevron_right);
              }

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  trailing: trailingIcon,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LabPage(
                          allTests: widget.tests
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList(),
                          currentIndex: index,
                          queueStaus: queueStatus.toUpperCase(),
                          mode: 0, // individual test click
                        ),
                      ),
                    );
                    if (result == true && testId != null) {
                      setState(() {
                        _completedTestIds.add(testId);
                      });
                      widget.onRefresh();
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );

    // Full card click if all tests completed
    return GestureDetector(
      onTap: _isAllCompleted
          ? () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LabPage(
                    allTests: widget.tests
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList(),
                    currentIndex: 0,
                    queueStaus: 'COMPLETED',
                    mode: 1, // full card click
                  ),
                ),
              );
              if (result == true) {
                setState(() {
                  // futureXRayQueue = TestingScanningService()
                  //     .getAllTestingAndScanning('Tests');
                  widget.onRefresh();
                });
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.genderColor.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black45.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: cardContent,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            '$label :',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
