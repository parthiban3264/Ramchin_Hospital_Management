import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hospitrax/Admin/Pages/admin_edit_profile_page.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/a_new_medical/a_new_medical/medicines/widget/exist_batch.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/a_new_medical/a_new_medical/medicines/widget/exist_medicine.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/a_new_medical/a_new_medical/medicines/widget/new_batch.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/a_new_medical/a_new_medical/medicines/widget/new_medicine.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../Appbar/MobileAppbar.dart';
import '../../../../../utils/utils.dart';
import './widget/widget.dart';

const Color aRoyalBlue = Color(0xFF854929);

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => InventoryPageState();
}

class InventoryPageState extends State<InventoryPage> {
  String? hospitalId;
  List<Map<String, dynamic>> medicines = [];
  bool isLoading = true;
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  static bool showAddMedicine = false;
  bool showAddBatch = false;
  final TextEditingController searchCtrl = TextEditingController();
  List<String> backendCategories = [];
  bool isCategoryLoading = false;
  List<Map<String, dynamic>> filteredMedicines = [];
  bool showExistingMedicine = false;
  bool showExistingMedicineBatch = false;
  bool isEditingProfit = false;
  bool isEditingSelling = false;
  Timer? debounce;
  bool isBatchTaken = false;

  @override
  void initState() {
    super.initState();

    loadShopId();
  }

  Future loadShopId() async {
    final prefs = await SharedPreferences.getInstance();
    hospitalId = prefs.getString('hospitalId');
    _loadHospitalInfo();
    if (hospitalId != null) fetchMedicines();
    setState(() {});
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();

    hospitalName = prefs.getString('hospitalName') ?? "Unknown";
    hospitalPlace = prefs.getString('hospitalPlace') ?? "Unknown";
    hospitalPhoto =
        prefs.getString('hospitalPhoto') ??
        "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    setState(() {});
  }

  Future<void> fetchCategories() async {
    setState(() => isCategoryLoading = true);
    final prefs = await SharedPreferences.getInstance();
    hospitalId = prefs.getString('hospitalId');
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/inventory/medicine/categories/$hospitalId"),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        setState(() {
          backendCategories = data.map((e) => e.toString()).toList();
        });
      }
    } catch (_) {
    } finally {
      setState(() => isCategoryLoading = false);
    }
  }

  Future<void> updateInventoryStatus({
    required int medicineId,
    int? batchId,
    required bool isActive,
  }) async {
    try {
      await http.patch(
        Uri.parse("$baseUrl/inventory/status"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "shop_id": int.parse(hospitalId!),
          "medicine_id": medicineId,
          if (batchId != null) "batch_id": batchId,
          "is_active": isActive,
        }),
      );

      fetchMedicines();
      if (mounted) {
        showMessage(
          isActive ? "Activated successfully" : "Deactivated successfully",
          context,
        );
      }
    } catch (e) {
      if (mounted) showMessage("Status update failed", context);
    }
  }

  Future<void> fetchMedicines() async {
    if (hospitalId == null) return;

    setState(() => isLoading = true);

    try {
      final url = Uri.parse("$baseUrl/inventory/medicine/shop/$hospitalId");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          medicines = data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();

          filteredMedicines = medicines;
        });
      } else {
        if (mounted) showMessage("❌ Failed to load medicines", context);
      }
    } catch (e) {
      if (mounted) showMessage("❌ Error fetching medicines: $e", context);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void searchMedicines(String query) {
    final numericQuery = query.replaceAll(RegExp(r'\D'), '');
    final lowerQuery = query.toLowerCase();

    setState(() {
      filteredMedicines = medicines.where((medicine) {
        final nameMatch =
            medicine['name']?.toLowerCase().contains(lowerQuery) ?? false;

        bool batchMatch = false;

        if (numericQuery.isNotEmpty || lowerQuery.isNotEmpty) {
          batchMatch = (medicine['batches'] as List).any((batch) {
            final expiry = batch['expiry_date'];
            if (expiry == null) return false;

            final variants = normalizeDateVariants(
              date: expiry,
              updateInventoryStatus: updateInventoryStatus,
            );

            return variants.any((v) {
              final normalized = v.replaceAll(RegExp(r'\D'), '');

              return (numericQuery.isNotEmpty &&
                      normalized.contains(numericQuery)) ||
                  (lowerQuery.isNotEmpty &&
                      v.toLowerCase().contains(lowerQuery));
            });
          });
        }

        return nameMatch || batchMatch;
      }).toList();
    });
  }

  Widget actionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: outlinedRoyalButton,
                onPressed: () {
                  setState(() {
                    showAddMedicine = !showAddMedicine;
                    showAddBatch = false;
                    showExistingMedicine = false;
                    showExistingMedicineBatch = false;
                  });
                },
                child: Text(
                  showAddMedicine ? "Close Medicine Form" : "Add Medicine",
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: outlinedRoyalButton,
                onPressed: () {
                  setState(() {
                    showAddBatch = !showAddBatch;
                    showAddMedicine = false;
                    showExistingMedicine = false;
                    showExistingMedicineBatch = false;
                  });
                },
                child: Text(showAddBatch ? "Close Batch Form" : "Add Batch"),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 🔹 NEW BUTTON
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity, // ← makes button full-width
            child: ElevatedButton(
              style: outlinedRoyalButton,
              onPressed: () {
                setState(() {
                  showExistingMedicine = !showExistingMedicine;
                  showAddMedicine = false;
                  showAddBatch = false;
                  showExistingMedicineBatch = false;
                });
              },
              child: Text(
                showExistingMedicine
                    ? "Close Existing Medicines"
                    : "Add Existing Medicine",
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity, // ← makes button full-width
            child: ElevatedButton(
              style: outlinedRoyalButton,
              onPressed: () {
                setState(() {
                  showExistingMedicineBatch = !showExistingMedicineBatch;

                  showExistingMedicine = false;
                  showAddMedicine = false;
                  showAddBatch = false;
                });
              },
              child: Text(
                showExistingMedicine
                    ? "Close Existing Medicines Batch"
                    : "Add Existing Medicine Batch",
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget searchBar() {
    return TextField(
      controller: searchCtrl,
      onChanged: searchMedicines,
      cursorColor: primaryColor,
      style: TextStyle(color: primaryColor),
      decoration: InputDecoration(
        hintText: "Search by medicine name or expiry date",
        hintStyle: TextStyle(color: primaryColor),
        prefixIcon: const Icon(Icons.search),
        prefixIconColor: primaryColor,
        suffixIcon: searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchCtrl.clear();
                  setState(() => filteredMedicines = medicines);
                },
              )
            : null,
        suffixIconColor: primaryColor,
        filled: true,
        fillColor: primaryColor.withValues(alpha: 0.1),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (hospitalId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Medicines',
        pageContext: context,
        showBackButton: true,
        showNotificationIcon: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  buildHospitalCard(
                    hospitalName: hospitalName,
                    hospitalPlace: hospitalPlace,
                    hospitalPhoto: hospitalPhoto,
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: actionButtons(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        if (showAddMedicine)
                          AddMedicineForm(
                            hospitalId: hospitalId!,
                            fetchMedicines: fetchMedicines,
                            onClose: (val) =>
                                setState(() => showAddMedicine = val),
                            categories: backendCategories,
                          ),
                        if (showExistingMedicine)
                          ExistingMedicineWidget(
                            hospitalId: hospitalId!,
                            fetchMedicines: fetchMedicines,
                            onClose: (val) =>
                                setState(() => showExistingMedicine = val),
                            categories: backendCategories,
                          ),

                        if (showAddBatch)
                          AddBatchForm(
                            hospitalId: hospitalId!,
                            fetchMedicines: fetchMedicines,
                            onClose: (val) =>
                                setState(() => showAddBatch = val),
                            medicines: medicines,
                          ),
                        if (showExistingMedicineBatch)
                          ExistingMedicineBatchForm(
                            hospitalId: hospitalId!,
                            fetchMedicines: fetchMedicines,
                            onClose: (val) =>
                                setState(() => showExistingMedicineBatch = val),
                            medicines: medicines,
                          ),
                        const SizedBox(height: 16),
                        // if (showAddMedicine)
                        //   addMedicineForm(
                        //     context: context,
                        //     hospitalId: hospitalId!,
                        //     fetchMedicines: fetchMedicines,
                        //   ),
                        // if (showAddBatch)
                        //   addBatchForm(
                        //     medicines: medicines,
                        //     isBatchTaken: isBatchTaken,
                        //     debounce: debounce,
                        //     hospitalId: hospitalId!,
                        //     showAddBatch: showAddBatch,
                        //     fetchMedicines: fetchMedicines,
                        //   ),
                        const Divider(color: primaryColor),
                        if (medicines.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              "No medicines found",
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        if (medicines.isNotEmpty) searchBar(),
                        const SizedBox(height: 18),
                        ...filteredMedicines.map(
                          (medicine) => Padding(
                            padding: const EdgeInsets.only(bottom: 18.0),
                            child: medicineCard(
                              medicine: medicine,
                              context: context,
                              updateInventoryStatus: updateInventoryStatus,
                            ),
                          ),
                        ),
                        const SizedBox(height: 70),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
