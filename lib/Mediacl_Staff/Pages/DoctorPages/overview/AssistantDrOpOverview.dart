import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Admin/Pages/admin_overview_page.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/payment_service.dart';
import '../../../../Services/testing&scanning_service.dart';

class AssistantDrOverviewPage extends StatefulWidget {
  const AssistantDrOverviewPage({super.key});

  @override
  State<AssistantDrOverviewPage> createState() =>
      _AssistantDrOverviewPageState();
}

// ═══════════════════ THEME ═══════════════════
const Color _gold = Color(0xFFBF955E);
const Color _darkGold = Color(0xFF9E7A47);
const Color _bgColor = Color(0xFFF7F4EF);

// Status palette
const Color _colPending = Color(0xFFFFA726);
const Color _colCompleted = Color(0xFF43A047);
const Color _colCancelled = Color(0xFFE53935);
const Color _colAbandoned = Color(0xFF78909C);
const Color _colAdmitted = Color(0xFF17BDAA);
const Color _colEndProc = Color(0xFF8E24AA);
const Color _colDischarged = Color(0xFF107785);
const Color _colOngoing = Color(0xFF188FE4);

class _AssistantDrOverviewPageState extends State<AssistantDrOverviewPage>
    with TickerProviderStateMixin {
  final ConsultationService _consultationSvc = ConsultationService();
  final TestingScanningService _testingSvc = TestingScanningService();
  final PaymentService _paymentService = PaymentService();
  late Future<void> _dashboardFuture;
  Map<String, dynamic> _cData = {};
  Map<String, dynamic> _tsData = {};
  Map<String, dynamic> _payData = {};
  late AnimationController _staggerCtrl;
  late AnimationController _chartCtrl;
  late AnimationController _pulseCtrl;

  String? doctorId;
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  bool showToday = false;
  bool isRetrying = false;
  late Future<void> _dashFuture;
  String selectedMode = 'today';

  @override
  void initState() {
    super.initState();
    //_dashboardFuture = _loadDashboardData();
    //_loadDashboard();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _chartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _loadHospitalInfo();
    _dashFuture = _loadDashboard();
  }

  // Future<void> _loadDashboard() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   doctorId = prefs.getString('userId');
  //   final res = await Future.wait([
  //     _consultationSvc.getOverviewDashboardByUserId(doctorId!),
  //     _paymentService.getAllOverviewPayments(),
  //     _testingSvc.getOverviewTestScanDashboard(),
  //   ]);
  //   _cData = res[0];
  //   _payData = res[1];
  //   _tsData = res[2];
  //   if (mounted) {
  //     _staggerCtrl.forward(from: 0);
  //     _chartCtrl.forward(from: 0);
  //   }
  // }

  Future<void> _loadDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDoctorId = prefs.getString('assistantDoctorId');
    if (storedDoctorId == null) throw Exception("Doctor ID not found");
    doctorId = storedDoctorId;
    final res = await Future.wait([
      _consultationSvc.getOverviewDashboardByUserId(doctorId!),
      _paymentService.getAllOverviewPayments(),
      _testingSvc.getOverviewTestScanDashboard(),
    ]);

    if (!mounted) return;

    setState(() {
      _cData = res[0];
      _payData = res[1];
      _tsData = res[2];
    });

    //await _loadHospitalInfo();

    _staggerCtrl.forward(from: 0);
    _chartCtrl.forward(from: 0);
  }

  Future<void> _loadHospitalInfo() async {
    final p = await SharedPreferences.getInstance();
    hospitalName = p.getString('hospitalName') ?? 'Unknown';
    hospitalPlace = p.getString('hospitalPlace') ?? 'Unknown';
    hospitalPhoto =
        p.getString('hospitalPhoto') ??
        'https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg';
    if (mounted) setState(() {});
  }

  // ─── safe nested getter ───
  int _g(Map<String, dynamic> data, String path) {
    dynamic n = data;
    for (final p in path.split('.')) {
      if (n is Map<String, dynamic>) {
        n = n[p];
      } else {
        return 0;
      }
    }
    return (n is int) ? n : 0;
  }

  // ───────────────────── UI ─────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: FutureBuilder<void>(
        future: _dashFuture,
        builder: (ctx, snap) {
          if (snap.hasError) return _errorUI();
          if (snap.connectionState == ConnectionState.waiting) {
            return _loadingUI();
          }
          return RefreshIndicator(
            color: _gold,
            onRefresh: () async {
              final future = _loadDashboard();

              setState(() {
                _dashFuture = future;
              });

              await future;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hospitalBanner(),
                  const SizedBox(height: 20),
                  _modeToggle(),
                  const SizedBox(height: 22),

                  // ── TODAY SUMMARY BANNER ──
                  if (selectedMode == 'today') ...[
                    todaySummaryAnalytics(),
                    const SizedBox(height: 22),
                    runningTokens(),
                    const SizedBox(height: 12),
                  ],
                  // if (selectedMode == 'today') ...[
                  _todaySummaryBanner(selectedMode),
                  // const SizedBox(height: 22),
                  // ],

                  // ── CONSULTATION ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _consultationSection(
                      key: ValueKey('c_$selectedMode'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════ TODAY SUMMARY ANALYTICS ═══════════════════

  Widget todaySummaryAnalytics() {
    final Map<String, dynamic> last7 =
        _cData['analytics']['last7DaysRegistrations'];

    final summary = _cData['analytics']['summary'];

    final todayVsYesterday = summary['todayVsYesterdayPercentage'] ?? 0.0;
    final avgPerDay = summary['averagePerDay'] ?? 0.0;

    final entries = last7.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final List<double> values = [];
    final List<String> labels = [];

    for (var e in entries) {
      final date = DateTime.parse(e.key);
      labels.add("${date.month}/${date.day}");
      values.add((e.value as num).toDouble());
    }

    final todayValue = values.last;
    final yesterdayValue = values[5];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final isIncrease = todayVsYesterday >= 0;

    int diff = todayValue.toInt() - yesterdayValue.toInt();

    Color textColor;
    String text;

    if (diff > 0) {
      textColor = Colors.green;
      text = '+ $diff  ';
    } else if (diff < 0) {
      textColor = Colors.red;
      text = '– ${diff.toString().split('-')[1]}  ';
    } else {
      textColor = Colors.blue;
      text = '0  ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "LAST 7D REGISTRATIONS",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isIncrease
                      ? Colors.green.withValues(alpha: .1)
                      : Colors.red.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isIncrease ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isIncrease ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${todayVsYesterday.toStringAsFixed(1)}%",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isIncrease ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// TODAY VALUE
          Text(
            "${todayValue.toInt()}",
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            "Patients Today",
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45),
          ),

          const SizedBox(height: 20),

          /// GRAPH AREA
          SizedBox(
            height: 120,
            child: Stack(
              children: [
                /// LINE GRAPH
                LineGraphWithTooltip(values: values),

                /// BARS
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(values.length, (i) {
                    final height = maxValue == 0
                        ? 0.0
                        : (values[i] / maxValue) * 70;

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          /// TOOLTIP
                          Tooltip(
                            message: "${labels[i]} : ${values[i].toInt()}",
                            child: Container(
                              height: height,
                              width: 10,
                              decoration: BoxDecoration(
                                color: i == values.length - 1
                                    ? Colors.blue
                                    : Colors.blue.withValues(alpha: .35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            labels[i],
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// FOOTER
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                "Average per day:",
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(width: 6),
              Text(
                avgPerDay.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════ TODAY TOKEN BANNER ═══════════════════

  Widget runningTokens() {
    final doctorToday = _cData['today']['doctorToday'] ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        int itemsPerRow = 2;

        if (constraints.maxWidth > 1400) {
          itemsPerRow = 6;
        } else if (constraints.maxWidth > 1100) {
          itemsPerRow = 5;
        } else if (constraints.maxWidth > 800) {
          itemsPerRow = 4;
        } else {
          itemsPerRow = 2;
        }

        double spacing = 16;

        double cardWidth =
            (constraints.maxWidth - ((itemsPerRow - 1) * spacing)) /
            itemsPerRow;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Now Serving",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        "LIVE",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// EMPTY UI
            if (doctorToday.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 50),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "No Tokens Running",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Please wait for the next token",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            /// TOKEN CARDS
            else
              Center(
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: doctorToday.map<Widget>((item) {
                    return SizedBox(
                      width: cardWidth,

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            /// SIDE COLOR STRIP
                            Container(
                              width: 6,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xff4F46E5),
                                    Color(0xff6366F1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),

                            const SizedBox(width: 14),

                            /// TOKEN CONTENT
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "TOKEN",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      letterSpacing: 1,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    item["lastDisplayToken"],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff111827),
                                      letterSpacing: 2,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item["time"],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  // ═══════════════════ TODAY SUMMARY BANNER ═══════════════════
  Widget _todaySummaryBanner(String selectedMode) {
    final total = _g(_cData, '$selectedMode.total');
    final isTestOnlyTotal = selectedMode == 'today'
        ? _g(_cData, 'today.todayTestOnlyTotal')
        : _g(_cData, 'overall.overallTestOnlyTotal');
    final payment = selectedMode == 'today'
        ? _g(_cData, 'today.paymentCollected')
        : _g(_cData, 'overall.overallPaymentCollected');

    final int safeTotal = total == 0 ? 1 : total + isTestOnlyTotal;
    final int payTotal = total == 0 ? 1 : total;

    return _staggerItem(
      index: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _gold.withValues(alpha: 0.08),
              _gold.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _gold.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: _darkGold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Summary",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Header Row
                        Row(
                          children: [
                            Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 20,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Registrations",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Overall count",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 🔹 Large Centered Total
                        Center(
                          child: TweenAnimationBuilder<int>(
                            tween: IntTween(
                              begin: 0,
                              end: total + isTestOnlyTotal,
                            ),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, value, __) => Text(
                              '$value',
                              style: GoogleFonts.poppins(
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Mini Stats Row (Clickable Cards with Progress)
            Row(
              children: [
                _miniStatProgressCard(
                  label: 'O/P Reg',
                  value: total,
                  total: safeTotal,
                  icon: Icons.person_add_alt_1_rounded,
                  color: const Color(0xFF5C6BC0),
                  onTap: () {
                    // TODO: navigate or filter
                  },
                ),
                _miniStatProgressCard(
                  label: 'Pvt T/S Reg',
                  value: isTestOnlyTotal,
                  total: safeTotal,
                  icon: Icons.person_add_alt_1_rounded,
                  color: const Color(0xFF4C9E9B),
                  onTap: () {
                    // TODO: navigate or filter
                  },
                ),
                // _miniStatProgressCard(
                //   label: 'Emergency',
                //   value: emergency,
                //   total: safeTotal,
                //   icon: Icons.emergency_rounded,
                //   color: _colCancelled,
                //   onTap: () {},
                // ),
                _miniStatProgressCard(
                  label: 'Payments',
                  value: payment,
                  total: payTotal,
                  icon: Icons.payments_rounded,
                  color: _colCompleted,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStatProgressCard({
    required String label,
    required int value,
    required int total,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final double percent = total == 0 ? 0 : (value / total);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Progress Ring
              SizedBox(
                height: 48,
                width: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 4,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    Center(
                      child: Text(
                        '${(percent * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Animated Count
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: value),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(
                  '$v',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),

              // // Percentage
              // Text(
              //   '${(percent * 100).toStringAsFixed(1)}%',
              //   style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45),
              // ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════ LOADING ═══════════════════
  Widget _loadingUI() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            double scale = 1 + (_pulseCtrl.value * 0.4);

            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _gold.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold.withOpacity(0.08),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      hospitalPhoto ?? '',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.local_hospital, color: _gold, size: 40),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 28),

        HeartbeatLoader(color: _gold),

        const SizedBox(height: 18),

        Text(
          'Preparing your hospital dashboard...',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Loading patient insights & reports',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black38),
        ),
      ],
    ),
  );

  // ═══════════════════ ERROR ═══════════════════
  Widget _errorUI() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade50, Colors.red.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 52,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Connection Lost',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Could not load dashboard data.\nPlease check your connection.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: isRetrying
                ? null
                : () async {
                    setState(() => isRetrying = true);
                    try {
                      setState(() => _dashFuture = _loadDashboard());
                      await _dashFuture;
                    } finally {
                      if (mounted) setState(() => isRetrying = false);
                    }
                  },
            icon: isRetrying
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            label: Text(isRetrying ? 'Retrying…' : 'Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 3,
            ),
          ),
        ],
      ),
    ),
  );

  // ═══════════════════ HOSPITAL BANNER ═══════════════════
  Widget _hospitalBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A55A), Color(0xFFBF955E), Color(0xFFA67C4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBF955E).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -15,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(hospitalPhoto ?? ''),
                    onBackgroundImageError: (_, __) {},
                    child: hospitalPhoto == null
                        ? const Icon(
                            Icons.local_hospital,
                            size: 30,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospitalName ?? 'Hospital',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: Colors.white60,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hospitalPlace ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ MODE TOGGLE ═══════════════════
  Widget _modeToggle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleBtn('today', 'Today', Icons.today_rounded),
            _toggleBtn('overall', 'Overall', Icons.insights_rounded),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String mode, String label, IconData icon) {
    final active = selectedMode == mode;
    return GestureDetector(
      onTap: () {
        if (selectedMode != mode) {
          setState(() => selectedMode = mode);
          _staggerCtrl.forward(from: 0);
          _chartCtrl.forward(from: 0);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFFD4A55A), Color(0xFFBF955E)],
                )
              : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: active ? Colors.white : Colors.black38),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ CONSULTATION SECTION ═══════════════════
  Widget _consultationSection({Key? key}) {
    final isToday = selectedMode == 'today';

    final List<_Metric> cards;
    if (isToday) {
      cards = [
        _Metric(
          'PENDING',
          _g(_cData, 'today.statusBreakdown.PENDING'),
          Icons.schedule_rounded, // waiting / time
          const Color(0xFFFFA726), // soft amber
        ),

        _Metric(
          'ONGOING',
          _g(_cData, 'today.statusBreakdown.ONGOING') +
              _g(_cData, 'today.statusBreakdown.ENDPROCESSING'),
          Icons.autorenew_rounded, // in progress
          const Color(0xFF42A5F5), // blue
        ),

        _Metric(
          'ADMITTED',
          _g(_cData, 'today.statusBreakdown.ADMITTED'),
          Icons.local_hospital_rounded, // hospital admit
          const Color(0xFF26A69A), // teal
        ),

        _Metric(
          'DISCHARGED',
          _g(_cData, 'today.statusBreakdown.DISCHARGED'),
          Icons.exit_to_app_rounded, // exit / discharge
          const Color(0xFF66BB6A), // green
        ),

        _Metric(
          'COMPLETED',
          _g(_cData, 'today.statusBreakdown.COMPLETED'),
          Icons.check_circle_rounded, // success
          const Color(0xFF4CAF50), // success green
        ),

        _Metric(
          'CANCELLED',
          _g(_cData, 'today.statusBreakdown.CANCELLED'),
          Icons.cancel_rounded, // cancelled
          const Color(0xFFEF5350), // red
        ),

        _Metric(
          'ABANDONED',
          _g(_cData, 'today.statusBreakdown.ABANDONED'),
          Icons.person_off_rounded,
          _colAbandoned, // orange red
        ),

        _Metric(
          'EMERGENCY',
          _g(_cData, 'today.emergency'),
          Icons.emergency_rounded, // correct already
          const Color(0xFFD32F2F), // deep red
        ),

        //
        // _Metric(
        //   'Total',
        //   _g(_cData, 'today.total'),
        //   Icons.people_alt_rounded,
        //   const Color(0xFF5C6BC0),
        // ),
        // _Metric(
        //   'Test/Scan',
        //   _g(_cData, 'today.testingScanning'),
        //   Icons.science_rounded,
        //   _colAdmitted,
        // ),
        // _Metric(
        //   'Payments',
        //   _g(_cData, 'today.paymentCollected'),
        //   Icons.payments_rounded,
        //   _colCompleted,
        // ),
      ];
    } else {
      cards = [
        _Metric(
          'PENDING',
          _g(_cData, 'overall.statusBreakdown.PENDING'),
          Icons.schedule_rounded, // waiting / time
          const Color(0xFFFFA726), // soft amber
        ),

        _Metric(
          'ONGOING',
          _g(_cData, 'overall.statusBreakdown.ONGOING') +
              _g(_cData, 'overall.statusBreakdown.ENDPROCESSING'),
          Icons.autorenew_rounded, // in progress
          const Color(0xFF42A5F5), // blue
        ),

        _Metric(
          'ADMITTED',
          _g(_cData, 'overall.statusBreakdown.ADMITTED'),
          Icons.local_hospital_rounded, // hospital admit
          const Color(0xFF26A69A), // teal
        ),

        _Metric(
          'DISCHARGED',
          _g(_cData, 'overall.statusBreakdown.DISCHARGED'),
          Icons.exit_to_app_rounded, // exit / discharge
          const Color(0xFF66BB6A), // green
        ),

        _Metric(
          'COMPLETED',
          _g(_cData, 'overall.statusBreakdown.COMPLETED'),
          Icons.check_circle_rounded, // success
          const Color(0xFF4CAF50), // success green
        ),

        _Metric(
          'CANCELLED',
          _g(_cData, 'overall.statusBreakdown.CANCELLED'),
          Icons.cancel_rounded, // cancelled
          const Color(0xFFEF5350), // red
        ),

        _Metric(
          'ABANDONED',
          _g(_cData, 'overall.statusBreakdown.ABANDONED'),
          Icons.person_off_rounded,
          _colAbandoned, // orange red
        ),

        _Metric(
          'EMERGENCY',
          _g(_cData, 'overall.overallEmergency'),
          Icons.emergency_rounded, // correct already
          const Color(0xFFD32F2F), // deep red
        ),
        // _Metric(
        //   'Total',
        //   _g(_cData, 'overall.total'),
        //   Icons.people_alt_rounded,
        //   const Color(0xFF5C6BC0),
        // ),
        // _Metric(
        //   'Test/Scan',
        //   _g(_cData, 'overall.testingScanning'),
        //   Icons.science_rounded,
        //   _colAdmitted,
        // ),
        // _Metric(
        //   'Completed',
        //   _g(_cData, 'overall.statusBreakdown.COMPLETED'),
        //   Icons.verified_rounded,
        //   _colCompleted,
        // ),
        // _Metric(
        //   'Admitted',
        //   _g(_cData, 'overallStatusBreakdown.ADMITTED'),
        //   Icons.local_hospital_rounded,
        //   _colAdmitted,
        // ),
        // _Metric(
        //   'Pending',
        //   _g(_cData, 'overallStatusBreakdown.PENDING'),
        //   Icons.hourglass_top_rounded,
        //   _colPending,
        // ),
        // _Metric(
        //   'Discharged',
        //   _g(_cData, 'overallStatusBreakdown.DISCHARGED'),
        //   Icons.exit_to_app_rounded,
        //   _colDischarged,
        // ),
      ];
    }

    // chart breakdown
    final Map<String, int> breakdown = {};

    final bd = isToday
        ? _cData['today']['statusBreakdown']
        : _cData['overall']['statusBreakdown'];
    if (bd is Map<String, dynamic>) {
      bd.forEach((k, v) {
        if (v is int && v > 0) breakdown[k] = v;
      });
    }

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          Icons.medical_services_rounded,
          isToday ? 'Consultations — Today' : 'Consultations — Overall',
        ),
        const SizedBox(height: 14),
        _animatedCardGrid(cards, startIndex: 1),
        if (breakdown.isNotEmpty) ...[
          const SizedBox(height: 22),
          _staggerItem(
            index: cards.length + 1,
            child: _donutChartCard(
              title: 'Status Distribution',
              data: breakdown,
              colorMap: _cColorMap,
            ),
          ),
          // const SizedBox(height: 16),
          // _staggerItem(
          //   index: cards.length + 2,
          //   child: _barChartCard(
          //     title: 'Status Comparison',
          //     data: breakdown,
          //     colorMap: _cColorMap,
          //   ),
          // ),
        ],
      ],
    );
  }

  // ═══════════════════ SECTION HEADER ═══════════════════
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _gold.withValues(alpha: 0.18),
                _gold.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _darkGold, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ═══════════════════ ANIMATED CARD GRID ═══════════════════
  Widget _animatedCardGrid(List<_Metric> items, {int startIndex = 0}) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w > 1100
        ? 5
        : w > 800
        ? 4
        : w > 550
        ? 3
        : 2;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        return _staggerItem(
          index: startIndex + i,
          child: _metricCard(items[i]),
        );
      },
    );
  }

  // ═══════════════════ METRIC CARD ═══════════════════
  Widget _metricCard(_Metric m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: m.color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  m.color.withValues(alpha: 0.15),
                  m.color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(m.icon, color: m.color, size: 22),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: m.value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '$v',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            m.label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.black45,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════ DONUT CHART CARD ═══════════════════
  Widget _donutChartCard({
    required String title,
    required Map<String, int> data,
    required Map<String, Color> colorMap,
  }) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    final entries = data.entries.toList();

    String? selectedKey;
    int selectedValue = 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _chartCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.donut_large_rounded, size: 18, color: _darkGold),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Donut Chart Area
          SizedBox(
            height: 210,
            child: StatefulBuilder(
              builder: (context, setState) {
                return AnimatedBuilder(
                  animation: _chartCtrl,
                  builder: (_, __) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 50,
                            startDegreeOffset: -90,
                            sections: entries.map((e) {
                              final isSelected = e.key == selectedKey;
                              final pct = total > 0
                                  ? (e.value / total * 100)
                                  : 0.0;
                              final c = colorMap[e.key] ?? Colors.grey;

                              return PieChartSectionData(
                                value: e.value.toDouble(),
                                title: pct >= 6
                                    ? '${pct.toStringAsFixed(0)}%'
                                    : '',
                                color: c,
                                radius:
                                    (isSelected ? 60 : 50) * _chartCtrl.value,
                                titleStyle: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: isSelected ? 2 : 1,
                                ),
                              );
                            }).toList(),
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                if (response == null ||
                                    response.touchedSection == null) {
                                  return;
                                }

                                final index = response
                                    .touchedSection!
                                    .touchedSectionIndex;
                                if (index < 0 || index >= entries.length) {
                                  return;
                                }

                                final entry = entries[index];
                                setState(() {
                                  selectedKey = entry.key;
                                  selectedValue = entry.value;
                                });
                              },
                            ),
                          ),
                        ),

                        // Center Content (Dynamic)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TweenAnimationBuilder<int>(
                              tween: IntTween(
                                begin: 0,
                                end: selectedValue > 0 ? selectedValue : total,
                              ),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => Text(
                                '$v',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              selectedKey ?? 'Total',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Clean Legend (More Professional)
          Center(
            child: Wrap(
              spacing: 2,
              runSpacing: 6,
              children: entries.map((e) {
                final c = colorMap[e.key] ?? Colors.grey;
                final pct = total > 0 ? (e.value / total * 100) : 0.0;

                return Container(
                  width: 150, // 👈 fixed width for perfect alignment
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 🔹 Color Indicator
                      Container(
                        width: 8,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // 🔹 Label
                      Expanded(
                        child: Text(
                          _fmtLabel(e.key),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // 🔹 Value + Percentage (Right aligned)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${e.value}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ STAGGER WRAPPER ═══════════════════
  Widget _staggerItem({required int index, required Widget child}) {
    final delay = (index * 0.07).clamp(0.0, 0.7);
    final end = (delay + 0.35).clamp(0.0, 1.0);
    final curvedAnim = CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(delay, end, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: curvedAnim,
      builder: (_, child) {
        final v = curvedAnim.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + 0.15 * v,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - v)),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  // ═══════════════════ HELPERS ═══════════════════
  BoxDecoration _chartCardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.grey.shade100),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ],
  );

  String _fmtLabel(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  static const _cColorMap = {
    'PENDING': _colPending,
    'COMPLETED': _colCompleted,
    'CANCELLED': _colCancelled,
    'ABANDONED': _colAbandoned,
    'ADMITTED': _colAdmitted,
    'ONGOING': _colOngoing,
    'ENDPROCESSING': _colEndProc,
    'DISCHARGED': _colDischarged,
  };

  static const _tsColorMap = {
    'PENDING': _colPending,
    'COMPLETED': _colCompleted,
    'CANCELLED': _colCancelled,
    'ABANDONED': _colAbandoned,
  };
  static const _payColorMap = {
    'PENDING': _colPending,
    'PAID': _colCompleted,
    'CANCELLED': _colCancelled,
    'PAYLATER': _colAdmitted,
  };
}

// ═══════════════════ MODELS ═══════════════════
class _Metric {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _Metric(this.label, this.value, this.icon, this.color);
}

// ═══════════════════ ANIMATED BUILDER ═══════════════════
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext ctx) => builder(ctx, child);
}
