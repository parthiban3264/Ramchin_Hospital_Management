import 'package:hospitrax/Admin/Pages/Accounts/widgets/report_filter_widget.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AccountsReportPdf {
  static Future<void> generate({
    required Map<String, dynamic>? payments,
    required double expenses,
    required double income,
    required double drawingOut,
    required String hospitalName,
    required double previousBalance,
    required String hospitalPlace,
    required DateTime reportDate,
    required DateFilter reportFilter,
    required DateTime reportFromDate,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    /// ---------------- Data Selection ----------------
    final Map<String, dynamic> data;
    if (reportFilter == DateFilter.year) {
      data = payments?['year'] ?? {};
    } else if (reportFilter == DateFilter.month) {
      data = payments?['month'] ?? {};
    } else {
      // Day or Periodical (Periodical is currently handled as 'day' by backend's selectedDate)
      data = payments?['today'] ?? {};
    }

    final typeMap = data['type'] as Map<String, dynamic>? ?? {};

    // Helper to get Cash/Online from type map
    Map<String, double> getModeTotals(String key) {
      final m = typeMap[key] as Map<String, dynamic>? ?? {};
      return {
        'cash': (m['ManualPay'] ?? 0).toDouble(),
        'online': (m['OnlinePay'] ?? 0).toDouble(),
      };
    }

    Map<String, double> getFeeTotals(String key) {
      final m = data[key] as Map<String, dynamic>? ?? {};
      return {
        'cash': ((m['ManualPay'] ?? 0) as num).toDouble(),
        'online': ((m['OnlinePay'] ?? 0) as num).toDouble(),
      };
    }

    final regTotals = getFeeTotals('registerationFee');
    // Actually, looking at the provided JSON, REGISTRATIONFEE under 'type' has the breakdown.
    final double registrationCash = regTotals['cash'] ?? 0.0;
    final double registrationOnline = regTotals['online'] ?? 0.0;

    // Consultation breakdown usually comes from 'consultationDrFee'
    // final Map<String, dynamic> drFeeMap = data['consultationDrFee'] is Map
    //     ? data['consultationDrFee'] as Map<String, dynamic>
    //     : {};
    // final Map<String, Map<String, double>> doctorTotals = {};
    // drFeeMap.forEach((name, amount) {
    //   // Truncate name to fit 58mm layout
    //   final displayName = name.length > 12
    //       ? '${name.substring(0, 10)}...'
    //       : name;
    //   doctorTotals[displayName] = {
    //     'cash': (amount ?? 0).toDouble(),
    //     'online': 0.0,
    //   };
    // });

    final Map<String, dynamic> drFeeMap = data['consultationDrFee'] is Map
        ? Map<String, dynamic>.from(data['consultationDrFee'])
        : {};

    final Map<String, Map<String, double>> doctorTotals = {};

    drFeeMap.forEach((name, amount) {
      final displayName = name.length > 12
          ? '${name.substring(0, 10)}...'
          : name;

      final feeMap = Map<String, dynamic>.from(amount ?? {});

      doctorTotals[displayName] = {
        'cash': ((feeMap['ManualPay'] ?? 0) as num).toDouble(),
        'online': ((feeMap['OnlinePay'] ?? 0) as num).toDouble(),
      };
    });

    // final testScanTotals = getModeTotals('TESTINGFEESANDSCANNINGFEE');
    // final double testScanCash = testScanTotals['cash'] ?? 0.0;
    // final double testScanOnline = testScanTotals['online'] ?? 0.0;

    final testingTotals = getFeeTotals('testingAmount');
    final scanningTotals = getFeeTotals('ScanningAmount');

    final double testScanCash =
        testingTotals['cash']! + scanningTotals['cash']!;
    final double testScanOnline =
        testingTotals['online']! + scanningTotals['online']!;

    final dischargeTotals = getModeTotals('DISCHARGEFEE');
    final double dischargeCash = dischargeTotals['cash'] ?? 0.0;
    final double dischargeOnline = dischargeTotals['online'] ?? 0.0;

    final advanceTotals = getModeTotals('ADVANCEFEE');
    final double advanceCash = advanceTotals['cash'] ?? 0.0;
    final double advanceOnline = advanceTotals['online'] ?? 0.0;

    final supplementaryTotals = getModeTotals('SUPPLEMENTARYFEE');
    final double supplementaryCash = supplementaryTotals['cash'] ?? 0.0;
    final double supplementaryOnline = supplementaryTotals['online'] ?? 0.0;

    final dailyTotals = getModeTotals('DAILYTREATMENTFEE');
    final double dailyTreatmentCash = dailyTotals['cash'] ?? 0.0;
    final double dailyTreatmentOnline = dailyTotals['online'] ?? 0.0;

    final sugarTotals = getFeeTotals(
      'SUGARTESTFEE',
    ); // If backend provides this key
    final double sugarCash = sugarTotals['cash'] ?? 0.0;
    final double sugarOnline = sugarTotals['online'] ?? 0.0;

    final emergencyTotals = getFeeTotals('EMERGENCYFEE');
    final double emergencyCash = emergencyTotals['cash'] ?? 0.0;
    final double emergencyOnline = emergencyTotals['online'] ?? 0.0;

    final medicalTotals = getModeTotals('MEDICINETONICINJECTIONFEES');
    final double medicalCash = medicalTotals['cash'] ?? 0.0;
    final double medicalOnline = medicalTotals['online'] ?? 0.0;

    final double drawingOutTotal = (data['totalDrawingOut'] ?? 0).toDouble();
    final double otherIncomeTotal =
        (data['totalIncome'] ?? 0).toDouble() +
        (data['totalDrawingIn'] ?? 0).toDouble();
    final double totalExpenses = (data['totalExpense'] ?? 0).toDouble();

    final double totalCash = (data['paymentType']?['ManualPay'] ?? 0)
        .toDouble();
    final double totalOnline = (data['paymentType']?['OnlinePay'] ?? 0)
        .toDouble();

    final double balance =
        previousBalance + totalCash + otherIncomeTotal - totalExpenses;
    final double cashInHand = balance - drawingOutTotal;

    /// ---------------- PDF PAGE (58mm) ----------------
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity),
        theme: pw.ThemeData.withFont(base: font, bold: bold),
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _centerBold(hospitalName),
              _center(hospitalPlace),
              _dashDivider(),

              //_centerBold('Daily Report (${_today()})'),
              // _centerBold('Daily Report (${_formatDate(reportDate)})'),
              _centerBold(
                formatReportTitle(filter: reportFilter, from: reportFromDate),
              ),

              pw.SizedBox(height: 4),

              pw.Text(
                'Consultation Fee',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              _tripleHeader(),
              pw.SizedBox(height: 2),

              /// ---------- DOCTOR FEES ----------
              ...doctorTotals.entries.map(
                (e) => _tripleRow(e.key, e.value['cash']!, e.value['online']!),
              ),

              _dashDivider(),

              /// ---------- REGISTRATION ----------
              _tripleRow(
                'Registration Fee',
                registrationCash,
                registrationOnline,
              ),
              _tripleRow('Sugar Fee', sugarCash, sugarOnline),
              _tripleRow('Emergency Fee', emergencyCash, emergencyOnline),

              /// ---------- TEST & SCAN ----------
              _tripleRow('Test & Scan', testScanCash, testScanOnline),

              /// ---------- Discharge fee ------------------
              _tripleRow('I/P Advanced', advanceCash, advanceOnline),

              /// ---------- Discharge fee ------------------
              _tripleRow('I/P Discharge', dischargeCash, dischargeOnline),

              /// ---------- Daily Treatment fee ----------
              _tripleRow(
                'I/P Daily Tr..',
                dailyTreatmentCash,
                dailyTreatmentOnline,
              ),

              /// ---------- Supplementary fee ----------
              _tripleRow(
                'Supplementary Fee',
                supplementaryCash,
                supplementaryOnline,
              ),

              /// ---------- Medical fee ------------------
              _tripleRow('Medical/Injection', medicalCash, medicalOnline),

              /// ---------- OTHER INCOME ----------
              _dashDivider(),
              _tripleRowBold('Sub Total', totalCash, totalOnline),

              //pw.Divider(),
              _dashDivider(),
              _row('Total Income (Online)', totalOnline),
              _row('Total Income (Cash)', totalCash),
              _row('Other Income', otherIncomeTotal),
              _row('Expenses', totalExpenses),
              _dashDivider(),
              _row('Previous Balance', previousBalance),

              _dashDivider(),
              _row('Balance', balance),
              _row('Drawing Out', drawingOutTotal),
              _dashDivider(),
              pw.SizedBox(height: 2),
              _rowBold('Cash in Hand', cashInHand),
              pw.SizedBox(height: 2),
              pw.Align(
                alignment: pw.Alignment.bottomCenter,
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(top: 2),
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  // decoration: const pw.BoxDecoration(
                  //   border: pw.Border(
                  //     top: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  //   ),
                  // ),
                  child: pw.Text(
                    "Powered by Ramchin Technologies Pvt Ltd",
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey,
                      //fontWeight: pw.FontWeight.bold,
                      //letterSpacing: 0.5,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  static pw.Widget _tripleRowBold(String name, double cash, double online) {
    final total = cash + online;
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            name,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            cash.toInt().toString(),
            textAlign: pw.TextAlign.end,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            online.toInt().toString(),
            textAlign: pw.TextAlign.end,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            total.toInt().toString(),
            textAlign: pw.TextAlign.end,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // static String _formatDate(DateTime date) =>
  //     '${date.day.toString().padLeft(2, '0')}.'
  //     '${date.month.toString().padLeft(2, '0')}.'
  //     '${date.year}';
  static String formatReportTitle({
    required DateFilter filter,
    required DateTime from,
  }) {
    switch (filter) {
      case DateFilter.day:
        return 'Daily Report (${DateFormat('dd-MM-yyyy').format(from)})';

      case DateFilter.month:
        return 'Monthly Report (${DateFormat('MMM-yyyy').format(from)})';

      case DateFilter.year:
        return 'Yearly Report (${DateFormat('yyyy').format(from)})';

      case DateFilter.periodical:
        return 'Report (${DateFormat('dd-MM-yyyy').format(from)})';
    }
  }

  /// ---------------- UI HELPERS ----------------
  static pw.Widget _tripleHeader() => pw.Row(
    children: [
      pw.Expanded(child: pw.Text('')), // Name column
      pw.Expanded(
        child: pw.Text(
          'Cash',
          textAlign: pw.TextAlign.end,
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.Expanded(
        child: pw.Text(
          'Online',
          textAlign: pw.TextAlign.end,
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.Expanded(
        child: pw.Text(
          'Total',
          textAlign: pw.TextAlign.end,
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );

  static pw.Widget _tripleRow(String name, double cash, double online) {
    final total = cash + online;
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            name,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: const pw.TextStyle(fontSize: 6),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            cash.toInt().toString(),
            textAlign: pw.TextAlign.end,
            style: const pw.TextStyle(fontSize: 7),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            online.toInt().toString(),
            textAlign: pw.TextAlign.end,
            style: const pw.TextStyle(fontSize: 7),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            total.toInt().toString(),
            textAlign: pw.TextAlign.end,
            style: const pw.TextStyle(fontSize: 7),
          ),
        ),
      ],
    );
  }

  static pw.Widget _row(String t, double v) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(t, style: const pw.TextStyle(fontSize: 7)),
      pw.Text(v.toInt().toString(), style: const pw.TextStyle(fontSize: 7)),
    ],
  );

  static pw.Widget _rowBold(String t, double v) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        t,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      ),
      pw.Text(
        v.toInt().toString(),
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      ),
    ],
  );

  static pw.Widget _center(String t) =>
      pw.Center(child: pw.Text(t, style: const pw.TextStyle(fontSize: 7)));

  static pw.Widget _centerBold(String t) => pw.Center(
    child: pw.Text(
      t,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
    ),
  );

  // static String _today() =>
  //     '${DateTime.now().day.toString().padLeft(2, '0')}.'
  //     '${DateTime.now().month.toString().padLeft(2, '0')}.'
  //     '${DateTime.now().year}';

  static pw.Widget _dashDivider() => pw.LayoutBuilder(
    builder: (context, constraints) {
      final dashCount = (constraints!.maxWidth / 4).floor();
      return pw.Text('-' * dashCount, textAlign: pw.TextAlign.center);
    },
  );
}
