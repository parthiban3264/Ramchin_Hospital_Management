import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../Services/admin_service.dart';

import '../../../../../Services/prescription_service.dart';
import '../../../Medical/Widget/ReportCard.dart';

import '../../../Nurse/global.dart';
import '../../../Nurse/notes_edit_remove.dart';

import '../../../OutPatient/Report/ScanReportPage.dart';

import 'add_treatment_progress_dialog.dart';
import 'inpatient_status_analise.dart';

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
    super.initState();

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
  bool _expandTests = false;
  bool _expandScans = false;

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

  //static const Color _redBadge = Color(0xFFFF3B30);

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
  //
  //   for (final rx in _prescriptions) {
  //     final payment = rx['payment'] as Map<String, dynamic>? ?? {};
  //
  //     if (payment['status'] == 'PAID') {
  //       final medicines = rx['MedicineAdministration'] as List<dynamic>? ?? [];
  //
  //       for (final m in medicines) {
  //         meds.add(Map<String, dynamic>.from(m));
  //       }
  //     }
  //   }
  //
  //   return meds;
  // }

  List<Map<String, dynamic>> get _allMedicines {
    final List<Map<String, dynamic>> meds = [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final rx in _prescriptions) {
      final payment = rx['payment'] as Map<String, dynamic>? ?? {};

      if (payment['status'] != 'PAID') continue;

      final createdAtString = rx['created_at'];
      if (createdAtString == null) continue;

      try {
        final createdAt = DateTime.parse(createdAtString).toLocal();

        final prescriptionDate = DateTime(
          createdAt.year,
          createdAt.month,
          createdAt.day,
        );

        if (!prescriptionDate.isAfter(today)) {
          final medicines =
              rx['MedicineAdministration'] as List<dynamic>? ?? [];

          // ✅ Filter only PENDING medicines
          final pendingMeds = medicines.where((m) {
            return (m['status'] ?? '').toString().toUpperCase() == 'PENDING' ||
                (m['status'] ?? '').toString().toUpperCase() == 'TAKEN';
          }).toList();

          if (pendingMeds.isEmpty) continue;

          final prescriptionMedicines = rx['medicines'] as List<dynamic>? ?? [];

          // ⚠ Make sure key name matches exactly
          final prescriptionMap = {
            for (var pres in prescriptionMedicines) pres['medicine_Id']: pres,
          };

          for (final m in pendingMeds) {
            final adminMap = Map<String, dynamic>.from(m);

            final matchingPrescription =
                prescriptionMap[adminMap['medicine_id']];

            meds.add({...adminMap, "route": matchingPrescription?['route']});
          }
        }
      } catch (_) {
        continue;
      }
    }

    return meds;
  }

  List<Map<String, dynamic>> get _allPendingMedicineCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _allMedicines.where((m) {
      final status = (m['status'] ?? '').toString().toUpperCase();
      if (status != 'PENDING') return false;

      final rawDate = m['date'];
      if (rawDate == null) return false;

      final parsedDate = DateTime.tryParse(rawDate);
      if (parsedDate == null) return false;

      final medDate = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      );

      // ❌ Skip future dates
      if (medDate.isAfter(today)) return false;

      final route = (m['route'] ?? '').toString().toUpperCase();

      final isPreviousDay = medDate.isBefore(today);

      // ❌ If previous day AND route is TABLETS → skip
      if (isPreviousDay && route == 'TABLETS') {
        return false;
      }

      return true;
    }).toList();
  }

  int get pendingCount => _allPendingMedicineCount.length;

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _allMedicines.where((m) {
      if ((m['status'] ?? '').toString().toUpperCase() != 'PENDING') {
        return false;
      }

      final createdAt = m['date'];
      if (createdAt == null) return false;

      final parsed = DateTime.parse(createdAt);

      final itemDate = DateTime(parsed.year, parsed.month, parsed.day);
      // ❌ Skip future dates
      if (itemDate.isAfter(today)) return false;
      final isPreviousDay = itemDate.isBefore(today);
      final route = (m['route'] ?? '').toString().toUpperCase();
      // ❌ If previous day AND route is TABLETS → skip
      if (isPreviousDay && route == 'TABLETS') {
        return false;
      }

      return true;
    }).toList();
  }
  // ── Further split: tests vs scans ──

  bool _isScan(dynamic ts) {
    final type = (ts['type'] ?? ts['title'] ?? '').toString().toLowerCase();

    return type.contains('scan') ||
        type.contains('x-ray') ||
        type.contains('xray') ||
        type.contains('mri-scan') ||
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
    //print('mediiii $m');
    final route = (m['route'] ?? '').toString().toLowerCase();
    //print('route $route , ${m['medicine']?['category']} ');
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

  int get _completedCount =>
      _completedTestScans.length + _completedMedicines.length;

  int get _pendingCount =>
      _pendingTestScans.length +
      _groupedTodayPendingMeds.length +
      _pendingInjections.length;

  int get _totalItems => _completedCount + _pendingCount;

  // int get _totalItems =>
  //     _testAndScans.length +
  //     _allPendingMedicineCount
  //         .length;

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
    } else if (hour >= 12 && hour < 16) {
      return 'AFTERNOON';
    } else {
      return 'NIGHT';
    }
  }

  String getTimeLabel(String slot) {
    switch (slot) {
      case 'MORNING':
        return '10:00 AM';

      case 'AFTERNOON':
        return '3:00 PM';

      case 'NIGHT':
        return '10:00 PM';

      default:
        return '';
    }
  }

  List<Map<String, dynamic>> get _todayPendingMeds {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final currentSlot = getCurrentTimeSlot();

    return _pendingMeds.where((m) {
      final rawDate = m['date'];
      //print('date $rawDate');
      if (rawDate == null) return false;

      final parsedDate = DateTime.tryParse(rawDate);
      //print('parsedDate $parsedDate');
      if (parsedDate == null) return false;

      // 🔥 DO NOT use toLocal()
      final medDate = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      );

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
    //print('ss ${_testAndScans.length} ${_allPendingMedicineCount.length}');
    // print('pendingCount $pendingCount');
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

            // ..._pendingTests.map((ts) => _buildPendingTestScanCard(ts)),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_pendingTests.length > 2) {
                  setState(() {
                    _expandTests = !_expandTests;
                  });
                }
              },
              child: Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFDFE4EF), width: 1),
                ),

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      children:
                          (_expandTests
                                  ? _pendingTests
                                  : _pendingTests.take(2).toList())
                              .map((ts) => _buildPendingTestScanCard(ts))
                              .toList(),
                    ),
                  ),
                ),
              ),
            ),

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

            //..._pendingScans.map((ts) => _buildPendingTestScanCard(ts)),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_pendingScans.length > 2) {
                  setState(() {
                    _expandScans = !_expandScans;
                  });
                }
              },
              child: Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFDFE4EF), width: 1),
                ),

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: List.generate(
                        _expandScans
                            ? _pendingScans.length
                            : (_pendingScans.length > 2
                                  ? 2
                                  : _pendingScans.length),
                        (index) {
                          final ts = _pendingScans[index];

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              key: ValueKey(ts), // important for animation
                              child: _buildPendingTestScanCard(ts),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

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
                      'Treatment Progress',

                      style: TextStyle(
                        fontSize: 20,

                        fontWeight: FontWeight.w800,

                        color: _darkText,

                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Text(
                          'Milestone $_completedCount of $_totalItems',

                          style: const TextStyle(
                            fontSize: 13,
                            color: _greyText,
                          ),
                        ),
                        Spacer(),
                        if (_pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),

                            decoration: BoxDecoration(
                              color: _greenBadge,

                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: Row(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                const SizedBox(width: 2),

                                Text(
                                  '$_pendingCount remain ',

                                  style: const TextStyle(
                                    fontSize: 12,

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
                  ],
                ),
              ),

              // Remaining badge
            ],
          ),

          const SizedBox(height: 12),

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
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientAnalyticsScreen(
                    consultationId: widget.consultation['id'],
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.indigo],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "Patient Analytics Dashboard",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          /// Left Accent Line
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(width: 10),

          /// Title
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _sectionLabel,
                letterSpacing: 1.1,
              ),
            ),
          ),

          /// Modern Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withOpacity(0.25), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'item ${count.toString()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ],
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
    final selectedOptions = ts['selectedOptions'] as List<dynamic>? ?? [];
    final style = _getTestScanStyle(type.isEmpty ? title : type);
    final createdAt = ts['createdAt']?.toString() ?? '';
    final timeStr = _extractTime(createdAt);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isExpanded = false;

        return StatefulBuilder(
          builder: (context, setInnerState) {
            final visibleOptions = isExpanded
                ? selectedOptions
                : selectedOptions.take(2).toList();

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setInnerState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                style.bgColor.withOpacity(0.9),
                                style.bgColor.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            style.icon,
                            color: style.iconColor,
                            size: 24,
                          ),
                        ),

                        const SizedBox(width: 14),

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
                              if (timeStr.isNotEmpty)
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _greyText,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _greenBadge,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'COMPLETED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),

                    /// RESULTS
                    if (selectedOptions.isNotEmpty) ...[
                      const SizedBox(height: 16),

                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: _buildResultMetrics(
                          visibleOptions,
                        ), // show 2
                        secondChild: _buildResultMetrics(
                          selectedOptions,
                        ), // show all
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
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

    final timeSlot = m['time_slot'];

    final style = _getMedicineStyle(route);

    // Dispense time

    String timeStr = '';

    final dispenses = m['dispenses'] as List<dynamic>?;

    if (dispenses != null && dispenses.isNotEmpty) {
      timeStr = _extractTime(dispenses.last['dispensed_at']?.toString() ?? '');
    }

    // Dosage label

    final dosageLabel = dosage.isNotEmpty ? '${dosage}mg' : '';

    final mealLabel = afterFood ? 'AC' : 'PC';
    final sessionLabel = timeSlot;

    final subtitle = [
      dosageLabel,

      mealLabel,
      sessionLabel,
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

    final scheduleDate = ts['scheduleDate']?.toString() ?? '';
    final scheduleLabel = _getScheduleLabel(scheduleDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 4, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// Icon Container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFF9FAFB), const Color(0xFFF3F4F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(style.icon, color: const Color(0xFF6B7280), size: 26),
          ),

          const SizedBox(width: 14),

          /// Title & Schedule
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 4),
                if (scheduleLabel.isNotEmpty)
                  Text(
                    scheduleLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _greyText,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          /// Status + Arrow
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // soft amber background
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'WAITING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════

  //  PENDING — MEDICINE CARD (dashed border)

  // ═══════════════════════════════════════════════════════

  Widget _buildPendingMedicineCard(Map<String, dynamic> m) {
    final name = m['medicine_name']?.toString().trim() ?? 'Medicine';
    final dose = m['dose']?.toString() ?? '';
    final slot = m['time_slot']?.toString() ?? '';
    final timeLabel = getTimeLabel(slot);
    final count = m['count'] ?? 1;
    final status = m['status']?.toString() ?? 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// ICON
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(width: 14),

          /// TITLE + SUBTITLE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count > 1 ? '$name ×$count' : name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dose due • $timeLabel ${dose.isNotEmpty ? "($dose)" : ""}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          /// RIGHT SIDE (MODE BASED)
          if (widget.mode == 0)
            _buildStatusBadge(status)
          else
            _buildConfirmCheckbox(m),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isPending = status.toUpperCase() == "PENDING";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPending ? const Color(0xFFDC2626) : const Color(0xFF059669),
        ),
      ),
    );
  }

  bool _isChecked = false;
  bool _isLoading = false;

  Widget _buildConfirmCheckbox(Map<String, dynamic> m) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: () async {
        if (_isChecked || _isLoading) return;

        final confirm = await _showConfirmDialog();
        if (confirm != true) return;

        // ── Full-screen loading dialog ──
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const PopScope(
              canPop: false,
              child: Center(
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF4A7BF7)),
                        SizedBox(width: 16),
                        Text(
                          'Updating\u2026',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        try {
          final success = await PrescriptionService()
              .updateMedicineAdministrationStatus(id: m['id'], status: "TAKEN");

          // Dismiss loading dialog
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          if (!mounted) return;

          if (success == true) {
            setState(() => _isChecked = true);
            // Trigger silent reload on queue page (2 routes back)
            QueueRefreshNotifier.triggerRefresh();
          } else {
            _showErrorSnackBar("Failed to update status");
          }
        } catch (e) {
          if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
          if (!mounted) return;
          _showErrorSnackBar("Something went wrong");
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            // decoration: BoxDecoration(
            //   shape: BoxShape.circle,
            //   color: _isChecked ? const Color(0xFF10B981) : Colors.white,
            //   border: Border.all(
            //     color: _isChecked
            //         ? const Color(0xFF10B981)
            //         : const Color(0xFFCBD5E1),
            //     width: 1.5,
            //   ),
            // ),
            child: Icon(
              _isChecked ? Icons.check : Icons.check_box_outline_blank,
              size: 25,
              color: _isChecked ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isChecked ? "Taken" : "Confirm",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _isChecked
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Medical Icon Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF059669)],
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Confirm Medication",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Are you sure you want to mark\nthis medicine as administered?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async => {Navigator.pop(context, false)},
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Confirm",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultMetrics(List<dynamic> options) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      children: options.map<Widget>((opt) {
        final name = opt['name']?.toString() ?? '';

        final result = opt['result']?.toString() ?? '';

        final unit = opt['unit']?.toString() ?? '';

        final unitStr = (unit.isNotEmpty && unit != '-' && unit != 'N/A')
            ? unit
            : '';

        // Display '-' for empty results
        final displayResult = (result.isEmpty || result == '-') ? '-' : result;

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
                      displayResult,

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
