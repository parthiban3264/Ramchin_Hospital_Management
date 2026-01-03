import 'package:hospitrax/Admin/Pages/Accounts/widgets/report_filter_widget.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AccountsReportPdf {
  static Future<void> generate({
    required List<dynamic> payments,
    required double expenses,
    required double income,
    required double drawingOut,
    required String hospitalName,
    required String hospitalPlace,
    required DateTime reportDate,
    required DateFilter reportFilter,
    required DateTime reportFromDate,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    /// ---------------- Totals ----------------
    final Map<String, Map<String, double>> doctorTotals = {};
    double registrationCash = 0, registrationOnline = 0;
    double testScanCash = 0, testScanOnline = 0;
    double otherIncomeCash = 0;
    double sugarCash = 0, sugarOnline = 0;
    double emergencyCash = 0, emergencyOnline = 0;

    for (final p in payments) {
      final type = (p['type'] ?? '').toString().toUpperCase();
      final mode = (p['paymentType'] ?? '').toString().toUpperCase();
      final isCash = mode == 'MANUALPAY';
      final isOnline = mode == 'ONLINEPAY';

      /// ---------- REGISTRATION + CONSULTATION ----------
      if (type == 'REGISTRATIONFEE' && p['Consultation'] != null) {
        final c = p['Consultation'];

        final regFee = (c['registrationFee'] ?? 0).toDouble();
        final consultFee = (c['consultationFee'] ?? 0).toDouble();
        final sugarFee = (c['sugarTestFee'] ?? 0).toDouble();
        final emergencyFee = (c['emergencyFee'] ?? 0).toDouble();

        if (isCash) registrationCash += regFee;
        if (isOnline) registrationOnline += regFee;

        if (consultFee > 0) {
          final doctorName = _doctorName(p);
          doctorTotals.putIfAbsent(doctorName, () => {'cash': 0, 'online': 0});

          if (isCash) {
            doctorTotals[doctorName]!['cash'] =
                doctorTotals[doctorName]!['cash']! + consultFee;
          }

          if (isOnline) {
            doctorTotals[doctorName]!['online'] =
                doctorTotals[doctorName]!['online']! + consultFee;
          }
        }
        // Sugar Test Fee
        if (sugarFee > 0) {
          if (isCash) sugarCash += sugarFee;
          if (isOnline) sugarOnline += sugarFee;
        }

        // Emergency Fee
        if (emergencyFee > 0) {
          if (isCash) emergencyCash += emergencyFee;
          if (isOnline) emergencyOnline += emergencyFee;
        }
      }

      /// ---------- TEST & SCAN ----------
      if (type == 'TESTINGFEESANDSCANNINGFEE') {
        for (final e in p['TestingAndScanningPatients'] ?? []) {
          final amt = (e['amount'] ?? 0).toDouble();
          if (isCash) testScanCash += amt;
          if (isOnline) testScanOnline += amt;
        }
      }
    }

    /// ---------------- CALCULATIONS ----------------
    double doctorCash = 0, doctorOnline = 0;
    doctorTotals.values.forEach((v) {
      doctorCash += v['cash']!;
      doctorOnline += v['online']!;
    });
    final totalCash =
        registrationCash +
        doctorCash +
        testScanCash +
        sugarCash +
        emergencyCash +
        otherIncomeCash;

    final totalOnline =
        registrationOnline +
        doctorOnline +
        testScanOnline +
        sugarOnline +
        emergencyOnline;

    final balance = totalCash + income - expenses;
    final cashInHand = balance - drawingOut;

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
              pw.Divider(),

              //_centerBold('Daily Report (${_today()})'),
              // _centerBold('Daily Report (${_formatDate(reportDate)})'),
              _centerBold(
                formatReportTitle(filter: reportFilter, from: reportFromDate),
              ),

              pw.SizedBox(height: 4),

              /// ---------- HEADER ----------
              /// ---------- HEADER ----------
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

              pw.Divider(),

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

              /// ---------- OTHER INCOME ----------
              _tripleRow('Other Income', income, 0),

              pw.Divider(),

              _row('Total Income (Cash)', totalCash),
              _row('Expenses', expenses),
              pw.Divider(),
              _row('Balance', balance),
              _row('Drawing Out', drawingOut),
              pw.Divider(),
              _rowBold('Cash in Hand', cashInHand),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
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
      pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Text(
        v.toInt().toString(),
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    ],
  );

  static pw.Widget _center(String t) =>
      pw.Center(child: pw.Text(t, style: const pw.TextStyle(fontSize: 7)));

  static pw.Widget _centerBold(String t) => pw.Center(
    child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
  );

  static String _today() =>
      '${DateTime.now().day.toString().padLeft(2, '0')}.'
      '${DateTime.now().month.toString().padLeft(2, '0')}.'
      '${DateTime.now().year}';

  static String _doctorName(Map p) {
    try {
      final admins = p['Hospital']['Admins'] as List;
      final docId = p['Consultation']['doctor_Id'];

      final name = admins
          .firstWhere((a) => a['user_Id'] == docId)['name']
          .toString();

      return name.length > 15 ? '${name.substring(0, 15)}...' : name;
    } catch (_) {
      return 'Doctor';
    }
  }
}
