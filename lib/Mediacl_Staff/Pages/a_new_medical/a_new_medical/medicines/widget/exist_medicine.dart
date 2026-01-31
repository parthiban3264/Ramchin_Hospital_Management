import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../../../../Admin/Pages/admin_edit_profile_page.dart';
import '../../../../../../utils/utils.dart';

class ExistingMedicineWidget extends StatefulWidget {
  final String hospitalId;
  final Function() fetchMedicines;
  final Function(bool) onClose;
  final List<String> categories; // ✅ NEW

  const ExistingMedicineWidget({
    super.key,
    required this.hospitalId,
    required this.fetchMedicines,
    required this.onClose,
    required this.categories,
  });

  @override
  State<ExistingMedicineWidget> createState() => _ExistingMedicineWidgetState();
}

class _ExistingMedicineWidgetState extends State<ExistingMedicineWidget> {
  final reorderCtrl = TextEditingController(text: '10');
  final nameCtrl = TextEditingController();
  bool isNameTaken = false;

  final ndcCtrl = TextEditingController();
  late List<String> medicineCategories;

  String selectedCategory = "Tablets";
  bool isOtherCategory = false;
  final otherCategoryCtrl = TextEditingController();

  DateTime? mfgDate;
  DateTime? expDate;

  final batchCtrl = TextEditingController(text: "01");
  final rackCtrl = TextEditingController();
  final unitCtrl = TextEditingController();
  int totalQuantity = 0; // was double
  double totalStock = 0; // ✅ FIX
  double sellingPerUnit = 0;
  double sellingPerQuantity = 0;
  final nameFocus = FocusNode();
  final ndcFocus = FocusNode();
  final reorderFocus = FocusNode();
  final batchFocus = FocusNode();
  final rackFocus = FocusNode();
  final unitFocus = FocusNode();
  final stockFocus = FocusNode();
  final sellingunitFocus = FocusNode();
  final sellingqtyFocus = FocusNode();

  final totalStockCtrl = TextEditingController();
  final sellingUnitCtrl = TextEditingController();
  final sellingQtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final defaultCategories = [
      "Tablets",
      "Syrups",
      "Drops",
      "Ointments",
      "Creams",
      "Soap",
    ];

    medicineCategories = {
      ...defaultCategories,
      ...widget.categories, // 👈 FROM BACKEND
      "Other",
    }.toList();

    // safety: selected value must exist
    if (!medicineCategories.contains(selectedCategory)) {
      selectedCategory = medicineCategories.first;
    }
  }

  Future<void> submitMedicine() async {
    if (!isFormValid()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => confirmMedicineDialog(),
    );

    if (confirmed != true) return;

    final finalCategory = isOtherCategory
        ? otherCategoryCtrl.text.trim()
        : selectedCategory;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/inventory/medicine/existing-med"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "hospital_id": int.parse(widget.hospitalId),
          "name": nameCtrl.text,
          "category": finalCategory,
          "ndc_code": ndcCtrl.text,
          "batch_no": batchCtrl.text,
          "mfg_date": mfgDate?.toIso8601String(),
          "exp_date": expDate?.toIso8601String(),
          "rack_no": rackCtrl.text,
          "total_quantity": totalQuantity,
          "unit": int.tryParse(unitCtrl.text),
          "total_stock": double.tryParse(totalStockCtrl.text),
          "reorder": int.tryParse(reorderCtrl.text),
          "selling_price_per_unit": truncateTo2Decimals(sellingPerUnit),
          "selling_price_per_quantity": truncateTo2Decimals(sellingPerQuantity),
        }),
      );

      /// ✅ SUCCESS ONLY
      if (response.statusCode >= 200 && response.statusCode < 300) {
        resetForm();
        widget.onClose(false);
        widget.fetchMedicines();
      } else {
        _showError("Failed to save medicine. Please try again.");
      }
    } catch (e) {
      _showError("Network error. Please check your connection.");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  double truncateTo2Decimals(double value) {
    return (value * 100).truncate() / 100;
  }

  void calculateTotalQuantity() {
    final stock = double.tryParse(totalStockCtrl.text) ?? 0;
    final unit = double.tryParse(unitCtrl.text) ?? 1; // avoid division by 0
    setState(() {
      // round up to nearest integer
      totalQuantity = (stock / unit).ceil(); // integer now
    });

    // Also update selling price if one is entered
    if (sellingPerUnit > 0) {
      sellingPerQuantity = truncateTo2Decimals(sellingPerUnit * unit);
      sellingQtyCtrl.text = sellingPerQuantity.toString();
    } else if (sellingPerQuantity > 0) {
      sellingPerUnit = unit != 0
          ? truncateTo2Decimals(sellingPerQuantity / unit)
          : 0;
      sellingUnitCtrl.text = sellingPerUnit.toString();
    }
  }

  void resetForm() {
    nameCtrl.clear();
    ndcCtrl.clear();
    batchCtrl.text = "01";
    rackCtrl.clear();
    unitCtrl.clear();
    totalStockCtrl.clear();
    sellingUnitCtrl.clear();
    sellingQtyCtrl.clear();
    reorderCtrl.clear();
    otherCategoryCtrl.clear();

    selectedCategory = medicineCategories.first;
    isOtherCategory = false;

    mfgDate = null;
    expDate = null;

    totalQuantity = 0;
    totalStock = 0;

    sellingPerUnit = 0;
    sellingPerQuantity = 0;
    isNameTaken = false;

    // Unfocus all fields
    nameFocus.unfocus();
    ndcFocus.unfocus();
    reorderFocus.unfocus();
    batchFocus.unfocus();
    rackFocus.unfocus();
    unitFocus.unfocus();
    stockFocus.unfocus();
    sellingunitFocus.unfocus();
    sellingqtyFocus.unfocus();

    setState(() {});
  }

  Widget confirmMedicineDialog() {
    final finalCategory = isOtherCategory
        ? otherCategoryCtrl.text.trim()
        : selectedCategory;
    Widget infoTile(
      String label,
      String value, {
      Color valueColor = primaryColor,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                "$label:",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? "-" : value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      contentPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: primaryColor, width: 1.2),
      ),
      title: const Center(
        child: Text(
          "Confirm Medicine Details",
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
      ),
      content: SingleChildScrollView(
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: primaryColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 BASIC INFO
                infoTile("Name", nameCtrl.text),
                infoTile("Category", finalCategory),
                if (ndcCtrl.text.trim().isNotEmpty)
                  infoTile("NDC", ndcCtrl.text),
                infoTile("Batch No", batchCtrl.text),
                if (rackCtrl.text.trim().isNotEmpty)
                  infoTile("Rack No", rackCtrl.text),

                Divider(color: primaryColor),

                /// 🔹 DATES
                infoTile(
                  "MFG Date",
                  mfgDate?.toLocal().toString().split(' ')[0] ?? "-",
                ),
                infoTile(
                  "EXP Date",
                  expDate?.toLocal().toString().split(' ')[0] ?? "-",
                ),

                const Divider(color: primaryColor),

                /// 🔹 STOCK
                infoTile("Total Quantity", totalQuantity.toString()),
                infoTile("Unit Per Pack", unitCtrl.text),
                infoTile("Total Stock", totalStockCtrl.text),

                const Divider(color: primaryColor),

                infoTile(
                  "Selling / Qty",
                  "₹${sellingPerQuantity.toStringAsFixed(2)}",
                ),
                infoTile(
                  "Selling / Unit",
                  "₹${sellingPerUnit.toStringAsFixed(2)}",
                ),
              ],
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: primaryColor), // ✅ outline color
            foregroundColor: primaryColor, // ✅ text & icon color
          ),
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel", style: TextStyle(color: primaryColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Confirm"),
        ),
      ],
    );
  }

  bool isFormValid() {
    final unitValue = double.tryParse(unitCtrl.text) ?? 0;
    final stockValue = double.tryParse(totalStockCtrl.text) ?? 0;

    return nameCtrl.text.trim().isNotEmpty &&
        !isNameTaken &&
        selectedCategory.isNotEmpty &&
        (!isOtherCategory || otherCategoryCtrl.text.trim().isNotEmpty) &&
        batchCtrl.text.trim().isNotEmpty &&
        unitCtrl.text.trim().isNotEmpty &&
        unitValue > 0 &&
        stockValue >= 0 &&
        sellingPerUnit > 0 &&
        sellingPerQuantity > 0 &&
        mfgDate != null &&
        expDate != null &&
        expDate!.isAfter(mfgDate!);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(10),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor, // 👈 border color
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Add Medicine & Batch",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = MediaQuery.of(context).size.width >= 1000;

                double fieldWidth(BoxConstraints c) {
                  if (!isDesktop) return c.maxWidth;
                  return (c.maxWidth - 32) / 3; // 3 columns with spacing
                }

                int columnCount;
                if (constraints.maxWidth >= 1000) {
                  columnCount = 4; // large desktop
                } else if (constraints.maxWidth >= 800) {
                  columnCount = 3; // tablet
                } else if (constraints.maxWidth >= 600) {
                  columnCount = 2; // tablet
                } else {
                  columnCount = 1; // mobile
                }

                double columnWidth =
                    (constraints.maxWidth - ((columnCount - 1) * 16)) /
                    columnCount;

                return Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "Name",
                        field: StatefulBuilder(
                          builder: (context, setLocalState) {
                            Timer? debounce;
                            return TextFormField(
                              controller: nameCtrl,
                              style: TextStyle(color: primaryColor),
                              cursorColor: primaryColor,
                              focusNode: nameFocus,
                              textInputAction:
                                  TextInputAction.next, // 👈 shows NEXT / Enter
                              onFieldSubmitted: (_) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(ndcFocus); // 👈 NEXT FOCUS
                              }, //                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: "Enter Medicine name",
                                hintStyle: TextStyle(color: primaryColor),
                                filled: true,
                                fillColor: primaryColor.withValues(alpha: 0.1),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: primaryColor,
                                    width: 0.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                suffixIcon: isNameTaken
                                    ? const Icon(Icons.error, color: Colors.red)
                                    : const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      ),
                              ),
                              onChanged: (value) {
                                if (debounce?.isActive ?? false)
                                  debounce!.cancel();
                                debounce = Timer(
                                  const Duration(milliseconds: 500),
                                  () async {
                                    if (value.trim().isEmpty) {
                                      setLocalState(() => isNameTaken = false);
                                      return;
                                    }
                                    try {
                                      final url = Uri.parse(
                                        "$baseUrl/inventory/medicine/check-name/${widget.hospitalId}?name=$value",
                                      );
                                      final response = await http.get(url);
                                      if (response.statusCode == 200) {
                                        final data = jsonDecode(response.body);
                                        setLocalState(
                                          () => isNameTaken =
                                              data['exists'] ?? false,
                                        );
                                      } else {
                                        setLocalState(
                                          () => isNameTaken = false,
                                        );
                                      }
                                    } catch (_) {
                                      setLocalState(() => isNameTaken = false);
                                    }
                                  },
                                );
                                setLocalState(() {});
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "Category",
                        field: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          iconEnabledColor: primaryColor,
                          style: const TextStyle(color: primaryColor),
                          decoration: _inputDecoration("Select category"),
                          items: medicineCategories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              selectedCategory = v!;
                              isOtherCategory = v == "Other";
                              if (!isOtherCategory) otherCategoryCtrl.clear();
                            });
                          },
                        ),
                      ),
                    ),

                    if (isOtherCategory)
                      SizedBox(
                        width: fieldWidth(constraints),
                        child: labeledField(
                          label: "Custom Category",
                          field: TextFormField(
                            controller: otherCategoryCtrl,
                            textCapitalization: TextCapitalization.words,
                            cursorColor: primaryColor,
                            style: const TextStyle(color: primaryColor),
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              "Enter custom category",
                            ),
                          ),
                        ),
                      ),

                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "NDC",
                        field: TextFormField(
                          controller: ndcCtrl,
                          cursorColor: primaryColor,
                          keyboardType: TextInputType.visiblePassword,
                          style: const TextStyle(color: primaryColor),
                          focusNode: ndcFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(reorderFocus);
                          },
                          decoration: _inputDecoration(
                            "Enter NDC code (optional)",
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "Reorder-Level",
                        field: TextFormField(
                          cursorColor: primaryColor,
                          style: TextStyle(color: primaryColor),
                          keyboardType: TextInputType.number,
                          controller: reorderCtrl,
                          focusNode: reorderFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(batchFocus);
                          },
                          onChanged: (_) => setState(() {}),
                          // ✅ update button state
                          decoration: _inputDecoration("Enter Re-order value"),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "Batch No",
                        field: TextFormField(
                          controller: batchCtrl,
                          cursorColor: primaryColor,
                          focusNode: batchFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(rackFocus);
                          },
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.visiblePassword,
                          style: const TextStyle(color: primaryColor),
                          decoration: _inputDecoration("Enter Batch no"),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "Rack No",
                        field: TextFormField(
                          controller: rackCtrl,
                          cursorColor: primaryColor,
                          focusNode: rackFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(stockFocus);
                          },
                          keyboardType: TextInputType.visiblePassword,
                          style: const TextStyle(color: primaryColor),
                          decoration: _inputDecoration("Optional"),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "MFG Date",
                        field: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            backgroundColor: primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: primaryColor,
                              width: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: primaryColor,
                                      onPrimary: Colors.white,
                                      onSurface: primaryColor,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: primaryColor,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null)
                              setState(() => mfgDate = picked);
                          },
                          child: Text(
                            mfgDate == null
                                ? "Select date"
                                : mfgDate!.toLocal().toString().split(' ')[0],
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "EXP Date",
                        field: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            backgroundColor: primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: primaryColor,
                              width: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: primaryColor,
                                      onPrimary: Colors.white,
                                      onSurface: primaryColor,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: primaryColor,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null)
                              setState(() => expDate = picked);
                          },
                          child: Text(
                            expDate == null
                                ? "Select date"
                                : expDate!.toLocal().toString().split(' ')[0],
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "Total Stock",
                        field: TextFormField(
                          controller: totalStockCtrl,
                          cursorColor: primaryColor,
                          style: const TextStyle(color: primaryColor),
                          focusNode: stockFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(unitFocus);
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => calculateTotalQuantity(),
                          decoration: _inputDecoration("Enter total stock"),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "Unit per Pack",
                        field: TextFormField(
                          controller: unitCtrl,
                          cursorColor: primaryColor,
                          focusNode: unitFocus,
                          style: const TextStyle(color: primaryColor),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(sellingunitFocus);
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => calculateTotalQuantity(),
                          decoration: _inputDecoration("Unit per quantity"),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "Selling / Unit",
                        field: TextFormField(
                          controller: sellingUnitCtrl,
                          cursorColor: primaryColor,
                          style: const TextStyle(color: primaryColor),
                          focusNode: sellingunitFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(sellingqtyFocus);
                          },
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final val = double.tryParse(v) ?? 0;
                            setState(() {
                              sellingPerUnit = val;
                              final unit = double.tryParse(unitCtrl.text) ?? 1;
                              sellingPerQuantity = truncateTo2Decimals(
                                val * unit,
                              );
                              sellingQtyCtrl.text = sellingPerQuantity
                                  .toString();
                            });
                          },
                          decoration: _inputDecoration(
                            "Enter selling price per unit",
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: fieldWidth(constraints),
                      child: labeledField(
                        label: "Selling / Quantity",
                        field: TextFormField(
                          controller: sellingQtyCtrl,
                          cursorColor: primaryColor,
                          style: const TextStyle(color: primaryColor),
                          focusNode: sellingqtyFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).unfocus(); // ✅ dismiss keyboard
                          },
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final val = double.tryParse(v) ?? 0;
                            setState(() {
                              sellingPerQuantity = val;
                              final unit = double.tryParse(unitCtrl.text) ?? 1;
                              sellingPerUnit = unit != 0
                                  ? truncateTo2Decimals(val / unit)
                                  : 0;
                              sellingUnitCtrl.text = sellingPerUnit.toString();
                            });
                          },
                          decoration: _inputDecoration(
                            "Enter selling price per quantity",
                          ),
                        ),
                      ),
                    ),
                    summaryBox(
                      width: columnWidth,
                      isDesktop: isDesktop,
                      text: "Total Quantity: $totalQuantity",
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFormValid()
                                ? primaryColor
                                : Colors.grey,
                            foregroundColor: isFormValid()
                                ? Colors.white
                                : primaryColor,
                            elevation: 0,
                            side: BorderSide(
                              color: isFormValid()
                                  ? primaryColor
                                  : Colors.grey.shade700,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: isFormValid() ? submitMedicine : null,
                          child: const Text(
                            "Submit Medicine",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget labeledField({required String label, required Widget field}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110, // 👈 FIXED LABEL WIDTH (adjust if needed)
          child: Text(
            label,
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: field),
      ],
    ),
  );
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: primaryColor.withValues(alpha: 0.8)),
    filled: true,
    fillColor: primaryColor.withValues(alpha: 0.1),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: primaryColor, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: primaryColor, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}

Widget summaryBox({
  required double width,
  required bool isDesktop,
  required String text,
  Color color = primaryColor,
}) {
  return SizedBox(
    width: width,
    child: Align(
      alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 14,
        ),
      ),
    ),
  );
}
