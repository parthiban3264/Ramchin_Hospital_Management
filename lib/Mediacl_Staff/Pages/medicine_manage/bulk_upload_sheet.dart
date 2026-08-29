import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'medicine_model.dart';

// ─────────────────────────────────────────────────────────────
//  BulkUploadSheet
//  • Step 1 — Download a pre-filled template .xlsx
//  • Step 2 — Pick a filled .xlsx from device
//  • Step 3 — Preview rows (valid ✅ / errors ❌)
//  • Step 4 — Confirm import
// ─────────────────────────────────────────────────────────────
class BulkUploadSheet extends StatefulWidget {
  final void Function(List<Medicine>) onImport;
  const BulkUploadSheet({super.key, required this.onImport});

  @override
  State<BulkUploadSheet> createState() => _BulkUploadSheetState();
}

class _BulkUploadSheetState extends State<BulkUploadSheet>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ────────────────────────────────────────────
  static const Color primary = Color(0xFFBF955E);
  static const Color surface = Color(0xFFF8F9FB);
  static const Color cardBg = Colors.white;
  static const Color green = Color(0xFF1E8449);
  static const Color greenBg = Color(0xFFEAF7EE);
  static const Color red = Color(0xFF922B21);
  static const Color redBg = Color(0xFFFDF0EE);
  static const Color textMain = Color(0xFF1A202C);
  static const Color textSub = Color(0xFF718096);

  // ── State ────────────────────────────────────────────────────
  String _stage = 'idle'; // idle | loading | preview
  String? _fileName;
  List<_ParsedRow> _rows = [];
  bool _downloadingTemplate = false;

  List<_ParsedRow> get _valid => _rows.where((r) => r.errors.isEmpty).toList();
  List<_ParsedRow> get _invalid =>
      _rows.where((r) => r.errors.isNotEmpty).toList();

  // ── Column metadata ──────────────────────────────────────────
  static const _cols = [
    _Col('name', 'Medicine Name', 'Paracetamol 500mg', required: true),
    _Col('category', 'Category', 'Tablet / Capsule / Syrup'),
    _Col('genericName', 'Generic Name', 'Acetaminophen'),
    _Col('manufacturer', 'Manufacturer', 'Sun Pharma'),
    _Col('batchNo', 'Batch Number', 'BT2024001', required: true),
    _Col('hsnCode', 'HSN Code', '30049099'),
    _Col('location', 'Location', 'A-12 / FRIDGE-1'),
    _Col('rxType', 'Rx Type', 'OTC or Rx'),
    _Col('quantity', 'Quantity', '250'),
    _Col('unit', 'Unit', 'Strips / Bottles / Vials'),
    _Col('reorderLevel', 'Reorder Level', '10'),
    _Col('mfgDate', 'Mfg Date', '2023-06  (YYYY-MM)'),
    _Col('expiryDate', 'Expiry Date', '2026-12  (YYYY-MM)', required: true),
    _Col('mrp', 'MRP (₹)', '12.50', required: true),
    _Col('costPrice', 'Cost Price (₹)', '8.00'),
    _Col('gstPercent', 'GST %', '0 / 5 / 12 / 18 / 28'),
    _Col('discountPercent', 'Discount %', '5'),
    _Col('supplierName', 'Supplier Name', 'ABC Pharma'),
    _Col('invoiceNo', 'Invoice No', 'INV-2024-001'),
    _Col('purchaseDate', 'Purchase Date', '2024-01-10  (YYYY-MM-DD)'),
    _Col('notes', 'Notes', 'Refrigerate 2-8°C'),
  ];

  // ── Download template ────────────────────────────────────────
  Future<void> _downloadTemplate() async {
    setState(() => _downloadingTemplate = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Medicine Template'];
      excel.setDefaultSheet('Medicine Template');

      // Header row — bold gold background
      final headerStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#BF955E'),
        horizontalAlign: HorizontalAlign.Center,
      );

      for (int i = 0; i < _cols.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(_cols[i].key);
        cell.cellStyle = headerStyle;
        sheet.setColumnWidth(i, 22);
      }

      // Example row 1
      final eg1 = [
        'Paracetamol 500mg',
        'Tablet',
        'Acetaminophen',
        'Sun Pharma',
        'BT2024001',
        '30049099',
        'A-01',
        'OTC',
        '250',
        'Strips',
        '50',
        '2023-06',
        '2026-06',
        '12.50',
        '8.00',
        '12',
        '0',
        'MedDist Pvt Ltd',
        'INV-001',
        '2024-01-10',
        '',
      ];
      // Example row 2
      final eg2 = [
        'Amoxicillin 250mg',
        'Capsule',
        'Amoxicillin',
        'Cipla',
        'BT2024002',
        '',
        'B-05',
        'Rx',
        '30',
        'Strips',
        '40',
        '',
        '2025-09',
        '85.00',
        '60.00',
        '12',
        '5',
        'PharmaCo Ltd',
        'INV-002',
        '',
        'Keep in cool place',
      ];

      final rowStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FEF9F4'),
      );
      final altStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      for (int i = 0; i < eg1.length; i++) {
        final c1 = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
        );
        c1.value = TextCellValue(eg1[i]);
        c1.cellStyle = rowStyle;
        final c2 = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
        );
        c2.value = TextCellValue(eg2[i]);
        c2.cellStyle = altStyle;
      }

      // Save & share
      final bytes = excel.encode()!;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/medicine_template.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(
          file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ], subject: 'Medicine Bulk Upload Template');
    } catch (e) {
      _snack('Could not create template: $e', red);
    } finally {
      setState(() => _downloadingTemplate = false);
    }
  }

  // ── Pick & parse file ────────────────────────────────────────
  Future<void> _pickFile() async {
    setState(() => _stage = 'loading');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _stage = 'idle');
        return;
      }

      final file = result.files.first;
      _fileName = file.name;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;
      final allRows = sheet.rows;

      if (allRows.isEmpty) {
        _snack('Excel file is empty', red);
        setState(() => _stage = 'idle');
        return;
      }

      // Map header → column index (case-insensitive)
      final headerRow = allRows.first;
      final Map<String, int> colIdx = {};
      for (int i = 0; i < headerRow.length; i++) {
        final val = _str(headerRow[i]).toLowerCase().trim();
        for (final col in _cols) {
          if (val == col.key.toLowerCase()) colIdx[col.key] = i;
        }
      }

      String get(List<Data?> row, String key) {
        final idx = colIdx[key];
        if (idx == null || idx >= row.length) return '';
        return _str(row[idx]).trim();
      }

      final parsed = <_ParsedRow>[];
      for (int r = 1; r < allRows.length; r++) {
        final row = allRows[r];
        if (row.every((c) => _str(c).trim().isEmpty)) continue;

        final errors = <String>[];
        final name = get(row, 'name');
        final batchNo = get(row, 'batchNo');
        final expiry = get(row, 'expiryDate');
        final mrpStr = get(row, 'mrp');
        final rxType = get(row, 'rxType');

        if (name.isEmpty) errors.add('Name required');
        if (batchNo.isEmpty) errors.add('Batch No required');
        if (expiry.isEmpty) {
          errors.add('Expiry Date required');
        } else if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(expiry)) {
          errors.add('Expiry must be YYYY-MM');
        }
        final mrp = double.tryParse(mrpStr);
        if (mrpStr.isEmpty || mrp == null) errors.add('MRP must be a number');
        if (rxType.isNotEmpty && rxType != 'OTC' && rxType != 'Rx') {
          errors.add("rxType must be OTC or Rx");
        }

        parsed.add(
          _ParsedRow(
            rowNumber: r + 1,
            errors: errors,
            medicine: Medicine(
              id: DateTime.now().millisecondsSinceEpoch + r,
              name: name,
              category: get(row, 'category'),
              genericName: get(row, 'genericName'),
              manufacturer: get(row, 'manufacturer'),
              batchNo: batchNo,
              hsnCode: get(row, 'hsnCode'),
              location: get(row, 'location'),
              rxType: rxType.isEmpty ? 'OTC' : rxType,
              quantity: int.tryParse(get(row, 'quantity')) ?? 0,
              unit: get(row, 'unit').isEmpty ? 'Strips' : get(row, 'unit'),
              reorderLevel: int.tryParse(get(row, 'reorderLevel')) ?? 10,
              mfgDate: get(row, 'mfgDate'),
              expiryDate: expiry,
              mrp: mrp ?? 0,
              costPrice: double.tryParse(get(row, 'costPrice')) ?? 0,
              gstPercent: double.tryParse(get(row, 'gstPercent')) ?? 12,
              discountPercent:
                  double.tryParse(get(row, 'discountPercent')) ?? 0,
              supplierName: get(row, 'supplierName'),
              invoiceNo: get(row, 'invoiceNo'),
              purchaseDate: get(row, 'purchaseDate'),
              notes: get(row, 'notes'),
            ),
          ),
        );
      }

      setState(() {
        _rows = parsed;
        _stage = 'preview';
      });
    } catch (e) {
      _snack('Failed to read file: $e', red);
      setState(() => _stage = 'idle');
    }
  }

  String _str(Data? cell) => cell?.value?.toString() ?? '';

  void _confirmImport() {
    widget.onImport(_valid.map((r) => r.medicine).toList());
    Navigator.pop(context);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, ctrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Scaffold(
          backgroundColor: surface,
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _stage == 'loading'
                    ? _buildLoading()
                    : _stage == 'preview'
                    ? _buildPreview(ctrl)
                    : _buildIdle(ctrl),
              ),
              if (_stage == 'preview') _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFBF955E), Color(0xFFD4A96A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.table_chart_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bulk Upload',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _stage == 'preview'
                            ? 'Review & Import'
                            : 'Import via Excel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_stage == 'preview')
                    _headerChip(
                      '${_valid.length} ready',
                      Colors.white,
                      const Color(0xFF1E8449),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerChip(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ── Loading ──────────────────────────────────────────────────
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: primary, strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Reading your file…',
            style: TextStyle(color: textSub, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Idle screen ──────────────────────────────────────────────
  Widget _buildIdle(ScrollController ctrl) {
    return SingleChildScrollView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // How it works
          _sectionTitle('How it works'),
          const SizedBox(height: 12),
          _howItWorksRow(),
          const SizedBox(height: 24),

          // Action cards
          _sectionTitle('Get Started'),
          const SizedBox(height: 12),

          // Card 1 — Download template
          _actionCard(
            icon: Icons.download_rounded,
            iconBg: const Color(0xFFE8F4FD),
            iconColor: const Color(0xFF1A5276),
            badge: 'STEP 1',
            badgeColor: const Color(0xFF1A5276),
            title: 'Download Template',
            subtitle:
                'Get a pre-formatted .xlsx with sample data and all 21 columns ready to fill.',
            action: _downloadingTemplate
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Download',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A5276),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
          ),

          const SizedBox(height: 12),

          // Card 2 — Upload file
          _actionCard(
            icon: Icons.upload_file_rounded,
            iconBg: const Color(0xFFFEF3E2),
            iconColor: primary,
            badge: 'STEP 2',
            badgeColor: primary,
            title: 'Upload Your File',
            subtitle:
                'Select the filled .xlsx from your device. Column order doesn\'t matter — we detect by name.',
            action: ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(
                Icons.folder_open_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: const Text(
                'Choose File',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Column reference (collapsible feel — always shown)
          _sectionTitle('Column Reference'),
          const SizedBox(height: 2),
          Text(
            'Use these exact names as your header row',
            style: TextStyle(fontSize: 12, color: textSub),
          ),
          const SizedBox(height: 12),
          _columnTable(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: textMain,
      letterSpacing: 0.2,
    ),
  );

  Widget _howItWorksRow() {
    final steps = [
      ('⬇', 'Download\nTemplate'),
      ('✏️', 'Fill in\nMedicines'),
      ('⬆', 'Upload\n& Review'),
      ('✅', 'Confirm\nImport'),
    ];
    return Row(
      children: steps.asMap().entries.map((e) {
        final isLast = e.key == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          e.value.$1,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.value.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: textSub,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E0),
                  size: 18,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required Widget action,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textSub,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                action,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _columnTable() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Column Key',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSub,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    'Example',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSub,
                    ),
                  ),
                ),
                SizedBox(width: 32),
              ],
            ),
          ),
          ..._cols.asMap().entries.map((e) {
            final isLast = e.key == _cols.length - 1;
            return Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFF1F4F8)),
                      ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Text(
                          e.value.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        if (e.value.required)
                          const Text(
                            ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      e.value.example,
                      style: const TextStyle(fontSize: 11, color: textSub),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: e.value.required
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'REQ',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.red,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Preview screen ───────────────────────────────────────────
  Widget _buildPreview(ScrollController ctrl) {
    return SingleChildScrollView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File info + stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Color(0xFF276749),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fileName ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textMain,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_rows.length} data rows detected',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statPill(
                      '${_valid.length} Valid',
                      greenBg,
                      green,
                      Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(width: 10),
                    _statPill(
                      '${_invalid.length} Errors',
                      redBg,
                      red,
                      Icons.error_outline_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Valid rows
          if (_valid.isNotEmpty) ...[
            _previewSectionTitle(
              'Ready to Import',
              _valid.length,
              green,
              greenBg,
            ),
            const SizedBox(height: 8),
            ..._valid.map((r) => _rowTile(r)),
            const SizedBox(height: 16),
          ],

          // Invalid rows
          if (_invalid.isNotEmpty) ...[
            _previewSectionTitle(
              'Skipped — Fix & Re-upload',
              _invalid.length,
              red,
              redBg,
            ),
            const SizedBox(height: 8),
            ..._invalid.map((r) => _rowTile(r)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _statPill(String label, Color bg, Color fg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewSectionTitle(String label, int count, Color fg, Color bg) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF2F7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSub,
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowTile(_ParsedRow r) {
    final ok = r.errors.isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok ? const Color(0xFFC6F6D5) : const Color(0xFFFED7D7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Row number bubble
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: ok ? greenBg : redBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${r.rowNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ok ? green : red,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.medicine.name.isEmpty ? '(No name)' : r.medicine.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 3),
                  ok
                      ? Row(
                          children: [
                            _miniTag(
                              'Batch: ${r.medicine.batchNo}',
                              const Color(0xFFEBF8FF),
                              const Color(0xFF2B6CB0),
                            ),
                            const SizedBox(width: 6),
                            _miniTag(
                              'Exp: ${r.medicine.expiryDate}',
                              const Color(0xFFFFF5F5),
                              const Color(0xFF9B2335),
                            ),
                            const SizedBox(width: 6),
                            _miniTag(
                              '₹${r.medicine.mrp.toStringAsFixed(2)}',
                              const Color(0xFFF0FFF4),
                              green,
                            ),
                          ],
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: r.errors
                              .map((e) => _miniTag(e, redBg, red))
                              .toList(),
                        ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: ok ? green : red,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _stage = 'idle';
              _rows = [];
            }),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Re-upload'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              side: const BorderSide(color: Color(0xFFCBD5E0)),
              foregroundColor: textSub,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _valid.isEmpty ? null : _confirmImport,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Import ${_valid.length} Medicine${_valid.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data models ──────────────────────────────────────────────
class _ParsedRow {
  final int rowNumber;
  final Medicine medicine;
  final List<String> errors;
  const _ParsedRow({
    required this.rowNumber,
    required this.medicine,
    required this.errors,
  });
}

class _Col {
  final String key;
  final String label;
  final String example;
  final bool required;
  const _Col(this.key, this.label, this.example, {this.required = false});
}
