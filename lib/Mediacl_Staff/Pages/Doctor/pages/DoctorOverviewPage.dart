import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../Services/consultation_service.dart';

const Color customGold = Color(0xFFBF955E);
const Color backgroundColor = Color(0xFFFFF7E6);
const Color cardColor = Colors.white;

const TextStyle cardTitleStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle cardValueStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

class DrOverviewPage extends StatefulWidget {
  const DrOverviewPage({super.key});

  @override
  State<DrOverviewPage> createState() => _DrOverviewPageState();
}

class _DrOverviewPageState extends State<DrOverviewPage> {
  final secureStorage = const FlutterSecureStorage();
  final ConsultationService _consultationService = ConsultationService();

  late Future<void> _dashboardFuture;

  String? doctorId;
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;


  int pending = 0, ongoing = 0, completed = 0, cancel = 0, reg = 0;

  int tPending = 0, tOngoing = 0, tCompleted = 0, tCancel = 0, treg = 0;


  bool showToday = false;
  bool isRetrying = false;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  // ----------------- DATE PARSER -----------------
  DateTime? parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    try {
      // Example → "2025-12-03 04:17 PM"
      final parts = raw.split(" ");
      if (parts.length < 3) return null;

      final datePart = parts[0];
      final timePart = parts[1];
      final ampm = parts[2];

      final datePieces = datePart.split("-");
      int year = int.parse(datePieces[0]);
      int month = int.parse(datePieces[1]);
      int day = int.parse(datePieces[2]);

      final timePieces = timePart.split(":");
      int hour = int.parse(timePieces[0]);
      int minute = int.parse(timePieces[1]);

      if (ampm == "PM" && hour != 12) hour += 12;
      if (ampm == "AM" && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print("Date Parse Error: $raw");
      return null;
    }
  }

  // ----------------- LOAD DATA -----------------
  Future<void> _loadDashboardData() async {
    final storedDoctorId = await secureStorage.read(key: 'userId');
    if (storedDoctorId == null) throw Exception("Doctor ID not found");

    doctorId = storedDoctorId;

    hospitalName = await secureStorage.read(key: 'hospitalName');
    hospitalPlace = await secureStorage.read(key: 'hospitalPlace');
    hospitalPhoto = await secureStorage.read(key: 'hospitalPhoto');

    final consultations = await _consultationService.getAllConsultations();

    final myConsultations = consultations
        .where((c) => c['doctor_Id'].toString() == doctorId)
        .toList();

    _countOverall(myConsultations);
    _countToday(myConsultations);
  }

  // ----------------- COUNT OVERALL -----------------
  void _countOverall(List<dynamic> list) {
    pending = list
        .where((c) => c['status'].toString().toLowerCase() == 'pending')
        .length;
    reg = list.length;

    ongoing = list.where((c) {
      final s = c['status'].toString().toLowerCase();
      return s == 'ongoing' || s == 'endprocessing';
    }).length;

    completed = list
        .where((c) => c['status'].toString().toLowerCase() == 'completed')
        .length;

    cancel = list

        .where((c) => c['status'].toString().toLowerCase() == 'cancelled')

        .length;
  }

  // ----------------- COUNT TODAY -----------------
  void _countToday(List<dynamic> list) {
    final now = DateTime.now();

    final todayList = list.where((c) {
      final date = parseDate(c['createdAt']);
      if (date == null) return false;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();

    tPending = todayList
        .where((c) => c['status'].toString().toLowerCase() == 'pending')
        .length;

    treg = todayList.length;


    tOngoing = todayList.where((c) {
      final s = c['status'].toString().toLowerCase();
      return s == 'ongoing' || s == 'endprocessing';
    }).length;

    tCompleted = todayList
        .where((c) => c['status'].toString().toLowerCase() == 'completed')
        .length;

    tCancel = todayList

        .where((c) => c['status'].toString().toLowerCase() == 'cancelled')

        .length;
  }

  // ----------------- BUILD UI -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) return _buildErrorUI();

          return RefreshIndicator(
            onRefresh: () async {
              await _loadDashboardData();
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHospitalCard(),
                  const SizedBox(height: 20),

                  // ---------- FILTER BUTTONS ----------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _filterButton("Today", showToday, () {
                        setState(() => showToday = true);
                      }),
                      _filterButton("Overall", !showToday, () {
                        setState(() => showToday = false);
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      "Assigned Patients Summary",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---------- METRIC CARDS ----------
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.3,
                    children: [
                      _buildMetricCard(
                        "Registered",
                        "${showToday ? treg : reg}",
                        Icons.app_registration,
                      ),
                      _buildMetricCard(
                        "Waiting",
                        "${showToday ? tPending : pending}",
                        Icons.pending_actions,
                      ),
                      _buildMetricCard(
                        "Consulting",
                        "${showToday ? tOngoing : ongoing}",
                        Icons.timelapse,
                      ),
                      _buildMetricCard(
                        "Completed",
                        "${showToday ? tCompleted : completed}",
                        Icons.verified_outlined,
                      ),
                      _buildMetricCard(


                        "Canceled",
                        "${showToday ? tCancel : cancel}",
                        Icons.cancel_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------- ERROR UI -----------------
  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 80),
          const SizedBox(height: 10),
          const Text(
            "Network Error",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 14),

          ElevatedButton(
            onPressed: isRetrying
                ? null
                : () async {
                    setState(() => isRetrying = true);
                    try {
                      await _loadDashboardData();
                      setState(() {});
                    } finally {
                      setState(() => isRetrying = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: customGold,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: isRetrying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "Try Again",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  // ----------------- HOSPITAL CARD -----------------
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

  // ----------------- FILTER BUTTON -----------------
  Widget _filterButton(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: active ? customGold : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: customGold),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : customGold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ----------------- METRIC CARD -----------------
  static Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: customGold, size: 28),
              const SizedBox(width: 10),
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
          const SizedBox(height: 8),
          Center(
            child: Text(
              value,
              style: cardValueStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
