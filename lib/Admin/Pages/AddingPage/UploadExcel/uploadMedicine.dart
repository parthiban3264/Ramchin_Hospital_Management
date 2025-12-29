import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../utils/utils.dart';

class UploadMedicine extends StatefulWidget {
  const UploadMedicine({super.key});

  @override
  State<UploadMedicine> createState() => _UploadMedicineState();
}

class _UploadMedicineState extends State<UploadMedicine> {
  File? selectedFile;
  bool isUploading = false;
  bool isDownloading = false;
  String message = '';

  /// PICK EXCEL FILE
  Future<void> pickExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xls', 'xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          selectedFile = File(result.files.single.path!);
          message = '';
        });
      }
    } catch (_) {
      setState(() {
        message = '❌ File picker not supported on this device';
      });
    }
  }

  /// UPLOAD EXCEL
  Future<void> uploadFile() async {
    if (selectedFile == null) {
      setState(() => message = 'Please select an Excel file');
      return;
    }

    setState(() {
      isUploading = true;
      message = '';
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/medicians/upload-excel'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', selectedFile!.path),
      );

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          message = '✅ Medicines uploaded successfully';
          selectedFile = null;
        });
      } else {
        setState(() {
          message = '❌ Upload failed (Server Error)';
        });
      }
    } catch (_) {
      setState(() {
        message = '❌ Upload failed. Please try again.';
      });
    } finally {
      setState(() => isUploading = false);
    }
  }

  /// DOWNLOAD EXCEL TEMPLATE
  Future<void> downloadTemplate() async {
    setState(() {
      isDownloading = true;
      message = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medicians/excel-template'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // final dir = await getApplicationDocumentsDirectory();
        final file = File(
          '/storage/emulated/0/Download/medicine_template.xlsx',
        );

        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          message = '📥 Template downloaded successfully';
        });
      } else {
        setState(() {
          message = '❌ Failed to download template';
        });
      }
    } catch (_) {
      setState(() {
        message = '❌ Download error';
      });
    } finally {
      setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Excel Import'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// UPLOAD CARD
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(Icons.file_upload, size: 70),
                    const SizedBox(height: 12),
                    Text(
                      selectedFile == null
                          ? 'No Excel file selected'
                          : selectedFile!.path.split('/').last,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: pickExcelFile,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Choose File'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isUploading ? null : uploadFile,
                            icon: isUploading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload),
                            label: const Text('Upload'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// DOWNLOAD TEMPLATE
            OutlinedButton.icon(
              onPressed: isDownloading ? null : downloadTemplate,
              icon: isDownloading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: const Text('Download Excel Template'),
            ),

            const SizedBox(height: 16),

            /// MESSAGE
            if (message.isNotEmpty)
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: message.contains('❌') ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const Spacer(),

            /// HELP TEXT
            const Text(
              '• Use the provided Excel template\n'
              '• Do not change column names\n'
              '• Date format: YYYY-MM-DD\n'
              '• Upload only .xls or .xlsx files',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
