import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../../Admin/Pages/admin_edit_profile_page.dart';
import '../add_medicines.dart';

Widget buildHospitalCard({
  required String? hospitalName,
  required String? hospitalPlace,
  required String? hospitalPhoto,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFFEDBA77),
          Color(0xFFC59A62),
          // Color(0xFFEDBA77),
        ], //customGold.withOpacity(0.8)
        begin: Alignment.topLeft,
        end: Alignment.bottomLeft,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 5)),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(18.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.network(
              hospitalPhoto ?? "",
              height: 65,
              width: 65,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_hospital,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospitalName ?? "Unknown Hospital",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hospitalPlace ?? "Unknown Place",
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void showMessage(String message, BuildContext context) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      backgroundColor: primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 3),
    ),
  );
}

List<String> normalizeDateVariants({
  required String date,
  required Future<void> Function({
    required int medicineId,
    int? batchId,
    required bool isActive,
  })
  updateInventoryStatus,
}) {
  try {
    final d = DateTime.parse(date);

    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final yy = yyyy.substring(2);

    return [
      // 🔢 numeric only
      "$dd$mm$yyyy",
      "$mm$dd$yyyy",
      "$yyyy$mm$dd",
      "$yyyy$dd$mm",
      "$dd$mm$yy",
      "$mm$dd$yy",
      "$yy$mm$dd",
      "$yy$dd$mm",
      // 📅 with separators
      "$dd/$mm/$yyyy",
      "$mm/$dd/$yyyy",
      "$yyyy/$mm/$dd",
      "$yyyy/$dd/$mm",

      "$dd-$mm-$yyyy",
      "$mm-$dd-$yyyy",
      "$yyyy-$mm-$dd",
      "$yyyy-$dd-$mm",
    ];
  } catch (_) {
    return [];
  }
}

Widget medicineCard({
  required Map<String, dynamic> medicine,
  required BuildContext context,
  required Function({
    required int medicineId,
    int? batchId,
    required bool isActive,
  })
  updateInventoryStatus,
}) {
  final batches = medicine['batches'] as List<dynamic>;

  return Card(
    elevation: 4,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: primaryColor),
    ),
    shadowColor: primaryColor.withValues(alpha: 0.2),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Medicine Name + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  safeValue(medicine['name']),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: aRoyalBlue,
                  ),
                ),
              ),
              Switch(
                value: medicine['is_active'] ?? false,
                // activeThumbColor: primaryColorblue,
                activeTrackColor: aRoyalBlue.withValues(alpha: 0.4),
                inactiveThumbColor: Colors.grey.shade600,
                inactiveTrackColor: Colors.grey.shade400,
                onChanged: (val) async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        val ? "Activate Medicine" : "Deactivate Medicine",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      content: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87),
                          children: [
                            const TextSpan(
                              text: "Medicine: ",
                              style: TextStyle(color: primaryColor),
                            ),
                            TextSpan(
                              text: medicine['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            TextSpan(
                              text:
                                  "\n\nDo you want to ${val ? "activate" : "deactivate"} this medicine?",
                              style: const TextStyle(color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            "OK",
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                  );

                  // ❌ Cancel pressed → revert switch
                  if (result != true) return;

                  // ✅ Proceed after OK
                  updateInventoryStatus(
                    medicineId: medicine['id'],
                    isActive: val,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Chips / Badges
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (shouldShow(medicine['id']))
                badge(
                  Icons.lock,
                  "Medicine-ID",
                  medicine['id'].toString(),
                  Colors.teal,
                ),
              if (shouldShow(medicine['category']))
                badge(
                  Icons.category,
                  "Category",
                  medicine['category'],
                  Colors.orange,
                ),
              if (shouldShow(medicine['stock']))
                badge(
                  Icons.inventory_2,
                  "Stock",
                  medicine['stock'].toString(),
                  Colors.green,
                ),
              if (shouldShow(medicine['ndc_code']))
                badge(Icons.qr_code, "NDC", medicine['ndc_code'], Colors.blue),
              if (shouldShow(medicine['reorder']))
                badge(
                  Icons.restart_alt,
                  "Re-Order",
                  medicine['reorder'].toString(),
                  Colors.red,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          if (batches.isNotEmpty)
            Divider(color: primaryColor.withValues(alpha: 0.4), thickness: 1),

          // Batch list
          if (batches.isNotEmpty)
            ...batches.map(
              (b) => batchTileImproved(
                batch: b,
                medicineName: medicine['name'],
                context: context,
                updateInventoryStatus: updateInventoryStatus,
              ),
            ),
        ],
      ),
    ),
  );
}

Widget badge(IconData icon, String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          "$label: $value",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

bool isExpired(String expiryDate) {
  final expiry = DateTime.parse(expiryDate);
  return expiry.isBefore(DateTime.now());
}

bool isShortDated(String expiryDate, {int thresholdDays = 60}) {
  final expiry = DateTime.parse(expiryDate);
  final now = DateTime.now();
  final diff = expiry.difference(now).inDays;
  return diff > 0 && diff <= thresholdDays;
}

int daysLeft(String expiryDate) {
  final expiry = DateTime.parse(expiryDate);
  return expiry.difference(DateTime.now()).inDays;
}

Widget expiryBadge(String expiryDate) {
  if (isExpired(expiryDate)) {
    return _badge("Expired", Colors.red);
  }

  if (isShortDated(expiryDate)) {
    return _badge("${daysLeft(expiryDate)} days left", Colors.orange);
  }

  return const SizedBox.shrink();
}

Widget _badge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

Widget batchTileImproved({
  required Map<String, dynamic> batch,
  required String medicineName,
  required BuildContext context,
  required Function({
    required int medicineId,
    int? batchId,
    required bool isActive,
  })
  updateInventoryStatus,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: primaryColor.withValues(alpha: 0.6)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12), // 👈 FIX
      child: ExpansionTile(
        backgroundColor: primaryColor.withValues(alpha: 0.05),
        collapsedBackgroundColor: Colors.white,
        iconColor: aRoyalBlue,
        collapsedIconColor: primaryColor,
        textColor: aRoyalBlue,
        collapsedTextColor: primaryColor,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                "${batch['batch_no']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            if (batch['expiry_date'] != null) expiryBadge(batch['expiry_date']),
            Switch(
              // activeThumbColor: primaryColorblue,
              activeTrackColor: aRoyalBlue.withValues(alpha: 0.4),
              inactiveThumbColor: Colors.grey.shade600,
              inactiveTrackColor: Colors.grey.shade400,
              value: batch['is_active'] ?? true,
              onChanged: (val) async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      val ? "Activate Batch" : "Deactivate Batch",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    content: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87),
                        children: [
                          const TextSpan(
                            text: "Medicine: ",
                            style: TextStyle(color: primaryColor),
                          ),
                          TextSpan(
                            text: medicineName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const TextSpan(
                            text: "\nBatch: ",
                            style: TextStyle(color: primaryColor),
                          ),
                          TextSpan(
                            text: batch['batch_no'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          TextSpan(
                            text:
                                "\n\nDo you want to ${val ? "activate" : "deactivate"} this batch?",
                            style: TextStyle(color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          "OK",
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                );

                // ❌ Cancel → nothing happens
                if (result != true) return;

                // ✅ Proceed
                updateInventoryStatus(
                  medicineId: batch['medicine_id'],
                  batchId: batch['id'],
                  isActive: val,
                );
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Medicine Details Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Medicine Details",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (shouldShow(batch['rack_no']))
                                      infoRow(
                                        "Rack No",
                                        batch['rack_no'] ?? "-",
                                      ),
                                    if (shouldShow(batch['total_stock']))
                                      infoRow(
                                        "Total Stock",
                                        batch['total_stock'].toString(),
                                      ),
                                    if (shouldShow(batch['total_quantity']))
                                      infoRow(
                                        "Total Quantity",
                                        batch['total_quantity'].toString(),
                                      ),
                                    if (shouldShow(batch['manufacture_date']))
                                      infoRow(
                                        "Manufacture Date",
                                        formatDate(batch['manufacture_date']),
                                      ),
                                    if (shouldShow(batch['expiry_date']))
                                      infoRow(
                                        "Expiry Date",
                                        formatDate(batch['expiry_date']),
                                      ),
                                    if (shouldShow(batch['HSN']))
                                      infoRow("HSN Code", batch['HSN'] ?? "-"),
                                    if (shouldShow(batch['unit']))
                                      infoRow("Unit", batch['unit'].toString()),
                                    if (shouldShow(
                                      batch['purchase_price_quantity'],
                                    ))
                                      infoRow(
                                        "Purchase Price/Quantity",
                                        "₹${batch['purchase_price_quantity']}",
                                      ),
                                    if (shouldShow(
                                      batch['purchase_price_unit'],
                                    ))
                                      infoRow(
                                        "Purchase Price/Unit",
                                        batch['purchase_price_unit']
                                                ?.toString() ??
                                            "-",
                                      ),
                                    if (shouldShow(
                                      batch['selling_price_quantity'],
                                    ))
                                      infoRow(
                                        "Selling Price/Quantity",
                                        "₹${batch['selling_price_quantity']}",
                                      ),
                                    if (shouldShow(batch['selling_price_unit']))
                                      infoRow(
                                        "Selling Price/Unit",
                                        "₹${batch['selling_price_unit']}",
                                      ),
                                    if (shouldShow(batch['profit']))
                                      infoRow(
                                        "Profit",
                                        batch['profit']?.toString() ?? "-",
                                      ),
                                    if (shouldShow(batch['mrp']))
                                      infoRow(
                                        "MRP",
                                        batch['mrp']?.toString() ?? "-",
                                      ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Purchased Details",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (shouldShow(batch['quantity']))
                                      infoRow(
                                        "Purchased Quantity",
                                        batch['quantity'].toString(),
                                      ),
                                    if (shouldShow(batch['free_quantity']))
                                      infoRow(
                                        "Free Quantity",
                                        batch['free_quantity'].toString(),
                                      ),
                                    if (shouldShow(
                                      batch['purchase_details']['rate_per_quantity'],
                                    ))
                                      infoRow(
                                        "Rate/ Quantity",
                                        "₹${batch['purchase_details']['rate_per_quantity']}",
                                      ),
                                    if (shouldShow(
                                      batch['purchase_details']['gst_percent'],
                                    ))
                                      infoRow(
                                        "GST %/Quantity",
                                        "${batch['purchase_details']['gst_percent']}%",
                                      ),
                                    if (shouldShow(
                                      batch['purchase_details']['gst_per_quantity'],
                                    ))
                                      infoRow(
                                        "GST Amount/Quantity",
                                        "₹${batch['purchase_details']['gst_per_quantity']}",
                                      ),
                                    if (shouldShow(
                                      batch['purchase_details']['base_amount'],
                                    ))
                                      infoRow(
                                        "Base Amount",
                                        "₹${batch['purchase_details']['base_amount']}",
                                      ),
                                    if (shouldShow(
                                      batch['purchase_details']['total_gst_amount'],
                                    ))
                                      infoRow(
                                        "Total GST Amount",
                                        "₹${batch['purchase_details']['total_gst_amount']}",
                                      ),
                                    if (shouldShow(
                                      batch['purchase_details']['purchase_price'],
                                    ))
                                      infoRow(
                                        "Purchased price",
                                        "₹${batch['purchase_details']['purchase_price']}",
                                      ),
                                    if (shouldShow(batch['supplier']?['name']))
                                      infoRow(
                                        "Supplier Name",
                                        batch['supplier']?['name'] ?? "-",
                                      ),
                                    if (shouldShow(batch['supplier']?['phone']))
                                      infoRow(
                                        "Supplier Phone",
                                        batch['supplier']?['phone'] ?? "-",
                                      ),
                                    if (shouldShow(
                                      batch['purchase_details']['purchase_date'],
                                    ))
                                      infoRow(
                                        "Date",
                                        formatDate(
                                          batch['purchase_details']['purchase_date'],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

String normalizeDate(String date) {
  try {
    final d = DateTime.parse(date);

    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();

    return "$day$month$year"; // 30022026
  } catch (_) {
    return "";
  }
}

Widget infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: aRoyalBlue,
            ),
          ),
        ),
        Expanded(
          child: Text(":$value", style: const TextStyle(color: primaryColor)),
        ),
      ],
    ),
  );
}

String safeValue(dynamic value) {
  if (value == null) return "-";
  if (value is String && value.trim().isEmpty) return "-";
  return value.toString();
}

bool shouldShow(dynamic value) {
  if (value == null) return false;
  if (value is String && value.trim().isEmpty) return false;
  if (value is num && value == 0) return false;
  return true;
}

String formatDate(String? date) {
  if (date == null || date.isEmpty) return "-";
  try {
    final d = DateTime.parse(date);
    return "${d.day}-${d.month}-${d.year}";
  } catch (_) {
    return "-";
  }
}

final ButtonStyle outlinedRoyalButton = ElevatedButton.styleFrom(
  backgroundColor: Colors.white, // white background
  foregroundColor: primaryColor, // text & icon color
  elevation: 0,
  side: const BorderSide(color: primaryColor, width: 1.5),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  padding: const EdgeInsets.symmetric(vertical: 14),
);

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

InputDecoration inputDecoration(String hint) {
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
