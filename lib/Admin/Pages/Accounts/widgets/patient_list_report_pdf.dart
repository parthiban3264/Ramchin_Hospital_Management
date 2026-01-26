import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PatientListReportPdf {
  static Future<void> generate({
    required List<dynamic> payments,
    required double total,
    required String hospitalName,
    required String hospitalPlace,
    required String hospitalPhoto,
    bool includeAll = false, // <-- NEW PARAM
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

    // ---------- Initialize summary maps ----------
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
      final isCash = paymentMode == "MANUALPAY";
      final isOnline = paymentMode == "ONLINEPAY";
      final amount = (p['amount'] ?? 0).toDouble();

      // ---------- Registration & Consultation Fees ----------
      if (type == "REGISTRATIONFEE") {
        final consultation = p['Consultation'];
        if (consultation != null) {
          final regFee = consultation['registrationFee']?.toDouble() ?? 0;
          if (regFee > 0) {
            feeCounts['Registration Fee']!['amount'] += regFee;
            feeCounts['Registration Fee']!['count'] += 1;
            if (isCash) feeCounts['Registration Fee']!['cash'] += regFee;
            if (isOnline) feeCounts['Registration Fee']!['online'] += regFee;
          }

          final consultFee = consultation['consultationFee']?.toDouble() ?? 0;
          if (consultFee > 0) {
            feeCounts['Consultation Fee']!['amount'] += consultFee;
            feeCounts['Consultation Fee']!['count'] += 1;
            if (isCash) feeCounts['Consultation Fee']!['cash'] += consultFee;
            if (isOnline)
              feeCounts['Consultation Fee']!['online'] += consultFee;
          }

          final sugarFee = consultation['sugarTestFee']?.toDouble() ?? 0;
          if (sugarFee > 0) {
            feeCounts['Sugar Test Fee']!['amount'] += sugarFee;
            feeCounts['Sugar Test Fee']!['count'] += 1;
            if (isCash) feeCounts['Sugar Test Fee']!['cash'] += sugarFee;
            if (isOnline) feeCounts['Sugar Test Fee']!['online'] += sugarFee;
          }

          final emergencyFee = consultation['emergencyFee']?.toDouble() ?? 0;
          if (emergencyFee > 0) {
            feeCounts['Emergency Fee']!['amount'] += emergencyFee;
            feeCounts['Emergency Fee']!['count'] += 1;
            if (isCash) feeCounts['Emergency Fee']!['cash'] += emergencyFee;
            if (isOnline) feeCounts['Emergency Fee']!['online'] += emergencyFee;
          }
        }
      }
      // ---------- Testing & Scanning ----------
      else if (type == "TESTINGFEESANDSCANNINGFEE") {
        for (var entry in p["TestingAndScanningPatients"] ?? []) {
          final name = (entry["type"] ?? "").toString();
          final amt = (entry["amount"] ?? 0).toDouble();
          if (name.toLowerCase().contains("test")) {
            final title = (entry["title"] ?? "Unknown Test").toString().trim();
            testCounts.putIfAbsent(
              title,
              () => {'count': 0, 'amount': 0.0, 'cash': 0.0, 'online': 0.0},
            );
            testCounts[title]!['count'] += 1;
            testCounts[title]!['amount'] += amt;
            if (isCash) testCounts[title]!['cash'] += amt;
            if (isOnline) testCounts[title]!['online'] += amt;
          } else {
            scanCounts.putIfAbsent(
              name,
              () => {'count': 0, 'amount': 0.0, 'cash': 0.0, 'online': 0.0},
            );
            scanCounts[name]!['count'] += 1;
            scanCounts[name]!['amount'] += amt;
            if (isCash) scanCounts[name]!['cash'] += amt;
            if (isOnline) scanCounts[name]!['online'] += amt;
          }
        }
      }
      // ---------- Medical / Injection / Tonic ----------
      else if (type == "MEDICINETONICINJECTIONFEES") {
        final medName = p['name'] ?? "Medical/Injection/Tonic";
        feeCounts['Medical / Injection / Tonic']!['amount'] += amount;
        feeCounts['Medical / Injection / Tonic']!['count'] += 1;
        if (isCash) feeCounts['Medical / Injection / Tonic']!['cash'] += amount;
        if (isOnline)
          feeCounts['Medical / Injection / Tonic']!['online'] += amount;
        medicalAmounts[medName] = (medicalAmounts[medName] ?? 0) + amount;
      }
    }

    // ---------- BUILD PDF ----------
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
          // Grand Total
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
          // Fee Summary
          pw.Text(
            "Fee Summary",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 6),
          _feeSummaryTable(feeCounts),
          pw.SizedBox(height: 16),
          // Tests Summary
          if (testCounts.isNotEmpty) ...[
            pw.Text(
              "Tests Summary",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 6),
            _summaryTable(testCounts),
            pw.SizedBox(height: 12),
          ],
          // Scans Summary
          if (scanCounts.isNotEmpty) ...[
            pw.Text(
              "Scans Summary",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 6),
            _summaryTable(scanCounts),
            pw.SizedBox(height: 12),
          ],
          // Medical Summary
          if (medicalAmounts.isNotEmpty) ...[
            pw.Text(
              "Medicians",
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

          // ---------- INCLUDE ALL PATIENTS SECTION ----------
          if (includeAll) ...[
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 12),
            pw.Text(
              "ALL PATIENTS REPORT",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),

            // Registration Fee Details
            pw.Text(
              "Registration / Consultation Fees",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            _detailedPatientTable(payments, "REGISTRATIONFEE"),

            // Testing & Scanning
            pw.SizedBox(height: 12),
            pw.Text(
              "Testing & Scanning Fees",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            _detailedPatientTable(payments, "TESTINGFEESANDSCANNINGFEE"),

            // Medical / Injection / Tonic
            pw.SizedBox(height: 12),
            pw.Text(
              "Medicians Fees",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            _detailedPatientTable(payments, "MEDICINETONICINJECTIONFEES"),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ---------------- HELPER: DETAILED PATIENT TABLE (Simplified & Colorful) ----------------
  static pw.Widget _detailedPatientTable(
    List<dynamic> payments,
    String typeFilter,
  ) {
    final filtered = payments
        .where((p) => (p['type'] ?? "").toString().toUpperCase() == typeFilter)
        .toList();

    if (filtered.isEmpty) return pw.Text("No records found");

    // Calculate totals
    final totalAmount = filtered.fold<double>(
      0,
      (sum, p) => sum + ((p['amount'] ?? 0).toDouble()),
    );
    final totalCount = filtered.length;

    // Table rows
    List<List<String>> rows = [];
    for (var p in filtered) {
      final patientName = p['Patient']?['name'] ?? "Unknown";
      final patientId = p['patient_Id']?.toString() ?? "-";
      final amount = (p['amount'] ?? 0).toStringAsFixed(1);
      final date = p['createdAt'] != null
          ? DateFormat('dd MMM yyyy').format(
              p['createdAt'] is DateTime
                  ? p['createdAt']
                  : DateTime.parse(p['createdAt']),
            )
          : "-";

      rows.add([patientName, patientId, "₹ $amount", date]);
    }

    // Add summary row at the end with only total count and total amount
    rows.add([
      "Total Patients : $totalCount", // Use 3rd column for total count
      "-", // Patient Name column empty
      "Total : ₹ ${totalAmount.toStringAsFixed(1)}", // 4th column for total amount
      "-", // ID column empty
    ]);

    return pw.Table.fromTextArray(
      headers: ['Patient Name', 'ID', 'Amount', 'Date'],
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 12,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColors.blue700),
      cellStyle: pw.TextStyle(fontSize: 11, color: PdfColors.black),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
      oddRowDecoration: pw.BoxDecoration(color: PdfColors.blue50),
      columnWidths: {
        0: pw.FlexColumnWidth(3), // Patient Name
        1: pw.FlexColumnWidth(1), // ID
        2: pw.FlexColumnWidth(2), // Amount (used for Total Patients)
        3: pw.FlexColumnWidth(2), // Date (used for Total Amount)
      },
    );
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
      cellAlignments: {
        0: pw.Alignment.centerLeft, // Fee Type
        1: pw.Alignment.center, // Count
        2: pw.Alignment.centerRight, // Cash
        3: pw.Alignment.centerRight, // Online
        4: pw.Alignment.centerRight, // Amount
      },
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
      cellAlignments: {
        0: pw.Alignment.centerLeft, // Fee Type
        1: pw.Alignment.center, // Count
        2: pw.Alignment.centerRight, // Cash
        3: pw.Alignment.centerRight, // Online
        4: pw.Alignment.centerRight, // Amount
      },
      border: pw.TableBorder.all(color: PdfColors.grey300),
    );
  }
}
