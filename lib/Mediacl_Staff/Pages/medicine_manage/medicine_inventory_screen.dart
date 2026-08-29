import 'package:flutter/material.dart';
import 'medicine_model.dart';
import 'add_medicine_sheet.dart';

class MedicineInventoryScreen extends StatefulWidget {
  const MedicineInventoryScreen({super.key});

  @override
  State<MedicineInventoryScreen> createState() => _MedicineInventoryScreenState();
}

class _MedicineInventoryScreenState extends State<MedicineInventoryScreen> {
  static const Color primary = Color(0xFF1A5276);
  static const Color bgColor = Color(0xFFF0F4F8);

  final TextEditingController _searchCtrl = TextEditingController();
  String _categoryFilter = '';
  String _statusFilter = '';
  String _sortCol = 'name';
  bool _sortAsc = true;
  final Set<int> _selected = {};

  // Sample data
  List<Medicine> medicines = [
    Medicine(id:1, name:'Paracetamol 500mg', category:'Tablet', genericName:'Acetaminophen', manufacturer:'Sun Pharma', batchNo:'BT24001', hsnCode:'30049099', location:'A-01', rxType:'OTC', quantity:250, unit:'Strips', reorderLevel:50, mfgDate:'2023-06', expiryDate:'2026-06', mrp:12.50, costPrice:8.00, gstPercent:12, supplierName:'MedDist Pvt Ltd', invoiceNo:'INV-001', purchaseDate:'2024-01-10'),
    Medicine(id:2, name:'Amoxicillin 250mg', category:'Capsule', genericName:'Amoxicillin', manufacturer:'Cipla', batchNo:'BT24002', location:'B-05', rxType:'Rx', quantity:30, unit:'Strips', reorderLevel:40, expiryDate:'2025-09', mrp:85.00, costPrice:60.00, gstPercent:12, discountPercent:5, supplierName:'PharmaCo Ltd', invoiceNo:'INV-002', notes:'Keep in cool place'),
    Medicine(id:3, name:'Cough Syrup 100ml', category:'Syrup', genericName:'Dextromethorphan', manufacturer:'Himalaya', batchNo:'BT24003', location:'C-02', rxType:'OTC', quantity:0, unit:'Bottles', reorderLevel:20, expiryDate:'2026-12', mrp:55.00, costPrice:35.00, gstPercent:5, supplierName:'MedDist Pvt Ltd'),
    Medicine(id:4, name:'Insulin Glargine', category:'Injection', genericName:'Insulin', manufacturer:'Novo Nordisk', batchNo:'BT24004', location:'FRIDGE-1', rxType:'Rx', quantity:12, unit:'Vials', reorderLevel:15, expiryDate:'2025-08', mrp:850.00, costPrice:700.00, gstPercent:12, supplierName:'SpecialMed', notes:'Refrigerate 2-8°C'),
    Medicine(id:5, name:'Betadine Ointment 15g', category:'Ointment', genericName:'Povidone-Iodine', manufacturer:'Win-Medicare', batchNo:'BT24005', location:'A-08', rxType:'OTC', quantity:95, unit:'Tubes', reorderLevel:25, expiryDate:'2027-03', mrp:45.00, costPrice:28.00, gstPercent:12, discountPercent:10),
    Medicine(id:6, name:'Metformin 500mg', category:'Tablet', genericName:'Metformin HCl', manufacturer:'USV Ltd', batchNo:'BT24006', location:'A-03', rxType:'Rx', quantity:8, unit:'Strips', reorderLevel:30, expiryDate:'2026-01', mrp:22.00, costPrice:14.00, gstPercent:12),
  ];

  List<Medicine> get filtered {
    String q = _searchCtrl.text.toLowerCase();
    List<Medicine> list = medicines.where((m) {
      bool matchQ = q.isEmpty || m.name.toLowerCase().contains(q) || m.batchNo.toLowerCase().contains(q) || m.genericName.toLowerCase().contains(q) || m.supplierName.toLowerCase().contains(q);
      bool matchCat = _categoryFilter.isEmpty || m.category == _categoryFilter;
      bool matchSt = _statusFilter.isEmpty || m.status == _statusFilter;
      return matchQ && matchCat && matchSt;
    }).toList();
    list.sort((a, b) {
      dynamic va, vb;
      switch (_sortCol) {
        case 'qty': va = a.quantity; vb = b.quantity; break;
        case 'mrp': va = a.mrp; vb = b.mrp; break;
        case 'expiry': va = a.expiryDate; vb = b.expiryDate; break;
        default: va = a.name; vb = b.name;
      }
      int cmp = va is String ? va.compareTo(vb) : (va as num).compareTo(vb as num);
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  void _openAddSheet([Medicine? m]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddMedicineSheet(
        medicine: m,
        onSave: (med) {
          setState(() {
            if (m != null) {
              final idx = medicines.indexWhere((x) => x.id == med.id);
              if (idx >= 0) medicines[idx] = med;
            } else {
              medicines.add(med);
            }
          });
          _showSnack(m == null ? 'Medicine added!' : 'Medicine updated!', Colors.green.shade700);
        },
      ),
    );
  }

  void _deleteMedicine(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => medicines.removeWhere((m) => m.id == id));
              Navigator.pop(context);
              _showSnack('Medicine deleted', Colors.red.shade700);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Delete ${_selected.length} selected medicines?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() { medicines.removeWhere((m) => _selected.contains(m.id)); _selected.clear(); });
              Navigator.pop(context);
              _showSnack('Deleted successfully', Colors.red.shade700);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final rows = filtered;
    final total = medicines.length;
    final inStock = medicines.where((m) => m.status == 'In Stock').length;
    final lowStock = medicines.where((m) => m.status == 'Low Stock').length;
    final outStock = medicines.where((m) => m.status == 'Out of Stock' || m.isExpired).length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.medication, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Medicine Inventory', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          if (_selected.isNotEmpty)
            TextButton.icon(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
              label: Text('Delete (${_selected.length})', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => setState(() {})),
        ],
      ),
      body: Column(
        children: [
          // STATS
          Container(
            color: primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Row(
              children: [
                _statCard('Total', total.toString(), Colors.white, const Color(0xFF1A5276)),
                _statCard('In Stock', inStock.toString(), const Color(0xFFD4EFDF), const Color(0xFF1E8449)),
                _statCard('Low Stock', lowStock.toString(), const Color(0xFFFDEBD0), const Color(0xFFA04000)),
                _statCard('Out/Expired', outStock.toString(), const Color(0xFFFADBD8), const Color(0xFF922B21)),
              ],
            ),
          ),

          // SEARCH & FILTER
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search name, batch, supplier...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primary)),
                    filled: true, fillColor: const Color(0xFFF7FAFC),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _searchCtrl.clear()))
                      : null,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _filterDropdown('Category', _categoryFilter, ['', 'Tablet', 'Capsule', 'Syrup', 'Injection', 'Ointment', 'Drops'], (v) => setState(() => _categoryFilter = v ?? ''))),
                    const SizedBox(width: 10),
                    Expanded(child: _filterDropdown('Status', _statusFilter, ['', 'In Stock', 'Low Stock', 'Out of Stock'], (v) => setState(() => _statusFilter = v ?? ''))),
                  ],
                ),
              ],
            ),
          ),

          // TABLE HEADER
          Container(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                SizedBox(width: 28, child: Checkbox(
                  value: _selected.length == medicines.length && medicines.isNotEmpty,
                  tristate: _selected.isNotEmpty && _selected.length < medicines.length,
                  onChanged: (v) => setState(() { if (v == true) _selected.addAll(medicines.map((m) => m.id)); else _selected.clear(); }),
                  activeColor: primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )),
                Expanded(flex: 3, child: _sortHeader('Medicine', 'name')),
                Expanded(flex: 2, child: _sortHeader('Category', 'cat')),
                Expanded(flex: 2, child: _sortHeader('Expiry', 'expiry')),
                Expanded(flex: 1, child: _sortHeader('Qty', 'qty')),
                Expanded(flex: 2, child: _sortHeader('MRP (₹)', 'mrp')),
                const SizedBox(width: 60, child: Center(child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4A5568))))),
                const SizedBox(width: 56),
              ],
            ),
          ),

          // TABLE ROWS
          Expanded(
            child: rows.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text('No medicines found', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                  ],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  itemCount: rows.length,
                  itemBuilder: (_, i) => _buildRow(rows[i]),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(),
        backgroundColor: primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Medicine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _statCard(String label, String val, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.75), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _sortHeader(String label, String col) {
    final active = _sortCol == col;
    return GestureDetector(
      onTap: () => setState(() { if (_sortCol == col) _sortAsc = !_sortAsc; else { _sortCol = col; _sortAsc = true; } }),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? primary : const Color(0xFF4A5568))),
          if (active) Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: primary),
        ],
      ),
    );
  }

  Widget _filterDropdown(String hint, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.isEmpty ? 'All $hint' : s, style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primary)),
        filled: true, fillColor: const Color(0xFFF7FAFC),
      ),
      style: const TextStyle(fontSize: 12, color: Colors.black87),
    );
  }

  Widget _buildRow(Medicine m) {
    final isSelected = _selected.contains(m.id);
    Color qtyColor = m.quantity == 0 ? Colors.red.shade700 : m.quantity <= m.reorderLevel ? Colors.orange.shade700 : Colors.green.shade700;
    Color expColor = m.isExpired ? Colors.red.shade700 : m.isExpiringSoon ? Colors.orange.shade700 : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEBF5FB) : Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: InkWell(
        onTap: () => _openAddSheet(m),
        onLongPress: () => setState(() => isSelected ? _selected.remove(m.id) : _selected.add(m.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(width: 28, child: Checkbox(
                value: isSelected,
                onChanged: (v) => setState(() => v! ? _selected.add(m.id) : _selected.remove(m.id)),
                activeColor: primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )),
              Expanded(flex: 3, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primary), overflow: TextOverflow.ellipsis),
                  if (m.genericName.isNotEmpty)
                    Text(m.genericName, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                  Text('Batch: ${m.batchNo}', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontFamily: 'monospace')),
                ],
              )),
              Expanded(flex: 2, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEAF0FB), borderRadius: BorderRadius.circular(4)),
                child: Text(m.category, style: const TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              )),
              Expanded(flex: 2, child: Text(
                m.expiryDate + (m.isExpired ? ' ⚠' : m.isExpiringSoon ? ' !' : ''),
                style: TextStyle(fontSize: 12, color: expColor, fontWeight: m.isExpired || m.isExpiringSoon ? FontWeight.w600 : FontWeight.normal),
              )),
              Expanded(flex: 1, child: Text(
                '${m.quantity}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: qtyColor),
              )),
              Expanded(flex: 2, child: Text('₹${m.mrp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              SizedBox(width: 60, child: _statusBadge(m.status)),
              SizedBox(width: 56, child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _openAddSheet(m),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: const Color(0xFFEAF0FB), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.edit, size: 15, color: primary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _deleteMedicine(m.id),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: const Color(0xFFFADBD8), borderRadius: BorderRadius.circular(6)),
                      child: Icon(Icons.delete_outline, size: 15, color: Colors.red.shade700),
                    ),
                  ),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg; Color fg;
    switch (status) {
      case 'In Stock': bg = const Color(0xFFD4EFDF); fg = const Color(0xFF1E8449); break;
      case 'Low Stock': bg = const Color(0xFFFDEBD0); fg = const Color(0xFFA04000); break;
      default: bg = const Color(0xFFFADBD8); fg = const Color(0xFF922B21);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
    );
  }
}
