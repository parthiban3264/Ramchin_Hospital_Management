import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hospitrax/Admin/Pages/admin_edit_profile_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../utils/utils.dart';
import 'reorder_pdf.dart';
import 'reorder_supplier_pdf.dart';
import 'supplier_reorderlist.dart';

const Color royal = primaryColor;

class ReorderPage extends StatefulWidget {
  const ReorderPage({super.key});

  @override
  State<ReorderPage> createState() => _ReorderPageState();
}

class _ReorderPageState extends State<ReorderPage> {
  String? shopId;
  bool isLoading = true;
  List<Map<String, dynamic>> supplierWiseList = [];
  List<Map<String, dynamic>> medicines = [];

  List<Map<String, dynamic>> _suppliers = [];
  bool isLoadingSuppliers = true;

  @override
  void initState() {
    super.initState();
    loadShopId();
  }

  Future<void> loadShopId() async {
    final prefs = await SharedPreferences.getInstance();
    shopId = prefs.getString('hospitalId');

    if (shopId != null) {
      await Future.wait([
        fetchReorderMedicines(),
        fetchSupplierWiseReorder(),
        _fetchSuppliers(),
      ]);
    }
    setState(() => isLoading = false);
  }

  Future<void> _fetchSuppliers() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString("hospitalId");
    if (shopId == null) return;

    try {
      final url = Uri.parse("$baseUrl/suppliers/$shopId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _suppliers = List<Map<String, dynamic>>.from(
            jsonDecode(response.body),
          );
        });
      }
    } catch (e) {
      _showMessage("Error loading suppliers");
    } finally {
      setState(() => isLoadingSuppliers = false);
    }
  }

  Future<void> fetchSupplierWiseReorder() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/reorder/supplier-wise/$shopId"),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        supplierWiseList = data
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching supplier-wise reorder: $e");
    }
  }

  Future<void> fetchReorderMedicines() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/reorder/$shopId"));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        medicines = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching reorder medicines: $e");
    }
  }

  Future<void> _reloadPage() async {
    setState(() => isLoading = true);

    await Future.wait([
      fetchReorderMedicines(),
      fetchSupplierWiseReorder(),
      _fetchSuppliers(),
    ]);

    setState(() => isLoading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: royal, fontSize: 16)),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: royal, width: 2),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: royal,
        title: const Text("Reorder", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.home), onPressed: () {})],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 600, // 👈 only form is constrained
                      ),
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text(
                              "Reorder List with Supplier Details",
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: royal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: medicines.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReorderSupplierPdfPage(
                                          medicines: medicines,
                                        ),
                                      ),
                                    );
                                  },
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text(
                              "Generate Reorder List",
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: royal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: medicines.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReorderPdfPage(
                                          medicines: medicines,
                                        ),
                                      ),
                                    );
                                  },
                          ),
                          const SizedBox(height: 30),

                          if (medicines.isNotEmpty)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Suppliers",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: royal,
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          if (medicines.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _suppliers.length,
                              itemBuilder: (context, index) {
                                final supplier = _suppliers[index];

                                return Card(
                                  elevation: 2,
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: royal.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.local_shipping,
                                      color: royal,
                                    ),
                                    title: Text(
                                      supplier['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text("📞 ${supplier['phone']}"),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: royal,
                                    ),

                                    /// ✅ SEND SELECTED SUPPLIER + ALL REORDER MEDICINES
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SupplierReorderDetailPage(
                                                supplier: supplier,
                                                medicines: medicines,
                                              ),
                                        ),
                                      );

                                      if (result == true) {
                                        _reloadPage(); // ✅ refresh everything
                                      }
                                    },
                                  ),
                                );
                              },
                            ),

                          if (medicines.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Text(
                                "No medicines need reorder",
                                style: TextStyle(color: royal),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
