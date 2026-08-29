import 'package:flutter/material.dart';
import 'medicine_model.dart';

class AddMedicineSheet extends StatefulWidget {
  final Medicine? medicine;
  final void Function(Medicine) onSave;

  const AddMedicineSheet({super.key, this.medicine, required this.onSave});

  @override
  State<AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<AddMedicineSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameCtrl = TextEditingController();
  final _genericCtrl = TextEditingController();
  final _mfrCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _reorderCtrl = TextEditingController();
  final _mrpCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _discCtrl = TextEditingController();
  final _supCtrl = TextEditingController();
  final _invCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _category = '';
  String _unit = 'Strips';
  String _rxType = 'OTC';
  String _gst = '12';
  String _expiryDate = '';
  String _mfgDate = '';
  String _purchaseDate = '';

  final List<String> _categories = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Ointment', 'Drops', 'Powder', 'Cream'];
  final List<String> _units = ['Strips', 'Bottles', 'Vials', 'Tubes', 'Pcs', 'Boxes', 'Sachets', 'Ampoules'];
  final List<String> _gstOptions = ['0', '5', '12', '18', '28'];

  static const Color primary = Color(0xFF1A5276);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final m = widget.medicine;
    if (m != null) {
      _nameCtrl.text = m.name;
      _genericCtrl.text = m.genericName;
      _mfrCtrl.text = m.manufacturer;
      _batchCtrl.text = m.batchNo;
      _hsnCtrl.text = m.hsnCode;
      _locCtrl.text = m.location;
      _qtyCtrl.text = m.quantity.toString();
      _reorderCtrl.text = m.reorderLevel.toString();
      _mrpCtrl.text = m.mrp.toString();
      _costCtrl.text = m.costPrice.toString();
      _discCtrl.text = m.discountPercent.toString();
      _supCtrl.text = m.supplierName;
      _invCtrl.text = m.invoiceNo;
      _notesCtrl.text = m.notes;
      _category = m.category;
      _unit = m.unit;
      _rxType = m.rxType;
      _gst = m.gstPercent.toStringAsFixed(0);
      _expiryDate = m.expiryDate;
      _mfgDate = m.mfgDate;
      _purchaseDate = m.purchaseDate;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [_nameCtrl, _genericCtrl, _mfrCtrl, _batchCtrl, _hsnCtrl, _locCtrl, _qtyCtrl, _reorderCtrl, _mrpCtrl, _costCtrl, _discCtrl, _supCtrl, _invCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickMonth(bool isExpiry) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: isExpiry ? 'Select Expiry Month' : 'Select Mfg Month',
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final val = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      setState(() => isExpiry ? _expiryDate = val : _mfgDate = val);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Purchase Date',
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _purchaseDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      _tabController.animateTo(0);
      _showError('Medicine name is required');
      return;
    }
    if (_batchCtrl.text.trim().isEmpty) {
      _tabController.animateTo(0);
      _showError('Batch number is required');
      return;
    }
    if (_expiryDate.isEmpty) {
      _tabController.animateTo(1);
      _showError('Expiry date is required');
      return;
    }
    if (_mrpCtrl.text.trim().isEmpty || double.tryParse(_mrpCtrl.text) == null) {
      _tabController.animateTo(1);
      _showError('Valid MRP is required');
      return;
    }

    final m = Medicine(
      id: widget.medicine?.id ?? DateTime.now().millisecondsSinceEpoch,
      name: _nameCtrl.text.trim(),
      category: _category,
      genericName: _genericCtrl.text.trim(),
      manufacturer: _mfrCtrl.text.trim(),
      batchNo: _batchCtrl.text.trim(),
      hsnCode: _hsnCtrl.text.trim(),
      location: _locCtrl.text.trim(),
      rxType: _rxType,
      quantity: int.tryParse(_qtyCtrl.text) ?? 0,
      unit: _unit,
      reorderLevel: int.tryParse(_reorderCtrl.text) ?? 10,
      mfgDate: _mfgDate,
      expiryDate: _expiryDate,
      mrp: double.tryParse(_mrpCtrl.text) ?? 0,
      costPrice: double.tryParse(_costCtrl.text) ?? 0,
      gstPercent: double.tryParse(_gst) ?? 12,
      discountPercent: double.tryParse(_discCtrl.text) ?? 0,
      supplierName: _supCtrl.text.trim(),
      invoiceNo: _invCtrl.text.trim(),
      purchaseDate: _purchaseDate,
      notes: _notesCtrl.text.trim(),
    );
    widget.onSave(m);
    Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.medication, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.medicine == null ? 'Add New Medicine' : 'Edit Medicine',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '📋 Basic Info'),
                Tab(text: '📦 Stock & Price'),
                Tab(text: '🏢 Supplier'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfo(scrollCtrl),
                _buildStockPrice(scrollCtrl),
                _buildSupplier(scrollCtrl),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('✔  Save Medicine', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(ScrollController ctrl) {
    return SingleChildScrollView(
      controller: ctrl,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _field('Medicine Name *', _nameCtrl, hint: 'e.g. Paracetamol 500mg Tablet'),
          _field('Generic / Salt Name', _genericCtrl, hint: 'e.g. Acetaminophen'),
          _dropdown('Category *', _category, _categories, (v) => setState(() => _category = v!)),
          _field('Manufacturer', _mfrCtrl, hint: 'Company name'),
          _field('Batch Number *', _batchCtrl, hint: 'e.g. BT2024001'),
          _field('HSN Code', _hsnCtrl, hint: 'e.g. 30049099'),
          _field('Rack / Shelf Location', _locCtrl, hint: 'e.g. A-12, FRIDGE-1'),
          _dropdown('Prescription Required?', _rxType, ['OTC', 'Rx'],
            (v) => setState(() => _rxType = v!),
            displayItems: ['No — OTC', 'Yes — Rx (Prescription)'],
          ),
        ],
      ),
    );
  }

  Widget _buildStockPrice(ScrollController ctrl) {
    return SingleChildScrollView(
      controller: ctrl,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Stock Details'),
          Row(children: [
            Expanded(child: _field('Quantity *', _qtyCtrl, hint: '0', keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _dropdown('Unit', _unit, _units, (v) => setState(() => _unit = v!))),
          ]),
          Row(children: [
            Expanded(child: _field('Reorder Level', _reorderCtrl, hint: '10', keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _datePicker('Mfg Date', _mfgDate, () => _pickMonth(false))),
          ]),
          _datePicker('Expiry Date *', _expiryDate, () => _pickMonth(true)),
          _sectionTitle('Price Details'),
          Row(children: [
            Expanded(child: _field('MRP (₹) *', _mrpCtrl, hint: '0.00', keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field('Cost Price (₹)', _costCtrl, hint: '0.00', keyboard: TextInputType.number)),
          ]),
          Row(children: [
            Expanded(child: _dropdown('GST %', _gst, _gstOptions, (v) => setState(() => _gst = v!))),
            const SizedBox(width: 12),
            Expanded(child: _field('Discount %', _discCtrl, hint: '0', keyboard: TextInputType.number)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSupplier(ScrollController ctrl) {
    return SingleChildScrollView(
      controller: ctrl,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _field('Supplier / Distributor Name', _supCtrl, hint: 'e.g. ABC Pharma'),
          _field('Invoice Number', _invCtrl, hint: 'e.g. INV-2024-001'),
          _datePicker('Purchase Date', _purchaseDate, _pickDate, isFullDate: true),
          _field('Storage / Special Notes', _notesCtrl, hint: 'e.g. Refrigerate 2-8°C', maxLines: 3),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String hint = '', TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A5568), letterSpacing: 0.3)),
          const SizedBox(height: 5),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboard,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primary, width: 1.5)),
              filled: true, fillColor: Colors.white,
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, {List<String>? displayItems}) {
    final display = displayItems ?? items;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A5568), letterSpacing: 0.3)),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : null,
            hint: Text('-- Select --', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            items: List.generate(items.length, (i) => DropdownMenuItem(value: items[i], child: Text(display[i], style: const TextStyle(fontSize: 13)))),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primary, width: 1.5)),
              filled: true, fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePicker(String label, String value, VoidCallback onTap, {bool isFullDate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A5568), letterSpacing: 0.3)),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF1A5276)),
                  const SizedBox(width: 8),
                  Text(
                    value.isEmpty ? 'Select date' : value,
                    style: TextStyle(fontSize: 13, color: value.isEmpty ? Colors.grey.shade400 : Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary, letterSpacing: 0.5)),
          const Divider(color: Color(0xFFEAF0FB), thickness: 2, height: 8),
        ],
      ),
    );
  }
}
