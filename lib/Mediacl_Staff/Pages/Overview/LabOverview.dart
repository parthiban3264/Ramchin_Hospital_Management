import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../Services/consultation_service.dart';
import '../../../Services/testing&scanning_service.dart';

const Color customGold = Color(0xFFBF955E);
const Color backgroundColor = Color(0xFFFFF7E6);
const Color cardColor = Colors.white;

const TextStyle sectionTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle cardTitleStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

const TextStyle cardValueStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

class LabOverviewPage extends StatefulWidget {
  const LabOverviewPage({super.key});

  @override
  State<LabOverviewPage> createState() => _LabOverviewPageState();
}

class _LabOverviewPageState extends State<LabOverviewPage> {
  final secureStorage = const FlutterSecureStorage();
  final ConsultationService _consultationService = ConsultationService();
  final TestingScanningService _testingService = TestingScanningService();

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  late Future<void> _dashboardFuture;
  bool isRetrying = false;
  String selectedMode = "today";

  // Consultation Stats
  int registered = 0;
  int pending = 0;
  int ongoing = 0;
  int completed = 0;

  int overallRegistered = 0;
  int overallPending = 0;
  int overallOngoing = 0;
  int overallCompleted = 0;

  // Testing & Scanning Stats
  int allTest = 0;
  int testPending = 0;
  int testOngoing = 0;
  int testCompleted = 0;
  int testCancelled = 0;

  int overallAllTest = 0;
  int overallTestPending = 0;
  int overallTestOngoing = 0;
  int overallTestCompleted = 0;
  int overallTestCancelled = 0;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _dashboardFuture = _loadDashboardData();
  }

  Future<void> _loadHospitalInfo() async {
    final name = await secureStorage.read(key: 'hospitalName');
    final place = await secureStorage.read(key: 'hospitalPlace');
    final photo = await secureStorage.read(key: 'hospitalPhoto');

    setState(() {
      hospitalName = name ?? "Unknown Hospital";
      hospitalPlace = place ?? "Unknown Place";
      hospitalPhoto =
          photo ??
          "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    });
  }

  bool isToday(String? dateString) {
    if (dateString == null || dateString.isEmpty) return false;
    try {
      final formatter = DateFormat('yyyy-MM-dd hh:mm a');
      final date = formatter.parse(dateString);
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadDashboardData() async {
    final consultation = await _consultationService.getAllConsultations();
    final testingAndScanning = await _testingService
        .getAllTestingAndScanningData();

    final todayConsultations = consultation
        .where((c) => isToday(c['createdAt']))
        .toList();
    final todayTesting = testingAndScanning
        .where((t) => isToday(t['createdAt']))
        .toList();

    _countConsultations(todayConsultations, consultation);
    _countTesting(todayTesting, testingAndScanning);
  }

  void _countConsultations(List<dynamic> todayData, List<dynamic> allData) {
    registered = todayData.length;
    pending = allData
        .where(
          (c) =>
              c['status'].toString().toLowerCase() == 'pending' &&
              c['paymentStatus'] == true,
        )
        .length;

    ongoing = allData.where((c) {
      final status = c['status'].toString().toLowerCase();
      return status == 'ongoing' || status == 'endprocessing';
    }).length;

    completed = todayData
        .where((c) => c['status'].toString().toLowerCase() == 'completed')
        .length;

    overallRegistered = allData.length;
    overallPending = allData
        .where(
          (c) =>
              c['status'].toString().toLowerCase() == 'pending' &&
              c['paymentStatus'] == true,
        )
        .length;
    overallOngoing = allData.where((c) {
      final status = c['status'].toString().toLowerCase();
      return status == 'ongoing' || status == 'endprocessing';
    }).length;
    overallCompleted = allData
        .where((c) => c['status'].toString().toLowerCase() == 'completed')
        .length;
  }

  void _countTesting(List<dynamic> todayData, List<dynamic> allData) {
    testPending = allData
        .where(
          (t) =>
              t['status'].toString().toLowerCase() == 'pending' &&
              t['paymentStatus'] == true,
        )
        .length;

    testOngoing = allData
        .where(
          (t) =>
              t['status'].toString().toLowerCase() == 'ongoing' ||
              t['status'].toString().toLowerCase() == 'endprocessing',
        )
        .length;
    testCompleted = todayData
        .where((t) => t['status'].toString().toLowerCase() == 'completed')
        .length;
    testCancelled = todayData
        .where((t) => t['status'].toString().toLowerCase() == 'cancelled')
        .length;
    allTest = todayData.length;
    overallAllTest = allData.length;

    overallTestPending = allData
        .where(
          (t) =>
              t['status'].toString().toLowerCase() == 'pending' &&
              t['paymentStatus'] == true,
        )
        .length;
    overallTestOngoing = allData
        .where((t) => t['status'].toString().toLowerCase() == 'ongoing')
        .length;
    overallTestCompleted = allData
        .where((t) => t['status'].toString().toLowerCase() == 'completed')
        .length;
    overallTestCancelled = allData
        .where((t) => t['status'].toString().toLowerCase() == 'cancelled')
        .length;
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<void>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.redAccent,
                    size: 80,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Network Error",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: isRetrying
                        ? null
                        : () async {
                            setState(() => isRetrying = true);
                            try {
                              await _loadDashboardData();
                              setState(
                                () => _dashboardFuture = _loadDashboardData(),
                              );
                            } finally {
                              setState(() => isRetrying = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: isRetrying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Try Again",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHospitalCard(),
                  const SizedBox(height: 22),
                  _modeButtons(),
                  const SizedBox(height: 22),
                  _buildSectionTitle(
                    selectedMode == "today"
                        ? "Testing & Scanning (Today)"
                        : "Testing & Scanning (Overall)",
                  ),
                  const SizedBox(height: 12),
                  _buildGrid([
                    _buildMetricCard(
                      "All Test",
                      selectedMode == "today" ? "$allTest" : "$overallAllTest",
                      Icons.all_inbox,
                    ),
                    _buildMetricCard(
                      "Waiting",
                      selectedMode == "today"
                          ? "$testPending"
                          : "$overallTestPending",
                      Icons.science_outlined,
                    ),
                    _buildMetricCard(
                      "Consulting",
                      selectedMode == "today"
                          ? "$testOngoing"
                          : "$overallTestOngoing",
                      Icons.biotech_rounded,
                    ),
                    _buildMetricCard(
                      "Completed",
                      selectedMode == "today"
                          ? "$testCompleted"
                          : "$overallTestCompleted",
                      Icons.check_circle_outline_rounded,
                    ),
                    _buildMetricCard(
                      "Cancelled",
                      selectedMode == "today"
                          ? "$testCancelled"
                          : "$overallTestCancelled",
                      Icons.cancel_outlined,
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- UI Helpers ----------------
  Widget _modeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _modeButton("today", "Today"),
        const SizedBox(width: 10),
        _modeButton("overall", "Overall"),
      ],
    );
  }

  Widget _modeButton(String mode, String label) {
    final bool isActive = selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? customGold : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: customGold, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : customGold,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                hospitalPhoto ?? "",
                height: 65,
                width: 65,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.local_hospital,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospitalName ?? "Unknown Hospital",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hospitalPlace ?? "Unknown Place",
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(width: 8),
      Text(title, style: sectionTitleStyle),
    ],
  );

  Widget _buildGrid(List<Widget> cards) => GridView.count(
    crossAxisCount: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.25,
    children: cards,
  );

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 5),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: customGold, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: cardTitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(child: Text(value, style: cardValueStyle)),
        ],
      ),
    );
  }
}
