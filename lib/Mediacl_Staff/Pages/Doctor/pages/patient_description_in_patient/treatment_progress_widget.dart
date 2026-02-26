import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../Services/admin_service.dart';

import '../../../Medical/Widget/ReportCard.dart';

import '../../../Nurse/notes_edit_remove.dart';

import '../../../OutPatient/Report/ScanReportPage.dart';

import 'add_treatment_progress_dialog.dart';

/// ─────────────────────────────────────────────────────────────────────────────

/// Treatment Progress Widget

/// Pixel-accurate implementation matching the provided screenshot design.

/// Reads data directly from the consultation map.

/// ─────────────────────────────────────────────────────────────────────────────

class TreatmentProgressWidget extends StatefulWidget {
  final Map<String, dynamic> consultation;

  final String role;

  final int mode;

  const TreatmentProgressWidget({
    super.key,

    required this.consultation,

    required this.role,

    required this.mode,
  });

  @override
  State<TreatmentProgressWidget> createState() =>
      _TreatmentProgressWidgetState();
}

class _TreatmentProgressWidgetState extends State<TreatmentProgressWidget> {
  @override
  void initState() {
    // TODO: implement initState

    super.initState();

    _loadHospitalLogo();

    // final labId =

    //     widget.consultation['TeatingAndScanningPatient'][0]['staff_Id'] ?? '';

    //

    // loadNames(labId);

    final List testingPatients =
        widget.consultation['TeatingAndScanningPatient'] as List? ?? [];

    if (testingPatients.isNotEmpty) {
      final dynamic staffIdRaw = testingPatients[0]?['staff_Id'];

      String labId = '';

      if (staffIdRaw is String) {
        labId = staffIdRaw;
      } else if (staffIdRaw is List && staffIdRaw.isNotEmpty) {
        labId = staffIdRaw.first.toString();
      }

      if (labId.isNotEmpty) {
        loadNames(labId);
      }
    }
  }

  String _labName = '';

  String? logo;

  void _loadHospitalLogo() async {
    final prefs = await SharedPreferences.getInstance();

    logo = prefs.getString('hospitalPhoto');

    setState(() {});
  }

  Future<void> loadNames(String userId) async {
    final labProfile = await AdminService().getLabProfile(userId);

    setState(() {
      _labName = labProfile?['name'] ?? '';
    });
  }

  Map<String, String> get allTestsOptionResults {
    final Map<String, String> results = {};

    final patient = widget.consultation['Patient'];

    if (patient == null) return results;

    final testingAndScanning =
        widget.consultation['TeatingAndScanningPatient'] as List<dynamic>? ??
        [];

    for (final testGroup in testingAndScanning) {
      final selectedOptions =
          testGroup['selectedOptions'] as List<dynamic>? ?? [];

      for (final opt in selectedOptions) {
        final name = opt['name']?.toString() ?? '';

        final result = (opt['result']?.toString() ?? '').trim();

        final selectedOption = opt['selectedOption']?.toString() ?? '';

        if (selectedOption == '-' || result.isEmpty) continue;

        results[name] = result;
      }
    }

    return results;
  }

  List<Map<String, dynamic>> get allTestsReportTable {
    final List<Map<String, dynamic>> formattedResults = [];

    final patient = widget.consultation['Patient'];

    if (patient == null) return formattedResults;

    final testingAndScanning =
        widget.consultation['TeatingAndScanningPatient'] as List<dynamic>? ??
        [];

    for (final testGroup in testingAndScanning) {
      final type = testGroup['type']?.toString().toLowerCase() ?? '';

      // Only handle tests, skip scans

      if (!type.contains('test')) continue;

      final String title =
          (testGroup['title']?.toString().trim().isNotEmpty ?? false)
          ? testGroup['title'].toString()
          : '-';

      final String impression =
          (testGroup['results']?.toString().trim().isNotEmpty ?? false)
          ? testGroup['results'].toString()
          : '-';

      final selectedOptions =
          testGroup['selectedOptions'] as List<dynamic>? ?? [];

      final List<Map<String, String>> results = [];

      for (final opt in selectedOptions) {
        final name = opt['name']?.toString().trim() ?? '';

        final result = opt['result']?.toString().trim() ?? '';

        final unit = opt['unit']?.toString().trim() ?? '';

        final reference = opt['reference']?.toString().trim() ?? '';

        final selectedOption = opt['selectedOption']?.toString().trim() ?? '';

        // Skip empty results or N/A

        if (selectedOption == 'N/A' || name.isEmpty || result.isEmpty) continue;

        results.add({
          'Test': name,

          'Result': result,

          'Unit': unit.isEmpty || unit == 'N/A' ? '-' : unit,

          'Range': reference.isEmpty || reference == 'N/A' ? '-' : reference,
        });
      }

      formattedResults.add({
        'title': title,

        'impression': impression,

        'results': results,
      });
    }

    return formattedResults;
  }

  // ─── Design tokens ───

  static const Color _primaryBlue = Color(0xFF4A7BF7);

  static const Color _greenBadge = Color(0xFF34C759);

  static const Color _orangeBadge = Color(0xFFFF9500);

  static const Color _redBadge = Color(0xFFFF3B30);

  static const Color _greyText = Color(0xFF8E8E93);

  static const Color _darkText = Color(0xFF1C1C1E);

  static const Color _sectionLabel = Color(0xFF6B7280);

  // ─── Data helpers ───

  List<dynamic> get _testAndScans =>
      (widget.consultation['TeatingAndScanningPatient'] as List<dynamic>?) ??
      [];

  List<dynamic> get _prescriptions =>
      (widget.consultation['Prescription'] as List<dynamic>?) ?? [];

  // List<Map<String, dynamic>> get _allMedicines {

  //   final List<Map<String, dynamic>> meds = [];

  //   for (final rx in _prescriptions) {

  //     final isPaid = rx['payment']['status'] == 'PAID';

  //     if (rx == null && !isPaid) continue;

  //

  //     final medicines = rx['MedicineAdministration'] as List<dynamic>? ?? [];

  //     for (final m in medicines) {

  //       meds.add(Map<String, dynamic>.from(m));

  //     }

  //   }

  //   return meds;

  // }

  List<Map<String, dynamic>> get _allMedicines {
    final List<Map<String, dynamic>> meds = [];

    for (final rx in _prescriptions) {
      final payment = rx['payment'] as Map<String, dynamic>? ?? {};

      if (payment['status'] == 'PAID') {
        final medicines = rx['MedicineAdministration'] as List<dynamic>? ?? [];
        final createdAt = medicines[0]['created_at'];

        for (final m in medicines) {
          meds.add(Map<String, dynamic>.from(m));
        }
      }
    }

    return meds;
  }

  // ── Split by status ──

  List<dynamic> get _completedTestScans => _testAndScans
      .where((t) => (t['status'] ?? '').toString().toUpperCase() == 'COMPLETED')
      .toList();

  List<dynamic> get _pendingTestScans => _testAndScans
      .where((t) => (t['status'] ?? '').toString().toUpperCase() != 'COMPLETED')
      .toList();

  List<Map<String, dynamic>> get _completedMedicines => _allMedicines
      .where((m) => (m['status'] ?? '').toString().toUpperCase() == 'TAKEN')
      .toList();

  // List<Map<String, dynamic>> get _pendingMedicines => _allMedicines

  //     .where((m) => (m['status'] ?? '').toString().toUpperCase() == 'PENDING')

  //     .toList();

  List<Map<String, dynamic>> get _pendingMedicines {
    final today = DateTime.now();

    final todayStart = DateTime(today.year, today.month, today.day);

    final tomorrowStart = todayStart.add(const Duration(days: 1));

    return _allMedicines.where((m) {
      if ((m['status'] ?? '').toString().toUpperCase() != 'PENDING') {
        return false;
      }

      final createdAt = m['created_at'];
      print(' createdAt $createdAt');

      if (createdAt == null) return false;

      final date = DateTime.parse(createdAt);

      return date.isAfter(
            todayStart.subtract(const Duration(milliseconds: 1)),
          ) &&
          date.isBefore(tomorrowStart);
    }).toList();
  }

  // ── Further split: tests vs scans ──

  bool _isScan(dynamic ts) {
    final type = (ts['type'] ?? ts['title'] ?? '').toString().toLowerCase();

    return type.contains('scan') ||
        type.contains('x-ray') ||
        type.contains('xray') ||
        type.contains('mri') ||
        type.contains('ct') ||
        type.contains('ultrasound') ||
        type.contains('echo');
  }

  List<dynamic> get _completedTests =>
      _completedTestScans.where((t) => !_isScan(t)).toList();

  List<dynamic> get _completedScans =>
      _completedTestScans.where((t) => _isScan(t)).toList();

  List<dynamic> get _pendingTests =>
      _pendingTestScans.where((t) => !_isScan(t)).toList();

  List<dynamic> get _pendingScans =>
      _pendingTestScans.where((t) => _isScan(t)).toList();

  // ── Further split: medicines vs injections ──

  bool _isInjection(Map<String, dynamic> m) {
    final route = (m['route'] ?? '').toString().toLowerCase();

    final cat = (m['medicine']?['category'] ?? '').toString().toLowerCase();

    return route.contains('injections') || cat.contains('injections');
  }

  List<Map<String, dynamic>> get _completedMeds =>
      _completedMedicines.where((m) => !_isInjection(m)).toList();

  List<Map<String, dynamic>> get _completedInjections =>
      _completedMedicines.where((m) => _isInjection(m)).toList();

  List<Map<String, dynamic>> get _pendingMeds =>
      _pendingMedicines.where((m) => !_isInjection(m)).toList();

  List<Map<String, dynamic>> get _pendingInjections =>
      _pendingMedicines.where((m) => _isInjection(m)).toList();

  int get _totalItems => _testAndScans.length + _allMedicines.length;

  int get _completedCount =>
      _completedTestScans.length + _completedMedicines.length;

  int get _pendingCount => _pendingTestScans.length + _pendingMedicines.length;

  double get _completionPercent =>
      _totalItems == 0 ? 0 : _completedCount / _totalItems;

  bool get _isAuthorizedRole {
    final r = widget.role.toLowerCase();

    return r == 'doctor' || r == 'nurse' || r == 'assistant doctor';
  }

  // ─── Icon/color mapping for test types ───

  _ItemStyle _getTestScanStyle(String type) {
    final t = type.toLowerCase();

    if (t.contains('blood') || t.contains('cbc') || t.contains('rbc')) {
      return _ItemStyle(
        Icons.bloodtype_rounded,

        const Color(0xFF4A7BF7),

        const Color(0xFFE8EEFF),
      );
    }

    if (t.contains('thyroid') || t.contains('hormone')) {
      return _ItemStyle(
        Icons.monitor_heart_rounded,

        const Color(0xFF9B59B6),

        const Color(0xFFF3E8FF),
      );
    }

    if (t.contains('x-ray') || t.contains('xray')) {
      return _ItemStyle(
        Icons.image_rounded,

        const Color(0xFF3498DB),

        const Color(0xFFE3F2FD),
      );
    }

    if (t.contains('ct-scan') || t.contains('mri-scan')) {
      return _ItemStyle(
        Icons.document_scanner_rounded,

        const Color(0xFF2ECC71),

        const Color(0xFFE8F5E9),
      );
    }

    if (t.contains('ecg') || t.contains('echo')) {
      return _ItemStyle(
        Icons.favorite_rounded,

        const Color(0xFFE74C3C),

        const Color(0xFFFFEBEE),
      );
    }

    if (t.contains('urine') || t.contains('culture')) {
      return _ItemStyle(
        Icons.science_rounded,

        const Color(0xFF795548),

        const Color(0xFFEFEBE9),
      );
    }

    if (t.contains('scan')) {
      return _ItemStyle(
        Icons.document_scanner_rounded,

        const Color(0xFF607D8B),

        const Color(0xFFECEFF1),
      );
    }

    return _ItemStyle(
      Icons.biotech_rounded,

      _primaryBlue,

      const Color(0xFFE8EEFF),
    );
  }

  _ItemStyle _getMedicineStyle(String route) {
    final r = route.toLowerCase();

    if (r.contains('injections')) {
      return _ItemStyle(
        Icons.vaccines_rounded,

        const Color(0xFFE74C3C),

        const Color(0xFFFFEBEE),
      );
    }

    if (r.contains('syrups') || r.contains('tonic')) {
      return _ItemStyle(
        Icons.local_drink_rounded,

        const Color(0xFF9B59B6),

        const Color(0xFFF3E8FF),
      );
    }

    return _ItemStyle(
      Icons.medication_rounded,

      const Color(0xFFE91E63),

      const Color(0xFFFCE4EC),
    );
  }

  String getCurrentTimeSlot() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return 'MORNING';
    } else if (hour >= 12 && hour < 18) {
      return 'AFTERNOON';
    } else {
      return 'NIGHT';
    }
  }

  String getTimeLabel(String slot) {
    switch (slot) {
      case 'MORNING':
        return '9:00 AM';

      case 'AFTERNOON':
        return '1:00 PM';

      case 'NIGHT':
        return '8:00 PM';

      default:
        return '';
    }
  }

  List<Map<String, dynamic>> get _todayPendingMeds {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final currentSlot = getCurrentTimeSlot(); // ✅ MORNING / AFTERNOON / NIGHT

    return _pendingMeds.where((m) {
      final rawDate = m['date'];

      if (rawDate == null) return false;

      final parsedUtc = DateTime.tryParse(rawDate);

      if (parsedUtc == null) return false;

      final localDate = parsedUtc.toLocal();

      final medDate = DateTime(localDate.year, localDate.month, localDate.day);

      return medDate == today &&
          m['time_slot'] == currentSlot &&
          m['status'] == 'PENDING';
    }).toList();
  }

  List<Map<String, dynamic>> get _groupedTodayPendingMeds {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final m in _todayPendingMeds) {
      final name = m['medicine_name']?.toString().trim() ?? '';

      final slot = m['time_slot']?.toString() ?? '';

      final status = m['status']?.toString() ?? '';

      final date = m['date']?.toString().split(' ') ?? '';

      // Unique group key

      final key = '$name|$slot';

      if (!grouped.containsKey(key)) {
        grouped[key] = {...m, 'count': 1};
      } else {
        grouped[key]!['count'] = (grouped[key]!['count'] as int) + 1;
      }
    }

    return grouped.values.toList();
  }

  // ═══════════════════════════════════════════════════════

  //  BUILD

  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // ── 1. Progress Header Card ──
        _buildProgressHeader(),

        const SizedBox(height: 20),

        // ── 2. Completed Tasks ──
        if (_completedCount > 0) ...[
          _buildSectionLabel('COMPLETED TASKS', _completedCount, _primaryBlue),

          const SizedBox(height: 12),

          // ── Tests ──
          if (_completedTests.isNotEmpty) ...[
            _buildGroupHeader(
              Icons.biotech_rounded,

              'Tests',

              _completedTests.length,

              const Color(0xFF4A7BF7),

              'completed',
            ),

            const SizedBox(height: 8),

            ..._completedTests.map((ts) => _buildCompletedTestScanCard(ts)),

            const SizedBox(height: 8),
          ],

          // ── Scans ──
          if (_completedScans.isNotEmpty) ...[
            _buildGroupHeader(
              Icons.document_scanner_rounded,

              'Scans',

              _completedScans.length,

              const Color(0xFF607D8B),

              'completed',
            ),

            const SizedBox(height: 8),

            ..._completedScans.map((ts) => _buildCompletedTestScanCard(ts)),

            const SizedBox(height: 8),
          ],

          // ── Medicines ──
          if (_completedMeds.isNotEmpty) ...[
            _buildGroupHeader(
              Icons.medication_rounded,

              'Medicines',

              _completedMeds.length,

              const Color(0xFFE91E63),

              'completed',
            ),

            const SizedBox(height: 8),

            ..._completedMeds.map((m) => _buildCompletedMedicineCard(m)),

            const SizedBox(height: 8),
          ],

          // ── Injections ──
          if (_completedInjections.isNotEmpty) ...[
            _buildGroupHeader(
              Icons.vaccines_rounded,

              'Injections',

              _completedInjections.length,

              const Color(0xFFE74C3C),

              'completed',
            ),

            const SizedBox(height: 8),

            ..._completedInjections.map((m) => _buildCompletedMedicineCard(m)),

            const SizedBox(height: 8),
          ],

          const SizedBox(height: 12),
        ],

        // ── 3. Pending Schedule ──
        if (_pendingCount > 0) ...[
          _buildSectionLabel('PENDING SCHEDULE', _pendingCount, _orangeBadge),

          const SizedBox(height: 12),

          // ── Tests ──
          if (_pendingTests.isNotEmpty) ...[
            _buildGroupHeader(
              Icons.biotech_rounded,

              'Tests',

              _pendingTests.length,

              const Color(0xFF4A7BF7),

              'pending',
            ),

            const SizedBox(height: 8),

            ..._pendingTests.map((ts) => _buildPendingTestScanCard(ts)),

            const SizedBox(height: 8),
          ],

          // ── Scans ──
          if (_pendingScans.isNotEmpty) ...[
            _buildGroupHeader(
              Icons.document_scanner_rounded,

              'Scans',

              _pendingScans.length,

              const Color(0xFF607D8B),

              'pending',
            ),

            const SizedBox(height: 8),

            ..._pendingScans.map((ts) => _buildPendingTestScanCard(ts)),

            const SizedBox(height: 8),
          ],

          // ── Medicines ──

          // if (_pendingNonInjMeds.isNotEmpty) ...[

          //   _buildGroupHeader(

          //     Icons.medication_rounded,

          //     'Medicines',

          //     _pendingNonInjMeds.length,

          //     const Color(0xFFE91E63),

          //     'pending',

          //   ),

          //const SizedBox(height: 8),

          //..._pendingNonInjMeds.map((m) => _buildPendingMedicineCard(m)),
          if (_todayPendingMeds.isNotEmpty) ...[
            _buildGroupHeader(
              Icons.medication_rounded,

              'Medicines',

              _todayPendingMeds.length,

              const Color(0xFFE91E63),

              'pending',
            ),

            const SizedBox(height: 8),

            ..._groupedTodayPendingMeds.map(
              (m) => _buildPendingMedicineCard(m),
            ),

            const SizedBox(height: 8),
          ],

          //const SizedBox(height: 8),

          //  ],

          // ── Injections ──
          if (_pendingInjections.isNotEmpty) ...[
            _buildGroupHeader(
              Icons.vaccines_rounded,

              'Injections',

              _pendingInjections.length,

              const Color(0xFFE74C3C),

              'pending',
            ),

            const SizedBox(height: 8),

            ..._pendingInjections.map((m) => _buildPendingMedicineCard(m)),

            const SizedBox(height: 8),
          ],

          //const SizedBox(height: 6),
        ],
        // ── 4. Empty State ──
        if (_totalItems == 0) _buildEmptyState(),

        // ── 5. Add Treatment Progress ──
        if (_isAuthorizedRole) ...[
          const SizedBox(height: 8),

          _buildAddProgressButton(),
        ],

        const SizedBox(height: 8),

        _showNotes(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════

  //  1. PROGRESS HEADER CARD
  // ═══════════════════════════════════════════════════════
  Widget _buildProgressHeader() {
    final pct = _completionPercent;

    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),

            blurRadius: 20,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 64,

                height: 64,

                child: Stack(
                  alignment: Alignment.center,

                  children: [
                    SizedBox(
                      width: 64,

                      height: 64,

                      child: CircularProgressIndicator(
                        value: pct,

                        strokeWidth: 6,

                        strokeCap: StrokeCap.round,

                        backgroundColor: const Color(0xFFE5E7EB),

                        valueColor: const AlwaysStoppedAnimation(_primaryBlue),
                      ),
                    ),

                    Text(
                      '${(pct * 100).toInt()}%',

                      style: const TextStyle(
                        fontSize: 16,

                        fontWeight: FontWeight.w800,

                        color: _primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Treatment\nProgress',

                      style: TextStyle(
                        fontSize: 20,

                        fontWeight: FontWeight.w800,

                        color: _darkText,

                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Milestone $_completedCount of $_totalItems',

                      style: const TextStyle(fontSize: 13, color: _greyText),
                    ),
                  ],
                ),
              ),

              // Remaining badge
              if (_pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,

                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: _greenBadge,

                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      const Icon(
                        Icons.more_horiz,

                        color: Colors.white,

                        size: 16,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        '$_pendingCount remaining',

                        style: const TextStyle(
                          fontSize: 11,

                          fontWeight: FontWeight.w600,

                          color: Colors.white,

                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),

            child: LinearProgressIndicator(
              value: pct,

              minHeight: 10,

              backgroundColor: const Color(0xFFE5E7EB),

              valueColor: const AlwaysStoppedAnimation(_primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  SECTION LABEL  ("COMPLETED TASKS  5 items")
  // ═══════════════════════════════════════════════════════

  Widget _buildSectionLabel(String title, int count, Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),

      child: Row(
        children: [
          Text(
            title,

            style: const TextStyle(
              fontSize: 13,

              fontWeight: FontWeight.w700,

              color: _sectionLabel,

              letterSpacing: 1.2,
            ),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(8),
            ),

            child: Text(
              '$count items',

              style: TextStyle(
                fontSize: 12,

                fontWeight: FontWeight.w700,

                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openReports(String label) {
    final consultation = widget.consultation;

    final doctorName = consultation['Doctor']?['name'] ?? '_';

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.92,

          decoration: const BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),

          child: label == 'Scans'
              ? ScanReportCard(
                  scanData: consultation,

                  hospitalLogo: logo,

                  mode: 1,
                )
              : ReportCardWidget(
                  record: consultation,

                  doctorName: doctorName,

                  staffName: _labName,

                  hospitalPhotoBase64: logo ?? '',

                  optionResults: allTestsOptionResults,

                  testTable: allTestsReportTable,

                  mode: 1,

                  showButtons: false,
                ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════

  //  GROUP SUB-HEADER  (icon + title + count pill)

  // ═══════════════════════════════════════════════════════

  Widget _buildGroupHeader(
    IconData icon,

    String label,

    int count,

    Color color,

    String status,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),

      child: Row(
        children: [
          Icon(icon, size: 18, color: color),

          const SizedBox(width: 6),

          Text(
            label,

            style: TextStyle(
              fontSize: 13,

              fontWeight: FontWeight.w700,

              color: color,
            ),
          ),

          const SizedBox(width: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),

              borderRadius: BorderRadius.circular(6),
            ),

            child: Text(
              '$count',

              style: TextStyle(
                fontSize: 11,

                fontWeight: FontWeight.w700,

                color: color,
              ),
            ),
          ),

          const Spacer(),

          if ((label == 'Scans' || label == 'Tests') &&
              status == 'completed') ...[
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openReports(label),

                  label: Text(
                    'REPORTS',

                    style: TextStyle(
                      fontSize: 12,

                      fontWeight: FontWeight.w700,

                      color: _primaryBlue,
                    ),
                  ),

                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,

                    minimumSize: Size.zero,

                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                const SizedBox(width: 2),

                Icon(Icons.open_in_new, color: _primaryBlue, size: 14),

                const SizedBox(width: 6),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════

  //  COMPLETED — TEST / SCAN CARD

  // ═══════════════════════════════════════════════════════

  Widget _buildCompletedTestScanCard(dynamic ts) {
    final title = ts['title']?.toString() ?? ts['type']?.toString() ?? '—';

    final type = ts['type']?.toString() ?? '';

    final result = ts['results']?.toString() ?? '';

    final selectedOptions = ts['selectedOptions'] as List<dynamic>? ?? [];

    final style = _getTestScanStyle(type.isEmpty ? title : type);

    // Extract time

    final createdAt = ts['createdAt']?.toString() ?? '';

    final timeStr = _extractTime(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 12,

            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // Header row
          Row(
            children: [
              // Icon circle
              Container(
                width: 48,

                height: 48,

                decoration: BoxDecoration(
                  color: style.bgColor,

                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(style.icon, color: style.iconColor, size: 24),
              ),

              const SizedBox(width: 12),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      '$title  ${_getSubtitle(ts)}',

                      style: const TextStyle(
                        fontSize: 16,

                        fontWeight: FontWeight.w700,

                        color: _darkText,
                      ),
                    ),

                    // if (_getSubtitle(ts).isNotEmpty)

                    //   Text(

                    //     _getSubtitle(ts),

                    //     style: const TextStyle(fontSize: 12, color: _greyText),

                    //   ),
                  ],
                ),
              ),

              // Completed + time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,

                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,

                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: _greenBadge,

                      borderRadius: BorderRadius.circular(8),
                    ),

                    child: const Text(
                      'COMPLETED',

                      style: TextStyle(
                        fontSize: 10,

                        fontWeight: FontWeight.w800,

                        color: Colors.white,

                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  if (timeStr.isNotEmpty) ...[
                    const SizedBox(height: 4),

                    Text(
                      timeStr,

                      style: const TextStyle(fontSize: 12, color: _greyText),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Result row

          // Selected options results (metric blocks like TSH, FREE T4)
          if (selectedOptions.isNotEmpty) ...[
            const SizedBox(height: 12),

            _buildResultMetrics(selectedOptions),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════

  //  COMPLETED — MEDICINE CARD

  // ═══════════════════════════════════════════════════════

  Widget _buildCompletedMedicineCard(Map<String, dynamic> m) {
    final name = m['medicine_name']?.toString().trim() ?? 'Medicine';

    final route = m['route']?.toString() ?? '';

    final dosage = m['dose']?.toString() ?? '';

    final afterFood = m['after_food'] == true;

    final style = _getMedicineStyle(route);

    // Dispense time

    String timeStr = '';

    final dispenses = m['dispenses'] as List<dynamic>?;

    if (dispenses != null && dispenses.isNotEmpty) {
      timeStr = _extractTime(dispenses.last['dispensed_at']?.toString() ?? '');
    }

    // Dosage label

    final dosageLabel = dosage.isNotEmpty ? '${dosage}mg' : '';

    final mealLabel = afterFood ? 'After Food' : 'Before Food';

    final subtitle = [
      dosageLabel,

      mealLabel,
    ].where((s) => s.isNotEmpty).join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 12,

            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          // Icon
          Container(
            width: 48,

            height: 48,

            decoration: BoxDecoration(
              color: style.bgColor,

              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(style.icon, color: style.iconColor, size: 24),
          ),

          const SizedBox(width: 12),

          // Name + dosage
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  name,

                  style: const TextStyle(
                    fontSize: 16,

                    fontWeight: FontWeight.w700,

                    color: _darkText,
                  ),
                ),

                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,

                    style: const TextStyle(fontSize: 12, color: _greyText),
                  ),
              ],
            ),
          ),

          // Status + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              const Text(
                'Taken',

                style: TextStyle(
                  fontSize: 14,

                  fontWeight: FontWeight.w700,

                  color: _darkText,
                ),
              ),

              if (timeStr.isNotEmpty)
                Text(
                  timeStr,

                  style: const TextStyle(fontSize: 12, color: _greyText),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════

  //  PENDING — TEST / SCAN CARD (dashed border)

  // ═══════════════════════════════════════════════════════

  Widget _buildPendingTestScanCard(dynamic ts) {
    final title = ts['title']?.toString() ?? ts['type']?.toString() ?? '—';

    final type = ts['type']?.toString() ?? '';

    final style = _getTestScanStyle(type.isEmpty ? title : type);

    // Schedule info

    final scheduleDate = ts['scheduleDate']?.toString() ?? '';

    final scheduleLabel = _getScheduleLabel(scheduleDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFD1D5DB),

          style: BorderStyle.solid,
        ),
      ),

      child: Row(
        children: [
          // Icon
          Container(
            width: 48,

            height: 48,

            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),

              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(style.icon, color: const Color(0xFF9CA3AF), size: 24),
          ),

          const SizedBox(width: 12),

          // Title + schedule
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 16,

                    fontWeight: FontWeight.w700,

                    color: _darkText,
                  ),
                ),

                if (scheduleLabel.isNotEmpty)
                  Text(
                    scheduleLabel,

                    style: const TextStyle(fontSize: 12, color: _greyText),
                  ),
              ],
            ),
          ),

          // Waiting badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),

              borderRadius: BorderRadius.circular(8),

              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),

            child: const Text(
              'WAITING',

              style: TextStyle(
                fontSize: 10,

                fontWeight: FontWeight.w800,

                color: _sectionLabel,

                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(width: 6),

          const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 22),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════

  //  PENDING — MEDICINE CARD (dashed border)

  // ═══════════════════════════════════════════════════════

  // Widget _buildPendingMedicineCard(Map<String, dynamic> m) {

  //   final name = m['medicine_name']?.toString().trim() ?? 'Medicine';

  //   final route = m['route']?.toString() ?? '';

  //   final style = _getMedicineStyle(route);

  //

  //   // Try to compute next dose info

  //   final morning = m['morning'] == true;

  //   final afternoon = m['afternoon'] == true;

  //   final night = m['night'] == true;

  //   String nextDoseLabel = '';

  //   if (morning || afternoon || night) {

  //     final sessions = <String>[];

  //     if (morning) sessions.add('8 AM');

  //     if (afternoon) sessions.add('1 PM');

  //     if (night) sessions.add('9 PM');

  //     nextDoseLabel = 'Dose due • ${sessions.join(" / ")}';

  //   }

  //

  //   // Days remaining

  //   final days = m['days'];

  //   final daysNum = days is num

  //       ? days.toDouble()

  //       : double.tryParse(days?.toString() ?? '') ?? 0;

  //   final daysLabel = daysNum > 0 ? '${daysNum.ceil()} day(s) left' : '';

  //

  //   return Container(

  //     margin: const EdgeInsets.only(bottom: 12),

  //     padding: const EdgeInsets.all(16),

  //     decoration: BoxDecoration(

  //       color: Colors.white,

  //       borderRadius: BorderRadius.circular(16),

  //       border: Border.all(

  //         color: const Color(0xFFD1D5DB),

  //         style: BorderStyle.solid,

  //       ),

  //     ),

  //     child: Row(

  //       children: [

  //         // Icon

  //         Container(

  //           width: 48,

  //           height: 48,

  //           decoration: BoxDecoration(

  //             color: const Color(0xFFF3F4F6),

  //             borderRadius: BorderRadius.circular(14),

  //           ),

  //           child: Icon(style.icon, color: const Color(0xFF9CA3AF), size: 24),

  //         ),

  //         const SizedBox(width: 12),

  //         // Name + dose info

  //         Expanded(

  //           child: Column(

  //             crossAxisAlignment: CrossAxisAlignment.start,

  //             children: [

  //               Text(

  //                 name,

  //                 style: const TextStyle(

  //                   fontSize: 16,

  //                   fontWeight: FontWeight.w700,

  //                   color: _darkText,

  //                 ),

  //               ),

  //               if (nextDoseLabel.isNotEmpty)

  //                 Text(

  //                   nextDoseLabel,

  //                   style: const TextStyle(fontSize: 12, color: _greyText),

  //                 ),

  //             ],

  //           ),

  //         ),

  //         // Next badge

  //         Container(

  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

  //           decoration: BoxDecoration(

  //             color: _redBadge,

  //             borderRadius: BorderRadius.circular(8),

  //           ),

  //           child: Text(

  //             daysLabel.isNotEmpty ? daysLabel.toUpperCase() : 'PENDING',

  //             style: const TextStyle(

  //               fontSize: 10,

  //               fontWeight: FontWeight.w800,

  //               color: Colors.white,

  //               letterSpacing: 0.3,

  //             ),

  //           ),

  //         ),

  //       ],

  //     ),

  //   );

  // }

  Widget _buildPendingMedicineCard(Map<String, dynamic> m) {
    final name = m['medicine_name']?.toString().trim() ?? 'Medicine';

    final dose = m['dose']?.toString() ?? '';

    final slot = m['time_slot']?.toString() ?? '';

    final status = m['status']?.toString() ?? '';

    final timeLabel = getTimeLabel(slot);

    final count = m['count'] ?? 1;

    // Check if this is an injection
    final isInjection = _isInjection(m);
    final medicineId = m['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),

      child: Row(
        children: [
          // Icon
          Container(
            width: 48,

            height: 48,

            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),

              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(Icons.medication_outlined),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  count > 1 ? '$name ×$count' : name,

                  style: const TextStyle(
                    fontSize: 16,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                Text(
                  'Dose due • $timeLabel ($dose)',

                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Checkbox for injections or PENDING badge for regular medicines
          if (isInjection)
            Checkbox(
              value: false, // Will be managed by state
              onChanged: (bool? value) {
                if (value == true) {
                  _updateMedicineStatus(medicineId, 'TAKEN');
                }
              },
              activeColor: Colors.green,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

              decoration: BoxDecoration(
                color: Colors.red,

                borderRadius: BorderRadius.circular(8),
              ),

              child: const Text(
                'PENDING',

                style: TextStyle(
                  fontSize: 10,

                  fontWeight: FontWeight.w800,

                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  UPDATE MEDICINE STATUS
  // ═══════════════════════════════════════════════════════
  Future<void> _updateMedicineStatus(
    String medicineId,
    String newStatus,
  ) async {
    try {
      // TODO: Add API call to update medicine status
      // For now, we'll simulate the update by refreshing the widget
      debugPrint('Updating medicine $medicineId to status: $newStatus');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medicine marked as $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh the widget to reflect changes
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating medicine: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  //  RESULT METRICS (blocks like "TSH LEVEL  3.2 mIU/L")
  // ═══════════════════════════════════════════════════════

  //   final withResults = options.where((o) {

  //     final result = o['result']?.toString().trim() ?? '';

  //     return result.isNotEmpty && result != '-';

  //   }).toList();

  //

  //   if (withResults.isEmpty) return const SizedBox.shrink();

  //

  //   return Wrap(

  //     spacing: 10,

  //     runSpacing: 10,

  //     children: withResults.map<Widget>((opt) {

  //       final name = opt['name']?.toString() ?? '';

  //       final result = opt['result']?.toString() ?? '';

  //       final unit = opt['unit']?.toString() ?? '';

  //       final unitStr = (unit.isNotEmpty && unit != '-' && unit != 'N/A')

  //           ? unit

  //           : '';

  //

  //       return Container(

  //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

  //         decoration: BoxDecoration(

  //           color: const Color(0xFFF9FAFB),

  //           borderRadius: BorderRadius.circular(12),

  //         ),

  //         child: Column(

  //           crossAxisAlignment: CrossAxisAlignment.start,

  //           mainAxisSize: MainAxisSize.min,

  //           children: [

  //             Text(

  //               name.toUpperCase(),

  //               style: const TextStyle(

  //                 fontSize: 10,

  //                 fontWeight: FontWeight.w700,

  //                 color: _greyText,

  //                 letterSpacing: 0.8,

  //               ),

  //             ),

  //             const SizedBox(height: 4),

  //             Row(

  //               mainAxisSize: MainAxisSize.min,

  //               crossAxisAlignment: CrossAxisAlignment.baseline,

  //               textBaseline: TextBaseline.alphabetic,

  //               children: [

  //                 Text(

  //                   result,

  //                   style: const TextStyle(

  //                     fontSize: 22,

  //                     fontWeight: FontWeight.w800,

  //                     color: _darkText,

  //                   ),

  //                 ),

  //                 if (unitStr.isNotEmpty) ...[

  //                   const SizedBox(width: 4),

  //                   Text(

  //                     unitStr,

  //                     style: const TextStyle(fontSize: 12, color: _greyText),

  //                   ),

  //                 ],

  //               ],

  //             ),

  //           ],

  //         ),

  //       );

  //     }).toList(),

  //   );

  // }

  Widget _buildResultMetrics(List<dynamic> options) {
    final withResults = options.where((o) {
      final result = o['result']?.toString().trim() ?? '';

      return result.isNotEmpty && result != '-';
    }).toList();

    if (withResults.isEmpty) return const SizedBox.shrink();

    return Column(
      children: withResults.map<Widget>((opt) {
        final name = opt['name']?.toString() ?? '';

        final result = opt['result']?.toString() ?? '';

        final unit = opt['unit']?.toString() ?? '';

        final unitStr = (unit.isNotEmpty && unit != '-' && unit != 'N/A')
            ? unit
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),

          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),

            borderRadius: BorderRadius.circular(12),
          ),

          child: Row(
            children: [
              // ── Metric name ──
              Expanded(
                flex: 3,

                child: Text(
                  name,

                  style: const TextStyle(
                    fontSize: 13,

                    fontWeight: FontWeight.w700,

                    color: _darkText,
                  ),
                ),
              ),

              // ── Result value ──
              Expanded(
                flex: 2,

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,

                  crossAxisAlignment: CrossAxisAlignment.baseline,

                  textBaseline: TextBaseline.alphabetic,

                  children: [
                    Text(
                      result,

                      style: const TextStyle(
                        fontSize: 18,

                        fontWeight: FontWeight.w800,

                        color: _darkText,
                      ),
                    ),

                    if (unitStr.isNotEmpty) ...[
                      const SizedBox(width: 4),

                      Text(
                        unitStr,

                        style: const TextStyle(fontSize: 12, color: _greyText),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════

  //  EMPTY STATE

  // ═══════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(vertical: 36),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 12,

            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,

            size: 48,

            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 10),

          Text(
            'No treatment data yet',

            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // void _bottomOpenNotes(dynamic rawNotes) {

  //   showModalBottomSheet(

  //     context: context,

  //     isScrollControlled: true,

  //     //backgroundWhat's: Colors.transparent,

  //     builder: (_) => BottomOpenNotes(rawNotes: rawNotes),

  //   );

  // }

  // ═══════════════════════════════════════════════════════

  //  SHOW NOTES BUTTON

  // ═══════════════════════════════════════════════════════

  Widget _showNotes() {
    final List admissions = widget.consultation['Admission'] as List? ?? [];

    if (admissions.isEmpty) {
      // Handle no admission case safely

      return const Center(child: Text('No admission data available'));
    }

    final admission = admissions.first;

    final notes = admission['notes'] ?? {};

    final drNotes = admission['DrNotes'] ?? {};

    final drInstructions = admission['doctorInstructions'] ?? [];

    final admitId = admission['id'];

    // final notes = widget.consultation['Admission'][0]['notes'] ?? [];

    // final DrNotes = widget.consultation['Admission'][0]['DrNotes'] ?? [];

    // final DrInstructions =

    //     widget.consultation['Admission'][0]['doctorInstructions'] ?? [];

    // final admitId = widget.consultation['Admission'][0]['id'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2),

      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,

              isScrollControlled: true,

              //backgroundWhat's: Colors.transparent,
              builder: (_) => BottomOpenNotes(
                rawNotes: notes,

                admitId: admitId,

                mode: widget.mode,

                rawNotesKey: 'notes',
              ),
            ),

            label: Text(
              'Notes',

              style: TextStyle(
                fontSize: 14,

                fontWeight: FontWeight.w700,

                color: _primaryBlue,
              ),
            ),

            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,

              minimumSize: Size.zero,

              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          const SizedBox(width: 2),

          Icon(Icons.open_in_new, color: _primaryBlue, size: 14),

          Spacer(),

          TextButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,

              isScrollControlled: true,

              //backgroundWhat's: Colors.transparent,
              builder: (_) => BottomOpenNotes(
                rawNotes: drNotes,

                admitId: admitId,

                mode: widget.mode,

                rawNotesKey: 'drNotes',
              ),
            ),

            label: Text(
              'DR Notes',

              style: TextStyle(
                fontSize: 14,

                fontWeight: FontWeight.w700,

                color: _primaryBlue,
              ),
            ),

            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,

              minimumSize: Size.zero,

              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          const SizedBox(width: 2),

          Icon(Icons.open_in_new, color: _primaryBlue, size: 14),

          if (widget.mode == 0) ...[
            Spacer(),

            TextButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,

                isScrollControlled: true,

                //backgroundWhat's: Colors.transparent,
                builder: (_) => BottomOpenNotes(
                  rawNotes: drInstructions,

                  admitId: admitId,

                  mode: widget.mode,

                  rawNotesKey: 'drInstruction',
                ),
              ),

              label: Text(
                'Instruction',

                style: TextStyle(
                  fontSize: 14,

                  fontWeight: FontWeight.w700,

                  color: _primaryBlue,
                ),
              ),

              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,

                minimumSize: Size.zero,

                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

            const SizedBox(width: 2),

            Icon(Icons.open_in_new, color: _primaryBlue, size: 14),
          ],

          const SizedBox(width: 6),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════

  //  ADD PROGRESS BUTTON

  // ═══════════════════════════════════════════════════════

  Widget _buildAddProgressButton() {
    return SizedBox(
      width: double.infinity,

      child: ElevatedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,

            isScrollControlled: true,

            backgroundColor: Colors.transparent,

            builder: (_) => AddTreatmentProgressDialog(
              consultation: widget.consultation,

              role: widget.role,

              mode: widget.mode,

              onSubmitted: () {
                if (mounted) setState(() {});
              },
            ),
          );
        },

        icon: const Icon(Icons.add_circle_outline, size: 20),

        label: const Text(
          'Add Treatment Notes',

          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,

          foregroundColor: Colors.white,

          elevation: 0,

          padding: const EdgeInsets.symmetric(vertical: 16),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════

  //  SHOW REPORT DETAILS DIALOG

  // ═══════════════════════════════════════════════════════

  void _showReportDetails(dynamic ts) {
    final title = ts['title']?.toString() ?? ts['type']?.toString() ?? 'Report';

    final result = ts['results']?.toString() ?? 'No main result recorded';

    final selectedOptions = ts['selectedOptions'] as List<dynamic>? ?? [];

    final createdAt = ts['createdAt']?.toString() ?? '';

    final timeStr = _extractTime(createdAt);

    showDialog(
      context: context,

      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.description, color: _primaryBlue, size: 28),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          title,

                          style: const TextStyle(
                            fontSize: 18,

                            fontWeight: FontWeight.bold,

                            color: _darkText,
                          ),
                        ),

                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,

                            style: const TextStyle(
                              fontSize: 13,

                              color: _greyText,
                            ),
                          ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.close, color: _greyText),

                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),

              const Divider(height: 32),

              // Main Result
              const Text(
                'PRIMARY RESULT',

                style: TextStyle(
                  fontSize: 12,

                  fontWeight: FontWeight.bold,

                  color: _sectionLabel,

                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),

                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),

                child: Text(
                  result,

                  style: const TextStyle(
                    fontSize: 15,

                    fontWeight: FontWeight.w600,

                    color: _darkText,
                  ),
                ),
              ),

              // Detailed Metrics
              if (selectedOptions.isNotEmpty) ...[
                const SizedBox(height: 24),

                const Text(
                  'DETAILED METRICS',

                  style: TextStyle(
                    fontSize: 12,

                    fontWeight: FontWeight.bold,

                    color: _sectionLabel,

                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,

                  child: _buildResultMetrics(selectedOptions),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),

                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════

  //  UTILITIES

  // ═══════════════════════════════════════════════════════

  /// Build a subtitle from selected options

  // String _getSubtitle(dynamic ts) {

  //   final options = ts['selectedOptions'] as List<dynamic>? ?? [];

  //   if (options.isEmpty) return '';

  //   final names = options

  //       .map(

  //         (o) => o['name']?.toString() ?? o['selectedOption']?.toString() ?? '',

  //       )

  //       .where((n) => n.isNotEmpty)

  //       .take(3)

  //       .toList();

  //   if (names.isEmpty) return '';

  //   return names.join(', ');

  // }

  String _getSubtitle(dynamic ts) {
    final options = ts['selectedOptions'] as List<dynamic>? ?? [];

    final count = options.where((o) {
      final name =
          o['name']?.toString() ?? o['selectedOption']?.toString() ?? '';

      return name.isNotEmpty;
    }).length;

    if (count == 0) return '';

    if (count == 1) return '( 1 )';

    return ' ( $count )';
  }

  String _extractTime(String raw) {
    if (raw.isEmpty) return '';

    try {
      // Handle ISO format

      if (raw.contains('T')) {
        final dt = DateTime.parse(raw);

        return DateFormat('h:mm a').format(dt);
      }

      // Handle "yyyy-MM-dd hh:mm a" format

      if (raw.contains(' ')) {
        final parts = raw.split(' ');

        if (parts.length >= 3) {
          return '${parts[1]} ${parts[2]}';
        }
      }

      return raw;
    } catch (_) {
      return '';
    }
  }

  String _getScheduleLabel(String raw) {
    if (raw.isEmpty) return 'Scheduled';

    try {
      final dt = DateTime.parse(raw);

      final now = DateTime.now();

      final diff = dt.difference(now).inDays;

      if (diff == 0) return 'Scheduled for Today';

      if (diff == 1) return 'Scheduled for Tomorrow';

      if (diff < 0) return 'Overdue';

      return 'Scheduled in $diff days';
    } catch (_) {
      return 'Scheduled';
    }
  }
}

// ─────────────────────────────────────────────────────────

// Internal helper class for icon/color mapping

// ─────────────────────────────────────────────────────────

class _ItemStyle {
  final IconData icon;

  final Color iconColor;

  final Color bgColor;

  const _ItemStyle(this.icon, this.iconColor, this.bgColor);
}
