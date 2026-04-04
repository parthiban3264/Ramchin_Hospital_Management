import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef OnAddInjection = void Function(List<Map<String, dynamic>> injections);

class InjectionCard extends StatefulWidget {
  final Color primaryColor;
  final OnAddInjection onAdd;
  final dynamic injectionService; // must have getAllInjections()
  final bool expanded;
  final VoidCallback onExpandToggle;
  final List<Map<String, dynamic>> allInjection;
  final bool injectionsLoaded;
  final List<Map<String, dynamic>> initialSavedInjection;

  const InjectionCard({
    super.key,
    required this.primaryColor,
    required this.onAdd,
    required this.injectionService,
    required this.expanded,
    required this.onExpandToggle,
    required this.allInjection,
    required this.injectionsLoaded,
    required this.initialSavedInjection,
  });

  @override
  State<InjectionCard> createState() => _InjectionCardState();
}

class _InjectionCardState extends State<InjectionCard>
    with AutomaticKeepAliveClientMixin {
  OverlayEntry? _overlayEntry;
  int? _overlayIndex;

  List<_InjectionEntry> injectionEntries = [];
  List<Map<String, dynamic>?> savedInjections = [];

  bool isLoading = false;

  // @override
  // void initState() {
  //   super.initState();
  //   // _addNewEntry();
  //
  //   // savedInjections = widget.initialSavedInjection; // <-- ALWAYS mirror parent
  //   savedInjections = [...widget.initialSavedInjection];
  //
  //   if (savedInjections.isNotEmpty) {
  //     for (var saved in savedInjections) {
  //       final entry = _InjectionEntry(
  //         onFieldsChanged: () => _onTrySave(injectionEntries.length - 1),
  //       );
  //
  //       entry.currentInjection = {...?saved};
  //       entry.nameController.text = saved?['name'] ?? '';
  //       entry.selectedDose = saved?['quantity']; // restore dose
  //       entry.currentInjection['days'] = saved?['days'] ?? 0;
  //       injectionEntries.add(entry);
  //     }
  //   } else {
  //     _addNewEntry();
  //   }
  // }
  @override
  void initState() {
    super.initState();

    savedInjections = [...widget.initialSavedInjection];

    if (savedInjections.isNotEmpty) {
      for (var saved in savedInjections) {
        final index = injectionEntries.length; // FIXED

        final entry = _InjectionEntry(
          onFieldsChanged: () => _onTrySave(index), // FIXED
        );

        entry.currentInjection = {...?saved};
        entry.nameController.text = saved?['name'] ?? '';
        entry.selectedDose = saved?['quantity'];
        entry.currentInjection['days'] = saved?['days'] ?? 0;

        injectionEntries.add(entry);
      }
    } else {
      _addNewEntry();
    }
  }

  @override
  void dispose() {
    for (var entry in injectionEntries) {
      entry.dispose();
    }
    _removeOverlay();
    super.dispose();
  }

  // void _addNewEntry() {
  //   final newEntry = _InjectionEntry(
  //     onFieldsChanged: () => _onTrySave(injectionEntries.length - 1),
  //   );
  //   setState(() {
  //     injectionEntries.add(newEntry);
  //     savedInjections.add(null);
  //   });
  //
  //   Future.delayed(const Duration(milliseconds: 100), () {
  //     if (mounted) newEntry.focusNode.requestFocus();
  //   });
  // }

  void _addNewEntry() {
    final int index = injectionEntries.length; // FIXED INDEX CAPTURE

    final newEntry = _InjectionEntry(
      onFieldsChanged: () => _onTrySave(index), // FIXED
    );

    setState(() {
      injectionEntries.add(newEntry);
      savedInjections.add(null);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) newEntry.focusNode.requestFocus();
    });
  }

  Future<void> _deleteInjectionEntry(int index) async {
    final entry = injectionEntries[index];
    final inj = entry.currentInjection;

    final isEmpty =
        (inj['name'] ?? '').toString().trim().isEmpty &&
        entry.selectedDose == null;

    if (isEmpty) {
      _performDelete(index);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
          "Are you sure you want to delete this injection entry?",
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

    if (confirm == true && mounted) _performDelete(index);
  }

  // void _performDelete(int index) {
  //   setState(() {
  //     injectionEntries[index].dispose();
  //     injectionEntries.removeAt(index);
  //     savedInjections.removeAt(index);
  //   });
  //   widget.onAdd(_getNonNullInjections());
  // }
  void _performDelete(int index) {
    setState(() {
      injectionEntries[index].dispose();
      injectionEntries.removeAt(index);
      savedInjections.removeAt(
        index,
      ); // savedInjections == initialSavedInjection
    });

    final updatedList = _getNonNullInjections();

    widget.onAdd(updatedList); // update summary
  }

  void _filterSuggestions(String query, int index) {
    final input = query.trim().toLowerCase();

    if (input.isEmpty) {
      _removeOverlay();
      setState(() => injectionEntries[index].suggestions.clear());
      return;
    }

    if (!widget.injectionsLoaded) return;

    final results = widget.allInjection
        .where((inj) {
          final name = (inj['injectionName'] ?? inj['name'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(input);
        })
        .take(5)
        .toList();

    setState(() {
      injectionEntries[index].suggestions = results;
    });

    if (injectionEntries[index].fieldKey.currentContext == null) {
      _removeOverlay();
      return;
    }

    if (_overlayIndex == index) _removeOverlay();

    if (results.isNotEmpty) {
      _showOverlay(index);
    } else {
      _showNoSuggestionOverlay(index);
    }
  }

  // void _selectSuggestion(Map<String, dynamic> inj, int index) {
  //   setState(() {
  //     final entry = injectionEntries[index];
  //     entry.currentInjection['injection_id'] = inj['id'];
  //     entry.currentInjection['name'] =
  //         inj['injectionName'] ?? inj['name'] ?? '';
  //     entry.currentInjection['stock'] = inj['stock'] ?? {};
  //     entry.currentInjection['amount'] = inj['amount'] ?? {};
  //     entry.nameController.text = entry.currentInjection['name'];
  //     entry.suggestions.clear();
  //     _removeOverlay();
  //   });
  //   // _onTrySave();
  // }

  void _selectSuggestion(Map<String, dynamic> inj, int index) {
    setState(() {
      final entry = injectionEntries[index];

      // Store previous dose before replacing values
      final oldDose = entry.selectedDose;

      // Update injection info
      entry.currentInjection['injection_id'] = inj['id'];
      entry.currentInjection['name'] =
          inj['injectionName'] ?? inj['name'] ?? '';
      entry.currentInjection['stock'] = inj['stock'] ?? {};
      entry.currentInjection['amount'] = inj['amount'] ?? {};
      entry.nameController.text = entry.currentInjection['name'];
      entry.suggestions.clear();

      // Get available doses from new injection
      final doseOptions = entry.availableDoseOptions();

      // Restore old selected dose only if it's still valid
      if (doseOptions.contains(oldDose)) {
        entry.selectedDose = oldDose;
      } else {
        entry.selectedDose =
            null; // reset since new injection doesn't support old dose
      }

      _removeOverlay();
    });
    // injectionEntries[index].triggerFieldsChanged();
    widget.onAdd(_getNonNullInjections());
  }

  void _showOverlay(int index) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final renderBox =
        injectionEntries[index].fieldKey.currentContext?.findRenderObject()
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
                link: injectionEntries[index].layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 6),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(8),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: injectionEntries[index].suggestions.length,
                    itemBuilder: (_, i) {
                      final inj = injectionEntries[index].suggestions[i];
                      final price =
                          inj['amount']?.values.first ?? inj['price'] ?? 0;
                      return ListTile(
                        leading: Icon(
                          Icons.vaccines,
                          color: widget.primaryColor,
                        ),
                        title: Text(inj['injectionName'] ?? inj['name'] ?? ''),
                        trailing: Text("₹$price"),
                        onTap: () => _selectSuggestion(inj, index),
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
        injectionEntries[index].fieldKey.currentContext?.findRenderObject()
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
                link: injectionEntries[index].layerLink,
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

  Map<String, dynamic>? _buildIfValid(_InjectionEntry entry) {
    final inj = entry.currentInjection;
    final name = (inj['name'] ?? '').toString().trim();
    final dose = entry.selectedDose;
    if (name.isEmpty || dose == null) return null;

    final amount = (inj['amount']?[dose] ?? 0).toString();
    final days = inj['days'] ?? 0;

    return {
      ...inj,
      'injection_Id': inj['injection_id'] ?? '',
      'name': name,
      'quantity': dose,
      'total': amount,
      'days': days,
      'createdAt': DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now()),
    };
  }

  // void _onTrySave() {
  //   final validInjections = <Map<String, dynamic>>[];
  //   for (int i = 0; i < injectionEntries.length; i++) {
  //     final inj = _buildIfValid(injectionEntries[i]);
  //     savedInjections[i] = inj;
  //     if (inj != null) validInjections.add(inj);
  //   }
  //   widget.onAdd(validInjections);
  // }
  void _onTrySave(int index) {
    if (index >= injectionEntries.length) return;
    // final eny = injectionEntries[index].triggerFieldsChanged;
    final entry = injectionEntries[index];
    final inj = _buildIfValid(entry);

    setState(() {
      savedInjections[index] = inj; // savedInjections == initial list
    });

    widget.onAdd(_getNonNullInjections()); // tell parent summary to rebuild
  }

  List<Map<String, dynamic>> _getNonNullInjections() =>
      savedInjections.whereType<Map<String, dynamic>>().toList();

  Widget _buildInjectionEntry(int index) {
    final entry = injectionEntries[index];

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
                        labelText: "Injection Name",
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.vaccines_outlined,
                          color: widget.primaryColor,
                        ),
                      ),
                      // onChanged: (v) {
                      //   entry.currentInjection['name'] = v;
                      //   _filterSuggestions(v, index);
                      //   // _onTrySave();
                      // },
                      onChanged: (v) {
                        final oldDose = entry.selectedDose;

                        entry.currentInjection['name'] = v;
                        _filterSuggestions(v, index);

                        // preserve dose IF it is still valid in current stock
                        final doseOptions = entry.availableDoseOptions();
                        if (!doseOptions.contains(oldDose)) {
                          entry.selectedDose = null; // reset only if not valid
                        } else {
                          entry.selectedDose = oldDose; // keep old dose
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: entry.selectedDose,
                    decoration: const InputDecoration(
                      labelText: "Dose(mL)",
                      border: OutlineInputBorder(),
                    ),
                    icon:
                        const SizedBox.shrink(), // 👈 Hides the dropdown arrow
                    items: entry
                        .availableDoseOptions()
                        .map(
                          (dose) => DropdownMenuItem<String>(
                            value: dose,
                            child: Text(dose),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => entry.selectedDose = val);
                      _onTrySave(index);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Days",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      entry.currentInjection['days'] = int.tryParse(val) ?? 0;
                      _onTrySave(index);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _timeCheckbox("MN", 'morning', entry, index),
                    _timeCheckbox("AN", 'afternoon', entry, index),
                    _timeCheckbox("NT", 'night', entry, index),
                  ],
                ),
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteInjectionEntry(index),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeCheckbox(
    String label,
    String key,
    _InjectionEntry entry,
    int index,
  ) {
    final entry = injectionEntries[index];

    // ❗ Disable condition
    final days = entry.currentInjection['days']?.toString() ?? "";
    final isDisabled = days.isEmpty || days == "0";

    return Column(
      children: [
        Text(label),

        AbsorbPointer(
          absorbing: isDisabled, // <- disable tap when true
          child: Opacity(
            opacity: isDisabled ? 0.25 : 1.0, // <- visual feedback
            child: Checkbox(
              value: entry.currentInjection[key] ?? false,
              activeColor: widget.primaryColor,
              onChanged: (v) {
                setState(() {
                  entry.currentInjection[key] = v ?? false;
                });
                _onTrySave(index);
              },
            ),
          ),
        ),
      ],
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
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.onExpandToggle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.vaccines, color: widget.primaryColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      "Add Injection",
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
                isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        children: [
                          const SizedBox(height: 12),
                          for (int i = 0; i < injectionEntries.length; i++)
                            _buildInjectionEntry(i),
                          Center(
                            child: IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: Colors.blue,
                                size: 46,
                              ),
                              onPressed: _addNewEntry,
                            ),
                          ),
                        ],
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InjectionEntry {
  final LayerLink layerLink = LayerLink();

  final TextEditingController nameController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final GlobalKey fieldKey = GlobalKey();
  List<Map<String, dynamic>> suggestions = [];
  String? selectedDose;

  Map<String, dynamic> currentInjection = {
    'name': '',
    'stock': '',
    'amount': '',
    'days': 0,
    'morning': false,
    'afternoon': false,
    'night': false,
  };

  final VoidCallback? onFieldsChanged;

  _InjectionEntry({this.onFieldsChanged});

  void triggerFieldsChanged() => onFieldsChanged?.call();

  List<String> availableDoseOptions() {
    if (currentInjection['stock'] == null) return [];
    final stock = currentInjection['stock'];
    if (stock is Map<String, dynamic>) {
      return stock.keys.map((e) => e.toString()).toList();
    }
    return [];
  }

  void dispose() {
    nameController.dispose();
    focusNode.dispose();
  }
}
