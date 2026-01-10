import 'dart:async';
import 'dart:io';

import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Admin/Pages/AdminEditProfilePage.dart';
import '../../../../Appbar/MobileAppbar.dart';
import '../medicines/widget/widget.dart';
import 'bulk_batch_upload.dart';

class BulkUploadPage extends StatefulWidget {
  const BulkUploadPage({super.key});

  @override
  State<BulkUploadPage> createState() => _BulkUploadPageState();
}

class _BulkUploadPageState extends State<BulkUploadPage> {
  bool isLoadingShop = true;
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  String? hospitalId;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    hospitalId = prefs.getString('hospitalId');
    hospitalName = prefs.getString('hospitalName') ?? "Unknown";
    hospitalPlace = prefs.getString('hospitalPlace') ?? "Unknown";
    hospitalPhoto =
        prefs.getString('hospitalPhoto') ??
        "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    isLoadingShop = false;
    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // ✅ FIXED DOWNLOAD TEMPLATE (NO ERRORS)
  Future<void> _downloadTemplate() async {
    try {
      final data = await rootBundle.load('assets/medicine.xlsx');
      final bytes = data.buffer.asUint8List();

      final data1 = await FileSaver.instance.saveFile(
        name: 'medicine',
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      // print(data1);
      //I/flutter ( 1761): /storage/emulated/0/Android/data/com.example.hospitrax/files/medicine.xlsx
      _showMessage("Template downloaded successfully in $data1");
    } catch (e) {
      _showMessage("Download failed: $e");
    }
  }

  Future<List<Map<String, dynamic>>> parseExcel(File file) async {
    final bytes = await file.readAsBytes();
    final ex = excel.Excel.decodeBytes(bytes);

    List<Map<String, dynamic>> rows = [];

    double toTwoDecimals(dynamic value) {
      if (value == null) return 0.0;
      final v = double.tryParse(value.toString()) ?? 0.0;
      return double.parse(v.toStringAsFixed(2));
    }

    String formatDate(dynamic value) {
      if (value == null) return "";
      try {
        DateTime date;
        if (value is DateTime) {
          date = value;
        } else if (value is double) {
          date = DateTime(1899, 12, 30).add(Duration(days: value.toInt()));
        } else {
          date = DateTime.parse(value.toString());
        }
        return date.toIso8601String().split("T")[0];
      } catch (_) {
        return "";
      }
    }

    for (var sheet in ex.tables.values) {
      for (var row in sheet.rows.skip(1)) {
        dynamic cell(int index) =>
            index < row.length ? row[index]?.value : null;

        rows.add({
          "MEDICINE_ID": cell(0),
          "Batch_no": cell(1),
          "Rack_no": cell(2),
          "HSN_code": cell(3),
          "EXP_Date": formatDate(cell(4)),
          "MFG_Date": formatDate(cell(5)),
          "Quantity": cell(6),
          "Free_quantity": cell(7),
          "Unit": cell(8),
          "Rate_per_quantity": toTwoDecimals(cell(9)),
          "GST": toTwoDecimals(cell(10)),
          "MRP": toTwoDecimals(cell(11)),
          "Profit": toTwoDecimals(cell(12)),
          "Supplier_id": cell(13),
          "Purchase_Date": formatDate(cell(14)),
        });
      }
    }

    return rows;
  }

  Future<void> _pickExcelAndOpenUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.single.path == null) {
        _showMessage("No file selected");
        return;
      }

      final file = File(result.files.single.path!);
      final rows = await parseExcel(file);

      if (rows.isEmpty) {
        _showMessage("Excel file is empty");
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BulkBatchUpload(
            batches: rows,
            hospitalId: hospitalId!,
            hospitalName: hospitalName!,
            hospitalPhoto: hospitalPhoto!,
          ),
        ),
      );
    } catch (e) {
      _showMessage("Failed to read Excel: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Bulk Upload',
        pageContext: context,
        showBackButton: true,
        showNotificationIcon: true,
      ),
      body: isLoadingShop
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  buildHospitalCard(
                    hospitalName: hospitalName,
                    hospitalPlace: hospitalPlace,
                    hospitalPhoto: hospitalPhoto,
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.download),
                    label: const Text("Download Template"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(220, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _pickExcelAndOpenUpload,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Excel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(180, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
