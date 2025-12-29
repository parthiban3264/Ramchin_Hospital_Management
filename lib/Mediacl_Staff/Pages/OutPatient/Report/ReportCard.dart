import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ReportCardWidget extends StatelessWidget {
  final Map<String, dynamic> record;
  final List<Map<String, dynamic>> testTable;
  final String doctorName;
  final String staffName;
  final String hospitalPhotoBase64;
  final Map<String, dynamic> optionResults;
  final int mode;
  final bool showButtons;

  const ReportCardWidget({
    super.key,
    required this.record,
    required this.testTable,
    required this.doctorName,
    required this.staffName,
    required this.hospitalPhotoBase64,
    required this.optionResults,
    required this.mode,
    required this.showButtons,
  });

  Color _getResultColor(String? resultStr, String? rangeStr) {
    final result = double.tryParse(resultStr ?? '');
    if (result == null) return Colors.black;

    final range = _parseRange(rangeStr);
    final min = range['min'];
    final max = range['max'];
    if (min == null || max == null) return Colors.black;

    final avg = (min + max) / 2;
    final greenMin = avg - 5;
    final greenMax = avg + 5;

    if (result < min || result > max) {
      return Colors.red; // ❌ Out of range
    } else if (result >= greenMin && result <= greenMax) {
      return Colors.green; // ✅ Within ±5 of average
    } else {
      return Colors.orangeAccent; // ⚠️ Within range but outside center band
    }
  }

  Map<String, double?> _parseRange(String? range) {
    if (range == null || range.isEmpty) return {'min': null, 'max': null};
    final parts = range.replaceAll('–', '-').split('-');
    if (parts.length != 2) return {'min': null, 'max': null};
    final min = double.tryParse(parts[0].trim());
    final max = double.tryParse(parts[1].trim());
    return {'min': min, 'max': max};
  }

  String _getResultStatus(String? resultStr, String? rangeStr) {
    final result = double.tryParse(resultStr ?? '');
    if (result == null) return "N/A";

    final range = _parseRange(rangeStr);
    final min = range['min'];
    final max = range['max'];
    if (min == null || max == null) return "N/A";

    final avg = (min + max) / 2;
    final greenMin = avg - 5;
    final greenMax = avg + 5;

    if (result < min) return "Low";
    if (result > max) return "High";
    if (result >= greenMin && result <= greenMax) return "Good";
    return "Normal";
  }

  /// --- PDF GENERATION ---
  Future<Uint8List> _generatePdf(BuildContext context) async {
    final doc = pw.Document();

    final PdfColor primaryBlue = PdfColor.fromHex("#0E3B7D");
    final PdfColor subtitle = PdfColor.fromHex("#444C68");
    final PdfColor borderGray = PdfColor.fromHex("#D9D9E0");

    final patient = record['Patient'] ?? {};
    final hospital = record['Hospital'] ?? {};
    final title = record['title'] ?? 'Lab Report';
    final testDate = record['createdAt'] ?? '';
    final gender = patient['gender'] ?? '';
    final phone = patient['phone'] ?? '';
    // final result = record['result'] ?? '';
    final pid = record['patient_Id'].toString();
    final hospitalAddress = hospital['address'] ?? '';

    pw.MemoryImage? photoBytes;

    // Helper: Try decode as Base64; if fails or empty, try fetch from URL
    Future<pw.MemoryImage?> loadImage(String imageInput) async {
      if (imageInput.isEmpty) return null;

      // Try Base64 decode (strip prefix if data URI)
      try {
        String base64String = imageInput;
        if (imageInput.contains(',')) {
          base64String = imageInput.split(',').last;
        }
        final bytes = base64Decode(base64String);
        return pw.MemoryImage(bytes);
      } catch (_) {
        // Not Base64? Treat like URL, try fetch
        try {
          final response = await http.get(Uri.parse(imageInput));
          if (response.statusCode == 200) {
            return pw.MemoryImage(response.bodyBytes);
          }
        } catch (_) {}
      }
      return null;
    }

    photoBytes = await loadImage(hospitalPhotoBase64);
    final ttf = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();
    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        // margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // HEADER
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      hospital['name'] ?? '-',
                      style: pw.TextStyle(
                        color: primaryBlue,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    pw.Text(
                      hospitalAddress,
                      style: pw.TextStyle(color: subtitle, fontSize: 10),
                    ),
                    pw.Text(
                      "Accurate | Caring | Instant",
                      style: pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                photoBytes != null
                    ? pw.Container(
                        width: 120,
                        height: 70,
                        child: pw.Image(photoBytes, fit: pw.BoxFit.cover),
                      )
                    : pw.Container(
                        width: 60,
                        height: 60,
                        color: primaryBlue,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          "LOGO",
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
          pw.Divider(color: borderGray),
          pw.SizedBox(height: 8),

          // PATIENT INFO
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderGray, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            padding: const pw.EdgeInsets.all(8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Name: ${patient['name'] ?? ''}',
                      style: pw.TextStyle(fontSize: 10, color: subtitle),
                    ),
                    pw.Text(
                      'PID: $pid',
                      style: pw.TextStyle(fontSize: 10, color: subtitle),
                    ),
                    pw.Text(
                      'Phone: $phone',
                      style: pw.TextStyle(fontSize: 10, color: subtitle),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Age: ${_calculateAge(patient['dob'])}',
                      style: pw.TextStyle(fontSize: 10, color: subtitle),
                    ),
                    pw.Text(
                      'Sex: $gender',
                      style: pw.TextStyle(fontSize: 10, color: subtitle),
                    ),
                    pw.Text(
                      'Date: $testDate',
                      style: pw.TextStyle(fontSize: 10, color: subtitle),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // TITLE BAR
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColor.fromHex("#0E3B7D"),
                  PdfColor.fromHex("#2A65C2"),
                ],
                begin: pw.Alignment.centerLeft,
                end: pw.Alignment.centerRight,
              ),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            alignment: pw.Alignment.center,
            child: pw.Text(
              title.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),

          pw.SizedBox(height: 12),

          // TEST TABLE
          // --- TEST TABLE SECTION (Styled like UI) ---
          // Table Header
          // --- TEST TABLE SECTION (Styled like UI, with vertical borders) ---
          pw.Container(
            color: PdfColor.fromHex("#E9EDF5"),
            child: pw.Table(
              border: pw.TableBorder.all(color: borderGray, width: 0.6),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.6),
                3: const pw.FlexColumnWidth(3.5),
                4: const pw.FlexColumnWidth(1.2),
              },
              children: [
                // 🔹 Table Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex("#E9EDF5"),
                  ),
                  children: [
                    _pdfHeaderCell("Test", color: primaryBlue),
                    _pdfHeaderCell("Result", color: primaryBlue),
                    _pdfHeaderCell("Unit", color: primaryBlue),
                    _pdfHeaderCell("Ref. Range", color: primaryBlue),
                    _pdfHeaderCell("Status", color: primaryBlue),
                  ],
                ),
              ],
            ),
          ),

          // 🔹 Loop through test sections
          for (int j = 0; j < testTable.length; j++) ...[
            // 🟦 Subsection Title
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 4,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex("#D2E6FA"),
                border: pw.Border.all(color: borderGray, width: 0.6),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                testTable[j]['title'] ?? '',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ),

            // 🔹 Table Rows (with borders)
            pw.Table(
              border: pw.TableBorder.all(color: borderGray, width: 0.3),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.8),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(1.6),
                3: const pw.FlexColumnWidth(3.5),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                for (
                  int i = 0;
                  i < (testTable[j]['results'] as List).length;
                  i++
                )
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: i % 2 == 0
                          ? PdfColors.white
                          : PdfColor.fromHex("#F8F9FB"),
                    ),
                    children: [
                      _pdfCell(testTable[j]['results'][i]['Test']),
                      _pdfResultCell(
                        testTable[j]['results'][i]['Result'],
                        testTable[j]['results'][i]['Range'],
                      ),
                      _pdfCell(
                        (testTable[j]['results'][i]['Unit']?.isEmpty ?? true) ||
                                testTable[j]['results'][i]['Unit'] == 'N/A'
                            ? '-'
                            : testTable[j]['results'][i]['Unit'],
                        align: pw.Alignment.center,
                      ),
                      _pdfCell(testTable[j]['results'][i]['Range']),
                      _pdfCell(
                        _getResultStatus(
                          testTable[j]['results'][i]['Result'],
                          testTable[j]['results'][i]['Range'],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // pw.SizedBox(height: 8),
          ],

          // --- IMPRESSION SECTION ---
          pw.SizedBox(height: 18),
          pw.Text(
            "IMPRESSION",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 16,
              color: primaryBlue,
            ),
          ),
          pw.SizedBox(height: 6),

          for (int i = 0; i < testTable.length; i++) ...[
            pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex("#FAFAFA"),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: PdfColor.fromHex("#DDDDDD"),
                  width: 0.8,
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 🔹 Title (e.g., "Kidney Function Test :")
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      "${testTable[i]['title'] ?? '-'} : ",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: primaryBlue,
                      ),
                    ),
                  ),

                  // 🧠 Impression Text
                  pw.Expanded(
                    flex: 7,
                    child: pw.Text(
                      (testTable[i]['impression'] == null ||
                              testTable[i]['impression'].toString().isEmpty ||
                              testTable[i]['impression'] == 'N/A')
                          ? '-'
                          : testTable[i]['impression'],
                      style: const pw.TextStyle(
                        fontSize: 10.5,
                        color: PdfColors.black,
                        lineSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 24),
          // SIGNATURES
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text(
                    "Lab Technician",
                    style: pw.TextStyle(
                      color: primaryBlue,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 25),
                  pw.Text(
                    staffName,
                    style: pw.TextStyle(fontSize: 10, color: subtitle),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    "Doctor",
                    style: pw.TextStyle(
                      color: primaryBlue,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 25),
                  pw.Text(
                    doctorName,
                    style: pw.TextStyle(fontSize: 10, color: subtitle),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              "Generated by Ramchintech.com",
              style: pw.TextStyle(color: primaryBlue, fontSize: 9),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // --- PDF Header Cell ---
  pw.Widget _pdfHeaderCell(String text, {required PdfColor color}) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: color,
          fontSize: 10.5,
        ),
      ),
    );
  }

  // --- Generic Table Cell ---
  pw.Widget _pdfCell(
    String? text, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    final displayText = (text == null || text.isEmpty || text == 'N/A')
        ? '-'
        : text;
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        displayText,
        textAlign: align == pw.Alignment.center
            ? pw.TextAlign.center
            : pw.TextAlign.left,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  // --- Result Cell (color logic) ---
  pw.Widget _pdfResultCell(String? result, String? range) {
    final displayResult = (result == null || result.isEmpty || result == 'N/A')
        ? '-'
        : result;
    final color = _getResultColor(result, range);

    PdfColor pdfColor;
    if (color == Colors.red) {
      pdfColor = PdfColors.red;
    } else if (color == Colors.green) {
      pdfColor = PdfColors.green;
    } else if (color == Colors.orangeAccent) {
      pdfColor = PdfColors.orange;
    } else {
      pdfColor = PdfColors.black;
    }

    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        displayResult,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: pdfColor,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// --- UTILITIES ---
  static String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return '';
    try {
      final birth = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return "$age";
    } catch (_) {
      return '';
    }
  }

  Future<void> _viewPdf(BuildContext context) async {
    final pdf = await _generatePdf(context);
    await Printing.layoutPdf(onLayout: (_) async => pdf);
  }

  Future<void> _sharePdf(BuildContext context) async {
    final pdf = await _generatePdf(context);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/report-card.pdf');
    await file.writeAsBytes(pdf);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  /// --- UI ---
  @override
  Widget build(BuildContext context) {
    bool isViewing = false;
    bool isSharing = false;
    final patient = record['Patient'] ?? {};
    final hospital = record['Hospital'] ?? {};
    final title = mode == 0 ? record['title'] : 'Lab Test Report';

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Center(
            child: Text(
              hospital['name'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF0E3B7D),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Divider(color: Colors.grey.shade400, thickness: 1),

          /// PATIENT INFO
          if (patient.toString() != '{}' && hospital.toString() != '{}')
            _patientInfoSection(patient, hospital),
          const SizedBox(height: 4),

          /// TEST RESULTS
          _testResultsSection(title),

          const SizedBox(height: 20),

          /// IMPRESSION
          const Text(
            " IMPRESSION ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF0E3B7D),
            ),
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < testTable.length; i++) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  // spacing between sections
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${testTable[i]['title'] ?? '-'} : ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0E3B7D),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // 🧠 Impression
                      Expanded(
                        child: Text(
                          testTable[i]['impression'] ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 22),

          /// SIGNATURES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _signatureColumn("Lab Technician", staffName),
              _signatureColumn("Doctor", doctorName),
            ],
          ),

          const SizedBox(height: 24),

          /// ACTION BUTTONS
          showButtons == true
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // REPORTS BUTTON
                    StatefulBuilder(
                      builder: (context, setState) {
                        return ElevatedButton.icon(
                          onPressed: isViewing
                              ? null
                              : () async {
                                  setState(() => isViewing = true);
                                  await _viewPdf(context);
                                  setState(() => isViewing = false);
                                },
                          icon: isViewing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.white,
                                ),
                          label: Text(
                            isViewing ? "Loading..." : "Reports",
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // 👈 ADDED RADIUS
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 12),

                    // SHARE BUTTON
                    StatefulBuilder(
                      builder: (context, setState) {
                        return ElevatedButton.icon(
                          onPressed: isSharing
                              ? null
                              : () async {
                                  setState(() => isSharing = true);
                                  await _sharePdf(context);
                                  setState(() => isSharing = false);
                                },
                          icon: isSharing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.share, color: Colors.white),
                          label: Text(
                            isSharing ? "Sharing..." : "Share",
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // 👈 ADDED RADIUS
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                )
              : const SizedBox(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// --- PATIENT INFO SECTION ---
  Widget _patientInfoSection(
    Map<String, dynamic> patient,
    Map<String, dynamic> hospital,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 Gender Icon + Name + ID (First Row)
          Row(
            children: [
              Icon(
                (patient['gender'] ?? '').toString().toLowerCase() == 'male'
                    ? Icons.male
                    : Icons.female,
                color:
                    (patient['gender'] ?? '').toString().toLowerCase() == 'male'
                    ? Colors.blue
                    : Colors.pink,
                size: 30,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (patient['name'] ?? '').length > 10
                      ? '${patient['name'].substring(0, 10)}...'
                      : patient['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E3B7D),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record['patient_Id'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(thickness: 0.8, color: Colors.grey.shade500),
          const SizedBox(height: 2),

          // 📞 Cell No + 🎂 Age
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone, color: Color(0xFF0E3B7D), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    patient['phone'] ?? '-',
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.cake, color: Color(0xFF0E3B7D), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "${_calculateAge(patient['dob'])} yrs",
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 📍 Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Color(0xFF0E3B7D), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  patient['address']?['Address'] ?? '',
                  style: const TextStyle(fontSize: 13.5, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 📅 Date
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFF0E3B7D),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                record['createdAt'] ?? '',
                style: const TextStyle(fontSize: 13.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// --- TEST RESULTS SECTION ---
  /// --- TEST RESULTS SECTION ---
  Widget _testResultsSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔷 Section Title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0E3B7D), Color(0xFF345DA7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade200.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "$title Results".toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1.2),
                    blurRadius: 2,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 🔹 Table Header + Body
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade100,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade400, width: 1.2),
                  top: BorderSide(color: Colors.grey.shade400, width: 1.2),
                ),
              ),
              child: Row(
                children: [
                  // 1st column
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.2,
                          ),
                          left: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Test',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0E3B7D),
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  // 2nd column
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Result',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0E3B7D),
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  // 3rd column
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.2,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Text(
                        'Ref. Range',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0E3B7D),
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Table Data Sections
            for (int j = 0; j < testTable.length; j++) ...[
              // Subsection Title
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade100,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade400, width: 1.2),
                    right: BorderSide(color: Colors.grey.shade400, width: 1.2),
                    bottom: BorderSide(color: Colors.grey.shade400, width: 1.2),
                  ),
                ),
                child: Text(
                  testTable[j]['title'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),

              // Test Results Rows
              Table(
                border: TableBorder.all(color: Colors.grey.shade400, width: 1),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
                children: [
                  for (int i = 0; i < testTable[j]['results'].length; i++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: i % 2 == 0
                            ? Colors.grey.shade50
                            : Colors.grey.shade100,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            testTable[j]['results'][i]['Test'] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Builder(
                            builder: (_) {
                              final result =
                                  testTable[j]['results'][i]['Result']
                                      ?.toString()
                                      .trim() ??
                                  '';
                              final unit =
                                  testTable[j]['results'][i]['Unit']
                                      ?.toString()
                                      .trim() ??
                                  '';

                              // Hide unit if result is empty, '-', or N/A
                              final showUnit =
                                  result.isNotEmpty &&
                                  result != '-' &&
                                  result != 'N/A';
                              final displayText = showUnit
                                  ? '$result $unit'
                                  : (result.isEmpty ? '-' : result);

                              return Text(
                                displayText,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getResultColor(
                                    result,
                                    testTable[j]['results'][i]['Range'],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            testTable[j]['results'][i]['Range'] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _signatureColumn(String role, String? name) {
    return Column(
      children: [
        Text(
          role,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0E3B7D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name ?? '—', // fallback to dash if null
          style: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }
}
