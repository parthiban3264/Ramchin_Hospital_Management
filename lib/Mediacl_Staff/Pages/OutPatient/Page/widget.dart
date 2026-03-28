import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../Services/admin_service.dart';
import '../../Payment/PaymentPage.dart';

Future<Uint8List> fetchImageBytes(String imageUrl) async {
  try {
    final response = await http.get(
      Uri.parse(imageUrl),
      headers: {
        'User-Agent': 'Mozilla/5.0',
        // ❌ DO NOT set Accept-Encoding
      },
    );

    if (response.statusCode == 200 &&
        response.headers['content-type']?.startsWith('image/') == true) {
      return response.bodyBytes;
    }

    throw Exception('Invalid image response: ${response.statusCode}');
  } catch (e) {
    rethrow;
  }
}

String shortWardType(String? type) {
  if (type == null || type.isEmpty) return '';

  final t = type.trim();

  /// Take first 5 letters + dot
  return t.length > 5 ? '${t.substring(0, 5)}.' : '$t.';
}

List<Map<String, dynamic>> groupCharges(
  List<Map<String, dynamic>> items,
  Map<String, dynamic> fee,
  List<Map<String, dynamic>> loadStaff,
) {
  Map<String, List<Map<String, dynamic>>> grouped = {};

  for (var c in items) {
    final date = DateTime.parse((c['createdAt'] ?? c['chargeDate']).toString());

    final desc = (c['description'] ?? '').toString().toUpperCase();
    final admission = fee['Admission'];

    String name;

    if (desc == 'ROOM RENT') {
      final ward = getWardForCharge(admission, date);

      final type = shortWardType(ward?['type']);
      final bed = (ward?['bedNo'] ?? '').toString().trim();
      final wName = (ward?['name'] ?? '').toString().trim();

      /// 👉 FINAL NAME FORMAT
      name = '$wName - $type • $bed ';
    } else if (desc == 'DOCTOR FEE') {
      final staff = getStaffForCharge(admission, date);
      final doctorName = getStaffDisplayName(staff?['doctor'], loadStaff);

      /// 👉 ADD PREFIX (optional)
      name = doctorName.isNotEmpty ? 'Dr.$doctorName' : 'Doctor';
    } else if (desc == 'NURSE FEE') {
      final staff = getStaffForCharge(admission, date);
      final nurseName = getStaffDisplayName(staff?['nurse'], loadStaff);

      name = nurseName.isNotEmpty ? 'Nr.$nurseName' : 'Nurse';
    } else {
      name = (c['description'] ?? 'Charge').toString().trim();
    }

    final rate = num.tryParse(c['amount'].toString()) ?? 0;

    final key = '$name-$rate';

    grouped.putIfAbsent(key, () => []).add({
      ...c,
      'name': name,
      'rate': rate,
      'date': date,
    });
  }

  List<Map<String, dynamic>> result = [];

  for (var group in grouped.values) {
    group.sort((a, b) => a['date'].compareTo(b['date']));

    final start = group.first['date'];
    final end = group.last['date'];

    result.add({
      'name': group.first['name'],
      'rate': group.first['rate'],
      'days': group.length,
      'start': start,
      'end': end,
      'total': group.fold<num>(0, (s, e) => s + e['rate']),
    });
  }

  return result;
}

Future<pw.Document> buildPdf({
  required String logo,
  required String hospitalName,
  required String hospitalPlace,
  required Map<String, dynamic> fee,
  required PaperSizeType pageFormat,
  required TextEditingController nameController,
  required TextEditingController cellController,
  required TextEditingController dobController,
  required TextEditingController addressController,
  required List<Map<String, dynamic>> loadStaff,
}) async {
  final consultation = fee['Consultation'];
  final tokenNo = fee['Consultation']?['displayToken'];
  final bool isTestOnly = consultation?['isTestOnly'] ?? false;
  final referredDoctorName =
      consultation?['referredByDoctorName'].toString() ?? '-';

  final supplementary = fee['Supplementary'] ?? {};

  final admitId = fee['Admission']?['id'].toString() ?? '-';
  final bedNo = fee['Admission']?['bed']['bedNo'].toString() ?? '-';
  final wardName =
      '${fee['Admission']?['bed']['ward']['name']} - '
      '${fee['Admission']?['bed']['ward']['type']}';
  final wardNo = fee['Admission']?['bed']['ward']['id'].toString() ?? '-';
  final admitDate =
      fee['Admission']?['admitTime'].toString().split('T').first ?? '-';
  final dischargeDate =
      fee['Admission']?['dischargeTime'].toString().split('T').first ?? '-';

  final tokenText =
      (tokenNo == null ||
          tokenNo.toString().isEmpty ||
          tokenNo.toString() == '0')
      ? '-'
      : tokenNo.toString();

  pw.Widget dashDivider() => pw.LayoutBuilder(
    builder: (context, constraints) {
      final dashCount = (constraints!.maxWidth / 4).floor();
      return pw.Text('-' * dashCount, textAlign: pw.TextAlign.center);
    },
  );

  ///===========================charges ------------------------------------
  final admission = fee['Admission'];
  final charges = (admission?['charges'] ?? [])
      .where((c) => (c['status'] ?? '').toString().toUpperCase() == 'PAID')
      .toList()
      .cast<Map<String, dynamic>>();
  charges.sort((a, b) {
    DateTime parse(dynamic c) {
      final dateStr = c['chargeDate'] ?? c['createdAt'];
      return DateTime.tryParse(dateStr?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return parse(a).compareTo(parse(b));
  });

  String formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')} "
      "${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} "
      "${d.year}";

  const knownCharges = {'ROOM RENT', 'DOCTOR FEE', 'NURSE FEE'};

  Map<String, List<Map<String, dynamic>>> grouped = {
    'Room Rent': [],
    'Doctor Fee': [],
    'Nurse Fee': [],
    'Others': [],
  };
  String normalize(String s) {
    if (s == 'ROOM RENT') return 'Room Rent';
    if (s == 'DOCTOR FEE') return 'Doctor Fee';
    if (s == 'NURSE FEE') return 'Nurse Fee';
    return s;
  }

  for (final c in charges) {
    final desc = (c['description'] ?? '').toString().toUpperCase();

    // ⛔ Always skip advance fee
    if (desc == 'INPATIENT ADVANCE FEE') {
      continue;
    }

    if (knownCharges.contains(desc)) {
      grouped[normalize(desc)]!.add(c);
    } else {
      grouped['Others']!.add(c);
    }
  }
  final num advanceAmount = (admission?['charges'] ?? [])
      .where(
        (c) =>
            (c['status'] ?? '').toString().toUpperCase() == 'PAID' &&
            (c['description'] ?? '').toString().toUpperCase() ==
                'INPATIENT ADVANCE FEE' &&
            c['admissionId'] == fee['Admission']['id'],
      )
      .fold<num>(
        0,
        (num sum, dynamic c) =>
            sum + (num.tryParse(c['amount']?.toString() ?? '0') ?? 0),
      );

  final num chargePaidAmount = (admission?['charges'] ?? [])
      .where(
        (c) =>
            (c['status'] ?? '').toString().toUpperCase() == 'PAID' &&
            (c['description'] ?? '').toString().toUpperCase() !=
                'INPATIENT ADVANCE FEE' &&
            c['admissionId'] == fee['Admission']['id'],
      )
      .fold<num>(
        0,
        (num sum, dynamic c) =>
            sum + (num.tryParse(c['amount']?.toString() ?? '0') ?? 0),
      );
  final bool isDischarge = fee['type'] == 'DISCHARGEFEE';
  final num safeAdvance = advanceAmount;

  final num diff = chargePaidAmount - safeAdvance;

  final String label = isDischarge && diff < 0 ? 'Return ' : 'Total';

  final num displayAmount = isDischarge
      ? diff.abs()
      : FeesPaymentPageState.calculateTotal(fee['amount']);

  Map<String, List<Map<String, dynamic>>> groupByDate(List charges) {
    Map<String, List<Map<String, dynamic>>> dayWise = {};

    for (final c in charges) {
      // Skip advance fee
      if ((c['description'] ?? '').toString().toUpperCase() ==
          'INPATIENT ADVANCE FEE')
        continue;

      final date = c['createdAt'] ?? c['chargeDate'];
      if (date == null) continue;

      final day = DateTime.tryParse(date.toString());
      if (day == null) continue;

      final dateKey =
          "${day.day.toString().padLeft(2, '0')} "
          "${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][day.month - 1]} "
          "${day.year}";

      if (!dayWise.containsKey(dateKey)) {
        dayWise[dateKey] = [];
      }
      dayWise[dateKey]!.add(c);
    }

    return dayWise;
  }

  // In your widget
  final dayWiseCharges = groupByDate(charges);

  Map<String, List<Map<String, dynamic>>> _groupByCategory(
    List<Map<String, dynamic>> charges,
  ) {
    const knownCharges = {'ROOM RENT', 'DOCTOR FEE', 'NURSE FEE'};

    Map<String, List<Map<String, dynamic>>> grouped = {
      'Room Rent': [],
      'Doctor Fee': [],
      'Nurse Fee': [],
      'Others': [],
    };

    for (final c in charges) {
      final desc = (c['description'] ?? '').toString().toUpperCase();
      if (knownCharges.contains(desc)) {
        if (desc == 'ROOM RENT') grouped['Room Rent']!.add(c);
        if (desc == 'DOCTOR FEE') grouped['Doctor Fee']!.add(c);
        if (desc == 'NURSE FEE') grouped['Nurse Fee']!.add(c);
      } else {
        grouped['Others']!.add(c);
      }
    }

    return grouped;
  }

  final pdf = pw.Document();
  final blue = PdfColor.fromHex("#0A3D91");
  // final lightBlue = PdfColor.fromHex("#1E5CC4");

  // THERMAL PAGE FORMAT

  final double receiptWidth = pageFormat == PaperSizeType.a4
      ? PdfPageFormat.a4.availableWidth
      : 72 * PdfPageFormat.mm;
  // ~72mm
  //final pageHeight = 600 * PdfPageFormat.mm; // or 800

  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();

  // LOGO - Fixed version
  pw.Widget logoWidget = pw.SizedBox(width: 60, height: 60);
  if (logo.isNotEmpty) {
    try {
      final logoBytes = await fetchImageBytes(logo);
      final logoImage = pw.MemoryImage(logoBytes);
      logoWidget = pw.Center(
        child: pw.Image(
          logoImage,
          width: 60,
          height: 60,
          fit: pw.BoxFit.contain,
        ),
      );
    } catch (e) {
      // Fallback to placeholder text
      logoWidget = pw.Center(
        child: pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(
            color: blue,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Center(
            child: pw.Text(
              'LOGO',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
      );
    }
  }

  pdf.addPage(
    pw.Page(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),

      pageFormat: PdfPageFormat(
        receiptWidth,
        double.infinity,
        marginAll: 4 * PdfPageFormat.mm,
      ),
      // pageFormat: PdfPageFormat(
      //   receiptWidth,
      //   pageHeight,
      //   marginAll: 4 * PdfPageFormat.mm,
      // ),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // ---- Rounded Logo ----
                pw.Container(
                  width: 40,
                  height: 40,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(width: 1, color: PdfColors.grey400),
                  ),
                  child: pw.ClipOval(
                    child: logoWidget, // pw.Image(...)
                  ),
                  //child: pw.Container(width: 40, height: 40, child: logoWidget),
                ),

                pw.SizedBox(width: 4),

                // ---- Hospital Info ----
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        hospitalName.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),

                      if (hospitalPlace.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          hospitalPlace,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // LOGO

            // HOSPITAL DETAILS
            //pw.Divider(),
            dashDivider(),

            // PATIENT INFO
            pw.Text(
              "PATIENT INFO",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            dashDivider(),
            //pw.SizedBox(height: 3),
            if (fee['type'] != 'ADVANCEFEE' &&
                fee['type'] != 'DAILYTREATMENTFEE' &&
                fee['type'] != 'DISCHARGEFEE' &&
                fee['type'] != 'ROOMFEE') ...[
              //pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.white),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 10),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          "TOKEN NO : ",
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black,
                              width: 1.2,
                            ),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Text(
                            tokenText,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.white),
              children: [
                pw.TableRow(
                  children: [
                    pw.Text("Name :", style: pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      nameController.text,
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Text("PID :", style: pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      fee['Patient']['id'].toString(),
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Text("Phone :", style: pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      cellController.text,
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Text("Age :", style: pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      FeesPaymentPageState.calculateAge(dobController.text),
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text("Sex :", style: pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      fee['Patient']['gender'] ?? '-',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Text("Address : ", style: pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      addressController.text,
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                if (isTestOnly == true) ...[
                  pw.TableRow(
                    children: [
                      pw.Text(
                        "Referred Dr : ",
                        style: pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        referredDoctorName,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
                pw.TableRow(
                  children: [
                    pw.Text("Date :", style: pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      FeesPaymentPageState.getFormattedDate(
                        DateTime.now().toString(),
                      ),
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),

            if (fee['type'] == 'ADVANCEFEE' ||
                fee['type'] == 'DAILYTREATMENTFEE' ||
                fee['type'] == 'DISCHARGEFEE' ||
                fee['type'] == 'ROOMFEE') ...[
              //pw.Divider(),
              dashDivider(),

              pw.Text(
                "ADMISSION INFO",
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              dashDivider(),
              pw.SizedBox(height: 3),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.white),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text("Admit Id :", style: pw.TextStyle(fontSize: 9)),
                      pw.Text(admitId, style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Text("Ward Name :", style: pw.TextStyle(fontSize: 9)),
                      pw.Text(wardName, style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Text("Ward No :", style: pw.TextStyle(fontSize: 9)),
                      pw.Text(wardNo, style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Text("Bed No : ", style: pw.TextStyle(fontSize: 9)),
                      pw.Text(bedNo, style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Text(
                        "Admit date : ",
                        style: pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(admitDate, style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Text(
                        "Discharge date : ",
                        style: pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(dischargeDate, style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ],
            dashDivider(),

            // HEADLINE
            pw.Text(
              fee['reason'].toString().toUpperCase(),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 2),
            dashDivider(),

            // TABLE HEADER
            // if (fee['type'] != 'ADVANCEFEE' &&
            //     fee['type'] != 'DAILYTREATMENTFEE' &&
            //     fee['type'] != 'DISCHARGEFEE' &&
            //     fee['type'] != 'ROOMFEE') ...[
            //   pw.Row(
            //     children: [
            //       pw.Expanded(
            //         flex: 3,
            //         child: pw.Text(
            //           "SERVICE",
            //           style: pw.TextStyle(
            //             fontSize: 9,
            //             fontWeight: pw.FontWeight.bold,
            //           ),
            //         ),
            //       ),
            //       pw.Expanded(
            //         flex: 1,
            //         child: pw.Text(
            //           "AMT",
            //           textAlign: pw.TextAlign.right,
            //           style: pw.TextStyle(
            //             fontSize: 9,
            //             fontWeight: pw.FontWeight.bold,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            //   dashDivider(),
            // ],

            // FEE ROWS
            if (fee['type'] == 'REGISTRATIONFEE') ...[
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: buildFeeRows(
                  registrationFee: fee['Consultation']?['registrationFee'],
                  consultationFee:
                      fee['Consultation']?['consultationFee'] +
                      fee['Consultation']?['registrationFee'],
                  emergencyFee: fee['Consultation']?['emergencyFee'],
                  sugarTestFee: fee['Consultation']?['sugarTestFee'],
                ),
              ),
            ],
            if (fee['type'] == 'ADVANCEFEE') ...[
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: buildAdvancedFeeRows(advancedFee: fee['amount']),
              ),
            ],
            if (fee['type'] == 'SUPPLEMENTARYFEE') ...[
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: supplementary.expand<pw.TableRow>((item) {
                  return buildSupplementaryFeeRows(
                    description: item['description'] ?? '-',
                    amount: item['amount'] ?? 0,
                  );
                }).toList(),
              ),
            ],
            if (fee['type'] == 'DISCHARGEFEE') ...[
              () {
                final startDt = DateTime.tryParse(
                  fee['Admission']?['admitTime']?.toString() ?? '',
                );
                final endDt = DateTime.tryParse(
                  fee['Admission']?['dischargeTime']?.toString() ?? '',
                );

                String dateRange = '-';
                String dayCount = '';
                if (startDt != null && endDt != null) {
                  final months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec',
                  ];
                  if (startDt.month == endDt.month &&
                      startDt.year == endDt.year) {
                    dateRange =
                        "${startDt.day}–${endDt.day} ${months[startDt.month - 1]}";
                  } else {
                    dateRange =
                        "${startDt.day} ${months[startDt.month - 1]} – ${endDt.day} ${months[endDt.month - 1]}";
                  }
                  final diff = endDt.difference(startDt).inDays + 1;
                  dayCount = "($diff Days)";
                }

                final groupedByAll = _groupByCategory(charges);

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header: 20–24 Mar (5 Days)     12000
                    pw.Row(
                      children: [
                        pw.Text(
                          "$dateRange $dayCount",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Spacer(),
                        pw.Text(
                          "₹$chargePaidAmount",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    dashDivider(),

                    // Categories
                    if (groupedByAll['Room Rent']!.isNotEmpty) ...[
                      _groupedFeeRow(
                        'Room Rent',
                        groupedByAll['Room Rent']!,
                        fee,
                        loadStaff,
                      ),
                      // dashDivider(),
                      pw.SizedBox(height: 4),
                    ],
                    if (groupedByAll['Doctor Fee']!.isNotEmpty) ...[
                      _groupedFeeRow(
                        'Doctor Fee',
                        groupedByAll['Doctor Fee']!,
                        fee,
                        loadStaff,
                      ),
                      // dashDivider(),
                      pw.SizedBox(height: 4),
                    ],
                    if (groupedByAll['Nurse Fee']!.isNotEmpty) ...[
                      _groupedFeeRow(
                        'Nurse Fee',
                        groupedByAll['Nurse Fee']!,
                        fee,
                        loadStaff,
                      ),
                      // dashDivider(),
                      pw.SizedBox(height: 4),
                    ],
                    if (groupedByAll['Others']!.isNotEmpty) ...[
                      _groupedFeeRow(
                        'Others',
                        groupedByAll['Others']!,
                        fee,
                        loadStaff,
                      ),
                      pw.SizedBox(height: 4),
                      // dashDivider(),
                    ],
                    dashDivider(),
                    // GROSS TOTAL
                    pw.Row(
                      children: [
                        pw.Text(
                          "GROSS TOTAL",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Spacer(),
                        pw.Text(
                          "₹$chargePaidAmount",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }(),
            ],
            if (fee['type'] == 'DAILYTREATMENTFEE') ...[
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: dayWiseCharges.entries.map((entry) {
                  final grouped = _groupByCategory(entry.value);
                  final total =
                      [
                        ...grouped['Doctor Fee']!,
                        ...grouped['Nurse Fee']!,
                        ...grouped['Others']!,
                      ].fold<num>(
                        0,
                        (sum, c) =>
                            sum + (num.tryParse(c['amount'].toString()) ?? 0),
                      );
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Date Header
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 1),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              entry.key,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11,
                                color: PdfColors.black,
                              ),
                            ),
                            pw.Spacer(),
                            pw.Text(
                              '₹$total',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (grouped['Doctor Fee']!.isNotEmpty)
                        _groupedFeeRow(
                          'Doctor Fee',
                          grouped['Doctor Fee']!,
                          fee,
                          loadStaff,
                        ),
                      if (grouped['Nurse Fee']!.isNotEmpty)
                        _groupedFeeRow(
                          'Nurse Fee',
                          grouped['Nurse Fee']!,
                          fee,
                          loadStaff,
                        ),
                      if (grouped['Others']!.isNotEmpty)
                        _groupedFeeRow(
                          'Others',
                          grouped['Others']!,
                          fee,
                          loadStaff,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ],
            if (fee['type'] == 'ROOMFEE') ...[
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: dayWiseCharges.entries.map((entry) {
                  final grouped = _groupByCategory(entry.value);
                  final total = grouped['Room Rent']!.fold<num>(
                    0,
                    (sum, c) =>
                        sum + (num.tryParse(c['amount'].toString()) ?? 0),
                  );
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Date Header
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 1),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              entry.key,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11,
                                color: PdfColors.black,
                              ),
                            ),
                            pw.Spacer(),
                            pw.Text(
                              '₹$total',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Categories
                      if (grouped['Room Rent']!.isNotEmpty)
                        _groupedFeeRow(
                          'Room Rent',
                          grouped['Room Rent']!,
                          fee,
                          loadStaff,
                        ),
                      // if (grouped['Doctor Fee']!.isNotEmpty)
                      //   _groupedFeeRow(
                      //     'Doctor Fee',
                      //     grouped['Doctor Fee']!,
                      //     fee,
                      //     loadStaff,
                      //   ),
                      // if (grouped['Nurse Fee']!.isNotEmpty)
                      //   _groupedFeeRow(
                      //     'Nurse Fee',
                      //     grouped['Nurse Fee']!,
                      //     fee,
                      //     loadStaff,
                      //   ),
                      // if (grouped['Others']!.isNotEmpty)
                      //   _groupedFeeRow(
                      //     'Others',
                      //     grouped['Others']!,
                      //     fee,
                      //     loadStaff,
                      //   ),
                    ],
                  );
                }).toList(),
              ),
            ],

            // TESTS LIST
            if (fee['TestingAndScanningPatients'] != null)
              ...fee['TestingAndScanningPatients'].map<pw.Widget>((t) {
                final String title = t['title']?.toString() ?? '-';
                final num testAmount = t['amount'] ?? 0;
                final dynamic selectedOption = t['selectedOptionAmounts'];

                final List<pw.Widget> rows = [];

                // 🔹 Parent test title (bold)
                rows.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            title,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              testAmount > 0 ? "₹ $testAmount" : "",
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                bool hasOptions = false;

                // 🔹 CASE 1: Map options
                if (selectedOption is Map) {
                  selectedOption.forEach((key, value) {
                    final num amt = num.tryParse(value.toString()) ?? 0;
                    if (amt > 0) {
                      hasOptions = true;
                      rows.add(
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10, top: 2),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  key.toString(),
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Align(
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    "₹ $amt",
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  });
                }
                // 🔹 CASE 2: List options
                else if (selectedOption is List) {
                  for (final o in selectedOption) {
                    if (o is Map) {
                      final String name = o['name']?.toString() ?? '';
                      final num amt = o['amount'] ?? 0;

                      if (name.isNotEmpty && amt > 0) {
                        hasOptions = true;
                        rows.add(
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 10, top: 2),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    name,
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Text(
                                      "₹ $amt",
                                      style: const pw.TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }
                  }
                }

                // 🔹 CASE 3: No options → show total
                if (!hasOptions && testAmount > 0) {
                  rows.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, top: 2),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'Amount',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                "₹ $testAmount",
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 🔹 Space after each test
                rows.add(pw.SizedBox(height: 6));

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: rows,
                );
              }).toList(),
            if (fee['type'] == 'DISCHARGEFEE')
              pw.Column(
                children: [
                  if (advanceAmount > 0) ...[
                    //pw.Divider(thickness: 1.5, height: 6),
                    dashDivider(),
                    feeRowAdvance(title: 'Advance', amount: advanceAmount),
                  ],
                ],
              ),
            //pw.Divider(),
            dashDivider(),

            // TOTAL
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    '$label :',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Spacer(),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    // "₹${FeesPaymentPageState.calculateTotal(fee['amount'])}",
                    "₹$displayAmount",
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Text(
              "THANK YOU!",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            //pw.SizedBox(height: 2),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Container(
                margin: const pw.EdgeInsets.only(top: 5),
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                // decoration: const pw.BoxDecoration(
                //   border: pw.Border(
                //     top: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                //   ),
                // ),
                child: pw.Text(
                  "Powered by Ramchin Technologies Pvt Ltd",
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.black,
                    //fontWeight: pw.FontWeight.bold,
                    //letterSpacing: 0.5,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),

            pw.SizedBox(height: 10),
          ],
        );
      },
    ),
  );

  return pdf;
}

pw.Widget buildTokenBadge(String tokenText, PaperSizeType paperType) {
  final bool isA4 = paperType == PaperSizeType.a4;

  return pw.Container(
    padding: pw.EdgeInsets.symmetric(
      horizontal: isA4 ? 10 : 6,
      vertical: isA4 ? 4 : 4,
    ),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: isA4 ? 1.5 : 1),
      borderRadius: pw.BorderRadius.circular(isA4 ? 4 : 2),
    ),
    child: pw.Text(
      tokenText,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(
        fontSize: isA4 ? 11 : 8,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

// pw.Widget _groupedFeeRow(
//   String title,
//   List<Map<String, dynamic>> items,
//   Map<String, dynamic> fee,
//   List<Map<String, dynamic>> loadStaff,
// ) {
//   //print('items $items');
//   final total = items.fold<num>(
//     0,
//     (sum, c) => sum + (num.tryParse(c['amount'].toString()) ?? 0),
//   );
//
//   return pw.Padding(
//     padding: pw.EdgeInsets.symmetric(horizontal: 8),
//     child: pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         feeRowWithRemove(title: title, amount: total),
//
//         ...items.map((c) => _breakupRow(c, fee, loadStaff)),
//       ],
//     ),
//   );
// }

pw.Widget _groupedFeeRow(
  String title,
  List<Map<String, dynamic>> items,
  Map<String, dynamic> fee,
  List<Map<String, dynamic>> loadStaff,
) {
  final groupedItems = groupCharges(items, fee, loadStaff);
  print(groupedItems);

  final total = groupedItems.fold<num>(0, (sum, e) => sum + e['total']);

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        /// HEADER
        pw.Row(
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Spacer(),
            pw.Text(
              '₹$total',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 4),

        /// GROUPED ROWS
        ...groupedItems.map((g) {
          final start = g['start'];
          final end = g['end'];

          final dateText =
              '${start.day}${start.day != end.day ? ' – ${end.day}' : ''}';

          // return pw.Padding(
          //   padding: const pw.EdgeInsets.only(top: 1),
          //   child: pw.Row(
          //     children: [
          //       pw.Expanded(
          //         child: pw.Text(
          //           '($dateText) ${g['name']}       ${g['rate']} x${g['days']}',
          //           style: pw.TextStyle(fontSize: 8),
          //         ),
          //       ),
          //       pw.Text('₹${g['total']}', style: pw.TextStyle(fontSize: 8)),
          //     ],
          //   ),
          // );
          return pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, bottom: 4),
            child: pw.Row(
              children: [
                /// LEFT SIDE (Name + Date)
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    '${g['name']} ',
                    style: pw.TextStyle(fontSize: 7),
                    maxLines: 1,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    '( $dateText )',
                    style: pw.TextStyle(fontSize: 6),
                    maxLines: 1,
                  ),
                ),

                /// MIDDLE (Rate x Days)
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    '${g['rate']} x ${g['days']}',
                    style: pw.TextStyle(fontSize: 6),
                    textAlign: pw.TextAlign.right,
                  ),
                ),

                /// RIGHT (Total)
                pw.SizedBox(width: 12),

                pw.Text('₹${g['total']}', style: pw.TextStyle(fontSize: 7)),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

DateTime parseStaffDate(String value) {
  // Format: yyyy-MM-dd hh:mm a
  final parts = value.split(' ');
  final date = parts[0];
  final time = parts[1];
  final period = parts[2];

  final d = DateTime.parse(date);
  final t = time.split(':');

  int hour = int.parse(t[0]);
  final minute = int.parse(t[1]);

  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;

  return DateTime(d.year, d.month, d.day, hour, minute);
}

Map<String, dynamic>? getStaffForCharge(
  Map<String, dynamic> admission,
  DateTime chargeDate,
) {
  final List staffChanges = admission['staffChange'] ?? [];

  if (staffChanges.isEmpty) return null;

  // Sort by dateTime
  staffChanges.sort((a, b) {
    return parseStaffDate(
      a['dateTime'],
    ).compareTo(parseStaffDate(b['dateTime']));
  });

  Map<String, dynamic>? staff;

  for (final change in staffChanges) {
    final changeTime = parseStaffDate(change['dateTime']);
    if (!chargeDate.isBefore(changeTime)) {
      staff = change;
    }
  }

  return staff;
}

Map<String, dynamic>? getWardForCharge(
  Map<String, dynamic> admission,
  DateTime chargeDate,
) {
  final List wardChanges = admission['wardChange'] ?? [];

  // If no ward change → use current bed ward
  if (wardChanges.isEmpty) {
    return admission['bed']?['ward'];
  }

  // Sort ward changes by movedAt (ASC)
  wardChanges.sort((a, b) {
    return DateTime.parse(a['movedAt']).compareTo(DateTime.parse(b['movedAt']));
  });

  // 🔑 Initial ward = fromWard of first change
  Map<String, dynamic>? currentWard = {
    'name': wardChanges.first['fromWard']['wardName'],
    'type': admission['bed']?['ward']?['type'],
    'bedNo': admission['bed']?['bedNo'],
  };

  // Apply changes if chargeDate >= movedAt
  for (final change in wardChanges) {
    final movedAt = DateTime.parse(change['movedAt']);

    if (!chargeDate.isBefore(movedAt)) {
      currentWard = {
        'name': change['toWard']['wardName'],
        'type': admission['bed']?['ward']?['type'],
        'bedNo': admission['bed']?['bedNo'],
      };
    }
  }

  return currentWard;
}

// List<Map<String, dynamic>> allStaff = [];
//
// Future<void> loadStaff() async {
//   allStaff = List<Map<String, dynamic>>.from(
//     await AdminService().getMedicalStaff(),
//   );
// }

String getStaffDisplayName(
  String? userId,
  List<Map<String, dynamic>> allStaff,
) {
  if (userId == null || allStaff.isEmpty) return '';

  /// Find staff safely
  final staff = allStaff.firstWhere(
    (s) => (s['user_Id'] ?? '').toString() == userId.toString(),
    orElse: () => {},
  );

  if (staff.isEmpty) return '';

  final role = (staff['role'] ?? '').toString().toUpperCase();
  print('role $role');
  final name = (staff['name'] ?? '').toString().trim();
  final specialist = (staff['specialist'] ?? '').toString().trim();

  /// 👇 FINAL DISPLAY LOGIC
  switch (role) {
    case 'DOCTOR':
      return specialist.isNotEmpty
          ? name // or "$name ($specialist)" if needed
          : name;

    case 'NURSE':
      return name;

    default:
      return name;
  }
}

// pw.Widget _breakupRow(
//   Map<String, dynamic> charge,
//   Map<String, dynamic> fee,
//   loadStaff,
// ) {
//   final desc = (charge['description'] ?? '').toString().toUpperCase();
//   final admission = fee['Admission'];
//   // print('admission $admission');
//   // print('admission ${admission['staffChanges']}');
//
//   String title;
//
//   // ⏰ Charge date
//   final chargeDate = DateTime.parse(
//     (charge['createdAt'] ?? charge['chargeDate']).toString(),
//   );
//
//   /// ROOM RENT → resolve ward by date
//   if (desc == 'ROOM RENT') {
//     final ward = getWardForCharge(admission, chargeDate);
//     title =
//         '${ward?['name'] ?? 'Ward'} - ${ward?['type'] ?? ''} • ${ward?['bedNo'] ?? ''}'
//             .trim();
//   }
//   /// DOCTOR FEE
//   else if (desc == 'DOCTOR FEE') {
//     final staff = getStaffForCharge(admission, chargeDate);
//     title = getStaffDisplayName(staff?['doctor'], loadStaff);
//   } else if (desc == 'NURSE FEE') {
//     final staff = getStaffForCharge(admission, chargeDate);
//     title = getStaffDisplayName(staff?['nurse'], loadStaff);
//   }
//   /// OTHERS
//   else {
//     title = charge['description'] ?? 'Charge';
//   }
//
//   final num currentAmount =
//       num.tryParse(charge['amount']?.toString() ?? '0') ?? 0;
//   // Store original amount if not already stored
//   charge['originalAmount'] ??= currentAmount;
//   final num maxAmount = charge['originalAmount'];
//
//   return pw.Padding(
//     padding: pw.EdgeInsets.only(left: 8, bottom: 0, right: 8, top: 0),
//     child: pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       children: [
//         pw.Expanded(
//           flex: 3,
//           child: pw.Text(
//             '• $title',
//             style: pw.TextStyle(
//               fontSize: 7,
//               //overflow: TextOverflow.ellipsis,
//               color: PdfColors.black,
//               fontWeight: pw.FontWeight.bold,
//             ),
//           ),
//         ),
//         // Editable amount field for pending payments
//         pw.Text(
//           '₹${charge['amount']}',
//           style: const pw.TextStyle(fontSize: 7, color: PdfColors.black),
//         ),
//       ],
//     ),
//   );
// }

pw.Widget _breakupRow(
  Map<String, dynamic> charge,
  Map<String, dynamic> fee,
  loadStaff,
) {
  final desc = (charge['description'] ?? '').toString().toUpperCase();
  final admission = fee['Admission'];

  final chargeDate = DateTime.parse(
    (charge['createdAt'] ?? charge['chargeDate']).toString(),
  );

  String title;

  /// ROOM RENT
  if (desc == 'ROOM RENT') {
    final ward = getWardForCharge(admission, chargeDate);
    title = '${ward?['name'] ?? 'Room'} ${ward?['bedNo'] ?? ''}'.trim();
  }
  /// DOCTOR
  else if (desc == 'DOCTOR FEE') {
    final staff = getStaffForCharge(admission, chargeDate);
    title = getStaffDisplayName(staff?['doctor'], loadStaff);
  }
  /// NURSE
  else if (desc == 'NURSE FEE') {
    final staff = getStaffForCharge(admission, chargeDate);
    title = getStaffDisplayName(staff?['nurse'], loadStaff);
  } else {
    title = charge['description'] ?? 'Charge';
  }

  final num amount = num.tryParse(charge['amount']?.toString() ?? '0') ?? 0;

  /// 👉 NEW UI FORMAT (no logic change, just display)
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    child: pw.Row(
      children: [
        /// LEFT SIDE TEXT
        pw.Expanded(
          flex: 3,
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),

        /// RIGHT SIDE AMOUNT (aligned)
        pw.Text('₹$amount', style: pw.TextStyle(fontSize: 8)),
      ],
    ),
  );
}

pw.Widget feeRowAdvance({required String title, required num? amount}) {
  if (amount == null || amount == 0) return pw.SizedBox.shrink();

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 0),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        /// Amount Row (tap to edit)
        pw.Expanded(child: feeRow(title, amount)),
      ],
    ),
  );
}

pw.Widget feeRowWithRemove({required String title, required num? amount}) {
  if (amount == null || amount == 0) {
    return pw.SizedBox.shrink();
  }

  // return pw.Padding(
  //   padding: const pw.EdgeInsets.symmetric(vertical: 2),
  //   child: pw.Row(
  //     crossAxisAlignment: pw.CrossAxisAlignment.center,
  //     children: [pw.Expanded(child: feeRow(title, amount))],
  //   ),
  // );

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    child: pw.Row(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.Spacer(),
        pw.Text(
          '₹$amount',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}

pw.Widget feeRow(String title, num? amount, {bool isTotal = false}) {
  if (amount == null || amount == 0) {
    return pw.SizedBox.shrink();
  }

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: isTotal ? 9 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.bold,
              color: isTotal ? PdfColors.black : PdfColors.grey800,
            ),
          ),
        ),
        pw.Text(
          "₹${amount.toStringAsFixed(0)}",
          style: pw.TextStyle(
            fontSize: isTotal ? 9 : 10,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.bold,
            color: isTotal ? PdfColors.green700 : PdfColors.black,
          ),
        ),
      ],
    ),
  );
}

List<pw.TableRow> buildFeeRows({
  required num registrationFee,
  required num consultationFee,
  required num emergencyFee,
  required num sugarTestFee,
}) {
  final rows = <pw.TableRow>[];
  // 🔹 Section Header
  rows.add(
    pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6, bottom: 2, left: 8),
          child: pw.Text(
            "Bill Details",
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(),
      ],
    ),
  );
  void addRow(String title, num? amount) {
    if (amount == null || amount == 0) return;

    rows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "₹ ${amount.toStringAsFixed(0)}",
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Fee Rows
  //addRow("Registration Fee", registrationFee);
  addRow("Consultation Fee", consultationFee);
  addRow("Emergency Fee", emergencyFee);
  addRow("Sugar Test Fee", sugarTestFee);

  return rows;
}

List<pw.TableRow> buildAdvancedFeeRows({required num advancedFee}) {
  final rows = <pw.TableRow>[];

  void addRow(String title, num? amount) {
    if (amount == null || amount == 0) return;

    rows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey900),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "₹ ${amount.toStringAsFixed(0)}",
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Fee Rows
  //addRow("Registration Fee", registrationFee);
  addRow("Advance Fee", advancedFee);

  return rows;
}

List<pw.TableRow> buildSupplementaryFeeRows({
  required num amount,
  required String description,
}) {
  final rows = <pw.TableRow>[];

  void addRow(String title, num? amount) {
    if (amount == null || amount == 0) return;

    rows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey900),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "₹ ${amount.toStringAsFixed(0)}",
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Fee Rows
  //addRow("Registration Fee", registrationFee);
  addRow(description, amount);

  return rows;
}
