import 'package:flutter/material.dart';

typedef OnAddTonic = void Function(List<Map<String, dynamic>> tonic);

class TonicCard extends StatefulWidget {
  final Color primaryColor;
  final OnAddTonic onAdd;
  final dynamic tonicService; // service with getAllTonics()
  final bool expanded;
  final VoidCallback onExpandToggle;
  final List<Map<String, dynamic>> allTonics;
  final bool tonicsLoaded;
  final List<Map<String, dynamic>> initialSavedTonics;

  const TonicCard({
    super.key,
    required this.primaryColor,
    required this.onAdd,
    required this.tonicService,
    required this.expanded,
    required this.onExpandToggle,
    required this.allTonics,
    required this.tonicsLoaded,
    required this.initialSavedTonics,
  });

  @override
  State<TonicCard> createState() => _TonicCardState();
}

class _TonicCardState extends State<TonicCard>
    with AutomaticKeepAliveClientMixin {
  OverlayEntry? _overlayEntry;
  int? _overlayIndex;

  final List<_TonicEntry> _tonicEntries = [];
  List<Map<String, dynamic>?> savedTonics = [];

  @override
  void initState() {
    super.initState();

    savedTonics = [...widget.initialSavedTonics];

    if (savedTonics.isNotEmpty) {
      for (var saved in widget.initialSavedTonics) {
        final entry = _TonicEntry(
          onFieldsChanged: () => _onTrySaveTonic(_tonicEntries.length - 1),
        );

        entry.currentTonic = {...saved};
        entry.nameController.text = saved['name'] ?? '';
        entry.selectedDose.text = saved['qtyPerDose'] ?? '';
        entry.selectedQty = saved['quantity']?.toString();

        _tonicEntries.add(entry);
        savedTonics.add(saved);
      }
    } else {
      _addNewEntry();
    }
  }

  @override
  void dispose() {
    for (var entry in _tonicEntries) {
      entry.dispose();
    }
    _removeOverlay();
    super.dispose();
  }

  // void _addNewEntry() {
  //   if (!widget.tonicsLoaded) return;
  //
  //   final newEntry = _TonicEntry(
  //     onFieldsChanged: () {
  //       _onTrySaveTonic(_tonicEntries.length - 1);
  //     },
  //   );
  //   newEntry.currentTonic['afterEat'] = true;
  //
  //   setState(() {
  //     _tonicEntries.add(newEntry);
  //     _savedTonics.add(null);
  //   });
  //
  //   Future.delayed(const Duration(milliseconds: 100), () {
  //     if (mounted) newEntry.focusNode.requestFocus();
  //   });
  // }

  void _addNewEntry() {
    final newEntry = _TonicEntry(
      onFieldsChanged: () => _onTrySaveTonic(_tonicEntries.length - 1),
    );
    newEntry.currentTonic['afterEat'] = true;
    newEntry.currentTonic['morning'] = true;
    newEntry.currentTonic['night'] = true;

    setState(() {
      _tonicEntries.add(newEntry);
      savedTonics.add(null);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) newEntry.focusNode.requestFocus();
    });
  }

  void _fetchSuggestions(String query, int index) {
    final input = query.trim().toLowerCase();

    if (input.isEmpty) {
      _removeOverlay();
      setState(() => _tonicEntries[index].suggestions.clear());
      return;
    }

    if (!widget.tonicsLoaded) return;

    final filtered = widget.allTonics
        .where(
          (t) =>
              (t['tonicName'] ?? '').toString().toLowerCase().contains(input),
        )
        .take(8)
        .toList();

    setState(() {
      _tonicEntries[index].suggestions = filtered;
    });

    if (_tonicEntries[index].fieldKey.currentContext == null) {
      _removeOverlay();
      return;
    }

    // Remove existing overlay first to avoid stacking overlays
    if (_overlayIndex == index) _removeOverlay();

    if (filtered.isNotEmpty) {
      _showOverlay(index);
    } else {
      _showNoSuggestionOverlay(index);
    }
  }

  void _selectSuggestion(Map<String, dynamic> tonic, int index) {
    setState(() {
      final entry = _tonicEntries[index];
      final oldDose = entry.selectedQty;
      entry.currentTonic['name'] = tonic['tonicName'] ?? '';
      entry.currentTonic['stock'] = tonic['stock'] ?? {};
      entry.currentTonic['amount'] = tonic['amount'] ?? {};

      entry.currentTonic['tonic_Id'] = tonic['id'] ?? '';
      entry.nameController.text = entry.currentTonic['name'];
      // entry.selectedDose.text =
      //     entry.currentTonic['qtyPerDose']?.toString() ?? "1";
      // Get available doses from new injection
      final doseOptions = entry.availableQtyOptions();

      // Restore old selected dose only if it's still valid
      if (doseOptions.contains(oldDose)) {
        entry.selectedQty = oldDose;
      } else {
        entry.selectedQty =
            null; // reset since new injection doesn't support old dose
      }
      entry.suggestions.clear();
      _removeOverlay();
    });
    _tonicEntries[index].triggerFieldsChanged();
  }

  void _showOverlay(int index) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final renderBox =
        _tonicEntries[index].fieldKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayIndex = index;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _removeOverlay(),
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 6,
              width: size.width,
              child: CompositedTransformFollower(
                link: _tonicEntries[index].layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 6),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(8),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _tonicEntries[index].suggestions.length,
                    itemBuilder: (_, i) {
                      final tonic = _tonicEntries[index].suggestions[i];
                      return ListTile(
                        leading: Icon(
                          Icons.local_drink,
                          color: widget.primaryColor,
                        ),
                        title: Text(tonic['tonicName'] ?? ''),
                        onTap: () => _selectSuggestion(tonic, index),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _showNoSuggestionOverlay(int index) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final renderBox =
        _tonicEntries[index].fieldKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayIndex = index;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _removeOverlay(),
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 6,
              width: size.width,
              child: CompositedTransformFollower(
                link: _tonicEntries[index].layerLink,
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
                      "No suggestion found",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayIndex = null;
  }

  Map<String, dynamic>? _buildIfValid(_TonicEntry entry) {
    final tonic = entry.currentTonic;
    final name = tonic['name']?.toString().trim() ?? '';
    final qty = entry.selectedQty;
    final Doase = entry.currentTonic['qtyPerDose'];
    if (name.isEmpty || qty == null) return null;

    final total = (tonic['amount']?[qty] ?? '0').toString();

    return {...tonic, 'quantity': qty, 'total': total, 'qtyPerDose': Doase};
  }

  // void _onTrySaveTonic(int index) {
  //   if (index >= _tonicEntries.length) return;
  //   final entry = _tonicEntries[index];
  //   final tonic = _buildIfValid(entry);
  //   setState(() {
  //     _savedTonics[index] = tonic;
  //   });
  //   widget.onAdd(_getNonNullTonics());
  // }

  void _onTrySaveTonic(int index) {
    if (index >= _tonicEntries.length) return;
    final entry = _tonicEntries[index];
    final toc = _buildIfValid(entry);
    setState(() {
      savedTonics[index] = toc;
    });
    widget.onAdd(_getNonNullTonics());
  }

  List<Map<String, dynamic>> _getNonNullTonics() =>
      savedTonics.whereType<Map<String, dynamic>>().toList();

  Future<void> _deleteTonicEntry(int index) async {
    final entry = _tonicEntries[index];
    final hasData =
        entry.nameController.text.trim().isNotEmpty ||
        entry.selectedQty != null ||
        entry.selectedDose.text.trim().isNotEmpty ||
        entry.currentTonic['morning'] == true ||
        entry.currentTonic['afternoon'] == true ||
        entry.currentTonic['night'] == true;

    if (!hasData) {
      _performDelete(index);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Tonic"),
        content: const Text("This tonic entry has data. Delete it anyway?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _performDelete(index);
    }
  }

  // void _performDelete(int index) {
  //   setState(() {
  //     _tonicEntries[index].dispose();
  //     _tonicEntries.removeAt(index);
  //     _savedTonics.removeAt(index);
  //   });
  //   widget.onAdd(_getNonNullTonics());
  // }
  void _performDelete(int index) {
    setState(() {
      _tonicEntries[index].dispose();
      _tonicEntries.removeAt(index);
      savedTonics.removeAt(index);
    });
    final updatedList = _getNonNullTonics();

    widget.onAdd(updatedList);

    if (mounted && widget.initialSavedTonics != updatedList) {
      widget.initialSavedTonics
        ..clear()
        ..addAll(updatedList);
    }
  }

  Widget _eatTypeToggleButton(_TonicEntry entry, int index) {
    final entry = _tonicEntries[index];
    final afterEat = entry.currentTonic['afterEat'] ?? true;
    final label = afterEat ? "AC" : "PC";
    final color = afterEat ? Colors.green : Colors.orangeAccent;

    return GestureDetector(
      onTap: () {
        setState(() {
          entry.currentTonic['afterEat'] = !afterEat;
        });
        entry.triggerFieldsChanged();
        _onTrySaveTonic(index);
      },
      child: SizedBox(
        width: 90,
        height: 60,
        child: Card(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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

  Widget _timeCheckbox(String label, String key, _TonicEntry entry, int index) {
    final entry = _tonicEntries[index];
    return Column(
      children: [
        Text(label),
        Checkbox(
          value: entry.currentTonic[key] ?? false,
          activeColor: widget.primaryColor,
          onChanged: (v) {
            setState(() {
              entry.currentTonic[key] = v ?? false;
            });
            entry.triggerFieldsChanged();
            _onTrySaveTonic(index);
          },
        ),
      ],
    );
  }

  Widget _buildTonicEntry(int index) {
    final entry = _tonicEntries[index];
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
                  flex: 7,
                  child: CompositedTransformTarget(
                    link: entry.layerLink,
                    child: TextField(
                      key: entry.fieldKey,
                      controller: entry.nameController,
                      focusNode: entry.focusNode,
                      decoration: InputDecoration(
                        labelText: "Tonic Name",
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.local_drink_outlined,
                          color: widget.primaryColor,
                        ),
                      ),

                      // onChanged: (v) {
                      //   _fetchSuggestions(v, index);
                      //   entry.currentTonic['name'] = v;
                      //   entry.triggerFieldsChanged();
                      // },
                      onChanged: (v) {
                        final oldDose = entry.selectedQty;
                        // Update name
                        entry.currentTonic['name'] = v;
                        _fetchSuggestions(v, index);

                        // If user clears or changes name → reset dependent fields
                        // setState(() {
                        //   entry.selectedQty = null;
                        // });
                        final doseOptions = entry.availableQtyOptions();
                        if (!doseOptions.contains(oldDose)) {
                          entry.selectedQty = null; // reset only if not valid
                        } else {
                          entry.selectedQty = oldDose; // keep old dose
                        }

                        entry.triggerFieldsChanged();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Qty (mL)",
                      border: OutlineInputBorder(),
                    ),
                    value: entry.selectedQty,
                    icon:
                        const SizedBox.shrink(), // 👈 Hides the dropdown arrow
                    items: entry
                        .availableQtyOptions()
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => entry.selectedQty = val);
                      entry.triggerFieldsChanged();
                      _onTrySaveTonic(index);
                    },
                  ),
                ),

                // Expanded(
                //   flex: 2,
                //   child: TextFormField(
                //     decoration: const InputDecoration(
                //       labelText: "Qty",
                //       border: OutlineInputBorder(),
                //     ),
                //     initialValue: entry.selectedQty,
                //     keyboardType: TextInputType.number,
                //     onChanged: (val) {
                //       setState(() => entry.selectedQty = val);
                //       entry.triggerFieldsChanged();
                //     },
                //   ),
                // ),
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTonicEntry(index),
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
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: entry.selectedDose,
                    decoration: const InputDecoration(
                      labelText: "Dose(ml)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      entry.currentTonic['qtyPerDose'] = double.tryParse(val);
                      entry.triggerFieldsChanged();
                      _onTrySaveTonic(index);
                    },
                  ),
                ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 5,
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
                      Icons.local_drink,
                      color: widget.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Add Tonic",
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
                for (int i = 0; i < _tonicEntries.length; i++)
                  _buildTonicEntry(i),
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

class _TonicEntry {
  final LayerLink layerLink = LayerLink();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController selectedDose = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final GlobalKey fieldKey = GlobalKey();
  List<Map<String, dynamic>> suggestions = [];
  String? selectedQty;

  Map<String, dynamic> currentTonic = {
    'name': '',
    'tonic_Id': '',
    'stock': <String, dynamic>{},
    'amount': <String, dynamic>{},
    'Dose': '',
    'afterEat': true,
    'morning': true,
    'afternoon': false,
    'night': true,
  };

  final VoidCallback? onFieldsChanged;
  _TonicEntry({this.onFieldsChanged});

  void triggerFieldsChanged() => onFieldsChanged?.call();

  List<String> availableQtyOptions() {
    final stockMap = currentTonic['stock'];
    if (stockMap is Map<String, dynamic>) {
      return stockMap.keys.map((e) => e.toString()).toList();
    }
    return [];
  }

  void dispose() {
    nameController.dispose();
    focusNode.dispose();
  }
}
