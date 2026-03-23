import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hospitrax/Admin/Pages/Accounts/widgets/accounts_report_pdf.dart';
import 'package:hospitrax/Admin/Pages/Accounts/widgets/report_filter_widget.dart';
import 'package:hospitrax/Services/payment_service.dart';

class AccountsReport extends StatefulWidget {
  const AccountsReport({super.key});

  @override
  State<AccountsReport> createState() => _AccountsReportState();
}

class _AccountsReportState extends State<AccountsReport> {
  final _paymentService = PaymentService();

  Map<String, dynamic>? _backendData;

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  DateTime? _reportFromDate;
  DateTime? reportToDate;
  DateFilter? _currentFilter;
  DateTime _lastSelectedDate = DateTime.now();

  bool _isGeneratingPdf = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _initLoad();
  }

  Future<void> _initLoad() async {
    if (_currentFilter == null) {
      // First time load: default to Today
      await _applyReportFilter(
        reportType: DateFilter.day,
        selectedDate: DateTime.now(),
      );
    } else {
      // Refresh current filter
      await _applyReportFilter(
        reportType: _currentFilter!,
        selectedDate: _lastSelectedDate,
      );
    }
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hospitalName = prefs.getString('hospitalName') ?? "Unknown Hospital";
      hospitalPlace = prefs.getString('hospitalPlace') ?? "Unknown Place";
      hospitalPhoto =
          prefs.getString('hospitalPhoto') ??
          "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    });
  }

  Future<void> _applyReportFilter({
    required DateFilter reportType,
    required DateTime selectedDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    late DateTime from;
    late DateTime to;

    switch (reportType) {
      case DateFilter.day:
        from = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
        to = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          23,
          59,
          59,
        );
        break;
      case DateFilter.month:
        from = DateTime(selectedDate.year, selectedDate.month, 1);
        to = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
        break;
      case DateFilter.year:
        from = DateTime(selectedDate.year, 1, 1);
        to = DateTime(selectedDate.year, 12, 31, 23, 59, 59);
        break;
      case DateFilter.periodical:
        if (fromDate == null || toDate == null) return;
        from = fromDate;
        to = toDate;
        break;
    }

    setState(() {
      _currentFilter = reportType;
      _lastSelectedDate = selectedDate;
      _reportFromDate = from;
      reportToDate = to;
      _isLoading = true;
    });

    try {
      String? dayParam;
      int? monthParam;
      int? yearParam;
      String? fromDate;
      String? toDate;

      if (reportType == DateFilter.day) {
        dayParam =
            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      } else if (reportType == DateFilter.month) {
        monthParam = selectedDate.month;
        yearParam = selectedDate.year;
      } else if (reportType == DateFilter.year) {
        yearParam = selectedDate.year;
      } else if (reportType == DateFilter.periodical) {
        fromDate =
            "${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}";
        toDate =
            "${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}";
      }

      final result = await _paymentService.getAllPaidAccountsFilterData(
        day: dayParam,
        month: monthParam,
        year: yearParam,
        fromDate: fromDate,
        toDate: toDate,
      );
      if (mounted) {
        setState(() {
          _backendData = result;
        });
      }
    } catch (e) {
      debugPrint("Error fetching account report filtered data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic>? _getCurrentDataMap() {
    if (_backendData == null) return null;

    if (_currentFilter == DateFilter.day) {
      return _backendData!['today'];
    } else if (_currentFilter == DateFilter.month) {
      return _backendData!['month'];
    } else if (_currentFilter == DateFilter.year) {
      return _backendData!['year'];
    } else if (_currentFilter == DateFilter.periodical) {
      // Backend does not natively supply a periodical map right now. Default to today or handle appropriately.
      // Assuming user agreed Periodical isn't fully supported yet in agg API, fallback to today.
      return _backendData!['today'];
    }
    return null;
  }

  String formatAmount(double value) {
    if (value >= 10000000) return "${(value / 10000000).toStringAsFixed(1)}Cr";
    if (value >= 100000) return "${(value / 100000).toStringAsFixed(1)}L";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}K";
    return value.toStringAsFixed(1);
  }

  Future<void> _generatePdf() async {
    final data = _getCurrentDataMap();
    if (data == null || _isGeneratingPdf) return;

    try {
      setState(() => _isGeneratingPdf = true);

      DateTime reportDate;
      if (_currentFilter == DateFilter.day) {
        reportDate = _reportFromDate!;
      } else if (_currentFilter == DateFilter.month) {
        reportDate = _reportFromDate!;
      } else if (_currentFilter == DateFilter.year) {
        reportDate = _reportFromDate!;
      } else {
        reportDate = _reportFromDate!;
      }

      final previousBalance = (_backendData!['previousAmount'] ?? 0).toDouble();
      //debugPrint('previousBalance $previousBalance');

      // AccountsReportPdf might need adapting depending on what parameter it takes. If it takes `payments`, you might need to supply a dummy list, or adapt AccountsReportPdf independently.
      // Note: If AccountsReportPdf requires _filteredPayments, you must change that widget as well.
      // For now passing empty list, as totals are precalculated.
      await AccountsReportPdf.generate(
        payments: _backendData,
        hospitalName: hospitalName ?? "Unknown Hospital",
        hospitalPlace: hospitalPlace ?? "",
        income:
            (data['totalIncome'] ?? 0).toDouble() +
            (data['totalDrawingIn'] ?? 0).toDouble(),
        expenses: (data['totalExpense'] ?? 0).toDouble(),
        drawingOut: (data['totalDrawingOut'] ?? 0).toDouble(),
        previousBalance: previousBalance,
        reportDate: reportDate,
        reportFilter: _currentFilter!,
        reportFromDate: _reportFromDate!,
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Widget _fullRowCard(String title, double amount, {Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            "₹ ${formatAmount(amount)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _backendData == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = _getCurrentDataMap();
    bool hasData = data != null;

    final double grandTotal = data != null
        ? (data['totalAmount'] ?? 0).toDouble()
        : 0.0;

    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return double.tryParse(value.toString()) ?? 0.0;
    }

    double sumFee(Map? fee) {
      if (fee == null) return 0.0;

      return toDouble(fee['ManualPay']) + toDouble(fee['OnlinePay']);
    }

    final regFee = sumFee(data?['registerationFee']);
    final consultationFee = sumFee(data?['consultationFee']);
    final sugarFee = sumFee(data?['sugarTestFee']);
    final emergencyFee = sumFee(data?['emergencyFee']);

    // final double regFee = data != null
    //     ? (data['registerationFee'] ?? 0).toDouble()
    //     : 0.0;
    // final double consultationFee = data != null
    //     ? (data['consultationFee'] ?? 0).toDouble()
    //     : 0.0;
    // final double sugarFee = data != null
    //     ? (data['sugarTestFee'] ?? 0).toDouble()
    //     : 0.0;
    // final double emergencyFee = data != null
    //     ? (data['emergencyFee'] ?? 0).toDouble()
    //     : 0.0;
    final double dischargeFee = data != null
        ? ((data['type']?['DISCHARGEFEE']?['ManualPay'] ?? 0) +
                  (data['type']?['DISCHARGEFEE']?['OnlinePay'] ?? 0))
              .toDouble()
        : 0.0;
    final double advanceFee = data != null
        ? ((data['type']?['ADVANCEFEE']?['ManualPay'] ?? 0) +
                  (data['type']?['ADVANCEFEE']?['OnlinePay'] ?? 0))
              .toDouble()
        : 0.0;
    final double dailyTreatmentFee = data != null
        ? ((data['type']?['DAILYTREATMENTFEE']?['ManualPay'] ?? 0) +
                  (data['type']?['DAILYTREATMENTFEE']?['OnlinePay'] ?? 0))
              .toDouble()
        : 0.0;

    // final double testFee = data != null
    //     ? (data['testingAmount'] ?? 0).toDouble()
    //     : 0.0;
    // final double scanFee = data != null
    //     ? (data['ScanningAmount'] ?? 0).toDouble()
    //     : 0.0;

    final testFee = sumFee(data?['testingAmount']);
    final scanFee = sumFee(data?['ScanningAmount']);

    final double cashIncome = data != null
        ? (data['paymentType']?['ManualPay'] ?? 0).toDouble()
        : 0.0;
    final double onlineIncome = data != null
        ? (data['paymentType']?['OnlinePay'] ?? 0).toDouble()
        : 0.0;
    final double expenses = data != null
        ? (data['totalExpense'] ?? 0).toDouble()
        : 0.0;
    final double balance = cashIncome - expenses;
    final double drawingOut = data != null
        ? (data['totalDrawingOut'] ?? 0).toDouble()
        : 0.0;
    final double otherIncome = data != null
        ? (data['totalIncome'] ?? 0).toDouble() +
              (data['totalDrawingIn'] ?? 0).toDouble()
        : 0.0;
    final double cashInHand = balance - drawingOut;

    final double medicalFee = data != null
        ? ((data['type']?['MEDICINETONICINJECTIONFEES']?['ManualPay'] ?? 0) +
                  (data['type']?['MEDICINETONICINJECTIONFEES']?['OnlinePay'] ??
                      0))
              .toDouble()
        : 0.0;

    final Map<String, dynamic> doctorFeeTotals = data != null
        ? (data['consultationDrFee'] ?? {})
        : {};

    double getTotal(dynamic value) {
      if (value is Map) {
        return ((value['ManualPay'] ?? 0) as num).toDouble() +
            ((value['OnlinePay'] ?? 0) as num).toDouble();
      }
      return (value ?? 0).toDouble();
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Colors.orange,
                  minHeight: 2,
                ),
              ),
            ReportFilterWidget(onApply: _applyReportFilter),
            const SizedBox(height: 20),

            // ---------------------Generate Pdf ----------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: hasData && !_isGeneratingPdf ? _generatePdf : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 16,
                    ),
                    backgroundColor: hasData
                        ? Colors.green
                        : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text(
                    "Generate PDF",
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ---------------- GRAND TOTAL ----------------
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Grand Total",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₹ ${formatAmount(grandTotal)}",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------------- REGISTRATION GROUP ----------------
            _buildGroupCard(
              title: "Registration & Consultation",
              children: [
                _fullRowCard(
                  "Registration Fee",
                  regFee,
                  color: Colors.blue.shade50,
                ),
                _fullRowCard(
                  "Consultation Fee",
                  consultationFee,
                  color: Colors.purple.shade50,
                ),
                _fullRowCard(
                  "Sugar Test Fee",
                  sugarFee,
                  color: Colors.green.shade50,
                ),
                _fullRowCard(
                  "Emergency Fee",
                  emergencyFee,
                  color: Colors.red.shade50,
                ),
                _fullRowCard(
                  "I/P Discharge Fee",
                  dischargeFee,
                  color: Colors.blue.shade50,
                ),
                _fullRowCard(
                  "I/P Advanced Fee",
                  advanceFee,
                  color: Colors.blue.shade50,
                ),
                _fullRowCard(
                  "I/P Daily Treatment Fee",
                  dailyTreatmentFee,
                  color: Colors.blue.shade50,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ---------------- TEST & SCAN GROUP ----------------
            _buildGroupCard(
              title: "Test & Scan Fees",
              children: [
                _fullRowCard("Test Fee", testFee, color: Colors.teal.shade50),
                _fullRowCard("Scan Fee", scanFee, color: Colors.cyan.shade50),
              ],
            ),

            const SizedBox(height: 16),
            _buildGroupCard(
              title: "Cash Summary",
              children: [
                _fullRowCard(
                  "Total Cash Income",
                  cashIncome,
                  color: Colors.green.shade50,
                ),
                _fullRowCard(
                  "Total Online Income",
                  onlineIncome,
                  color: Colors.green.shade50,
                ),
                _fullRowCard("Expenses", expenses, color: Colors.red.shade50),
                _fullRowCard(
                  "Other Income",
                  otherIncome,
                  color: Colors.yellow.shade50,
                ),
                _fullRowCard("Balance", balance, color: Colors.blue.shade50),
                _fullRowCard(
                  "Drawing Out",
                  drawingOut,
                  color: Colors.orange.shade50,
                ),
                _fullRowCard(
                  "Cash in Hand",
                  cashInHand,
                  color: Colors.purple.shade50,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---------------- MEDICAL GROUP ----------------
            _buildGroupCard(
              title: "Medical / Injection / Tonic",
              children: [
                _fullRowCard(
                  "Medical / Injection / Tonic",
                  medicalFee,
                  color: Colors.orange.shade50,
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              "Doctor-wise Consultation Fees",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ---------------- DOCTOR WISE SCROLLABLE ----------------
            doctorFeeTotals.isEmpty
                ? const Text("No doctor fees found.")
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: doctorFeeTotals.entries.map((e) {
                        return Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "₹ ${formatAmount(getTotal(e.value))}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPER: GROUP CARD ----------------
  Widget _buildGroupCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
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
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
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
                  " Accounts Report ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _isLoading ? null : _initLoad,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
