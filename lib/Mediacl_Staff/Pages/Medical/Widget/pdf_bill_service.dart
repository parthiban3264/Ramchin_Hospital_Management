import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfBillService {
  static Future<void> pdfBill({
    required String patientName,
    required double totalAmount,
    required Map<String, dynamic> allConsultation,
    required List<dynamic> medicines,
    // required List<dynamic> tonics,
    // required List<dynamic> injections,
  }) async {
    final hospital = allConsultation['Hospital'] ?? {};
    final patient = allConsultation['Patient'] ?? {};

    final pdf = pw.Document();
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    /// -------- LOGO --------
    Uint8List? logo;
    if (hospital['photo'] != null &&
        hospital['photo'].toString().startsWith('http')) {
      final res = await http.get(Uri.parse(hospital['photo']));
      if (res.statusCode == 200) logo = res.bodyBytes;
    }

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              /// ================= HEADER =================
              pw.Row(
                children: [
                  if (logo != null)
                    pw.Container(
                      height: 65,
                      width: 100,
                      child: pw.Image(
                        pw.MemoryImage(logo),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        hospital['name']?.toUpperCase() ?? '',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        hospital['address'] ?? '',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Ph: ${hospital['phone'] ?? ''}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Divider(),

              /// ================= PATIENT =================
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.7),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    _infoRow(
                      'Patient',
                      patient['name'] ?? '',
                      'Gender',
                      patient['gender'] ?? '',
                    ),
                    pw.SizedBox(height: 4),
                    _infoRow(
                      'Patient ID',
                      '${patient['id'] ?? ''}',
                      'Phone',
                      patient['phone']?['mobile'] ?? '',
                    ),
                    pw.SizedBox(height: 4),
                    _infoRow(
                      'Date',
                      DateTime.now().toString().split(' ')[0],
                      'Doctor ID',
                      '${allConsultation['doctor_Id'] ?? ''}',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              /// ================= PRESCRIPTION =================
              pw.Text(
                'PRESCRIPTION',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(width: 0.6),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.6),
                  1: const pw.FlexColumnWidth(3.2),
                  2: const pw.FlexColumnWidth(0.9),
                  3: const pw.FlexColumnWidth(0.9),
                  4: const pw.FlexColumnWidth(0.9),
                  5: const pw.FlexColumnWidth(1.2),
                  6: const pw.FlexColumnWidth(0.9),
                  7: const pw.FlexColumnWidth(1.1),
                },
                children: [_tableHeader(), ..._rows(medicines)],
              ),

              pw.SizedBox(height: 20),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 10),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'TOTAL : ',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '₹${totalAmount.toStringAsFixed(1)}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Spacer(),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Doctor Signature',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 15),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Prescription_$patientName.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)]);
  }

  /// ================= TABLE =================

  static pw.TableRow _tableHeader() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        _cell('No', bold: true),
        _cell('Medicine', bold: true),
        _cell('M', bold: true),
        _cell('A', bold: true),
        _cell('N', bold: true),
        _cell('Food', bold: true),
        _cell('Days', bold: true),
        _cell('Amt', bold: true),
      ],
    );
  }

  static List<pw.TableRow> _rows(List medicines) {
    int i = 1;
    final rows = <pw.TableRow>[];

    String doseValue(bool time, String dose) => time ? dose : '0';

    /// MEDICINES
    for (var m in medicines) {
      if (m['selected'] == true) {
        final qty = '${m['quantity']}';
        rows.add(
          pw.TableRow(
            children: [
              _cell('${i++}'),
              _cell(m['Medician']?['medicianName'] ?? ''),
              _cell(doseValue(m['morning'] == true, qty)),
              _cell(doseValue(m['afternoon'] == true, qty)),
              _cell(doseValue(m['night'] == true, qty)),
              _cell(m['afterEat'] == true ? 'After' : 'Before'),
              _cell('${m['days'] ?? '-'}'),
              _cell('₹${m['total'] ?? 0}'),
            ],
          ),
        );
      }
    }

    /// TONICS
    // for (var t in tonics) {
    //   if (t['selected'] == true) {
    //     final dose = t['Doase'].toString().split('.')[0];
    //     rows.add(
    //       pw.TableRow(
    //         children: [
    //           _cell('${i++}'),
    //           _cell('${t['Tonic']?['tonicName']} (Tonic)'),
    //           _cell(doseValue(t['morning'] == true, '$dose ml')),
    //           _cell(doseValue(t['afternoon'] == true, '$dose ml')),
    //           _cell(doseValue(t['night'] == true, '$dose ml')),
    //           _cell('After'),
    //           _cell('${t['days'] ?? '-'}'),
    //           _cell('₹${t['total'] ?? 0}'),
    //         ],
    //       ),
    //     );
    //   }
    // }

    /// INJECTIONS
    // for (var inj in injections) {
    //   if (inj['selected'] == true) {
    //     final dose = '${inj['Doase']}';
    //     rows.add(
    //       pw.TableRow(
    //         children: [
    //           _cell('${i++}'),
    //           _cell('${inj['Injection']?['injectionName']} (Inj)'),
    //           _cell(doseValue(inj['morning'] == true, dose)),
    //           _cell(doseValue(inj['afternoon'] == true, dose)),
    //           _cell(doseValue(inj['night'] == true, dose)),
    //           _cell('After'),
    //           _cell('${inj['days'] ?? '-'}'),
    //           _cell('₹${inj['total'] ?? 0}'),
    //         ],
    //       ),
    //     );
    //   }
    // }

    return rows;
  }

  /// ================= HELPERS =================

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static pw.Widget _infoRow(String l1, String v1, String l2, String v2) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('$l1: $v1', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('$l2: $v2', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }
}
