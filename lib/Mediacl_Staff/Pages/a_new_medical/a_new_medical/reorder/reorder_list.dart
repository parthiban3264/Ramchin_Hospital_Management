import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Admin/Pages/AdminEditProfilePage.dart';
import '../../../../Appbar/MobileAppbar.dart';
import '../../../../utils/utils.dart';
import '../medicines/widget/widget.dart';
import './reorder_pdf.dart';
import './reorder_supplier_pdf.dart';
import './supplier_reorderlist.dart';

class ReorderPage extends StatefulWidget {
  const ReorderPage({super.key});

  @override
  State<ReorderPage> createState() => _ReorderPageState();
}

class _ReorderPageState extends State<ReorderPage> {
  String? hospitalId;
  bool isLoading = true;
  List<Map<String, dynamic>> supplierWiseList = [];
  List<Map<String, dynamic>> medicines = [];
  List<Map<String, dynamic>> _suppliers = [];
  bool isLoadingSuppliers = true;
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  @override
  void initState() {
    super.initState();
    loadShopId();
  }

  Future<void> loadShopId() async {
    final prefs = await SharedPreferences.getInstance();
    hospitalId = prefs.getString('hospitalId');

    if (hospitalId != null) {
      await Future.wait([
        _loadHospitalInfo(),
        fetchReorderMedicines(),
        fetchSupplierWiseReorder(),
        _fetchSuppliers(),
      ]);
    }
    setState(() => isLoading = false);
  }

  Future<void> _fetchSuppliers() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt("shopId");
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
        Uri.parse("$baseUrl/reorder/supplier-wise/$hospitalId"),
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
      final res = await http.get(Uri.parse("$baseUrl/reorder/$hospitalId"));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        medicines = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching reorder medicines: $e");
    }
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: primaryColor, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryColor, width: 2),
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
      appBar: CustomAppBar(
        title: 'Reorder',
        pageContext: context,
        showBackButton: true,
        showNotificationIcon: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildHospitalCard(
                    hospitalName: hospitalName,
                    hospitalPlace: hospitalPlace,
                    hospitalPhoto: hospitalPhoto,
                  ),
                  const SizedBox(height: 30),
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
                              backgroundColor: primaryColor,
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
                              backgroundColor: primaryColor,
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

                          if (_suppliers.isNotEmpty)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Suppliers",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          /// 🔹 SUPPLIER LIST (FROM SUPPLIERS API)
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
                                    color: primaryColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.local_shipping,
                                    color: primaryColor,
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
                                    color: primaryColor,
                                  ),

                                  /// ✅ SEND SELECTED SUPPLIER + ALL REORDER MEDICINES
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SupplierReorderDetailPage(
                                          supplier:
                                              supplier, // ✅ selected supplier
                                          medicines:
                                              medicines, // ✅ ALL reorder medicines
                                        ),
                                      ),
                                    );
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
                                style: TextStyle(color: primaryColor),
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
