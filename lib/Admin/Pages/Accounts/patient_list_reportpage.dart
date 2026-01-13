import 'package:flutter/material.dart';
import 'package:hospitrax/Admin/Pages/Accounts/widgets/account_list_report_pdf.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/IncomeExpence_Service.dart';
import '../../../Services/drawer_Service.dart';
import '../../../Services/payment_service.dart';
import 'widgets/patient_list_report_pdf.dart';

enum ReportType { daily, monthly, yearly }

class PatientListReportPage extends StatefulWidget {
  const PatientListReportPage({Key? key}) : super(key: key);

  @override
  State<PatientListReportPage> createState() => _PatientListReportPageState();
}

class _PatientListReportPageState extends State<PatientListReportPage> {
  final PaymentService _paymentService = PaymentService();
  final _incexpService = IncomeExpenseService();
  final _drawerService = DrawerService();
  final Color themeColor = const Color(0xFFBF955E);

  List<Map<String, dynamic>> _allPayments = [];

  // Date selections
  int selectedDay = DateTime.now().day;
  String selectedMonth = DateFormat.MMMM().format(DateTime.now());
  int selectedYear = DateTime.now().year;
  bool _isGenerating = false;
  bool _includeAllPatientsDaily = false;
  bool _includeAllPatientsMonthly = false;
  bool _isDailyLoading = false;
  bool _isMonthlyLoading = false;
  bool _isYearlyLoading = false;
  int _currentTabIndex = 0; // <-- track selected tab

  // Hospital Info
  String hospitalName = "";
  String hospitalPlace = "";
  String hospitalPhoto = "";
  List<Map<String, dynamic>> _allExpenses = [];
  List<Map<String, dynamic>> _allDrawings = [];

  final List<String> months = DateFormat.MMMM().dateSymbols.MONTHS;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _loadPayments();
    _loadExpenses();
    _loadDrawings();
  }

  // ---------------- LOAD HOSPITAL INFO ----------------
  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    hospitalName = prefs.getString('hospitalName') ?? "Hospital";
    hospitalPlace = prefs.getString('hospitalPlace') ?? "Place";
    hospitalPhoto =
        prefs.getString('hospitalPhoto') ??
        "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    setState(() {});
  }

  Future<void> _loadExpenses() async {
    final List<dynamic> fetched = await _incexpService
        .getIncomeExpenseService();

    final List<Map<String, dynamic>> parsed = fetched.map((e) {
      final map = Map<String, dynamic>.from(e);
      map['createdAt'] = parseAppDate(map['createdAt']);
      return map;
    }).toList();

    setState(() {
      _allExpenses = parsed;
    });
  }

  Future<void> _loadDrawings() async {
    final List<dynamic> fetched = await _drawerService.getDrawers();

    final List<Map<String, dynamic>> parsed = fetched.map((d) {
      final map = Map<String, dynamic>.from(d);
      map['createdAt'] = parseAppDate(map['createdAt']);
      return map;
    }).toList();

    setState(() {
      _allDrawings = parsed;
    });
  }

  List<Map<String, dynamic>> _filterExpenses(ReportType type) {
    return _allExpenses.where((e) {
      final d = e['createdAt'] as DateTime;
      if (type == ReportType.daily) {
        return d.day == selectedDay &&
            DateFormat.MMMM().format(d) == selectedMonth &&
            d.year == selectedYear;
      }
      if (type == ReportType.monthly) {
        return DateFormat.MMMM().format(d) == selectedMonth &&
            d.year == selectedYear;
      }
      return d.year == selectedYear;
    }).toList();
  }

  List<Map<String, dynamic>> _filterDrawings(ReportType type) {
    return _allDrawings.where((d) {
      final date = d['createdAt'] as DateTime;
      if (type == ReportType.daily) {
        return date.day == selectedDay &&
            DateFormat.MMMM().format(date) == selectedMonth &&
            date.year == selectedYear;
      }
      if (type == ReportType.monthly) {
        return DateFormat.MMMM().format(date) == selectedMonth &&
            date.year == selectedYear;
      }
      return date.year == selectedYear;
    }).toList();
  }

  DateTime parseAppDate(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is DateTime) return value;

    final str = value.toString();

    try {
      // Try ISO first
      return DateTime.parse(str);
    } catch (_) {
      // Fallback to your format
      return DateFormat("yyyy-MM-dd hh:mm a").parse(str);
    }
  }

  // ---------------- LOAD PAYMENTS ----------------
  Future<void> _loadPayments() async {
    final List<dynamic> result = await _paymentService.getAllPaidShowAccounts();

    final parsed = result.map((e) => Map<String, dynamic>.from(e)).toList();

    for (var p in parsed) {
      try {
        p['createdAt'] = DateTime.parse(p['createdAt']);
      } catch (_) {
        p['createdAt'] = DateFormat("yyyy-MM-dd hh:mm a").parse(p['createdAt']);
      }
    }

    setState(() {
      _allPayments = parsed;
    });
  }

  // ---------------- FILTER PAYMENTS ----------------
  List<Map<String, dynamic>> _filterPayments(ReportType type) {
    return _allPayments.where((p) {
      final DateTime d = p['createdAt'];

      if (type == ReportType.daily) {
        return d.day == selectedDay &&
            DateFormat.MMMM().format(d) == selectedMonth &&
            d.year == selectedYear;
      }

      if (type == ReportType.monthly) {
        return DateFormat.MMMM().format(d) == selectedMonth &&
            d.year == selectedYear;
      }

      return d.year == selectedYear;
    }).toList();
  }

  // ---------------- GENERATE PDF ----------------
  // ---------------- UPDATE _generateReport ----------------
  // Future<void> _generateReport(
  //   ReportType type,
  //   bool includeAll,
  //   VoidCallback setLoading, {
  //   required int tabIndex, // 0 = Account List, 1 = Patient List
  // }) async {
  //   setLoading();
  //
  //   final filtered = _filterPayments(type);
  //
  //   if (filtered.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("No data found for selected period")),
  //     );
  //     setLoading();
  //     return;
  //   }
  //
  //   double total = 0;
  //   for (var p in filtered) total += (p['amount'] ?? 0).toDouble();
  //
  //   // Different PDF generation based on tab
  //   if (tabIndex == 0) {
  //     // Account List PDF
  //     await PatientListReportPdf.generate(
  //       payments: filtered,
  //       total: total,
  //       hospitalName: hospitalName,
  //       hospitalPlace: hospitalPlace,
  //       hospitalPhoto: hospitalPhoto,
  //       includeAll: includeAll,
  //       //reportType: "Account List", // optional
  //     );
  //   } else {
  //     // Patient List PDF
  //     await PatientListReportPdf.generate(
  //       payments: filtered,
  //       total: total,
  //       hospitalName: hospitalName,
  //       hospitalPlace: hospitalPlace,
  //       hospitalPhoto: hospitalPhoto,
  //       includeAll: includeAll,
  //       //reportType: "Patient List", // optional
  //     );
  //   }
  //
  //   setLoading();
  // }
  double _calculatePreviousBalance(ReportType type) {
    DateTime cutoff;

    if (type == ReportType.daily) {
      cutoff = DateTime(
        selectedYear,
        DateFormat.MMMM().parse(selectedMonth).month,
        selectedDay,
      ).subtract(const Duration(days: 1));
    } else if (type == ReportType.monthly) {
      final monthIndex = DateFormat.MMMM().parse(selectedMonth).month;
      cutoff = DateTime(
        selectedYear,
        monthIndex,
        1,
      ).subtract(const Duration(days: 1));
    } else {
      // yearly
      cutoff = DateTime(selectedYear, 1, 1).subtract(const Duration(days: 1));
    }

    double income = 0;
    double expense = 0;
    double drawingIn = 0;
    double drawingOut = 0;

    // -------- PAYMENTS (INCOME) --------
    for (final p in _allPayments) {
      final d = p['createdAt'] as DateTime;
      if (!d.isAfter(cutoff)) {
        income += (p['amount'] ?? 0).toDouble();
      }
    }

    // -------- EXPENSES / INCOME --------
    for (final e in _allExpenses) {
      final d = e['createdAt'] as DateTime;
      if (!d.isAfter(cutoff)) {
        final type = (e['type'] ?? '').toString().toUpperCase();
        if (type == 'INCOME') {
          income += (e['amount'] ?? 0).toDouble();
        } else if (type == 'EXPENSE') {
          expense += (e['amount'] ?? 0).toDouble();
        }
      }
    }

    // -------- DRAWINGS --------
    for (final d in _allDrawings) {
      final date = d['createdAt'] as DateTime;
      if (!date.isAfter(cutoff)) {
        final type = (d['type'] ?? '').toString().toUpperCase();
        if (type == 'IN') {
          drawingIn += (d['amount'] ?? 0).toDouble();
        } else if (type == 'OUT') {
          drawingOut += (d['amount'] ?? 0).toDouble();
        }
      }
    }

    return income - expense + drawingIn - drawingOut;
  }

  Future<void> _generateReport(
    ReportType type,
    bool includeAll,
    VoidCallback setLoading, {
    required int tabIndex, // 0 = Account List, 1 = Patient List
  }) async {
    setLoading();

    final filteredPayments = _filterPayments(type);

    if (tabIndex == 0) {
      // Account List = combine payments + income/expense + drawings
      final filteredExpenses = _filterExpenses(type);
      final filteredDrawings = _filterDrawings(type);

      double totalPayments = filteredPayments.fold(
        0.0,
        (sum, p) => sum + (p['amount'] ?? 0).toDouble(),
      );
      double totalExpenses = filteredExpenses.fold(
        0.0,
        (sum, e) => sum + (e['amount'] ?? 0).toDouble(),
      );
      double totalDrawings = filteredDrawings.fold(
        0.0,
        (sum, d) => sum + (d['amount'] ?? 0).toDouble(),
      );
      final previousBalance = _calculatePreviousBalance(type);
      await AccountListReportPdf.generate(
        payments: filteredPayments,
        expenses: filteredExpenses,
        drawings: filteredDrawings,

        total: totalPayments,
        totalExpenses: totalExpenses,
        totalDrawings: totalDrawings,

        hospitalName: hospitalName,
        hospitalPlace: hospitalPlace,
        hospitalPhoto: hospitalPhoto,

        //includeAll: includeAll,
        previousBalance: previousBalance,
        reportType: type,
      );
    } else {
      // Patient List PDF only uses payments
      double total = filteredPayments.fold(
        0.0,
        (sum, p) => sum + (p['amount'] ?? 0).toDouble(),
      );

      await PatientListReportPdf.generate(
        payments: filteredPayments,
        total: total,
        hospitalName: hospitalName,
        hospitalPlace: hospitalPlace,
        hospitalPhoto: hospitalPhoto,
        includeAll: includeAll,
        //reportType: "Patient List"
      );
    }

    setLoading();
  }

  // ---------------- PICKERS ----------------
  void _pickDaily() {
    int tempDay = selectedDay;
    String tempMonth = selectedMonth;

    showDialog(
      context: context,
      builder: (_) => _pickerDialog(
        title: "Select Day & Month",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dayDropdown(tempDay, (v) => tempDay = v),
            _monthDropdown(tempMonth, (v) => tempMonth = v),
          ],
        ),
        onOk: () {
          setState(() {
            selectedDay = tempDay;
            selectedMonth = tempMonth;
          });
        },
      ),
    );
  }

  void _pickMonthly() {
    String tempMonth = selectedMonth;
    int tempYear = selectedYear;

    showDialog(
      context: context,
      builder: (_) => _pickerDialog(
        title: "Select Month & Year",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _monthDropdown(tempMonth, (v) => tempMonth = v),
            const SizedBox(height: 12),
            _yearDropdown(tempYear, (v) => tempYear = v),
          ],
        ),
        onOk: () {
          setState(() {
            selectedMonth = tempMonth;
            selectedYear = tempYear;
          });
        },
      ),
    );
  }

  void _pickYearly() {
    int tempYear = selectedYear;

    showDialog(
      context: context,
      builder: (_) => _pickerDialog(
        title: "Select Year",
        content: _yearDropdown(tempYear, (v) => tempYear = v),
        onOk: () => setState(() => selectedYear = tempYear),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: _buildAppBar(),
      body: _buildTabBody(), // <-- build content based on selected tab
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        selectedItemColor: themeColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentTabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: "Account List",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Patient List",
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _reportCard(
            title: "DAILY REPORT",
            subtitle: "Select day & month",
            value: "$selectedDay $selectedMonth",
            showToggle: _currentTabIndex == 1 ? true : false,
            toggleValue: _includeAllPatientsDaily,
            onToggleChanged: (v) =>
                setState(() => _includeAllPatientsDaily = v),
            isLoading: _isDailyLoading,
            onPick: _pickDaily,
            onGenerate: (includeAll) async {
              await _generateReport(
                ReportType.daily,
                includeAll,
                () => setState(() => _isDailyLoading = !_isDailyLoading),
                tabIndex: _currentTabIndex, // <-- pass tab index
              );
            },
          ),
          _reportCard(
            title: "MONTHLY REPORT",
            subtitle: "Select Mon & year",
            value: "$selectedMonth $selectedYear",
            showToggle: _currentTabIndex == 1 ? true : false,
            toggleValue: _includeAllPatientsMonthly,
            isLoading: _isMonthlyLoading,
            onToggleChanged: (v) =>
                setState(() => _includeAllPatientsMonthly = v),
            onPick: _pickMonthly,
            onGenerate: (includeAll) async {
              await _generateReport(
                ReportType.monthly,
                includeAll,
                () => setState(() => _isMonthlyLoading = !_isMonthlyLoading),
                tabIndex: _currentTabIndex,
              );
            },
          ),
          _reportCard(
            title: "YEARLY REPORT",
            subtitle: "Select Year",
            value: "$selectedYear",
            showToggle: false,
            onPick: _pickYearly,
            isLoading: _isYearlyLoading,
            onGenerate: (includeAll) async {
              await _generateReport(
                ReportType.yearly,
                false,
                () => setState(() => _isYearlyLoading = !_isYearlyLoading),
                tabIndex: _currentTabIndex,
              );
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFBF955E),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
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
                const Text(
                  " List Report ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ReportType typeFromTitle(String title) {
    switch (title.toUpperCase()) {
      case "DAILY REPORT":
        return ReportType.daily;
      case "MONTHLY REPORT":
        return ReportType.monthly;
      case "YEARLY REPORT":
        return ReportType.yearly;
      default:
        return ReportType.daily;
    }
  }

  // ---------------- UPDATE _reportCard ----------------
  Widget _reportCard({
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onPick,
    required Future<void> Function(bool includeAll) onGenerate,
    bool isLoading = false,
    bool showToggle = false,
    bool toggleValue = false,
    Function(bool)? onToggleChanged,
  }) {
    final bool isDisabled = value.trim().isEmpty || isLoading;
    final filteredDataEmpty = _filterPayments(typeFromTitle(title)).isEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- HEADER ----------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    Spacer(),
                    // ---------- TOGGLE BUTTON ----------
                    if (showToggle)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Patients List",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.scale(
                            scale:
                                0.8, // <--- adjust this to make it smaller (0.8 = 80% of default)
                            child: Switch(
                              value: toggleValue,
                              onChanged: (v) => onToggleChanged?.call(v),
                              activeColor: themeColor,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (showToggle == false) const SizedBox(height: 6),
                const SizedBox(height: 6),

                // ---------- DATE PICKER ----------
                InkWell(
                  onTap: isLoading ? null : onPick,
                  borderRadius: BorderRadius.circular(16),
                  child: Opacity(
                    opacity: isLoading ? 0.6 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            value.isEmpty ? "Select date" : value,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: value.isEmpty ? Colors.grey : themeColor,
                            ),
                          ),
                          Icon(Icons.calendar_month_rounded, color: themeColor),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ---------- GENERATE BUTTON ----------
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: filteredDataEmpty || isLoading
                        ? null
                        : () async {
                            await onGenerate(toggleValue);
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            filteredDataEmpty
                                ? "No data to generate"
                                : "Generate Report",
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

  // ---------------- PICKER HELPERS ----------------
  Widget _pickerDialog({
    required String title,
    required Widget content,
    required VoidCallback onOk,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---------- HEADER ----------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor, themeColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // ---------- BODY ----------
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: content,
                ),

                const SizedBox(height: 22),

                // ---------- ACTION BUTTONS ----------
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeColor,
                          side: BorderSide(color: themeColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          onOk();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Apply",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthDropdown(String value, Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(labelText: "Month"),
      items: months
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }

  Widget _dayDropdown(int value, Function(int) onChanged) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: const InputDecoration(labelText: "Day"),
      items: List.generate(
        31,
        (i) => DropdownMenuItem(value: i + 1, child: Text("${i + 1}")),
      ),
      onChanged: (v) => onChanged(v!),
    );
  }

  Widget _yearDropdown(int value, Function(int) onChanged) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: const InputDecoration(labelText: "Year"),
      items: List.generate(
        10,
        (i) => DropdownMenuItem(
          value: DateTime.now().year - i,
          child: Text("${DateTime.now().year - i}"),
        ),
      ),
      onChanged: (v) => onChanged(v!),
    );
  }
}
