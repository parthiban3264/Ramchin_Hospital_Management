import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../patient_list_reportpage.dart';

class AccountListReportPdf {
  static Future<void> generate({
    required List<dynamic> payments,
    required List<dynamic> expenses,
    required List<dynamic> drawings,

    required double total,
    required double totalExpenses,
    required double totalDrawings,
    required double previousBalance,

    required String hospitalName,
    required String hospitalPlace,
    required String hospitalPhoto,

    required ReportType reportType,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    Uint8List? logo;
    try {
      logo = (await networkImage(hospitalPhoto)) as Uint8List?;
    } catch (_) {}

    final List<_AccountRow> rows = [];

    // -------- PAYMENTS (INCOME) --------
    for (var p in payments) {
      rows.add(
        _AccountRow(
          date: p['createdAt'],
          income: (p['amount'] ?? 0).toDouble(),
        ),
      );
    }

    // -------- EXPENSE --------
    for (var e in expenses) {
      final type = (e['type'] ?? '').toString().toUpperCase();
      rows.add(
        _AccountRow(
          date: e['createdAt'],
          expense: type == 'EXPENSE' ? (e['amount'] ?? 0).toDouble() : 0,
          drawingOut: type == 'INCOME' ? (e['amount'] ?? 0).toDouble() : 0,
        ),
      );
    }

    // -------- DRAWINGS --------
    for (var d in drawings) {
      final type = (d['type'] ?? '').toString().toUpperCase();
      rows.add(
        _AccountRow(
          date: d['createdAt'],
          drawingIn: type == 'IN' ? (d['amount'] ?? 0).toDouble() : 0,
          drawingOut: type == 'OUT' ? (d['amount'] ?? 0).toDouble() : 0,
        ),
      );
    }

    rows.sort((a, b) => a.date.compareTo(b.date));

    final List<_AccountRow> finalRows = reportType == ReportType.daily
        ? rows
        : reportType == ReportType.monthly
        ? _combineByDay(rows)
        : _combineByMonth(rows);

    final closingBalance =
        previousBalance +
        total -
        totalExpenses +
        rows.fold(0.0, (s, r) => s + r.drawingIn) -
        rows.fold(0.0, (s, r) => s + r.drawingOut);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: bold),
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          // ---------- HEADER ----------
          pw.Row(
            children: [
              if (logo != null)
                pw.Container(
                  width: 60,
                  height: 60,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(pw.MemoryImage(logo)),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    hospitalName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(hospitalPlace),
                  pw.Text(
                    "ACCOUNT LIST REPORT",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ---------- TABLE ----------
          _accountTable(finalRows, reportType),

          pw.SizedBox(height: 16),

          // ---------- SUMMARY ----------
          _summaryBox(
            previousBalance,
            total,
            totalExpenses,
            rows.fold(0.0, (s, r) => s + r.drawingIn),
            rows.fold(0.0, (s, r) => s + r.drawingOut),
            closingBalance,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ================= TABLE =================

  static pw.Widget _accountTable(
    List<_AccountRow> rows,
    ReportType reportType,
  ) {
    final total = _AccountRow(date: DateTime.now());
    for (final r in rows) {
      total.add(r);
    }

    final bool showProfit = reportType != ReportType.monthly;

    final headers = [
      'S.No',
      reportType == ReportType.yearly ? 'Month' : 'Date',
      'Income',
      'Expense',
      'Drawing +',
      'Drawing -',
      if (showProfit) 'Profit / Loss',
    ];

    final data = [
      ...List.generate(rows.length, (i) {
        final r = rows[i];
        return [
          '${i + 1}',
          reportType == ReportType.yearly
              ? DateFormat('MMM yyyy').format(r.date)
              : DateFormat('dd-MM-yyyy').format(r.date),
          '₹${r.income.toStringAsFixed(2)}',
          '₹${r.expense.toStringAsFixed(2)}',
          '₹${r.drawingIn.toStringAsFixed(2)}',
          '₹${r.drawingOut.toStringAsFixed(2)}',
          if (showProfit) '₹${r.profitLoss.toStringAsFixed(2)}',
        ];
      }),

      // -------- TOTAL ROW --------
      [
        '',
        'TOTAL',
        '₹${total.income.toStringAsFixed(2)}',
        '₹${total.expense.toStringAsFixed(2)}',
        '₹${total.drawingIn.toStringAsFixed(2)}',
        '₹${total.drawingOut.toStringAsFixed(2)}',
        if (showProfit) '₹${total.profitLoss.toStringAsFixed(2)}',
      ],
    ];

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(color: PdfColors.grey400),
    );
  }

  // ================= SUMMARY =================

  static pw.Widget _summaryBox(
    double prev,
    double income,
    double expense,
    double drawIn,
    double drawOut,
    double balance,
  ) {
    pw.Widget row(String t, double v, {bool bold = false}) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          t,
          style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null),
        ),
        pw.Text(
          '₹${v.toStringAsFixed(2)}',
          style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null),
        ),
      ],
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          row("Previous Balance", prev),
          row("Total Income (+)", income),
          row("Total Expense (-)", expense),
          row("Drawing In (+)", drawIn),
          row("Drawing Out (-)", drawOut),
          pw.Divider(),
          row("Closing Balance", balance, bold: true),
        ],
      ),
    );
  }

  // ================= GROUPING =================

  static List<_AccountRow> _combineByDay(List<_AccountRow> rows) {
    final Map<String, _AccountRow> map = {};
    for (final r in rows) {
      final key = DateFormat('yyyy-MM-dd').format(r.date);
      map.putIfAbsent(key, () => _AccountRow(date: r.date));
      map[key]!.add(r);
    }
    return map.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  static List<_AccountRow> _combineByMonth(List<_AccountRow> rows) {
    final Map<String, _AccountRow> map = {};
    for (final r in rows) {
      final key = '${r.date.year}-${r.date.month}';
      map.putIfAbsent(
        key,
        () => _AccountRow(date: DateTime(r.date.year, r.date.month)),
      );
      map[key]!.add(r);
    }
    return map.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }
}

// ================= MODEL =================

class _AccountRow {
  final DateTime date;
  double income, expense, drawingIn, drawingOut;

  _AccountRow({
    required this.date,
    this.income = 0,
    this.expense = 0,
    this.drawingIn = 0,
    this.drawingOut = 0,
  });

  void add(_AccountRow r) {
    income += r.income;
    expense += r.expense;
    drawingIn += r.drawingIn;
    drawingOut += r.drawingOut;
  }

  double get profitLoss => income - expense + drawingIn - drawingOut;
}
