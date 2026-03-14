import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Services/consultation_service.dart';
import '../../Services/payment_service.dart';
import '../../Services/testing&scanning_service.dart';

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

// ═══════════════════ PAGE ═══════════════════
class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});
  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage>
    with TickerProviderStateMixin {
  final ConsultationService _consultationSvc = ConsultationService();
  final TestingScanningService _testingSvc = TestingScanningService();
  final PaymentService _paymentService = PaymentService();

  String? hospitalName, hospitalPlace, hospitalPhoto;
  Map<String, dynamic> _cData = {};
  Map<String, dynamic> _tsData = {};
  Map<String, dynamic> _payData = {};
  late Future<void> _dashFuture;
  bool isRetrying = false;
  String selectedMode = 'today';

  // Animations
  late AnimationController _staggerCtrl;
  late AnimationController _chartCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _chartCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
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

  // Future<void> _loadDashboard() async {
  //   final res = await Future.wait([
  //     _consultationSvc.getOverviewDashboard(),
  //     _paymentService.getAllOverviewPayments(),
  //     _testingSvc.getOverviewTestScanDashboard(),
  //   ]);
  //   _cData = res[0];
  //   _payData = res[1];
  //   _tsData = res[2];
  //   _loadHospitalInfo();
  //   if (mounted) {
  //     _staggerCtrl.forward(from: 0);
  //     _chartCtrl.forward(from: 0);
  //   }
  // }

  Future<void> _loadDashboard() async {
    final res = await Future.wait([
      _consultationSvc.getOverviewDashboard(),
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

  // ═══════════════════ BUILD ═══════════════════
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
                  const SizedBox(height: 22),
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

                  // ── PAYMENT ──
                  SizedBox(height: 18),

                  _paymentSummaryBanner(selectedMode),
                  const SizedBox(height: 10),

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
                    child: _paymentSection(key: ValueKey('pay_$selectedMode')),
                  ),

                  const SizedBox(height: 26),

                  // ── TEST & SCAN ──
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
                    child: _testScanSection(key: ValueKey('ts_$selectedMode')),
                  ),
                ],
              ),
            ),
          );
        },
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
          builder: (_, __) => Transform.scale(
            scale: 0.9 + (_pulseCtrl.value * 0.35),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  hospitalPhoto ?? '',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.local_hospital, color: _gold),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        HeartbeatLoader(color: _gold),

        const SizedBox(height: 18),

        Text(
          'Preparing your dashboard...',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Fetching latest insights',
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

  //final lastToken = _g(_cData, 'today.lastTokenNumber');

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

  Widget _paymentSummaryBanner(String selectedMode) {
    final total = _g(_payData, '$selectedMode.total');
    final paid = _g(_payData, '$selectedMode.status.PAID');
    final pending = _g(_payData, '$selectedMode.status.PENDING');
    final cancel = _g(_payData, '$selectedMode.status.CANCELLED');

    final payLater = _g(_payData, '$selectedMode.status.PAYLATER');
    final cash = _g(_payData, '$selectedMode.paymentType.ManualPay');
    final online = _g(_payData, '$selectedMode.paymentType.OnlinePay');

    final int safeTotal = total == 0 ? 1 : total;
    int totalAmount = cash + online;

    double cashPct = totalAmount > 0 ? (cash / totalAmount) * 100 : 0;
    double onlinePct = totalAmount > 0 ? (online / totalAmount) * 100 : 0;

    return _staggerItem(
      index: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
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
                  "Today's Payment Summary",
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
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Payments",
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
                            tween: IntTween(begin: 0, end: total),
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

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _paymentItem(
                      label: "Cash",
                      amount: cash.toString(),
                      percentage: cashPct,
                      color: Colors.green,
                    ),
                  ),

                  /// Vertical Divider
                  // Container(width: 4, height: 60, color: Colors.grey.shade200),
                  SizedBox(width: 12),

                  Expanded(
                    child: _paymentItem(
                      label: "Online",
                      amount: online.toString(),
                      percentage: onlinePct,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Mini Stats Row (Clickable Cards with Progress)
            Row(
              children: [
                _miniStatProgressCard(
                  label: 'Paid',
                  value: paid,
                  total: safeTotal,
                  icon: Icons.person_add_alt_1_rounded,
                  color: const Color(0xFF1FAF6E),
                  onTap: () {
                    // TODO: navigate or filter
                  },
                ),
                _miniStatProgressCard(
                  label: 'Pending',
                  value: pending,
                  total: safeTotal,
                  icon: Icons.person_add_alt_1_rounded,
                  color: const Color(0xFFEC8B2C),
                  onTap: () {
                    // TODO: navigate or filter
                  },
                ),
                _miniStatProgressCard(
                  label: 'PayLater',
                  value: payLater,
                  total: safeTotal,
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF15B6C5),
                  onTap: () {},
                ),
                _miniStatProgressCard(
                  label: 'Cancel',
                  value: cancel,
                  total: safeTotal,
                  icon: Icons.emergency_rounded,
                  color: _colCancelled,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentItem({
    required String label,
    required String amount,
    required double percentage,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05), // subtle tinted background
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// Label Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// Amount (Main Focus)
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 6),

          /// Percentage Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),

          const SizedBox(height: 14),

          /// Modern Rounded Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                FractionallySizedBox(
                  widthFactor: percentage.clamp(0, 100) / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.7), color],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

              // Percentage
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

  // ═══════════════════ TEST & SCAN SECTION ═══════════════════

  Widget _paymentSection({Key? key}) {
    final isToday = selectedMode == 'today';

    final List<_Metric> cards;
    if (isToday) {
      cards = [
        _Metric(
          'Register',
          _g(_payData, 'today.type.REGISTRATIONFEE'),
          Icons.schedule_rounded, // waiting / time
          const Color(0xFFFFA726), // soft amber
        ),

        _Metric(
          'Test/Scan',
          _g(_payData, 'today.type.TESTINGFEESANDSCANNINGFEE'),
          Icons.watch_later, // success
          const Color(0xFF248AD3), // success green
        ),
        _Metric(
          'Medicine',
          _g(_payData, 'today.type.MEDICINETONICINJECTIONFEES'),
          Icons.check_circle_rounded, // success
          const Color(0xFF4CAF50), // success green
        ),
        _Metric(
          'Advanced',
          _g(_payData, 'today.type.ADVANCEFEE'),
          Icons.check_circle_rounded, // success
          const Color(0xFF4CAF50), // success green
        ),

        _Metric(
          'Daily Treatment',
          _g(_cData, 'today.type.DAILYTREATMENTFEE'),
          Icons.cancel_rounded, // cancelled
          const Color(0xFFEF5350), // red
        ),
        _Metric(
          'Discharge',
          _g(_cData, 'today.type.DISCHARGEFEE'),
          Icons.cancel_rounded, // cancelled
          const Color(0xFFEF5350), // red
        ),
      ];
    } else {
      cards = [
        _Metric(
          'Register',
          _g(_payData, 'overall.type.REGISTRATIONFEE'),
          Icons.schedule_rounded, // waiting / time
          const Color(0xFFFFA726), // soft amber
        ),

        _Metric(
          'Test/Scan',
          _g(_payData, 'overall.type.TESTINGFEESANDSCANNINGFEE'),
          Icons.watch_later, // success
          const Color(0xFF248AD3), // success green
        ),
        _Metric(
          'Medicine',
          _g(_payData, 'overall.type.MEDICINETONICINJECTIONFEES'),
          Icons.check_circle_rounded, // success
          const Color(0xFF4CAF50), // success green
        ),
        _Metric(
          'Advanced',
          _g(_payData, 'overall.type.ADVANCEFEE'),
          Icons.check_circle_rounded, // success
          const Color(0xFF4CAF50), // success green
        ),

        _Metric(
          'Daily Treatment',
          _g(_cData, 'overall.type.DAILYTREATMENTFEE'),
          Icons.cancel_rounded, // cancelled
          const Color(0xFFEF5350), // red
        ),
        _Metric(
          'Discharge',
          _g(_cData, 'overall.type.DISCHARGEFEE'),
          Icons.cancel_rounded, // cancelled
          const Color(0xFFEF5350), // red
        ),
      ];
    }

    // chart breakdown
    final Map<String, int> breakdowns = {};

    final bd = _payData[isToday ? 'today' : 'overall']?['status'];

    if (bd is Map<String, dynamic>) {
      bd.forEach((k, v) {
        if (v is int && v > 0) {
          breakdowns[k] = v;
        }
      });
    }

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          Icons.medical_services_rounded,
          isToday ? 'Payments — Today' : 'Payments — Overall',
        ),
        const SizedBox(height: 14),
        _animatedCardGrid(cards, startIndex: 1),
        if (breakdowns.isNotEmpty) ...[
          const SizedBox(height: 22),
          _staggerItem(
            index: cards.length + 1,
            child: _donutChartCard(
              title: 'Status Distribution',
              data: breakdowns,
              colorMap: _payColorMap,
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

  // ═══════════════════ TEST & SCAN SECTION ═══════════════════
  Widget _testScanSection({Key? key}) {
    final isToday = selectedMode == 'today';
    final pre = isToday ? 'today' : 'overall';

    final cards = [
      _Metric(
        'Total',
        _g(_tsData, '$pre.total'),
        Icons.assignment_rounded,
        const Color(0xFF5C6BC0),
      ),
      _Metric(
        'Pending',
        _g(_tsData, '$pre.PENDING'),
        Icons.hourglass_top_rounded,
        _colPending,
      ),
      _Metric(
        'Completed',
        _g(_tsData, '$pre.COMPLETED'),
        Icons.check_circle_rounded,
        _colCompleted,
      ),
      _Metric(
        'Cancelled',
        _g(_tsData, '$pre.CANCELLED'),
        Icons.cancel_rounded,
        _colCancelled,
      ),
      _Metric(
        'Abandoned',
        _g(_tsData, '$pre.ABANDONED'),
        Icons.person_off_rounded,
        _colAbandoned,
      ),
    ];

    final Map<String, int> chartData = {};
    final node = _tsData[pre];
    if (node is Map<String, dynamic>) {
      for (final s in ['PENDING', 'COMPLETED', 'CANCELLED', 'ABANDONED']) {
        final v = node[s];
        if (v is int && v > 0) chartData[s] = v;
      }
    }

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          Icons.biotech_rounded,
          isToday
              ? 'Testing & Scanning — Today'
              : 'Testing & Scanning — Overall',
        ),
        const SizedBox(height: 14),
        _animatedCardGrid(cards, startIndex: 8),
        if (chartData.isNotEmpty) ...[
          const SizedBox(height: 22),
          _staggerItem(
            index: 13,
            child: _donutChartCard(
              title: 'Test/Scan Distribution',
              data: chartData,
              colorMap: _tsColorMap,
            ),
          ),
          // const SizedBox(height: 16),
          // _staggerItem(
          //   index: 14,
          //   child: _barChartCard(
          //     title: 'Test/Scan Comparison',
          //     data: chartData,
          //     colorMap: _tsColorMap,
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

class LineGraphWithTooltip extends StatefulWidget {
  final List<double> values;
  final List<String>? labels;

  const LineGraphWithTooltip({super.key, required this.values, this.labels});

  @override
  State<LineGraphWithTooltip> createState() => _LineGraphWithTooltipState();
}

class _LineGraphWithTooltipState extends State<LineGraphWithTooltip> {
  int? selectedIndex;
  Offset? tooltipPosition;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final step = width / (widget.values.length - 1);
        final maxValue = widget.values.reduce((a, b) => a > b ? a : b);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (d) => _detect(d.localPosition, step, height, maxValue),
          onPanUpdate: (d) => _detect(d.localPosition, step, height, maxValue),
          onPanEnd: (_) {
            setState(() {
              selectedIndex = null;
              tooltipPosition = null;
            });
          },
          child: Stack(
            children: [
              /// GRAPH
              CustomPaint(
                size: Size(width, height),
                painter: SmoothGraphPainter(
                  values: widget.values,
                  selectedIndex: selectedIndex,
                ),
              ),

              /// TOOLTIP
              if (selectedIndex != null && tooltipPosition != null)
                Builder(
                  builder: (context) {
                    const tooltipWidth = 70;
                    const tooltipHeight = 40;

                    double left = tooltipPosition!.dx - tooltipWidth / 4;
                    double top = tooltipPosition!.dy - tooltipHeight - 4;

                    /// prevent LEFT overflow
                    if (left < 0) {
                      left = 2;
                    }

                    /// prevent RIGHT overflow
                    if (left + tooltipWidth > width) {
                      left = width - tooltipWidth + 5;
                    }

                    /// prevent TOP overflow
                    if (top < 0) {
                      top = tooltipPosition!.dy + 10;
                    }

                    return Positioned(left: left, top: top, child: _tooltip());
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _tooltip() {
    final value = widget.values[selectedIndex!];
    final label = widget.labels?[selectedIndex!] ?? "";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xff111827),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.white70),
            ),
          Text(
            value.toInt().toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _detect(Offset pos, double step, double height, double maxValue) {
    int index = (pos.dx / step).round();
    index = index.clamp(0, widget.values.length - 1);

    final value = widget.values[index];
    final y = maxValue == 0 ? height : height - (value / maxValue) * height;

    setState(() {
      selectedIndex = index;
      tooltipPosition = Offset(index * step, y);
    });
  }
}

class SmoothGraphPainter extends CustomPainter {
  final List<double> values;
  final int? selectedIndex;

  SmoothGraphPainter({required this.values, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    //final minValue = values.reduce((a, b) => a < b ? a : b);

    final width = size.width;
    final height = size.height;

    final step = width / values.length;

    /// GRID
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: .15)
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    /// CREATE POINTS
    List<Offset> points = [];

    for (int i = 0; i < values.length; i++) {
      final x = (i * step) + step / 2;

      final y = maxValue == 0
          ? height
          : height - (values[i] / maxValue) * height;

      points.add(Offset(x, y));
    }

    /// AREA PATH (for gradient)
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final cx = (p0.dx + p1.dx) / 2;

      fillPath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    fillPath
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    /// AREA GRADIENT (neutral blue)
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xff3B82F6).withValues(alpha: .25),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(fillPath, fillPaint);

    /// DRAW SEGMENT LINES
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      Color color;

      if (values[i + 1] > values[i]) {
        color = const Color(0xff22C55E); // GREEN
      } else if (values[i + 1] < values[i]) {
        color = const Color(0xffEF4444); // RED
      } else {
        color = const Color(0xff3B82F6); // BLUE
      }

      final paint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();

      final cx = (p0.dx + p1.dx) / 2;

      path.moveTo(p0.dx, p0.dy);
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);

      canvas.drawPath(path, paint);
    }

    /// DOTS
    for (int i = 0; i < points.length; i++) {
      Color color;

      if (i == 0) {
        color = const Color(0xff3B82F6);
      } else if (values[i] > values[i - 1]) {
        color = const Color(0xff22C55E);
      } else if (values[i] < values[i - 1]) {
        color = const Color(0xffEF4444);
      } else {
        color = const Color(0xff3B82F6);
      }

      canvas.drawCircle(points[i], 4, Paint()..color = color);
      canvas.drawCircle(points[i], 2, Paint()..color = Colors.white);
    }

    /// SELECTED POINT
    if (selectedIndex != null && selectedIndex! < points.length) {
      final point = points[selectedIndex!];

      canvas.drawLine(
        Offset(point.dx, 0),
        Offset(point.dx, height),
        Paint()
          ..color = Colors.grey.withValues(alpha: .35)
          ..strokeWidth = 1,
      );

      canvas.drawCircle(
        point,
        14,
        Paint()..color = const Color(0xff3B82F6).withValues(alpha: .2),
      );

      canvas.drawCircle(point, 7, Paint()..color = const Color(0xff3B82F6));
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant SmoothGraphPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.values != values;
  }
}

class HeartbeatLoader extends StatefulWidget {
  final Color color;
  const HeartbeatLoader({required this.color});

  @override
  State<HeartbeatLoader> createState() => HeartbeatLoaderState();
}

class HeartbeatLoaderState extends State<HeartbeatLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (i) {
            double height =
                8 +
                (20 *
                    (0.5 +
                        0.5 *
                            (1 - (i - (_controller.value * 6)).abs()).clamp(
                              0,
                              1,
                            )));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
