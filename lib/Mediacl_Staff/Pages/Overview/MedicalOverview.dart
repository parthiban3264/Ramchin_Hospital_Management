import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../Services/consultation_service.dart';
import '../../../Services/payment_service.dart';
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

class MedicalOverviewPage extends StatefulWidget {
  const MedicalOverviewPage({super.key});

  @override
  State<MedicalOverviewPage> createState() => _MedicalOverviewPageState();
}

class _MedicalOverviewPageState extends State<MedicalOverviewPage> {
  final secureStorage = const FlutterSecureStorage();
  final PaymentService _paymentService = PaymentService();

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  late Future<void> _dashboardFuture;

  bool showToday = true; // toggle
  bool isRetrying = false;

  // Payment stats
  int totalPendingPayments = 0;
  int overAllPendingPayments = 0;
  int totalPaidToday = 0;
  int totalPaidOverall = 0;

  int regToday = 0;
  int regOverall = 0;

  int registrationFeeToday = 0;
  int registrationFeeOverall = 0;

  int testingFeeToday = 0;
  int testingFeeOverall = 0;

  int manualPayToday = 0;
  int manualPayOverall = 0;

  int onlinePayToday = 0;
  int onlinePayOverall = 0;

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
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadDashboardData() async {
    final payments = await _paymentService.getAllPayments();

    // 🔥 1. Global filter → remove MEDICINETONICINJECTIONFEES everywhere
    final validPayments = payments.where(
      (p) => p['type'].toString().toUpperCase() == 'MEDICINETONICINJECTIONFEES',
    );

    // 🔥 2. Today PAID (after filter)
    final todayList = validPayments
        .where(
          (p) =>
              p['status'].toString().toUpperCase() == 'PAID' &&
              isToday(p['createdAt']),
        )
        .toList();

    // 🔥 3. Overall PAID (after filter)
    final overallList = validPayments
        .where((p) => p['status'].toString().toUpperCase() == 'PAID')
        .toList();

    // 🔥 4. Today ALL (not only paid)
    final todayAll = validPayments
        .where((p) => isToday(p['createdAt']))
        .toList();

    // 🔥 5. Overall ALL (not only paid)
    final overallAll = validPayments.toList();

    setState(() {
      // TOTAL REGISTRATION COUNTS (Your logic)
      regToday = todayAll.length;
      regOverall = overallAll.length;

      // PENDING (after skip)
      totalPendingPayments = todayAll
          .where((p) => p['status'].toString().toUpperCase() == 'PENDING')
          .length;

      overAllPendingPayments = overallAll
          .where((p) => p['status'].toString().toUpperCase() == 'PENDING')
          .length;

      // PAID COUNTS
      totalPaidToday = todayList.length;
      totalPaidOverall = overallList.length;

      // REGISTRATION FEES
      registrationFeeToday = todayList
          .where((p) => p['type'].toString().toUpperCase() == 'REGISTRATIONFEE')
          .length;

      registrationFeeOverall = overallList
          .where((p) => p['type'].toString().toUpperCase() == 'REGISTRATIONFEE')
          .length;

      // TESTING
      testingFeeToday = todayList
          .where(
            (p) =>
                p['type'].toString().toUpperCase() ==
                'MEDICINETONICINJECTIONFEES',
          )
          .length;

      testingFeeOverall = overallList
          .where(
            (p) =>
                p['type'].toString().toUpperCase() ==
                'MEDICINETONICINJECTIONFEES',
          )
          .length;

      // MANUAL PAY
      manualPayToday = todayList
          .where(
            (p) => p['paymentType'].toString().toUpperCase() == 'MANUALPAY',
          )
          .length;

      manualPayOverall = overallList
          .where(
            (p) => p['paymentType'].toString().toUpperCase() == 'MANUALPAY',
          )
          .length;

      // ONLINE PAY
      onlinePayToday = todayList
          .where(
            (p) => p['paymentType'].toString().toUpperCase() == 'ONLINEPAY',
          )
          .length;

      onlinePayOverall = overallList
          .where(
            (p) => p['paymentType'].toString().toUpperCase() == 'ONLINEPAY',
          )
          .length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          // ---------------- NETWORK ERROR PAGE ----------------
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 85,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Network Error",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Retry button with loading
                  ElevatedButton(
                    onPressed: isRetrying
                        ? null
                        : () async {
                            setState(() => isRetrying = true);
                            try {
                              await _loadDashboardData();
                              setState(() {
                                _dashboardFuture = _loadDashboardData();
                              });
                            } finally {
                              setState(() => isRetrying = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customGold,
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
                              strokeWidth: 2,
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

          // ---------------- LOADING ----------------
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ---------------- SUCCESS UI ----------------
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
                  const SizedBox(height: 20),

                  //---------------- Toggle Buttons ----------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildToggle("Today", showToday, () {
                        setState(() => showToday = true);
                      }),
                      const SizedBox(width: 16),
                      _buildToggle("Overall", !showToday, () {
                        setState(() => showToday = false);
                      }),
                    ],
                  ),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    "Medical Overview ( ${showToday ? 'Today' : 'Overall'} )",
                  ),
                  const SizedBox(height: 12),

                  _buildGrid([
                    // _buildMetricCard(
                    //   "Register",
                    //   "${showToday ? regToday : regOverall}",
                    //   Icons.app_registration,
                    // ),
                    _buildMetricCard(
                      "Pending",
                      "${showToday ? totalPendingPayments : overAllPendingPayments}",
                      Icons.pending_actions_outlined,
                    ),

                    _buildMetricCard(
                      "Paid ",
                      "${showToday ? totalPaidToday : totalPaidOverall}",
                      Icons.verified_outlined,
                    ),

                    // _buildMetricCard(
                    //   "Prescription\n Fees",
                    //   "${showToday ? registrationFeeToday : registrationFeeOverall}",
                    //   Icons.receipt_long_rounded,
                    // ),
                    _buildMetricCard(
                      "Prescription\n Fees",
                      "${showToday ? testingFeeToday : testingFeeOverall}",
                      Icons.biotech_rounded,
                    ),
                    _buildMetricCard(
                      "Manual Pay",
                      "${showToday ? manualPayToday : manualPayOverall}",
                      Icons.payments,
                    ),

                    _buildMetricCard(
                      "Online Pay",
                      "${showToday ? onlinePayToday : onlinePayOverall}",
                      Icons.phone_iphone,
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

  // -----------------------------------------------------------
  // TOGGLE BUTTON STYLE (same as your admin page)
  // -----------------------------------------------------------
  Widget _buildToggle(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFFF5D6A2), Color(0xFFEEC98F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFFF3E0), Color(0xFFFFF3E0)],
                ),
          border: Border.all(
            color: active ? Color(0xFF886638) : Colors.brown.shade300,
            width: active ? 1.8 : 1.2,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.brown.shade800 : Colors.brown.shade600,
            fontSize: 15,
            fontWeight: FontWeight.bold,
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
                errorBuilder: (context, e, s) => const Icon(
                  Icons.local_hospital,
                  size: 55,
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
    children: [Text(title, style: sectionTitleStyle)],
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
                  maxLines: 2,
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
