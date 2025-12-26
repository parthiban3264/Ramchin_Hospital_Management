// // // // import 'package:flutter/material.dart';
// // // //
// // // // class RolePage extends StatelessWidget {
// // // //   final String role;
// // // //   final int hospitalId;
// // // //   final int userId;
// // // //
// // // //   const RolePage({
// // // //     super.key,
// // // //     required this.role,
// // // //     required this.hospitalId,
// // // //     required this.userId,
// // // //   });
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     String message;
// // // //
// // // //     if (role == "Admin") {
// // // //       message = "Welcome Admin!\nHospital ID: $hospitalId\nUser ID: $userId";
// // // //     } else {
// // // //       message =
// // // //           "Welcome $role!\nHospital ID: $hospitalId\nUser ID: $userId\nRole: $role";
// // // //     }
// // // //
// // // //     return Scaffold(
// // // //       appBar: AppBar(title: Text("$role Dashboard")),
// // // //       body: Center(
// // // //         child: Text(
// // // //           message,
// // // //           textAlign: TextAlign.center,
// // // //           style: const TextStyle(fontSize: 20),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // //
// // //
// // // import 'package:flutter/material.dart';
// // // import '../../../../Services/Medicine_Service.dart';
// // //
// // // typedef OnAddMedicine = void Function(List<Map<String, dynamic>> data);
// // //
// // // class MedicineCard extends StatefulWidget {
// // //   final Color primaryColor;
// // //   final OnAddMedicine onAdd;
// // //   final MedicineService medicineService;
// // //   final List<Map<String, dynamic>> allMedicines;
// // //   final bool expanded;
// // //   final VoidCallback onExpandToggle;
// // //   final bool medicinesLoaded;
// // //
// // //   const MedicineCard({
// // //     Key? key,
// // //     required this.primaryColor,
// // //     required this.onAdd,
// // //     required this.medicineService,
// // //     required this.expanded,
// // //     required this.onExpandToggle,
// // //     required this.allMedicines,
// // //     required this.medicinesLoaded,
// // //   }) : super(key: key);
// // //
// // //   @override
// // //   State<MedicineCard> createState() => _MedicineCardState();
// // // }
// // //
// // // class _MedicineCardState extends State<MedicineCard> {
// // //   OverlayEntry? _overlayEntry;
// // //   int? _overlayIndex;
// // //
// // //   List<_MedicineEntry> medicineEntries = [];
// // //   List<Map<String, dynamic>?> savedMedicines = [];
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _addNewEntry();
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     for (var entry in medicineEntries) {
// // //       entry.dispose();
// // //     }
// // //     _removeOverlay();
// // //     super.dispose();
// // //   }
// // //
// // //   void _addNewEntry() {
// // //     final newEntry = _MedicineEntry(
// // //       onFieldsChanged: () => _onTrySaveCard(medicineEntries.length - 1),
// // //     );
// // //     newEntry.currentMedicine['afterEat'] = true;
// // //     newEntry.currentMedicine['morning'] = true;
// // //     newEntry.currentMedicine['night'] = true;
// // //
// // //     setState(() {
// // //       medicineEntries.add(newEntry);
// // //       savedMedicines.add(null);
// // //     });
// // //
// // //     Future.delayed(const Duration(milliseconds: 100), () {
// // //       if (mounted) newEntry.focusNode.requestFocus();
// // //     });
// // //   }
// // //
// // //   Future<void> _deleteMedicineEntry(int index) async {
// // //     final entry = medicineEntries[index];
// // //     final med = entry.currentMedicine;
// // //
// // //     final bool isEmpty =
// // //         (med['name'] ?? '').toString().trim().isEmpty &&
// // //             (entry.quantityController.text == '1' ||
// // //                 entry.quantityController.text.isEmpty) &&
// // //             (med['days'] == 0 || med['days'] == null);
// // //
// // //     if (isEmpty) {
// // //       _performDelete(index);
// // //       return;
// // //     }
// // //
// // //     final confirm = await showDialog<bool>(
// // //       context: context,
// // //       builder: (ctx) => AlertDialog(
// // //         title: const Text("Confirm Delete"),
// // //         content: const Text(
// // //           "Are you sure you want to delete this medicine entry?",
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(ctx, false),
// // //             child: const Text("Cancel"),
// // //           ),
// // //           ElevatedButton(
// // //             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
// // //             onPressed: () => Navigator.pop(ctx, true),
// // //             child: const Text("Delete"),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //
// // //     if (confirm == true && mounted) {
// // //       _performDelete(index);
// // //     }
// // //   }
// // //
// // //   void _performDelete(int index) {
// // //     setState(() {
// // //       medicineEntries[index].dispose();
// // //       medicineEntries.removeAt(index);
// // //       savedMedicines.removeAt(index);
// // //     });
// // //     widget.onAdd(_getNonNullMedicines());
// // //   }
// // //
// // //   void _fetchSuggestions(String query, int index) {
// // //     final input = query.trim().toLowerCase();
// // //
// // //     if (input.isEmpty) {
// // //       if (_overlayIndex == index) _removeOverlay();
// // //       setState(() => medicineEntries[index].suggestions = []);
// // //       return;
// // //     }
// // //
// // //     if (!widget.medicinesLoaded) return;
// // //
// // //     final filtered = widget.allMedicines.where((m) {
// // //       final name = (m['medicianName'] ?? '').toString().toLowerCase();
// // //       return name.contains(input);
// // //     }).toList();
// // //
// // //     filtered.sort((a, b) {
// // //       final nameA = (a['medicianName'] ?? '').toString().toLowerCase();
// // //       final nameB = (b['medicianName'] ?? '').toString().toLowerCase();
// // //
// // //       int posA = nameA.indexOf(input);
// // //       int posB = nameB.indexOf(input);
// // //
// // //       if (posA != posB) return posA - posB;
// // //
// // //       int countA = _countOccurrences(nameA, input);
// // //       int countB = _countOccurrences(nameB, input);
// // //
// // //       return countB - countA;
// // //     });
// // //
// // //     final results = filtered.take(5).toList();
// // //
// // //     if (!mounted) return;
// // //
// // //     setState(() {
// // //       medicineEntries[index].suggestions = results;
// // //     });
// // //
// // //     if (medicineEntries[index].fieldKey.currentContext != null) {
// // //       _removeOverlay();
// // //
// // //       if (results.isNotEmpty) {
// // //         _showOverlay(index);
// // //       } else {
// // //         _showNoSuggestionOverlay(index);
// // //       }
// // //     } else {
// // //       if (_overlayIndex == index) _removeOverlay();
// // //     }
// // //   }
// // //
// // //   int _countOccurrences(String string, String pattern) {
// // //     int count = 0;
// // //     int index = 0;
// // //     while (true) {
// // //       index = string.indexOf(pattern, index);
// // //       if (index == -1) break;
// // //       count++;
// // //       index += pattern.length;
// // //     }
// // //     return count;
// // //   }
// // //
// // //   void _showOverlay(int index) {
// // //     if (_overlayIndex == index && _overlayEntry != null) return;
// // //     _removeOverlay();
// // //
// // //     final overlay = Overlay.of(context);
// // //     final renderBox =
// // //     medicineEntries[index].fieldKey.currentContext?.findRenderObject()
// // //     as RenderBox?;
// // //     if (renderBox == null) return;
// // //
// // //     final size = renderBox.size;
// // //     final offset = renderBox.localToGlobal(Offset.zero);
// // //
// // //     _overlayIndex = index;
// // //
// // //     _overlayEntry = OverlayEntry(
// // //       builder: (context) {
// // //         return GestureDetector(
// // //           behavior: HitTestBehavior.translucent,
// // //           onTap: () => _removeOverlay(),
// // //           child: Stack(
// // //             children: [
// // //               Positioned(
// // //                 left: offset.dx,
// // //                 top: offset.dy + size.height + 6,
// // //                 width: size.width,
// // //                 child: CompositedTransformFollower(
// // //                   link: medicineEntries[index]
// // //                       .layerLink, // Use individual LayerLink
// // //                   showWhenUnlinked: false,
// // //                   offset: Offset(0, size.height + 6),
// // //                   child: Material(
// // //                     elevation: 6,
// // //                     borderRadius: BorderRadius.circular(8),
// // //                     child: ListView.builder(
// // //                       padding: EdgeInsets.zero,
// // //                       shrinkWrap: true,
// // //                       itemCount: medicineEntries[index].suggestions.length,
// // //                       itemBuilder: (_, i) {
// // //                         final med = medicineEntries[index].suggestions[i];
// // //                         return ListTile(
// // //                           leading: Icon(
// // //                             Icons.medication,
// // //                             color: widget.primaryColor,
// // //                           ),
// // //                           title: Text(med['medicianName'] ?? ''),
// // //                           trailing: Text(
// // //                             "₹${(med['price'] ?? med['amount'] ?? 0.0).toString()}",
// // //                           ),
// // //                           onTap: () => _selectSuggestion(med, index),
// // //                         );
// // //                       },
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         );
// // //       },
// // //     );
// // //
// // //     overlay?.insert(_overlayEntry!);
// // //   }
// // //
// // //   void _showNoSuggestionOverlay(int index) {
// // //     _removeOverlay();
// // //
// // //     final overlay = Overlay.of(context);
// // //     final renderBox =
// // //     medicineEntries[index].fieldKey.currentContext?.findRenderObject()
// // //     as RenderBox?;
// // //     if (renderBox == null) return;
// // //
// // //     final size = renderBox.size;
// // //     final offset = renderBox.localToGlobal(Offset.zero);
// // //
// // //     _overlayIndex = index;
// // //
// // //     _overlayEntry = OverlayEntry(
// // //       builder: (context) {
// // //         return GestureDetector(
// // //           behavior: HitTestBehavior.translucent,
// // //           onTap: () => _removeOverlay(),
// // //           child: Stack(
// // //             children: [
// // //               Positioned(
// // //                 left: offset.dx,
// // //                 top: offset.dy + size.height + 6,
// // //                 width: size.width,
// // //                 child: CompositedTransformFollower(
// // //                   link: medicineEntries[index]
// // //                       .layerLink, // Use individual LayerLink
// // //                   showWhenUnlinked: false,
// // //                   offset: Offset(0, size.height + 6),
// // //                   child: Material(
// // //                     elevation: 6,
// // //                     borderRadius: BorderRadius.circular(8),
// // //                     child: Container(
// // //                       padding: const EdgeInsets.symmetric(
// // //                         horizontal: 12,
// // //                         vertical: 8,
// // //                       ),
// // //                       child: const Text(
// // //                         "No suggestion Found",
// // //                         style: TextStyle(fontSize: 14, color: Colors.grey),
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         );
// // //       },
// // //     );
// // //
// // //     overlay?.insert(_overlayEntry!);
// // //   }
// // //
// // //   void _removeOverlay() {
// // //     _overlayEntry?.remove();
// // //     _overlayEntry = null;
// // //     _overlayIndex = null;
// // //   }
// // //
// // //   void _selectSuggestion(Map<String, dynamic> med, int index) {
// // //     setState(() {
// // //       final entry = medicineEntries[index];
// // //       entry.currentMedicine['name'] = med['medicianName'] ?? '';
// // //       entry.currentMedicine['price'] = (med['price'] ?? med['amount'] ?? 0.0)
// // //           .toDouble();
// // //       entry.currentMedicine['medicineId'] = med['id'] ?? '';
// // //       entry.medicineNameController.text = entry.currentMedicine['name'];
// // //       entry.suggestions.clear();
// // //       _removeOverlay();
// // //     });
// // //     medicineEntries[index].triggerFieldsChanged();
// // //   }
// // //
// // //   double _parseQtyText(String text) {
// // //     final t = text.trim();
// // //     if (t.contains('/')) {
// // //       final parts = t.split('/');
// // //       if (parts.length == 2) {
// // //         final num = double.tryParse(parts[0]) ?? 0.0;
// // //         final den = double.tryParse(parts[1]) ?? 1.0;
// // //         if (den != 0) return num / den;
// // //       }
// // //     }
// // //     return double.tryParse(t) ?? 1.0;
// // //   }
// // //
// // //   int _dosesPerDay(Map<String, dynamic> med) =>
// // //       ['morning', 'afternoon', 'night'].where((k) => med[k] == true).length;
// // //
// // //   int _totalDays(Map<String, dynamic> med) =>
// // //       (med['days'] ?? 0) + (med['weeks'] ?? 0) * 7 + (med['months'] ?? 0) * 30;
// // //
// // //   bool _isCardValid(_MedicineEntry entry) {
// // //     final med = entry.currentMedicine;
// // //     final name = (med['name'] ?? '').toString().trim();
// // //     final price = (med['price'] ?? 0.0) as double;
// // //     final afterEat = med['afterEat'];
// // //     final hasDose =
// // //         med['morning'] == true ||
// // //             med['afternoon'] == true ||
// // //             med['night'] == true;
// // //     final days = (med['days'] ?? 0) as int;
// // //     return name.isNotEmpty &&
// // //         price > 0 &&
// // //         afterEat != null &&
// // //         hasDose &&
// // //         days > 0;
// // //   }
// // //
// // //   Map<String, dynamic>? _buildIfValid(_MedicineEntry entry) {
// // //     if (!_isCardValid(entry)) return null;
// // //     final med = entry.currentMedicine;
// // //     final qtyPerDose = _parseQtyText(entry.quantityController.text);
// // //     final dosesPerDay = _dosesPerDay(med);
// // //     final days = _totalDays(med);
// // //     final neededQuantity = qtyPerDose * dosesPerDay * (days > 0 ? days : 1);
// // //     final tabletsToCharge = neededQuantity.ceil();
// // //     final totalCost = tabletsToCharge * (med['price'] ?? 0.0);
// // //
// // //     return {
// // //       ...med,
// // //       'qtyPerDose': qtyPerDose,
// // //       'quantityNeeded': neededQuantity,
// // //       'quantity': tabletsToCharge,
// // //       'total': totalCost,
// // //       'days': days,
// // //     };
// // //   }
// // //
// // //   void _onTrySaveCard(int index) {
// // //     if (index >= medicineEntries.length) return;
// // //     final entry = medicineEntries[index];
// // //     final med = _buildIfValid(entry);
// // //     setState(() {
// // //       savedMedicines[index] = med;
// // //     });
// // //     widget.onAdd(_getNonNullMedicines());
// // //   }
// // //
// // //   List<Map<String, dynamic>> _getNonNullMedicines() =>
// // //       savedMedicines.whereType<Map<String, dynamic>>().toList();
// // //
// // //   Widget _eatTypeToggleButton(_MedicineEntry entry) {
// // //     bool afterEat = entry.currentMedicine['afterEat'] ?? true;
// // //     String label = afterEat ? "AC" : "PC";
// // //     Color color = afterEat ? Colors.green : Colors.orangeAccent;
// // //
// // //     return GestureDetector(
// // //       onTap: () {
// // //         setState(() {
// // //           entry.currentMedicine['afterEat'] = !afterEat;
// // //         });
// // //         entry.triggerFieldsChanged();
// // //       },
// // //       child: SizedBox(
// // //         width: 90,
// // //         height: 60,
// // //         child: Card(
// // //           color: color,
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(10),
// // //           ),
// // //           child: Center(
// // //             child: Row(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 Icon(
// // //                   afterEat ? Icons.fastfood : Icons.restaurant_menu,
// // //                   color: Colors.white,
// // //                 ),
// // //                 const SizedBox(width: 8),
// // //                 Text(
// // //                   label,
// // //                   style: const TextStyle(
// // //                     color: Colors.white,
// // //                     fontWeight: FontWeight.bold,
// // //                     fontSize: 20,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _timeCheckbox(String label, String key, _MedicineEntry entry) {
// // //     return Column(
// // //       children: [
// // //         Text(label),
// // //         Checkbox(
// // //           value: entry.currentMedicine[key] ?? false,
// // //           activeColor: widget.primaryColor,
// // //           onChanged: (v) {
// // //             setState(() {
// // //               entry.currentMedicine[key] = v ?? false;
// // //             });
// // //             entry.triggerFieldsChanged();
// // //           },
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _durationInput(String label, String key, _MedicineEntry entry) {
// // //     return SizedBox(
// // //       width: 80,
// // //       child: TextField(
// // //         decoration: InputDecoration(
// // //           labelText: label,
// // //           border: const OutlineInputBorder(),
// // //         ),
// // //         keyboardType: TextInputType.number,
// // //         onChanged: (val) {
// // //           setState(() {
// // //             entry.currentMedicine[key] = int.tryParse(val) ?? 0;
// // //           });
// // //           entry.triggerFieldsChanged();
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildMedicineEntry(int index) {
// // //     final entry = medicineEntries[index];
// // //     return Card(
// // //       margin: const EdgeInsets.symmetric(vertical: 8),
// // //       elevation: 3,
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(12),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             CompositedTransformTarget(
// // //               link:
// // //               entry.layerLink, // Use this card's individual LayerLink here
// // //               child: TextField(
// // //                 key: entry.fieldKey,
// // //                 controller: entry.medicineNameController,
// // //                 focusNode: entry.focusNode,
// // //                 decoration: InputDecoration(
// // //                   labelText: "Medicine Name",
// // //                   border: const OutlineInputBorder(),
// // //                   prefixIcon: Icon(
// // //                     Icons.medication_outlined,
// // //                     color: widget.primaryColor,
// // //                   ),
// // //                 ),
// // //                 onChanged: (v) {
// // //                   _fetchSuggestions(v, index);
// // //                   entry.currentMedicine['name'] = v;
// // //                   entry.triggerFieldsChanged();
// // //                 },
// // //               ),
// // //             ),
// // //             const SizedBox(height: 12),
// // //             Row(
// // //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // //               children: [
// // //                 _eatTypeToggleButton(entry),
// // //                 _timeCheckbox("MN", 'morning', entry),
// // //                 _timeCheckbox("AN", 'afternoon', entry),
// // //                 _timeCheckbox("NT", 'night', entry),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 12),
// // //             Row(
// // //               children: [
// // //                 Expanded(
// // //                   flex: 3,
// // //                   child: TextField(
// // //                     controller: entry.quantityController,
// // //                     decoration: const InputDecoration(
// // //                       labelText: "Qty",
// // //                       border: OutlineInputBorder(),
// // //                     ),
// // //                     keyboardType: TextInputType.text,
// // //                     onChanged: (v) => entry.triggerFieldsChanged(),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(width: 10),
// // //                 Expanded(flex: 3, child: _durationInput("Days", 'days', entry)),
// // //                 if (index > 0)
// // //                   IconButton(
// // //                     icon: const Icon(Icons.delete, color: Colors.red),
// // //                     onPressed: () => _deleteMedicineEntry(index),
// // //                   ),
// // //               ],
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Card(
// // //       elevation: 5,
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// // //       child: AnimatedSize(
// // //         duration: const Duration(milliseconds: 300),
// // //         curve: Curves.easeInOut,
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(5),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               InkWell(
// // //                 onTap: widget.onExpandToggle,
// // //                 child: Row(
// // //                   mainAxisAlignment: MainAxisAlignment.center,
// // //                   children: [
// // //                     Icon(
// // //                       Icons.medication,
// // //                       color: widget.primaryColor,
// // //                       size: 28,
// // //                     ),
// // //                     const SizedBox(width: 10),
// // //                     Text(
// // //                       "Add Medicine",
// // //                       style: TextStyle(
// // //                         fontSize: 22,
// // //                         fontWeight: FontWeight.bold,
// // //                         color: widget.primaryColor,
// // //                       ),
// // //                     ),
// // //                     Icon(
// // //                       widget.expanded
// // //                           ? Icons.keyboard_arrow_up
// // //                           : Icons.keyboard_arrow_down,
// // //                       color: widget.primaryColor,
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //               if (widget.expanded) ...[
// // //                 const SizedBox(height: 12),
// // //                 for (int i = 0; i < medicineEntries.length; i++)
// // //                   _buildMedicineEntry(i),
// // //                 Center(
// // //                   child: IconButton(
// // //                     icon: Icon(Icons.add_circle, color: Colors.blue, size: 46),
// // //                     onPressed: _addNewEntry,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _MedicineEntry {
// // //   final LayerLink layerLink = LayerLink(); // Add individual LayerLink here
// // //
// // //   final TextEditingController medicineNameController = TextEditingController();
// // //   final TextEditingController quantityController = TextEditingController(
// // //     text: "1",
// // //   );
// // //   final GlobalKey fieldKey = GlobalKey();
// // //   final FocusNode focusNode = FocusNode();
// // //   List<Map<String, dynamic>> suggestions = [];
// // //   Map<String, dynamic> currentMedicine = {
// // //     'name': '',
// // //     'price': 0.0,
// // //     'qtyPerDose': 1.0,
// // //     'afterEat': true,
// // //     'morning': true,
// // //     'afternoon': false,
// // //     'night': true,
// // //     'days': 0,
// // //     'weeks': 0,
// // //     'months': 0,
// // //     'total': 0.0,
// // //   };
// // //
// // //   final VoidCallback? onFieldsChanged;
// // //
// // //   _MedicineEntry({this.onFieldsChanged});
// // //
// // //   void triggerFieldsChanged() => onFieldsChanged?.call();
// // //
// // //   void dispose() {
// // //     medicineNameController.dispose();
// // //     quantityController.dispose();
// // //     focusNode.dispose();
// // //   }
// // // }
// // //
// // //
// // //
// //
// //
// // import 'package:flutter/material.dart';
// // import '../../../../Services/Medicine_Service.dart';
// //
// // typedef OnAddMedicine = void Function(List<Map<String, dynamic>> data);
// //
// // class MedicineCard extends StatefulWidget {
// //   final Color primaryColor;
// //   final OnAddMedicine onAdd;
// //   final MedicineService medicineService;
// //   final List<Map<String, dynamic>> allMedicines;
// //   final bool expanded;
// //   final VoidCallback onExpandToggle;
// //   final bool medicinesLoaded;
// //
// //   const MedicineCard({
// //     Key? key,
// //     required this.primaryColor,
// //     required this.onAdd,
// //     required this.medicineService,
// //     required this.expanded,
// //     required this.onExpandToggle,
// //     required this.allMedicines,
// //     required this.medicinesLoaded,
// //   }) : super(key: key);
// //
// //   @override
// //   State<MedicineCard> createState() => _MedicineCardState();
// // }
// //
// // class _MedicineCardState extends State<MedicineCard> {
// //   OverlayEntry? _overlayEntry;
// //   int? _overlayIndex;
// //
// //   List<_MedicineEntry> medicineEntries = [];
// //   List<Map<String, dynamic>?> savedMedicines = [];
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _addNewEntry();
// //   }
// //
// //   @override
// //   void dispose() {
// //     for (var entry in medicineEntries) {
// //       entry.dispose();
// //     }
// //     _removeOverlay();
// //     super.dispose();
// //   }
// //
// //   void _addNewEntry() {
// //     final newEntry = _MedicineEntry(
// //       onFieldsChanged: () => _onTrySaveCard(medicineEntries.length - 1),
// //     );
// //     newEntry.currentMedicine['afterEat'] = true;
// //     newEntry.currentMedicine['morning'] = true;
// //     newEntry.currentMedicine['night'] = true;
// //
// //     setState(() {
// //       medicineEntries.add(newEntry);
// //       savedMedicines.add(null);
// //     });
// //
// //     Future.delayed(const Duration(milliseconds: 100), () {
// //       if (mounted) newEntry.focusNode.requestFocus();
// //     });
// //   }
// //
// //   Future<void> _deleteMedicineEntry(int index) async {
// //     final entry = medicineEntries[index];
// //     final med = entry.currentMedicine;
// //
// //     final bool isEmpty =
// //         (med['name'] ?? '').toString().trim().isEmpty &&
// //             (entry.quantityController.text == '1' ||
// //                 entry.quantityController.text.isEmpty) &&
// //             (med['days'] == 0 || med['days'] == null);
// //
// //     if (isEmpty) {
// //       _performDelete(index);
// //       return;
// //     }
// //
// //     final confirm = await showDialog<bool>(
// //       context: context,
// //       builder: (ctx) => AlertDialog(
// //         title: const Text("Confirm Delete"),
// //         content: const Text(
// //           "Are you sure you want to delete this medicine entry?",
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(ctx, false),
// //             child: const Text("Cancel"),
// //           ),
// //           ElevatedButton(
// //             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
// //             onPressed: () => Navigator.pop(ctx, true),
// //             child: const Text("Delete"),
// //           ),
// //         ],
// //       ),
// //     );
// //
// //     if (confirm == true && mounted) {
// //       _performDelete(index);
// //     }
// //   }
// //
// //   void _performDelete(int index) {
// //     setState(() {
// //       medicineEntries[index].dispose();
// //       medicineEntries.removeAt(index);
// //       savedMedicines.removeAt(index);
// //     });
// //     widget.onAdd(_getNonNullMedicines());
// //   }
// //
// //   void _fetchSuggestions(String query, int index) {
// //     final input = query.trim().toLowerCase();
// //
// //     if (input.isEmpty) {
// //       if (_overlayIndex == index) _removeOverlay();
// //       setState(() => medicineEntries[index].suggestions = []);
// //       return;
// //     }
// //
// //     if (!widget.medicinesLoaded) return;
// //
// //     final filtered = widget.allMedicines.where((m) {
// //       final name = (m['medicianName'] ?? '').toString().toLowerCase();
// //       return name.contains(input);
// //     }).toList();
// //
// //     filtered.sort((a, b) {
// //       final nameA = (a['medicianName'] ?? '').toString().toLowerCase();
// //       final nameB = (b['medicianName'] ?? '').toString().toLowerCase();
// //
// //       int posA = nameA.indexOf(input);
// //       int posB = nameB.indexOf(input);
// //
// //       if (posA != posB) return posA - posB;
// //
// //       int countA = _countOccurrences(nameA, input);
// //       int countB = _countOccurrences(nameB, input);
// //
// //       return countB - countA;
// //     });
// //
// //     final results = filtered.take(5).toList();
// //
// //     if (!mounted) return;
// //
// //     setState(() {
// //       medicineEntries[index].suggestions = results;
// //     });
// //
// //     if (medicineEntries[index].fieldKey.currentContext != null) {
// //       _removeOverlay();
// //
// //       if (results.isNotEmpty) {
// //         _showOverlay(index);
// //       } else {
// //         _showNoSuggestionOverlay(index);
// //       }
// //     } else {
// //       if (_overlayIndex == index) _removeOverlay();
// //     }
// //   }
// //
// //   int _countOccurrences(String string, String pattern) {
// //     int count = 0;
// //     int index = 0;
// //     while (true) {
// //       index = string.indexOf(pattern, index);
// //       if (index == -1) break;
// //       count++;
// //       index += pattern.length;
// //     }
// //     return count;
// //   }
// //
// //   void _showOverlay(int index) {
// //     if (_overlayIndex == index && _overlayEntry != null) return;
// //     _removeOverlay();
// //
// //     final overlay = Overlay.of(context);
// //     final renderBox =
// //     medicineEntries[index].fieldKey.currentContext?.findRenderObject()
// //     as RenderBox?;
// //     if (renderBox == null) return;
// //
// //     final size = renderBox.size;
// //     final offset = renderBox.localToGlobal(Offset.zero);
// //
// //     _overlayIndex = index;
// //
// //     _overlayEntry = OverlayEntry(
// //       builder: (context) {
// //         return GestureDetector(
// //           behavior: HitTestBehavior.translucent,
// //           onTap: () => _removeOverlay(),
// //           child: Stack(
// //             children: [
// //               Positioned(
// //                 left: offset.dx,
// //                 top: offset.dy + size.height + 6,
// //                 width: size.width,
// //                 child: CompositedTransformFollower(
// //                   link: medicineEntries[index]
// //                       .layerLink, // Use individual LayerLink
// //                   showWhenUnlinked: false,
// //                   offset: Offset(0, size.height + 6),
// //                   child: Material(
// //                     elevation: 6,
// //                     borderRadius: BorderRadius.circular(8),
// //                     child: ListView.builder(
// //                       padding: EdgeInsets.zero,
// //                       shrinkWrap: true,
// //                       itemCount: medicineEntries[index].suggestions.length,
// //                       itemBuilder: (_, i) {
// //                         final med = medicineEntries[index].suggestions[i];
// //                         return ListTile(
// //                           leading: Icon(
// //                             Icons.medication,
// //                             color: widget.primaryColor,
// //                           ),
// //                           title: Text(med['medicianName'] ?? ''),
// //                           trailing: Text(
// //                             "₹${(med['price'] ?? med['amount'] ?? 0.0).toString()}",
// //                           ),
// //                           onTap: () => _selectSuggestion(med, index),
// //                         );
// //                       },
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //
// //     overlay?.insert(_overlayEntry!);
// //   }
// //
// //   void _showNoSuggestionOverlay(int index) {
// //     _removeOverlay();
// //
// //     final overlay = Overlay.of(context);
// //     final renderBox =
// //     medicineEntries[index].fieldKey.currentContext?.findRenderObject()
// //     as RenderBox?;
// //     if (renderBox == null) return;
// //
// //     final size = renderBox.size;
// //     final offset = renderBox.localToGlobal(Offset.zero);
// //
// //     _overlayIndex = index;
// //
// //     _overlayEntry = OverlayEntry(
// //       builder: (context) {
// //         return GestureDetector(
// //           behavior: HitTestBehavior.translucent,
// //           onTap: () => _removeOverlay(),
// //           child: Stack(
// //             children: [
// //               Positioned(
// //                 left: offset.dx,
// //                 top: offset.dy + size.height + 6,
// //                 width: size.width,
// //                 child: CompositedTransformFollower(
// //                   link: medicineEntries[index]
// //                       .layerLink, // Use individual LayerLink
// //                   showWhenUnlinked: false,
// //                   offset: Offset(0, size.height + 6),
// //                   child: Material(
// //                     elevation: 6,
// //                     borderRadius: BorderRadius.circular(8),
// //                     child: Container(
// //                       padding: const EdgeInsets.symmetric(
// //                         horizontal: 12,
// //                         vertical: 8,
// //                       ),
// //                       child: const Text(
// //                         "No suggestion Found",
// //                         style: TextStyle(fontSize: 14, color: Colors.grey),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //
// //     overlay?.insert(_overlayEntry!);
// //   }
// //
// //   void _removeOverlay() {
// //     _overlayEntry?.remove();
// //     _overlayEntry = null;
// //     _overlayIndex = null;
// //   }
// //
// //   void _selectSuggestion(Map<String, dynamic> med, int index) {
// //     setState(() {
// //       final entry = medicineEntries[index];
// //       entry.currentMedicine['name'] = med['medicianName'] ?? '';
// //       entry.currentMedicine['price'] = (med['price'] ?? med['amount'] ?? 0.0)
// //           .toDouble();
// //       entry.currentMedicine['medicineId'] = med['id'] ?? '';
// //       entry.medicineNameController.text = entry.currentMedicine['name'];
// //       entry.suggestions.clear();
// //       _removeOverlay();
// //     });
// //     medicineEntries[index].triggerFieldsChanged();
// //   }
// //
// //   double _parseQtyText(String text) {
// //     final t = text.trim();
// //     if (t.contains('/')) {
// //       final parts = t.split('/');
// //       if (parts.length == 2) {
// //         final num = double.tryParse(parts[0]) ?? 0.0;
// //         final den = double.tryParse(parts[1]) ?? 1.0;
// //         if (den != 0) return num / den;
// //       }
// //     }
// //     return double.tryParse(t) ?? 1.0;
// //   }
// //
// //   int _dosesPerDay(Map<String, dynamic> med) =>
// //       ['morning', 'afternoon', 'night'].where((k) => med[k] == true).length;
// //
// //   int _totalDays(Map<String, dynamic> med) =>
// //       (med['days'] ?? 0) + (med['weeks'] ?? 0) * 7 + (med['months'] ?? 0) * 30;
// //
// //   bool _isCardValid(_MedicineEntry entry) {
// //     final med = entry.currentMedicine;
// //     final name = (med['name'] ?? '').toString().trim();
// //     final price = (med['price'] ?? 0.0) as double;
// //     final afterEat = med['afterEat'];
// //     final hasDose =
// //         med['morning'] == true ||
// //             med['afternoon'] == true ||
// //             med['night'] == true;
// //     final days = (med['days'] ?? 0) as int;
// //     return name.isNotEmpty &&
// //         price > 0 &&
// //         afterEat != null &&
// //         hasDose &&
// //         days > 0;
// //   }
// //
// //   Map<String, dynamic>? _buildIfValid(_MedicineEntry entry) {
// //     if (!_isCardValid(entry)) return null;
// //     final med = entry.currentMedicine;
// //     final qtyPerDose = _parseQtyText(entry.quantityController.text);
// //     final dosesPerDay = _dosesPerDay(med);
// //     final days = _totalDays(med);
// //     final neededQuantity = qtyPerDose * dosesPerDay * (days > 0 ? days : 1);
// //     final tabletsToCharge = neededQuantity.ceil();
// //     final totalCost = tabletsToCharge * (med['price'] ?? 0.0);
// //
// //     return {
// //       ...med,
// //       'qtyPerDose': qtyPerDose,
// //       'quantityNeeded': neededQuantity,
// //       'quantity': tabletsToCharge,
// //       'total': totalCost,
// //       'days': days,
// //     };
// //   }
// //
// //   void _onTrySaveCard(int index) {
// //     if (index >= medicineEntries.length) return;
// //     final entry = medicineEntries[index];
// //     final med = _buildIfValid(entry);
// //     setState(() {
// //       savedMedicines[index] = med;
// //     });
// //     widget.onAdd(_getNonNullMedicines());
// //   }
// //
// //   List<Map<String, dynamic>> _getNonNullMedicines() =>
// //       savedMedicines.whereType<Map<String, dynamic>>().toList();
// //
// //   Widget _eatTypeToggleButton(_MedicineEntry entry) {
// //     bool afterEat = entry.currentMedicine['afterEat'] ?? true;
// //     String label = afterEat ? "AC" : "PC";
// //     Color color = afterEat ? Colors.green : Colors.orangeAccent;
// //
// //     return GestureDetector(
// //       onTap: () {
// //         setState(() {
// //           entry.currentMedicine['afterEat'] = !afterEat;
// //         });
// //         entry.triggerFieldsChanged();
// //       },
// //       child: SizedBox(
// //         width: 90,
// //         height: 60,
// //         child: Card(
// //           color: color,
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(10),
// //           ),
// //           child: Center(
// //             child: Row(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Icon(
// //                   afterEat ? Icons.fastfood : Icons.restaurant_menu,
// //                   color: Colors.white,
// //                 ),
// //                 const SizedBox(width: 8),
// //                 Text(
// //                   label,
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 20,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _timeCheckbox(String label, String key, _MedicineEntry entry) {
// //     return Column(
// //       children: [
// //         Text(label),
// //         Checkbox(
// //           value: entry.currentMedicine[key] ?? false,
// //           activeColor: widget.primaryColor,
// //           onChanged: (v) {
// //             setState(() {
// //               entry.currentMedicine[key] = v ?? false;
// //             });
// //             entry.triggerFieldsChanged();
// //           },
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _durationInput(String label, String key, _MedicineEntry entry) {
// //     return SizedBox(
// //       width: 80,
// //       child: TextField(
// //         decoration: InputDecoration(
// //           labelText: label,
// //           border: const OutlineInputBorder(),
// //         ),
// //         keyboardType: TextInputType.number,
// //         onChanged: (val) {
// //           setState(() {
// //             entry.currentMedicine[key] = int.tryParse(val) ?? 0;
// //           });
// //           entry.triggerFieldsChanged();
// //         },
// //       ),
// //     );
// //   }
// //
// //   Widget _buildMedicineEntry(int index) {
// //     final entry = medicineEntries[index];
// //     return Card(
// //       margin: const EdgeInsets.symmetric(vertical: 8),
// //       elevation: 3,
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //       child: Padding(
// //         padding: const EdgeInsets.all(12),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             CompositedTransformTarget(
// //               link:
// //               entry.layerLink, // Use this card's individual LayerLink here
// //               child: TextField(
// //                 key: entry.fieldKey,
// //                 controller: entry.medicineNameController,
// //                 focusNode: entry.focusNode,
// //                 decoration: InputDecoration(
// //                   labelText: "Medicine Name",
// //                   border: const OutlineInputBorder(),
// //                   prefixIcon: Icon(
// //                     Icons.medication_outlined,
// //                     color: widget.primaryColor,
// //                   ),
// //                 ),
// //                 onChanged: (v) {
// //                   _fetchSuggestions(v, index);
// //                   entry.currentMedicine['name'] = v;
// //                   entry.triggerFieldsChanged();
// //                 },
// //               ),
// //             ),
// //             const SizedBox(height: 12),
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //               children: [
// //                 _eatTypeToggleButton(entry),
// //                 _timeCheckbox("MN", 'morning', entry),
// //                 _timeCheckbox("AN", 'afternoon', entry),
// //                 _timeCheckbox("NT", 'night', entry),
// //               ],
// //             ),
// //             const SizedBox(height: 12),
// //             Row(
// //               children: [
// //                 Expanded(
// //                   flex: 3,
// //                   child: TextField(
// //                     controller: entry.quantityController,
// //                     decoration: const InputDecoration(
// //                       labelText: "Qty",
// //                       border: OutlineInputBorder(),
// //                     ),
// //                     keyboardType: TextInputType.text,
// //                     onChanged: (v) => entry.triggerFieldsChanged(),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 10),
// //                 Expanded(flex: 3, child: _durationInput("Days", 'days', entry)),
// //                 if (index > 0)
// //                   IconButton(
// //                     icon: const Icon(Icons.delete, color: Colors.red),
// //                     onPressed: () => _deleteMedicineEntry(index),
// //                   ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Card(
// //       elevation: 5,
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //       child: AnimatedSize(
// //         duration: const Duration(milliseconds: 300),
// //         curve: Curves.easeInOut,
// //         child: Padding(
// //           padding: const EdgeInsets.all(5),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               InkWell(
// //                 onTap: widget.onExpandToggle,
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Icon(
// //                       Icons.medication,
// //                       color: widget.primaryColor,
// //                       size: 28,
// //                     ),
// //                     const SizedBox(width: 10),
// //                     Text(
// //                       "Add Medicine",
// //                       style: TextStyle(
// //                         fontSize: 22,
// //                         fontWeight: FontWeight.bold,
// //                         color: widget.primaryColor,
// //                       ),
// //                     ),
// //                     Icon(
// //                       widget.expanded
// //                           ? Icons.keyboard_arrow_up
// //                           : Icons.keyboard_arrow_down,
// //                       color: widget.primaryColor,
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               if (widget.expanded) ...[
// //                 const SizedBox(height: 12),
// //                 for (int i = 0; i < medicineEntries.length; i++)
// //                   _buildMedicineEntry(i),
// //                 Center(
// //                   child: IconButton(
// //                     icon: Icon(Icons.add_circle, color: Colors.blue, size: 46),
// //                     onPressed: _addNewEntry,
// //                   ),
// //                 ),
// //               ],
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _MedicineEntry {
// //   final LayerLink layerLink = LayerLink(); // Add individual LayerLink here
// //
// //   final TextEditingController medicineNameController = TextEditingController();
// //   final TextEditingController quantityController = TextEditingController(
// //     text: "1",
// //   );
// //   final GlobalKey fieldKey = GlobalKey();
// //   final FocusNode focusNode = FocusNode();
// //   List<Map<String, dynamic>> suggestions = [];
// //   Map<String, dynamic> currentMedicine = {
// //     'name': '',
// //     'price': 0.0,
// //     'qtyPerDose': 1.0,
// //     'afterEat': true,
// //     'morning': true,
// //     'afternoon': false,
// //     'night': true,
// //     'days': 0,
// //     'weeks': 0,
// //     'months': 0,
// //     'total': 0.0,
// //   };
// //
// //   final VoidCallback? onFieldsChanged;
// //
// //   _MedicineEntry({this.onFieldsChanged});
// //
// //   void triggerFieldsChanged() => onFieldsChanged?.call();
// //
// //   void dispose() {
// //     medicineNameController.dispose();
// //     quantityController.dispose();
// //     focusNode.dispose();
// //   }
// // }
// //// scanreport  .//////
// import 'package:flutter/material.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'package:printing/printing.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/services.dart' show rootBundle;
//
// class ScanReportCard extends StatelessWidget {
//   final Map<String, dynamic> scanData;
//   final String? hospitalLogo; // network url or base64 etc
//   final int mode;
//   const ScanReportCard({
//     super.key,
//     required this.scanData,
//     required this.hospitalLogo,
//     required this.mode,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final patient = scanData["Patient"];
//     // final testDetails =
//     //     scanData["testDetails"][0] ?? scanData['TeatingAndScanningPatient'][0];
//     // final testDetails =
//     //     (scanData["testDetails"] != null && scanData["testDetails"].isNotEmpty)
//     //     ? scanData["testDetails"][0]
//     //     : (scanData['TeatingAndScanningPatient'] != null &&
//     //           scanData['TeatingAndScanningPatient'].isNotEmpty)
//     //     ? scanData['TeatingAndScanningPatient'][0]
//     //     : null;
//     //
//     // final images = List<String>.from(testDetails["scanImages"] ?? []);
//     // // final options = List<Map<String, dynamic>>.from(
//     // //   testDetails["options"] ?? testDetails["selectedOptions"],
//     // // );
//     // List<Map<String, dynamic>> options = [];
//     // if (testDetails != null) {
//     //   if (testDetails["options"] is List && testDetails["options"].isNotEmpty) {
//     //     options = List<Map<String, dynamic>>.from(testDetails["options"]);
//     //   } else if (testDetails["selectedOptions"] is List &&
//     //       testDetails["selectedOptions"].isNotEmpty) {
//     //     options = List<Map<String, dynamic>>.from(
//     //       testDetails["selectedOptions"],
//     //     );
//     //   }
//     // }
//
//     // Pick first non-test item (like a scan)
//     final testDetails =
//     ((scanData['testDetails'] as List<dynamic>? ?? []).firstWhere(
//           (item) => item['type']?.toString().toLowerCase() != 'tests',
//       orElse: () => null,
//     ) ??
//         (scanData['TeatingAndScanningPatient'] as List<dynamic>? ?? [])
//             .firstWhere(
//               (item) => item['type']?.toString().toLowerCase() != 'tests',
//           orElse: () => null,
//         ));
//
//     // Get scan images safely
//     final images = List<String>.from(testDetails?["scanImages"] ?? []);
//
//     // Get options safely
//     List<Map<String, dynamic>> options = [];
//     if (testDetails != null) {
//       if (testDetails["options"] is List && testDetails["options"].isNotEmpty) {
//         options = List<Map<String, dynamic>>.from(testDetails["options"]);
//       } else if (testDetails["selectedOptions"] is List &&
//           testDetails["selectedOptions"].isNotEmpty) {
//         options = List<Map<String, dynamic>>.from(
//           testDetails["selectedOptions"],
//         );
//       }
//     }
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // _buildHospitalHeader(),
//           // const SizedBox(height: 20),
//           _buildSectionTitle("PATIENT INFORMATION"),
//           _buildInfoCard([
//             ["Name", patient["name"]],
//             ["Gender", patient["gender"]],
//             ["Age", patient["age"].toString()],
//             ["Blood Group", patient["bldGrp"]],
//             ["Phone", patient["phone"]],
//           ]),
//           const SizedBox(height: 20),
//           _buildSectionTitle("SCAN DETAILS"),
//           _buildInfoCard([
//             ["Scan Type", testDetails["title"]],
//             ["Result", testDetails["results"]],
//             ["Date", scanData["createdAt"]],
//           ]),
//           const SizedBox(height: 20),
//           _buildSectionTitle("X-RAY RESULT DETAILS"),
//           _buildResultTable(options),
//           const SizedBox(height: 20),
//           _buildSectionTitle("SCAN IMAGES"),
//           images.isEmpty
//               ? const Text(
//             "No images available",
//             style: TextStyle(fontSize: 16),
//           )
//               : _buildImageGrid(images),
//           const SizedBox(height: 10),
//           if (mode == 2) ...[
//             const SizedBox(height: 20),
//             _buildActionButtons(context),
//             const SizedBox(height: 40),
//           ],
//         ],
//       ),
//     );
//   }
//
//   // Widget _buildHospitalHeader() {
//   //   return Container(
//   //     padding: const EdgeInsets.all(20),
//   //     decoration: BoxDecoration(
//   //       color: Colors.blue.shade50,
//   //       borderRadius: BorderRadius.circular(12),
//   //       boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
//   //     ),
//   //     child: Column(
//   //       children: [
//   //         Text(
//   //           scanData['Hospital']?['name'] ?? '',
//   //           style: TextStyle(
//   //             fontSize: 24,
//   //             fontWeight: FontWeight.bold,
//   //             color: Colors.blue.shade900,
//   //           ),
//   //         ),
//   //         const SizedBox(height: 4),
//   //         Text(
//   //           scanData['Hospital']?['address'] ?? '',
//   //           style: TextStyle(color: Colors.grey.shade700),
//   //         ),
//   //         Text(
//   //           "Accurate | Caring | Instant",
//   //           style: TextStyle(color: Colors.grey.shade600),
//   //         ),
//   //         Ink.image(image: NetworkImage(hospitalLogo ?? ''), height: 50),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   Widget _buildSectionTitle(String title) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade700,
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Center(
//         child: Text(
//           title,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 17,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoCard(List<List<String>> data) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
//       ),
//       child: Column(
//         children: data.map((row) {
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 6),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   row[0],
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 Flexible(child: Text(row[1], textAlign: TextAlign.right)),
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildResultTable(List<Map<String, dynamic>> options) {
//     final filteredOptions = options.where((e) {
//       final selected = e["selectedOption"];
//       if (selected == null) return false;
//       final str = selected.toString().trim().toUpperCase();
//       return str != "N/A" && str.isNotEmpty;
//     }).toList();
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: const [
//               Expanded(
//                 child: Text(
//                   "Scan Name",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//               Expanded(
//                 child: Text(
//                   "Result",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ),
//           const Divider(),
//           ...filteredOptions.map((e) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       e["selectedOption"].toString().split('(').first,
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       e["result"] ?? "-",
//                       style: const TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildImageGrid(List<String> images) {
//     if (images.isEmpty) {
//       return const Center(
//         child: Text(
//           "No images available",
//           style: TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//       );
//     }
//
//     return GridView.builder(
//       physics: const NeverScrollableScrollPhysics(),
//       shrinkWrap: true,
//       padding: const EdgeInsets.all(12),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         mainAxisSpacing: 12,
//         crossAxisSpacing: 12,
//         childAspectRatio: 1,
//       ),
//       itemCount: images.length,
//       itemBuilder: (context, index) {
//         return GestureDetector(
//           onTap: () => _openFullImage(context, images[index]),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.shade300,
//                   blurRadius: 6,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Stack(
//                 children: [
//                   Positioned.fill(
//                     child: Image.network(
//                       images[index],
//                       fit: BoxFit.cover,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return const Center(child: CircularProgressIndicator());
//                       },
//                       errorBuilder: (context, error, stackTrace) {
//                         return const Center(
//                           child: Icon(
//                             Icons.broken_image,
//                             size: 40,
//                             color: Colors.grey,
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     left: 0,
//                     right: 0,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 8,
//                         horizontal: 8,
//                       ),
//                       color: Colors.black45,
//                       child: Text(
//                         "X-Ray ${index + 1}",
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void _openFullImage(BuildContext context, String imageUrl) {
//     showDialog(
//       context: context,
//       builder: (_) {
//         return GestureDetector(
//           onTap: () => Navigator.pop(context), // tap to close
//           child: Container(
//             color: Colors.black.withOpacity(0.9),
//             child: Center(
//               child: InteractiveViewer(
//                 panEnabled: true,
//                 minScale: 0.8,
//                 maxScale: 4.0,
//                 child: Image.network(imageUrl, fit: BoxFit.contain),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildActionButtons(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.redAccent,
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//             ),
//             icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
//             label: const Text(
//               "View PDF",
//               style: TextStyle(color: Colors.white),
//             ),
//             onPressed: () async {
//               final pdf = await _generatePdf();
//               final bytes = await pdf.save();
//               await Printing.layoutPdf(onLayout: (format) => bytes);
//             },
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//             ),
//             icon: const Icon(Icons.share, color: Colors.white),
//             label: const Text("Share", style: TextStyle(color: Colors.white)),
//             onPressed: () async {
//               final pdf = await _generatePdf();
//               final bytes = await pdf.save();
//               await Printing.sharePdf(
//                 bytes: bytes,
//                 filename: 'scan_report.pdf',
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Future<pw.Document> _generatePdf() async {
//     final pdf = pw.Document();
//
//     final patient = scanData["Patient"] ?? {};
//     final testDetails =
//     (scanData["testDetails"] != null && scanData["testDetails"].isNotEmpty)
//         ? scanData["testDetails"][0]
//         : {};
//     final options = List<Map<String, dynamic>>.from(
//       testDetails["options"] ?? [],
//     );
//     final images = List<String>.from(testDetails["scanImages"] ?? []);
//
//     // Load fonts
//     pw.Font bodyFont;
//     pw.Font boldFont;
//     try {
//       final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
//       final fontBoldData = await rootBundle.load(
//         "assets/fonts/Roboto-Bold.ttf",
//       );
//       bodyFont = pw.Font.ttf(fontData);
//       boldFont = pw.Font.ttf(fontBoldData);
//     } catch (e) {
//       bodyFont = pw.Font.helvetica();
//       boldFont = pw.Font.helveticaBold();
//     }
//
//     // Load hospital logo for PDF header
//     pw.ImageProvider? logoProvider;
//     try {
//       if (hospitalLogo != null && hospitalLogo!.isNotEmpty) {
//         final uri = Uri.tryParse(hospitalLogo!);
//         if (uri != null) {
//           final resp = await http.get(uri);
//           if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
//             logoProvider = pw.MemoryImage(resp.bodyBytes);
//           }
//         }
//       }
//     } catch (_) {}
//
//     // Prepare scan images widgets for PDF
//     final List<pw.Widget> imageWidgets = [];
//     for (var img in images) {
//       try {
//         final uri = Uri.tryParse(img);
//         if (uri != null) {
//           final response = await http.get(uri);
//           if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
//             final imageProvider = pw.MemoryImage(response.bodyBytes);
//
//             imageWidgets.add(
//               pw.Padding(
//                 padding: const pw.EdgeInsets.symmetric(vertical: 6),
//                 child: pw.Container(
//                   width: 140, // square width
//                   height: 130, // square height
//                   decoration: pw.BoxDecoration(
//                     border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
//                     borderRadius: pw.BorderRadius.circular(8),
//                   ),
//                   child: pw.ClipRRect(
//                     horizontalRadius: 8,
//                     verticalRadius: 8,
//                     child: pw.FittedBox(
//                       fit: pw.BoxFit.cover, // forces perfect square crop
//                       child: pw.Image(imageProvider),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }
//         }
//       } catch (e) {
//         // ignore errors gracefully
//       }
//     }
//
//     // Filter the options except "N/A"
//     final filteredOptions = options.where((e) {
//       final selected = e["selectedOption"];
//       if (selected == null) return false;
//       final str = selected.toString().trim().toUpperCase();
//       return str != "N/A" && str.isNotEmpty;
//     }).toList();
//
//     final theme = pw.ThemeData.withFont(base: bodyFont, bold: boldFont);
//
//     pdf.addPage(
//       pw.MultiPage(
//         margin: const pw.EdgeInsets.fromLTRB(32, 50, 32, 40),
//         theme: theme,
//         header: (context) => pw.Container(
//           padding: const pw.EdgeInsets.only(bottom: 8),
//           decoration: const pw.BoxDecoration(
//             border: pw.Border(
//               bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
//             ),
//           ),
//           child: pw.Row(
//             crossAxisAlignment: pw.CrossAxisAlignment.center,
//             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//             children: [
//               if (logoProvider != null)
//                 pw.Container(
//                   width: 130,
//                   height: 50,
//                   child: pw.Image(logoProvider, fit: pw.BoxFit.cover),
//                 ),
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.end,
//                 children: [
//                   pw.Text(
//                     scanData['Hospital']?['name'] ?? '',
//                     style: pw.TextStyle(
//                       fontSize: 16,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                   pw.Text(
//                     scanData['Hospital']?['address'] ?? '',
//                     style: const pw.TextStyle(fontSize: 9),
//                   ),
//                   pw.Text(
//                     "Accurate | Caring | Instant",
//                     style: const pw.TextStyle(fontSize: 9),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         footer: (context) => pw.Container(
//           alignment: pw.Alignment.centerRight,
//           margin: const pw.EdgeInsets.only(top: 8),
//           child: pw.Text(
//             'Page ${context.pageNumber} of ${context.pagesCount}',
//             style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
//           ),
//         ),
//         build: (context) => [
//           pw.SizedBox(height: 12),
//           pw.Center(
//             child: pw.Text(
//               "SCAN REPORT",
//               style: pw.TextStyle(
//                 fontSize: 18,
//                 fontWeight: pw.FontWeight.bold,
//                 decoration: pw.TextDecoration.underline,
//               ),
//             ),
//           ),
//           pw.SizedBox(height: 10),
//
//           // Patient and Scan details in two columns for better layout
//           _sectionBox(
//             title: " Patient Details",
//             child: pw.Row(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//               children: [
//                 /// LEFT COLUMN
//                 pw.Expanded(
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       _infoRow("Name", patient["name"] ?? "-"),
//                       _infoRow("Gender", patient["gender"] ?? "-"),
//                       _infoRow("Age", patient["age"]?.toString() ?? "-"),
//                     ],
//                   ),
//                 ),
//
//                 pw.SizedBox(width: 10),
//
//                 /// CENTER COLUMN
//                 pw.Expanded(
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       _infoRow("Blood Group", patient["bldGrp"] ?? "-"),
//                       _infoRow("Phone", patient["phone"] ?? "-"),
//                       _infoRow(
//                         "Address",
//                         patient["address"]?['Address'] ?? "-",
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 pw.SizedBox(width: 10),
//
//                 /// RIGHT COLUMN
//                 pw.Expanded(
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       _infoRow("Scan Type", testDetails["title"] ?? "-"),
//                       _infoRow("Result", testDetails["results"] ?? "-"),
//                       _infoRow("Date", scanData["createdAt"] ?? "-"),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           pw.SizedBox(height: 16),
//
//           // X-ray details table
//           _tableSection(
//             "X-Ray Result Details",
//             headers: const ["Test Name", "Result"],
//             data: filteredOptions
//                 .map(
//                   (e) => [
//                 (e["name"] ?? "-").toString(),
//                 (e["result"] ?? "-").toString(),
//               ],
//             )
//                 .toList(),
//           ),
//
//           if (imageWidgets.isNotEmpty) pw.SizedBox(height: 16),
//
//           if (imageWidgets.isNotEmpty)
//             pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text(
//                   "Scan Images",
//                   style: pw.TextStyle(
//                     fontSize: 13,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//                 pw.SizedBox(height: 6),
//                 pw.Wrap(spacing: 8, runSpacing: 8, children: imageWidgets),
//               ],
//             ),
//
//           pw.SizedBox(height: 24),
//
//           // Signature or footer note area
//           pw.Row(
//             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//             children: [
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     "Doctor Signature",
//
//                     style: pw.TextStyle(
//                       fontSize: 10,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                   pw.SizedBox(height: 24),
//                   pw.Container(
//                     width: 120,
//                     height: 0.5,
//                     color: PdfColors.grey600,
//                   ),
//                 ],
//               ),
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.end,
//                 children: [
//                   pw.Text(
//                     "This is a system generated report.",
//                     style: const pw.TextStyle(
//                       fontSize: 9,
//                       color: PdfColors.grey600,
//                     ),
//                   ),
//                   pw.Text(
//                     "No signature required.",
//                     style: const pw.TextStyle(
//                       fontSize: 9,
//                       color: PdfColors.grey600,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//
//     return pdf;
//   }
//
//   pw.Widget _infoRow(String label, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 6),
//       child: pw.Row(
//         mainAxisSize: pw.MainAxisSize.min, // compact row
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text(
//             "$label: ",
//             textAlign: pw.TextAlign.center,
//             style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5),
//           ),
//           pw.Text(value, style: pw.TextStyle(fontSize: 10.5)),
//         ],
//       ),
//     );
//   }
//
//   /// PDF helper: box section with label/value pairs
//   pw.Widget _sectionBox({required String title, required pw.Widget child}) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(12),
//       decoration: pw.BoxDecoration(
//         border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
//         borderRadius: pw.BorderRadius.circular(6),
//       ),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.center,
//         children: [
//           pw.Text(
//             title,
//             style: pw.TextStyle(
//               fontSize: 13,
//               fontWeight: pw.FontWeight.bold,
//               color: PdfColors.blue800,
//             ),
//           ),
//           pw.SizedBox(height: 2),
//           pw.Divider(color: PdfColors.grey500, thickness: 0.7),
//           pw.SizedBox(height: 4),
//           child, // <-- IMPORTANT
//         ],
//       ),
//     );
//   }
//
//   /// PDF helper: titled table with borders
//   pw.Widget _tableSection(
//       String title, {
//         required List<String> headers,
//         required List<List<String>> data,
//       }) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           title,
//           style: pw.TextStyle(
//             fontSize: 16,
//             fontWeight: pw.FontWeight.bold,
//             color: PdfColors.blue800,
//           ),
//         ),
//         pw.SizedBox(height: 8),
//         pw.Table.fromTextArray(
//           headers: headers,
//           data: data
//               .map((row) => row.map((cell) => cell.toString()).toList())
//               .toList(),
//           headerStyle: pw.TextStyle(
//             fontSize: 15,
//             fontWeight: pw.FontWeight.bold,
//             color: PdfColors.white,
//           ),
//           headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
//           cellStyle: const pw.TextStyle(fontSize: 11),
//           headerAlignment: pw.Alignment.centerLeft,
//           cellAlignment: pw.Alignment.centerLeft,
//           border: pw.TableBorder(
//             horizontalInside: const pw.BorderSide(
//               color: PdfColors.grey400,
//               width: 0.5,
//             ),
//             verticalInside: const pw.BorderSide(
//               color: PdfColors.grey400,
//               width: 0.5,
//             ),
//             top: const pw.BorderSide(color: PdfColors.grey400, width: 0.5),
//             bottom: const pw.BorderSide(color: PdfColors.grey400, width: 0.5),
//             left: const pw.BorderSide(color: PdfColors.grey400, width: 0.5),
//             right: const pw.BorderSide(color: PdfColors.grey400, width: 0.5),
//           ),
//           cellPadding: const pw.EdgeInsets.symmetric(
//             vertical: 7,
//             horizontal: 7,
//           ),
//         ),
//       ],
//     );
//   }
// }
