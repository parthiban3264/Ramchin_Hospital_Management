import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MedicalPdfBillMaker {
  static Future<void> generateMedicalBillPdf({
    required Map<String, dynamic> patientData,
    required double totalAmount,
    required Map<String, dynamic> allConsultation,
    required List<dynamic> medicines,
  }) async {
    final pdf = pw.Document();

    /// ===== 3 inch thermal paper width (76mm) =====
    //const double pageWidth = 76 * PdfPageFormat.mm;
    print('medicines $medicines');
    final hospital = allConsultation['hospital'] ?? {};
    final patientName = patientData['name'] ?? '';
    final pid = patientData['id']?.toString() ?? '';

    final phone = patientData['phone']?['mobile'] ?? '';
    final dateTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
    final logoUrl = hospital['photo'];
    //final mid = medicines['']

    int totalQty = 0;

    /// ===== Load logo safely =====
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

        // pageFormat: PdfPageFormat(pageWidth, double.infinity, marginAll: 6),
        build: (context) {
          print('medicines $medicines');
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              /// ================= HEADER =================
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
                          hospital['name'] ?? 'Hospital Name',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.left,
                        ),
                        pw.Text(
                          hospital['address'] ?? '',
                          style: const pw.TextStyle(fontSize: 7),
                          textAlign: pw.TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),

              pw.SizedBox(height: 4),

              /// ================= PATIENT DETAILS =================
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
                      color: PdfColors.black,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 4),
              pw.Text(
                'Name    :   $patientName',
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'PID       :   $pid',
                style: const pw.TextStyle(fontSize: 7.5),
              ),

              pw.SizedBox(height: 2),
              pw.Text(
                'Phone   :   $phone',
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.SizedBox(height: 2),

              dashedLine(),

              /// ================= TABLE HEADER =================
              pw.Row(
                children: [
                  tableHeader('Item', 5),
                  tableHeader('B/N', 3),
                  tableHeader('Qty', 2),
                  tableHeader('Ses', 3),
                  tableHeader('Exp', 2),
                  tableHeader('Amt', 3, alignRight: true),
                ],
              ),

              dashedLine(),

              /// ================= MEDICINES =================
              ...medicines.map((item) {
                print('itemssss $item');
                final qty = item['quantityNeeded'] ?? 0;
                totalQty += qty as int;

                // final expDate =
                //     (item['medicine']?['batches'] != null &&
                //         item['medicine']['batches'].isNotEmpty)
                //     ? item['medicine']['batches'][0]['expiry_date']
                //           .toString()
                //           .substring(0, 7)
                //     : '--';

                String expDate = '--';

                final batches = item['medicine']?['batches'];
                final batchesNo = item['batchNo'].toString();
                final bool afterEat = item['after_food'] ?? false;
                final bool morning = item['morning'] ?? false;
                final bool afternoon = item['afternoon'] ?? false;
                final bool night = item['night'] ?? false;
                print('after $afterEat $morning $afternoon $night');
                final int days = item['days'] ?? 0;
                final String category =
                    item['category'].toString().toLowerCase() ?? '';
                print('category $category');
                String timeFormat =
                    '${morning ? 1 : 0}-${afternoon ? 1 : 0}-${night ? 1 : 0}';

                // If all times are 0-0-0 → show "-"
                if (!morning && !afternoon && !night) {
                  timeFormat = '-';
                }

                String result = timeFormat;

                // Show AC/PC only if category is injections AND days != 0
                List<String> acPcCategories = [
                  'injections',
                  'creams',
                  'soap',
                  'drops',
                  'ointments',
                ];

                if (days != 0 && timeFormat != '-') {
                  String foodType = afterEat ? 'B' : 'A';

                  if (acPcCategories.contains(category)) {
                    // injections, creams, drops etc
                    result = timeFormat;
                  } else {
                    // paracetamol, tonic, tablets etc
                    result = '($foodType)$timeFormat';
                  }
                }

                if (batches != null && batches.isNotEmpty) {
                  final rawDate = batches[0]['expiry_date']?.toString();

                  if (rawDate != null && rawDate.length >= 7) {
                    final year = rawDate.substring(2, 4); // YY
                    final month = rawDate.substring(5, 7); // MM
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
                    tableCell(batchesNo.toString(), 3),
                    tableCell(qty.toString(), 2),
                    tableCell(result, 3),
                    tableCell(expDate, 2),
                    tableCell(
                      (item['total'].toStringAsFixed(1) ?? 0).toString(),
                      3,
                      alignRight: true,
                    ),
                  ],
                );
              }).toList(),

              pw.SizedBox(height: 6),

              dashedLine(),

              /// ================= TOTAL =================
              pw.Row(
                children: [
                  // Item column
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  // Qty column (aligned under Qty)
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

                  // Exp column (empty)
                  //pw.Expanded(flex: 1, child: pw.Text('')),

                  // Amount column (aligned under Amt)
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

              /// ================= FOOTER =================
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
          );
        },
      ),
    );

    /// ================= PRINT =================
    await Printing.layoutPdf(
      name: 'Medical_Bill_$pid.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  /// ===== Dashed divider =====
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

  // static pw.Widget tableCell(String text, int flex, {bool alignRight = false}) {
  //   return pw.Expanded(
  //     flex: flex,
  //     child: pw.Text(
  //       text,
  //       style: const pw.TextStyle(fontSize: 6),
  //       textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
  //     ),
  //   );
  // }
  static pw.Widget tableCell(String text, int flex, {bool alignRight = false}) {
    String displayText = text;

    // Check if text contains something like (T)
    final RegExp regExp = RegExp(r'\(.*?\)$');

    final match = regExp.firstMatch(text);

    if (match != null) {
      String suffix = match.group(0)!; // (T)
      String namePart = text.substring(0, match.start);

      if (namePart.length > 10) {
        namePart = '${namePart.substring(0, 8)}...';
      }

      displayText = '$namePart$suffix';
    } else {
      // Normal truncate if no (T)
      if (text.length > 10) {
        displayText = '${text.substring(0, 8)}...';
      }
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
