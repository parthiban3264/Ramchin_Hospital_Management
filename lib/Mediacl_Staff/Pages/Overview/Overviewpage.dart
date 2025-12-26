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

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final secureStorage = const FlutterSecureStorage();
  final ConsultationService _consultationService = ConsultationService();
  final TestingScanningService _testingService = TestingScanningService();

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  late Future<void> _dashboardFuture;

  bool showToday = true;
  bool networkError = false;

  // Consultation
  int regToday = 0;
  int regOverall = 0;

  int pendingToday = 0;
  int pendingOverall = 0;

  int ongoingToday = 0;
  int ongoingOverall = 0;

  int completedToday = 0;
  int completedOverall = 0;

  int cancelToday = 0;
  int cancelOverall = 0;

  // Testing
  int testPendingToday = 0;
  int testPendingOverall = 0;

  int testOngoingToday = 0;
  int testOngoingOverall = 0;

  int testCompletedToday = 0;
  int testCompletedOverall = 0;

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
    try {
      networkError = false;

      final consultation = await _consultationService.getAllConsultations();
      final testData = await _testingService.getAllTestingAndScanningData();

      final todayConsult = consultation
          .where((c) => isToday(c['createdAt']))
          .toList();
      final todayTest = testData.where((t) => isToday(t['createdAt'])).toList();

      // Consultation Today
      regToday = todayConsult.length;
      pendingToday = todayConsult
          .where((c) => c['status'].toString().toLowerCase() == 'pending')
          .length;
      ongoingToday = todayConsult
          .where(
            (c) =>
                c['status'].toString().toLowerCase() == 'ongoing' ||
                c['status'].toString().toLowerCase() == 'endprocessing',
          )
          .length;
      completedToday = todayConsult
          .where((c) => c['status'].toString().toLowerCase() == 'completed')
          .length;
      cancelToday = todayConsult
          .where((c) => c['status'].toString().toLowerCase() == 'cancelled')
          .length;

      // Consultation overall
      regOverall = consultation.length;
      pendingOverall = consultation
          .where((c) => c['status'].toString().toLowerCase() == 'pending')
          .length;
      ongoingOverall = consultation
          .where(
            (c) =>
                c['status'].toString().toLowerCase() == 'ongoing' ||
                c['status'].toString().toLowerCase() == 'endprocessing',
          )
          .length;
      completedOverall = consultation
          .where((c) => c['status'].toString().toLowerCase() == 'completed')
          .length;
      cancelOverall = consultation
          .where((c) => c['status'].toString().toLowerCase() == 'cancelled')
          .length;

      // Testing Today
      testCompletedToday = todayTest
          .where((t) => t['status'].toString().toLowerCase() == 'completed')
          .length;
      testPendingToday = todayTest
          .where((t) => t['status'].toString().toLowerCase() == 'pending')
          .length;
      testOngoingToday = todayTest
          .where((t) => t['status'].toString().toLowerCase() == 'ongoing')
          .length;

      // Testing Overall
      testCompletedOverall = testData
          .where((t) => t['status'].toString().toLowerCase() == 'completed')
          .length;
      testPendingOverall = testData
          .where((t) => t['status'].toString().toLowerCase() == 'pending')
          .length;
      testOngoingOverall = testData
          .where(
            (t) =>
                t['status'].toString().toLowerCase() == 'ongoing' ||
                t['status'].toString().toLowerCase() == 'endprocessing',
          )
          .length;
    } catch (e) {
      networkError = true;
    }

    setState(() {});
  }

  // -------------------------------------------------------------------
  // UI BUILD
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardFuture = _loadDashboardData();
              });
              await _dashboardFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHospitalCard(),
                  const SizedBox(height: 22),
                  _modeButtons(),
                  const SizedBox(height: 20),

                  if (networkError) _networkErrorCard(),

                  _buildSectionTitle(
                    "Consultations (${showToday ? "Today" : "Overall"})",
                  ),
                  const SizedBox(height: 12),

                  _buildGrid([
                    _metricBox(
                      "Registered",
                      showToday ? "$regToday" : "$regOverall",
                      Icons.person_add_alt_1_rounded,
                    ),
                    _metricBox(
                      "Waiting",
                      showToday ? "$pendingToday" : "$pendingOverall",
                      Icons.pending_actions_outlined,
                    ),
                    _metricBox(
                      "Consulting",
                      showToday ? "$ongoingToday" : "$ongoingOverall",
                      Icons.timelapse_rounded,
                    ),
                    _metricBox(
                      "Completed",
                      showToday ? "$completedToday" : "$completedOverall",
                      Icons.verified_outlined,
                    ),
                    _metricBox(
                      "Cancelled",
                      showToday ? "$cancelToday" : "$cancelOverall",
                      Icons.cancel_outlined,
                    ),
                  ]),

                  // const SizedBox(height: 28),
                  // _buildSectionTitle(
                  //   "Testing & Scanning (${showToday ? "Today" : "Overall"})",
                  // ),
                  // const SizedBox(height: 12),
                  //
                  // _buildGrid([
                  //   _metricBox(
                  //     "Pending",
                  //     showToday ? "$testPendingToday" : "$testPendingOverall",
                  //     Icons.science_outlined,
                  //   ),
                  //   _metricBox(
                  //     "Ongoing",
                  //     showToday ? "$testOngoingToday" : "$testOngoingOverall",
                  //     Icons.biotech_rounded,
                  //   ),
                  //   _metricBox(
                  //     "Completed",
                  //     showToday
                  //         ? "$testCompletedToday"
                  //         : "$testCompletedOverall",
                  //     Icons.check_circle_outline_rounded,
                  //   ),
                  // ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------
  // WIDGETS (AdminOverview UI)
  // -------------------------------------------------------------------

  Widget _modeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _modeButton(true, "Today"),
        const SizedBox(width: 10),
        _modeButton(false, "Overall"),
      ],
    );
  }

  Widget _modeButton(bool today, String label) {
    final bool active = today == showToday;

    return GestureDetector(
      onTap: () => setState(() => showToday = today),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: active ? customGold : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: customGold, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : customGold,
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
                errorBuilder: (c, e, s) => const Icon(
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
                    hospitalName ?? "",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hospitalPlace ?? "",
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

  Widget _networkErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: const [
          Icon(Icons.wifi_off_rounded, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Network error! Unable to load data.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Text(title, style: sectionTitleStyle)],
    );
  }

  Widget _buildGrid(List<Widget> cards) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: cards,
    );
  }

  Widget _metricBox(String title, String value, IconData icon) {
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
