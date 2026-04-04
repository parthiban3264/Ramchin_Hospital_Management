import 'package:flutter/material.dart';
import '../../../../Services/Medicine_Service.dart';

typedef OnAddMedicine = void Function(List<Map<String, dynamic>> data);

class MedicineCard extends StatefulWidget {
  final Color primaryColor;
  final OnAddMedicine onAdd;
  final MedicineService medicineService;
  final List<Map<String, dynamic>> allMedicines;
  final bool expanded;
  final VoidCallback onExpandToggle;
  final bool medicinesLoaded;
  final List<Map<String, dynamic>> initialSavedMedicines;

  const MedicineCard({
    super.key,
    required this.primaryColor,
    required this.onAdd,
    required this.medicineService,
    required this.expanded,
    required this.onExpandToggle,
    required this.allMedicines,
    required this.medicinesLoaded,
    required this.initialSavedMedicines,
  });

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard>
    with AutomaticKeepAliveClientMixin {
  OverlayEntry? _overlayEntry;
  int? _overlayIndex;

  List<_MedicineEntry> medicineEntries = [];
  List<Map<String, dynamic>?> savedMedicines = [];

  @override
  void initState() {
    super.initState();
    // _addNewEntry();
    if (widget.initialSavedMedicines.isNotEmpty) {
      for (var saved in widget.initialSavedMedicines) {
        final entry = _MedicineEntry(
          onFieldsChanged: () => _onTrySaveCard(medicineEntries.length - 1),
        );

        entry.currentMedicine = {...saved};
        entry.medicineNameController.text = saved['name'] ?? '';
        entry.quantityController.text = saved['qtyPerDose']?.toString() ?? "1";

        medicineEntries.add(entry);
        savedMedicines.add(saved);
      }
    } else {
      _addNewEntry();
    }
  }

  @override
  void dispose() {
    for (var entry in medicineEntries) {
      entry.dispose();
    }
    _removeOverlay();
    super.dispose();
  }

  void _addNewEntry() {
    final newEntry = _MedicineEntry(
      onFieldsChanged: () => _onTrySaveCard(medicineEntries.length - 1),
    );
    newEntry.currentMedicine['afterEat'] = true;
    newEntry.currentMedicine['morning'] = true;
    newEntry.currentMedicine['night'] = true;

    setState(() {
      medicineEntries.add(newEntry);
      savedMedicines.add(null);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) newEntry.focusNode.requestFocus();
    });
  }

  Future<void> _deleteMedicineEntry(int index) async {
    final entry = medicineEntries[index];
    final med = entry.currentMedicine;

    final bool isEmpty =
        (med['name'] ?? '').toString().trim().isEmpty &&
        (entry.quantityController.text == '1' ||
            entry.quantityController.text.isEmpty) &&
        (med['days'] == 0 || med['days'] == null);

    if (isEmpty) {
      _performDelete(index);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
          "Are you sure you want to delete this medicine entry?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _performDelete(index);
    }
  }

  void _performDelete(int index) {
    setState(() {
      medicineEntries[index].dispose();
      medicineEntries.removeAt(index);
      savedMedicines.removeAt(index);
    });
    final updatedList = _getNonNullMedicines();

    widget.onAdd(updatedList);

    if (mounted && widget.initialSavedMedicines != updatedList) {
      widget.initialSavedMedicines
        ..clear()
        ..addAll(updatedList);
    }
  }

  void _fetchSuggestions(String query, int index) {
    final input = query.trim().toLowerCase();

    if (input.isEmpty) {
      if (_overlayIndex == index) _removeOverlay();
      setState(() => medicineEntries[index].suggestions = []);
      return;
    }

    if (!widget.medicinesLoaded) return;

    final filtered = widget.allMedicines.where((m) {
      final name = (m['medicianName'] ?? '').toString().toLowerCase();
      return name.contains(input);
    }).toList();

    filtered.sort((a, b) {
      final nameA = (a['medicianName'] ?? '').toString().toLowerCase();
      final nameB = (b['medicianName'] ?? '').toString().toLowerCase();

      int posA = nameA.indexOf(input);
      int posB = nameB.indexOf(input);

      if (posA != posB) return posA - posB;

      int countA = _countOccurrences(nameA, input);
      int countB = _countOccurrences(nameB, input);

      return countB - countA;
    });

    final results = filtered.take(5).toList();

    if (!mounted) return;

    setState(() {
      medicineEntries[index].suggestions = results;
    });

    if (medicineEntries[index].fieldKey.currentContext != null) {
      _removeOverlay();

      if (results.isNotEmpty) {
        _showOverlay(index);
      } else {
        _showNoSuggestionOverlay(index);
      }
    } else {
      if (_overlayIndex == index) _removeOverlay();
    }
  }

  int _countOccurrences(String string, String pattern) {
    int count = 0;
    int index = 0;
    while (true) {
      index = string.indexOf(pattern, index);
      if (index == -1) break;
      count++;
      index += pattern.length;
    }
    return count;
  }

  void _showOverlay(int index) {
    if (_overlayIndex == index && _overlayEntry != null) return;
    _removeOverlay();

    final overlay = Overlay.of(context);
    final renderBox =
        medicineEntries[index].fieldKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayIndex = index;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _removeOverlay(),
          child: Stack(
            children: [
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 6,
                width: size.width,
                child: CompositedTransformFollower(
                  link: medicineEntries[index]
                      .layerLink, // Use individual LayerLink
                  showWhenUnlinked: false,
                  offset: Offset(0, size.height + 6),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(8),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: medicineEntries[index].suggestions.length,
                      itemBuilder: (_, i) {
                        final med = medicineEntries[index].suggestions[i];
                        return ListTile(
                          leading: Icon(
                            Icons.medication,
                            color: widget.primaryColor,
                          ),
                          title: Text(med['medicianName'] ?? ''),
                          trailing: Text(
                            "₹${(med['price'] ?? med['amount'] ?? 0.0).toString()}",
                          ),
                          onTap: () => _selectSuggestion(med, index),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _showNoSuggestionOverlay(int index) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final renderBox =
        medicineEntries[index].fieldKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayIndex = index;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _removeOverlay(),
          child: Stack(
            children: [
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 6,
                width: size.width,
                child: CompositedTransformFollower(
                  link: medicineEntries[index]
                      .layerLink, // Use individual LayerLink
                  showWhenUnlinked: false,
                  offset: Offset(0, size.height + 6),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: const Text(
                        "No suggestion Found",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayIndex = null;
  }

  void _selectSuggestion(Map<String, dynamic> med, int index) {
    setState(() {
      final entry = medicineEntries[index];
      entry.currentMedicine['name'] = med['medicianName'] ?? '';
      entry.currentMedicine['price'] = (med['price'] ?? med['amount'] ?? 0.0)
          .toDouble();
      entry.currentMedicine['medicineId'] = med['id'] ?? '';
      entry.medicineNameController.text = entry.currentMedicine['name'];
      entry.suggestions.clear();
      _removeOverlay();
    });
    medicineEntries[index].triggerFieldsChanged();
  }

  double _parseQtyText(String text) {
    final t = text.trim();
    if (t.contains('/')) {
      final parts = t.split('/');
      if (parts.length == 2) {
        final num = double.tryParse(parts[0]) ?? 0.0;
        final den = double.tryParse(parts[1]) ?? 1.0;
        if (den != 0) return num / den;
      }
    }
    return double.tryParse(t) ?? 1.0;
  }

  int _dosesPerDay(Map<String, dynamic> med) =>
      ['morning', 'afternoon', 'night'].where((k) => med[k] == true).length;

  int _totalDays(Map<String, dynamic> med) =>
      (med['days'] ?? 0) + (med['weeks'] ?? 0) * 7 + (med['months'] ?? 0) * 30;

  bool _isCardValid(_MedicineEntry entry) {
    final med = entry.currentMedicine;
    final name = (med['name'] ?? '').toString().trim();
    final price = (med['price'] ?? 0.0) as double;
    final afterEat = med['afterEat'];
    final hasDose =
        med['morning'] == true ||
        med['afternoon'] == true ||
        med['night'] == true;
    final days = (med['days'] ?? 0) as int;
    return name.isNotEmpty &&
        price > 0 &&
        afterEat != null &&
        hasDose &&
        days > 0;
  }

  Map<String, dynamic>? _buildIfValid(_MedicineEntry entry) {
    if (!_isCardValid(entry)) return null;
    final med = entry.currentMedicine;
    final qtyPerDose = _parseQtyText(entry.quantityController.text);
    final dosesPerDay = _dosesPerDay(med);
    final days = _totalDays(med);
    final neededQuantity = qtyPerDose * dosesPerDay * (days > 0 ? days : 1);
    final tabletsToCharge = neededQuantity.ceil();
    final totalCost = tabletsToCharge * (med['price'] ?? 0.0);

    return {
      ...med,
      'qtyPerDose': qtyPerDose,
      'quantityNeeded': neededQuantity,
      'quantity': tabletsToCharge,
      'total': totalCost,
      'days': days,
    };
  }

  void _onTrySaveCard(int index) {
    if (index >= medicineEntries.length) return;
    final entry = medicineEntries[index];
    final med = _buildIfValid(entry);
    setState(() {
      savedMedicines[index] = med;
    });
    widget.onAdd(_getNonNullMedicines());
  }

  List<Map<String, dynamic>> _getNonNullMedicines() =>
      savedMedicines.whereType<Map<String, dynamic>>().toList();

  Widget _eatTypeToggleButton(_MedicineEntry entry, int index) {
    final entry = medicineEntries[index];
    bool afterEat = entry.currentMedicine['afterEat'] ?? true;
    String label = afterEat ? "AC" : "PC";
    Color color = afterEat ? Colors.green : Colors.orangeAccent;

    return GestureDetector(
      onTap: () {
        setState(() {
          entry.currentMedicine['afterEat'] = !afterEat;
        });
        entry.triggerFieldsChanged();
        _onTrySaveCard(index);
      },
      child: SizedBox(
        width: 90,
        height: 60,
        child: Card(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  afterEat ? Icons.fastfood : Icons.restaurant_menu,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeCheckbox(
    String label,
    String key,
    _MedicineEntry entry,
    int index,
  ) {
    final entry = medicineEntries[index];
    return Column(
      children: [
        Text(label),
        Checkbox(
          value: entry.currentMedicine[key] ?? false,
          activeColor: widget.primaryColor,
          onChanged: (v) {
            setState(() {
              entry.currentMedicine[key] = v ?? false;
            });
            entry.triggerFieldsChanged();
            _onTrySaveCard(index);
          },
        ),
      ],
    );
  }

  Widget _durationInput(
    String label,
    String key,
    _MedicineEntry entry,
    int index,
  ) {
    final entry = medicineEntries[index];
    return SizedBox(
      width: 80,
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        onChanged: (val) {
          setState(() {
            entry.currentMedicine[key] = int.tryParse(val) ?? 0;
          });
          entry.triggerFieldsChanged();
          _onTrySaveCard(index);
        },
      ),
    );
  }

  Widget _buildMedicineEntry(int index) {
    final entry = medicineEntries[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 8,
                  child: CompositedTransformTarget(
                    link: entry
                        .layerLink, // Use this card's individual LayerLink here
                    child: TextField(
                      key: entry.fieldKey,
                      controller: entry.medicineNameController,
                      focusNode: entry.focusNode,
                      decoration: InputDecoration(
                        labelText: "Medicine Name",
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.medication_outlined,
                          color: widget.primaryColor,
                        ),
                      ),
                      onChanged: (v) {
                        _fetchSuggestions(v, index);
                        entry.currentMedicine['name'] = v;
                        entry.triggerFieldsChanged();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: entry.quantityController,
                    decoration: const InputDecoration(
                      labelText: "Qty",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      entry.triggerFieldsChanged();
                      _onTrySaveCard(index);
                    },
                  ),
                ),
                if (index > 0)
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      //onPressed: () => _deleteMedicineEntry(index),
                      onPressed: () async {
                        await _deleteMedicineEntry(index);
                        // setState(() {
                        //   // DELETE FROM LOCAL LISTS
                        //   medicineEntries.removeAt(index);
                        //   savedMedicines.removeAt(index);
                        //
                        //   // RETURN UPDATED DATA TO PARENT → UPDATE SUMMARY
                        //   final updatedList = _getNonNullMedicines();
                        //   widget.onAdd(updatedList);
                        // });
                      },
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _eatTypeToggleButton(entry, index),
                _timeCheckbox("MN", 'morning', entry, index),
                _timeCheckbox("AN", 'afternoon', entry, index),
                _timeCheckbox("NT", 'night', entry, index),
                Expanded(
                  flex: 2,
                  child: _durationInput("Days", 'days', entry, index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Expanded(
                //   flex: 3,
                //   child: TextField(
                //     controller: entry.quantityController,
                //     decoration: const InputDecoration(
                //       labelText: "Qty",
                //       border: OutlineInputBorder(),
                //     ),
                //     keyboardType: TextInputType.text,
                //     onChanged: (v) {
                //       entry.triggerFieldsChanged();
                //       _onTrySaveCard(index);
                //     },
                //   ),
                // ),
                const SizedBox(width: 10),
                // Expanded(
                //   flex: 3,
                //   child: _durationInput("Days", 'days', entry, index),
                // ),
                // if (index > 0)
                //   IconButton(
                //     icon: const Icon(Icons.delete, color: Colors.red),
                //     // onPressed: () => _deleteMedicineEntry(index),
                //     onPressed: () {
                //       setState(() {
                //         // DELETE FROM LOCAL LISTS
                //         medicineEntries.removeAt(index);
                //         savedMedicines.removeAt(index);
                //
                //         // RETURN UPDATED DATA TO PARENT → UPDATE SUMMARY
                //         final updatedList = _getNonNullMedicines();
                //         widget.onAdd(updatedList);
                //       });
                //     },
                //   ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.onExpandToggle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication,
                      color: widget.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Add Medicine",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: widget.primaryColor,
                      ),
                    ),
                    Icon(
                      widget.expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: widget.primaryColor,
                    ),
                  ],
                ),
              ),
              if (widget.expanded) ...[
                const SizedBox(height: 12),
                for (int i = 0; i < medicineEntries.length; i++)
                  _buildMedicineEntry(i),
                Center(
                  child: IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.blue, size: 46),
                    onPressed: _addNewEntry,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineEntry {
  final LayerLink layerLink = LayerLink(); // Add individual LayerLink here

  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(
    text: "1",
  );
  final GlobalKey fieldKey = GlobalKey();
  final FocusNode focusNode = FocusNode();
  List<Map<String, dynamic>> suggestions = [];
  Map<String, dynamic> currentMedicine = {
    'name': '',
    'price': 0.0,
    'qtyPerDose': 1.0,
    'afterEat': true,
    'morning': true,
    'afternoon': false,
    'night': true,
    'days': 0,
    'weeks': 0,
    'months': 0,
    'total': 0.0,
  };

  final VoidCallback? onFieldsChanged;

  _MedicineEntry({this.onFieldsChanged});

  void triggerFieldsChanged() => onFieldsChanged?.call();

  void dispose() {
    medicineNameController.dispose();
    quantityController.dispose();
    focusNode.dispose();
  }
}
