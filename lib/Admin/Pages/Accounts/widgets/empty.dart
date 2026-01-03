import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AccountsReportPdf {
  static Future<void> generate({
    required List<dynamic> payments,
    required double total,
    required String hospitalName,
    required String hospitalPlace,
    required String hospitalPhoto,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    // ---------- Load logo ----------
    Uint8List? logo;
    try {
      final res = await http.get(Uri.parse(hospitalPhoto));
      if (res.statusCode == 200) logo = res.bodyBytes;
    } catch (_) {}

    // ---------- Summarize payments ----------
    // Fee amounts and counts
    // Map<String, Map<String, dynamic>> feeCounts = {
    //   'Registration Fee': {'count': 0, 'amount': 0.0},
    //   'Consultation Fee': {'count': 0, 'amount': 0.0},
    //   'Sugar Test Fee': {'count': 0, 'amount': 0.0},
    //   'Emergency Fee': {'count': 0, 'amount': 0.0},
    //   'Medical / Injection / Tonic': {'count': 0, 'amount': 0.0},
    // };
    Map<String, Map<String, dynamic>> feeCounts = {
      'Registration Fee': {
        'count': 0,
        'amount': 0.0,
        'cash': 0.0,
        'online': 0.0,
      },
      'Consultation Fee': {
        'count': 0,
        'amount': 0.0,
        'cash': 0.0,
        'online': 0.0,
      },
      'Sugar Test Fee': {'count': 0, 'amount': 0.0, 'cash': 0.0, 'online': 0.0},
      'Emergency Fee': {'count': 0, 'amount': 0.0, 'cash': 0.0, 'online': 0.0},
      'Medical / Injection / Tonic': {
        'count': 0,
        'amount': 0.0,
        'cash': 0.0,
        'online': 0.0,
      },
    };

    Map<String, double> medicalAmounts = {};
    Map<String, Map<String, dynamic>> testCounts = {};
    Map<String, Map<String, dynamic>> scanCounts = {};

    for (var p in payments) {
      final type = (p['type'] ?? "").toString().toUpperCase();
      final paymentMode = (p['paymentType'] ?? "").toString().toUpperCase();
      final bool isCash = paymentMode == "MANUALPAY";
      final bool isOnline = paymentMode == "ONLINEPAY";

      final amount = (p['amount'] ?? 0).toDouble();

      if (type == "REGISTRATIONFEE") {
        final consultation = p['Consultation'];
        if (consultation != null) {
          // Registration Fee
          final regFee = consultation['registrationFee']?.toDouble() ?? 0;
          if (regFee > 0) {
            feeCounts['Registration Fee']!['amount'] += regFee;
            feeCounts['Registration Fee']!['count'] += 1;

            if (isCash) feeCounts['Registration Fee']!['cash'] += regFee;
            if (isOnline) feeCounts['Registration Fee']!['online'] += regFee;
          }

          // Consultation Fee
          final consultFee = consultation['consultationFee']?.toDouble() ?? 0;
          if (consultFee > 0) {
            feeCounts['Consultation Fee']!['amount'] += consultFee;
            feeCounts['Consultation Fee']!['count'] += 1;

            if (isCash) feeCounts['Consultation Fee']!['cash'] += consultFee;
            if (isOnline)
              feeCounts['Consultation Fee']!['online'] += consultFee;
          }

          // Sugar Test Fee
          final sugarFee = consultation['sugarTestFee']?.toDouble() ?? 0;
          if (sugarFee > 0) {
            feeCounts['Sugar Test Fee']!['amount'] += sugarFee;
            feeCounts['Sugar Test Fee']!['count'] += 1;

            if (isCash) feeCounts['Sugar Test Fee']!['cash'] += sugarFee;
            if (isOnline) feeCounts['Sugar Test Fee']!['online'] += sugarFee;
          }

          // Emergency Fee
          final emergencyFee = consultation['emergencyFee']?.toDouble() ?? 0;
          if (emergencyFee > 0) {
            feeCounts['Emergency Fee']!['amount'] += emergencyFee;
            feeCounts['Emergency Fee']!['count'] += 1;

            if (isCash) feeCounts['Emergency Fee']!['cash'] += emergencyFee;
            if (isOnline) feeCounts['Emergency Fee']!['online'] += emergencyFee;
          }
        }
      } else if (type == "TESTINGFEESANDSCANNINGFEE") {
        for (var entry in p["TestingAndScanningPatients"] ?? []) {
          final name = (entry["type"] ?? "").toString();
          final amt = (entry["amount"] ?? 0).toDouble();

          // Separate Tests vs Scans
          if (name.toLowerCase().contains("test")) {
            final String title = (entry["title"] ?? "Unknown Test")
                .toString()
                .trim();

            if (!testCounts.containsKey(title)) {
              testCounts[title] = {
                'count': 0,
                'amount': 0.0,
                'cash': 0.0,
                'online': 0.0,
              };
            }

            testCounts[title]!['count'] += 1;
            testCounts[title]!['amount'] += amt;
            if (isCash) testCounts[title]!['cash'] += amt;
            if (isOnline) testCounts[title]!['online'] += amt;

            // testCounts[title]!['count'] += 1;
            // testCounts[title]!['amount'] += amt;
          } else {
            if (!scanCounts.containsKey(name)) {
              scanCounts[name] = {
                'count': 0,
                'amount': 0.0,
                'cash': 0.0,
                'online': 0.0,
              };
            }

            scanCounts[name]!['count'] += 1;
            scanCounts[name]!['amount'] += amt;
            if (isCash) scanCounts[name]!['cash'] += amt;
            if (isOnline) scanCounts[name]!['online'] += amt;
            // scanCounts[name]!['count'] += 1;
            // scanCounts[name]!['amount'] += amt;
          }
        }
      } else if (type == "MEDICINETONICINJECTIONFEES") {
        final medName = p['name'] ?? "Medical/Injection/Tonic";
        feeCounts['Medical / Injection / Tonic']!['amount'] += amount;
        feeCounts['Medical / Injection / Tonic']!['count'] += 1;

        if (isCash) feeCounts['Medical / Injection / Tonic']!['cash'] += amount;
        if (isOnline)
          feeCounts['Medical / Injection / Tonic']!['online'] += amount;

        if (!medicalAmounts.containsKey(medName)) medicalAmounts[medName] = 0;
        medicalAmounts[medName] = medicalAmounts[medName]! + amount;
      }
    }

    // ---------- PDF Page ----------
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Row(
            children: [
              if (logo != null)
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    image: pw.DecorationImage(
                      image: pw.MemoryImage(logo),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    hospitalName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(hospitalPlace, style: pw.TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              'ACCOUNTS REPORT',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),

          // ---------- GRAND TOTAL CARD ----------
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Center(
              child: pw.Text(
                "GRAND TOTAL: ₹ ${total.toStringAsFixed(1)}",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // ---------- FEE SUMMARY TABLE ----------
          pw.Text(
            "Fee Summary",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 6),
          _feeSummaryTable(feeCounts),
          pw.SizedBox(height: 16),

          // ---------- TESTS SUMMARY ----------
          if (testCounts.isNotEmpty) ...[
            pw.Text(
              "Tests Summary",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 6),
            _summaryTable(testCounts),
            pw.SizedBox(height: 12),
          ],

          // ---------- SCANS SUMMARY ----------
          if (scanCounts.isNotEmpty) ...[
            pw.Text(
              "Scans Summary",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 6),
            _summaryTable(scanCounts),
            pw.SizedBox(height: 12),
          ],

          // ---------- MEDICAL SUMMARY ----------
          if (medicalAmounts.isNotEmpty) ...[
            pw.Text(
              "Medical / Injection / Tonic Summary",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headers: ['Name', 'Amount'],
              data: medicalAmounts.entries
                  .map((e) => [e.key, "₹ ${e.value.toStringAsFixed(1)}"])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey400),
              cellAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(color: PdfColors.grey300),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ---------------- Helper Summary Table with Total ----------------
  static pw.Widget _summaryTable(Map<String, Map<String, dynamic>> data) {
    num totalCount = 0;
    double totalAmount = 0;
    double totalCash = 0;
    double totalOnline = 0;

    final rows = data.entries.map((e) {
      final count = e.value['count'] ?? 0;
      final amount = (e.value['amount'] ?? 0).toDouble();
      final cash = (e.value['cash'] ?? 0).toDouble();
      final online = (e.value['online'] ?? 0).toDouble();

      totalCount += count;
      totalAmount += amount;
      totalCash += cash;
      totalOnline += online;

      return [
        e.key,
        count.toString(),
        "₹ ${cash.toStringAsFixed(1)}",
        "₹ ${online.toStringAsFixed(1)}",
        "₹ ${amount.toStringAsFixed(1)}",
      ];
    }).toList();

    // TOTAL row at top
    rows.insert(0, [
      "TOTAL",
      totalCount.toString(),
      "₹ ${totalCash.toStringAsFixed(1)}",
      "₹ ${totalOnline.toStringAsFixed(1)}",
      "₹ ${totalAmount.toStringAsFixed(1)}",
    ]);

    return pw.Table.fromTextArray(
      headers: ['Name', 'Count', 'Cash', 'Online', 'Amount'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey400),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey300),
    );
  }

  // ---------------- Fee Summary Table with Counts ----------------
  static pw.Widget _feeSummaryTable(Map<String, Map<String, dynamic>> data) {
    num totalCount = 0;
    double totalAmount = 0;
    double totalCash = 0;
    double totalOnline = 0;

    final rows = data.entries.map((e) {
      final count = e.value['count'] ?? 0;
      final amount = (e.value['amount'] ?? 0).toDouble();
      final cash = (e.value['cash'] ?? 0).toDouble();
      final online = (e.value['online'] ?? 0).toDouble();

      totalCount += count;
      totalAmount += amount;
      totalCash += cash;
      totalOnline += online;

      return [
        e.key,
        count.toString(),
        "₹ ${cash.toStringAsFixed(1)}",
        "₹ ${online.toStringAsFixed(1)}",
        "₹ ${amount.toStringAsFixed(1)}",
      ];
    }).toList();

    // TOTAL row
    rows.insert(0, [
      "TOTAL",
      totalCount.toString(),
      "₹ ${totalCash.toStringAsFixed(1)}",
      "₹ ${totalOnline.toStringAsFixed(1)}",
      "₹ ${totalAmount.toStringAsFixed(1)}",
    ]);

    return pw.Table.fromTextArray(
      headers: ['Fee Type', 'Count', 'Cash', 'Online', 'Amount'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey400),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey300),
    );
  }
}
