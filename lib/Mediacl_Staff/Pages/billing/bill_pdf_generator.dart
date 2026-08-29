import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class BillPdfGenerator {
  static Future<void> generateAndPrintBill({
    required List<Map<String, dynamic>> medicines,
    required Map<String, dynamic> hospitalData,
    required double totalAmount,
  }) async {
    final pdf = pw.Document();

    print('medicines $medicines');
    final hospital = hospitalData ?? {};
    final patientName = hospitalData['name'] ?? '';
    final dateTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
    final logoUrl = hospital['hospitalPhoto'];

    int totalQty = 0;
    int itemLength = 0;

    pw.ImageProvider? logoImage;
    if (logoUrl != null && logoUrl.toString().isNotEmpty) {
      try {
        logoImage = await networkImage(logoUrl);
      } catch (_) {}
    }

    final font = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font, bold: bold),
        pageFormat: PdfPageFormat(
          76.2 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 6,
        ),
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 28,
                        height: 28,
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(14),
                          border: pw.Border.all(width: 0.8),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 14,
                          verticalRadius: 14,
                          child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            hospital['hospitalName'] ?? 'Hospital Name',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            hospital['hospitalAddress'] ?? '-',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Text(
                      'PATIENT DETAILS',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      dateTime,
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Name    :   -',
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'PID       :   -',
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Phone   :   -',
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
                pw.SizedBox(height: 2),
                dashedLine(),
                pw.Row(
                  children: [
                    tableHeader('Item', 5),
                    tableHeader('B/N', 3),
                    tableHeader('Qty', 3),
                    tableHeader('Ses', 3),
                    tableHeader('Exp', 2),
                    tableHeader('Amt', 3, alignRight: true),
                  ],
                ),
                dashedLine(),
                ...medicines.map((item) {
                  final qty = item['quantityNeeded'] ?? 0;
                  totalQty += qty as int;

                  String expDate = '--';

                  final batches = item['medicine']?['batches'];
                  final batchesNo = item['batchNo'].toString();
                  final bool afterEat = item['after_food'] ?? false;
                  final bool morning = item['morning'] ?? false;
                  final bool afternoon = item['afternoon'] ?? false;
                  final bool night = item['night'] ?? false;
                  final int days = item['days'] ?? 0;
                  final String category = item['category']
                      .toString()
                      .toLowerCase();
                  final length = item['itemLength'];
                  itemLength = length;
                  String timeFormat =
                      '${morning ? 1 : 0}-${afternoon ? 1 : 0}-${night ? 1 : 0}';
                  if (!morning && !afternoon && !night) timeFormat = '-';

                  String result = timeFormat;
                  List<String> acPcCategories = [
                    'injections',
                    'creams',
                    'soap',
                    'drops',
                    'ointments',
                  ];

                  if (days != 0 && timeFormat != '-') {
                    String foodType = afterEat ? 'B' : 'A';
                    result = acPcCategories.contains(category)
                        ? timeFormat
                        : '$timeFormat ($foodType)';
                  }

                  if (batches != null && batches.isNotEmpty) {
                    final rawDate = batches[0]['expiry_date']?.toString();
                    if (rawDate != null && rawDate.length >= 7) {
                      final year = rawDate.substring(2, 4);
                      final month = rawDate.substring(5, 7);
                      expDate = '$month / $year';
                    }
                  }

                  final categories = item['medicine']['category']
                      ?.toString()
                      .trim();
                  final categoryInitial =
                      (categories != null && categories.isNotEmpty)
                      ? categories[0].toUpperCase()
                      : '';

                  return pw.Row(
                    children: [
                      tableCell('${item['name']}($categoryInitial)', 5),
                      tableCell(batchesNo, 3),
                      tableCell(qty.toString(), 2),
                      tableCell(result, 3),
                      tableCell(expDate, 2),
                      tableCell(
                        ((item['total'] as num).toStringAsFixed(1)),
                        3,
                        alignRight: true,
                      ),
                    ],
                  );
                }).toList(),
                pw.SizedBox(height: 6),
                dashedLine(),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        'TOTAL ($itemLength)',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        totalQty.toString(),
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          '₹ ${totalAmount.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                dashedLine(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank You!',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'Powered by Ramchin Technologics Pvt Ltd',
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'Medical_Bill_12.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  static pw.Widget dashedLine() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: List.generate(
          30,
          (index) => pw.Expanded(
            child: pw.Container(
              height: 0.6,
              margin: const pw.EdgeInsets.symmetric(horizontal: 1),
              color: PdfColors.grey700,
            ),
          ),
        ),
      ),
    );
  }

  static pw.Widget tableHeader(
    String text,
    int flex, {
    bool alignRight = false,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget tableCell(String text, int flex, {bool alignRight = false}) {
    String displayText = text;
    final RegExp regExp = RegExp(r'\(.*?\)$');
    final match = regExp.firstMatch(text);

    if (match != null) {
      String suffix = match.group(0)!;
      String namePart = text.substring(0, match.start);
      if (namePart.length > 10) namePart = '${namePart.substring(0, 8)}...';
      displayText = '$namePart$suffix';
    } else if (text.length > 10) {
      displayText = '${text.substring(0, 8)}...';
    }

    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        displayText,
        style: const pw.TextStyle(fontSize: 6),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }
}
