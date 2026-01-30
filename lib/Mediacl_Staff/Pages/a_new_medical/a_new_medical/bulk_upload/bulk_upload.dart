import 'dart:async';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../Admin/Pages/admin_edit_profile_page.dart';
import '../../../../../Appbar/MobileAppbar.dart';
import '../medicines/widget/widget.dart';
import 'bulk_batch_upload.dart';
import 'bulk_medicine_upload.dart';

class BulkUploadPage extends StatefulWidget {
  const BulkUploadPage({super.key});

  @override
  State<BulkUploadPage> createState() => _BulkUploadPageState();
}

class _BulkUploadPageState extends State<BulkUploadPage> {
  bool isLoadingShop = true;

  String? hospitalId;
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  int selectedIndex = 0;

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

    setState(() => isLoadingShop = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: primaryColor),
      );
  }

  // ---------------- TEMPLATE DOWNLOAD ----------------

  Future<void> _downloadTemplate(String asset, String name) async {
    try {
      final data = await rootBundle.load(asset);
      await FileSaver.instance.saveFile(
        name: name,
        bytes: data.buffer.asUint8List(),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      _showMessage("Template downloaded successfully");
    } catch (e) {
      _showMessage("Download failed: $e");
    }
  }

  // ---------------- EXCEL PARSER (ONE SOURCE OF TRUTH) ----------------

  Future<List<Map<String, dynamic>>> parseExcelFromBytesBatch(
    Uint8List bytes,
  ) async {
    final excel = Excel.decodeBytes(bytes);
    final List<Map<String, dynamic>> rows = [];

    double toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;

    String formatDate(dynamic value) {
      if (value == null) return "";
      try {
        if (value is DateTime) {
          return value.toIso8601String().split('T')[0];
        } else if (value is double) {
          final d = DateTime(1899, 12, 30).add(Duration(days: value.toInt()));
          return d.toIso8601String().split('T')[0];
        }
        return DateTime.parse(value.toString()).toIso8601String().split('T')[0];
      } catch (_) {
        return "";
      }
    }

    for (final sheet in excel.tables.values) {
      for (final row in sheet.rows.skip(1)) {
        dynamic cell(int i) => i < row.length ? row[i]?.value : null;

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
          "Rate_per_quantity": toDouble(cell(9)),
          "GST": toDouble(cell(10)),
          "MRP": toDouble(cell(11)),
          "Profit": toDouble(cell(12)),
          "Supplier_id": cell(13),
          "Purchase_Date": formatDate(cell(14)),
        });
      }
    }

    return rows;
  }

  Future<List<Map<String, dynamic>>> parseExcelFromBytesMedicine(
    Uint8List bytes,
  ) async {
    final excel = Excel.decodeBytes(bytes);
    final List<Map<String, dynamic>> rows = [];

    double toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;

    int toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

    String formatDate(dynamic value) {
      if (value == null) return "";
      try {
        if (value is DateTime) {
          return value.toIso8601String().split('T')[0];
        } else if (value is double) {
          // Excel serial date
          final d = DateTime(1899, 12, 30).add(Duration(days: value.toInt()));
          return d.toIso8601String().split('T')[0];
        }
        return DateTime.parse(value.toString()).toIso8601String().split('T')[0];
      } catch (_) {
        return "";
      }
    }

    for (final sheet in excel.tables.values) {
      for (final row in sheet.rows.skip(1)) {
        dynamic cell(int i) => i < row.length ? row[i]?.value : null;

        rows.add({
          "MEDICINE_NAME": cell(0),
          "NDC_CODE": cell(1),
          "Category": cell(2),
          "Other_Category": cell(3),
          "Reorder": toInt(cell(4)),
          "Batch_no": cell(5),
          "Rack_no": cell(6),
          "HSN_code": cell(7),
          "EXP_Date": formatDate(cell(8)),
          "MFG_Date": formatDate(cell(9)),
          "Quantity": toInt(cell(10)),
          "Free_quantity": toInt(cell(11)),
          "Unit": cell(12),
          "Rate_per_quantity": toDouble(cell(13)),
          "GST": toDouble(cell(14)),
          "MRP": toDouble(cell(15)),
          "Profit": toDouble(cell(16)),
          "Supplier_id": cell(17),
          "Purchase_Date": formatDate(cell(18)),
        });
      }
    }

    return rows;
  }

  // ---------------- PICK & NAVIGATE ----------------

  Future<void> _pickExcelAndNavigateBatch({
    required Widget Function(List<Map<String, dynamic>> rows) builder,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true, // REQUIRED for web
      );

      if (result == null || result.files.single.bytes == null) {
        _showMessage("No file selected");
        return;
      }

      final rows = await parseExcelFromBytesBatch(result.files.single.bytes!);

      if (rows.isEmpty) {
        _showMessage("Excel file is empty");
        return;
      }

      if (!mounted) return;

      Navigator.push(context, MaterialPageRoute(builder: (_) => builder(rows)));
    } catch (e) {
      _showMessage("Failed to read Excel file");
    }
  }

  // Future<void> _pickExcelAndNavigateMedicine({
  //   required Widget Function(List<Map<String, dynamic>> rows) builder,
  // }) async {
  //   try {
  //     final result = await FilePicker.platform.pickFiles(
  //       type: FileType.custom,
  //       allowedExtensions: ['xlsx'],
  //       withData: true, // REQUIRED for web
  //     );
  //
  //     if (result == null || result.files.single.bytes == null) {
  //       _showMessage("No file selected");
  //       return;
  //     }
  //
  //     final rows = await parseExcelFromBytesMedicine(
  //       result.files.single.bytes!,
  //     );
  //
  //     if (rows.isEmpty) {
  //       _showMessage("Excel file is empty");
  //       return;
  //     }
  //
  //     if (!mounted) return;
  //
  //     Navigator.push(context, MaterialPageRoute(builder: (_) => builder(rows)));
  //   } catch (e) {
  //     _showMessage("Failed to read Excel file");
  //   }
  // }
  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: selectedIndex == 0
            ? 'Bulk Upload Batch'
            : 'Bulk Upload Medicine',
        pageContext: context,
        showBackButton: true,
        showNotificationIcon: true,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Colors.pink,
        onTap: (i) => setState(() => selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.batch_prediction),
            label: 'Batch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medicine',
          ),
        ],
      ),
      body: isLoadingShop
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: selectedIndex,
              children: [
                _buildTab(
                  download: () => _downloadTemplate(
                    'assets/medicine_batch.xlsx',
                    'medicine_batch',
                  ),
                  upload: () => _pickExcelAndNavigateBatch(
                    builder: (rows) => BulkBatchUpload(
                      batches: rows,
                      hospitalId: hospitalId!,
                      hospitalName: hospitalName!,
                      hospitalPhoto: hospitalPhoto!,
                    ),
                  ),
                ),
                // _buildTab(
                //   download: () =>
                //       _downloadTemplate('assets/medicine.xlsx', 'medicine'),
                //   upload: () => _pickExcelAndNavigateMedicine(
                //     builder: (rows) => BulkUploadMedicinePage(),
                //   ),
                // ),
                BulkUploadMedicinePage(),
              ],
            ),
    );
  }

  Widget _buildTab({
    required VoidCallback download,
    required VoidCallback upload,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          buildHospitalCard(
            hospitalName: hospitalName,
            hospitalPlace: hospitalPlace,
            hospitalPhoto: hospitalPhoto,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 220,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: download,
              icon: const Icon(Icons.download_rounded),
              label: const Text(
                "Download Template",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                elevation: 3,
                shadowColor: Colors.green.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: 180,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: upload,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text(
                "Upload Excel",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                elevation: 3,
                shadowColor: Colors.blue.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
