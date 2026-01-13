import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Mediacl_Staff/Pages/a_new_medical/a_new_medical/bulk_upload/bulk_upload.dart';
import '../../Mediacl_Staff/Pages/a_new_medical/a_new_medical/medicines/add_medicines.dart';
import '../../Mediacl_Staff/Pages/a_new_medical/a_new_medical/reorder/reorder_list.dart';
import '../../Mediacl_Staff/Pages/a_new_medical/a_new_medical/stock/stock_management.dart';
import '../../Mediacl_Staff/Pages/a_new_medical/a_new_medical/supplier/supplier.dart';
import '../../Mediacl_Staff/Pages/inpatient/add_rooms.dart';
import '../../Mediacl_Staff/Pages/inpatient/assign_change_detail.dart';
import 'AddingPage/ActiveStaff.dart';
import 'AddingPage/AddingScanData.dart';
import 'AddingPage/AddingTestData.dart';
import 'AddingPage/AdminAddPage.dart';
import 'AddingPage/AssignFeesPage.dart';
import 'AddingPage/AssignRoleButton.dart';
import 'AddingPage/InjectionAddPage.dart';
import 'AddingPage/Medicine/MedicinePage.dart';
import 'AddingPage/StaffAddPage.dart';
import 'AddingPage/Tonic/TonicPage.dart';
import 'AddingPage/create_test_scan.dart';

class AdminAddingPage extends StatefulWidget {
  const AdminAddingPage({super.key});

  @override
  State<AdminAddingPage> createState() => _AdminAddingPageState();
}

class _AdminAddingPageState extends State<AdminAddingPage> {
  String hospitalName = "Unknown Hospital";
  String hospitalPlace = "Unknown Place";
  String hospitalPhoto = "";
  String currentDate = DateFormat('MMM dd, yyyy').format(DateTime.now());

  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      hospitalName = _prefs?.getString('hospitalName') ?? hospitalName;
      hospitalPlace = _prefs?.getString('hospitalPlace') ?? hospitalPlace;
      hospitalPhoto =
          _prefs?.getString('hospitalPhoto') ??
          "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    });
  }

  // 🔑 RESPONSIVE GRID (FULL WIDTH + CENTERED)
  Widget _responsiveGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns = width >= 1200
            ? 7
            : width >= 900
            ? 6
            : width >= 700
            ? 5
            : width >= 500
            ? 4
            : 3;

        const spacing = 24.0;

        final itemWidth = (width - (spacing * (columns - 1))) / columns;

        return SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: spacing,
            children: children
                .map(
                  (child) => SizedBox(
                    width: itemWidth,
                    child: Center(child: child),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E6),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHospitalCard(),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBF955E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ===== MANAGE =====
              _buildSection(
                "MANAGE",
                _responsiveGrid([
                  _buildActionItem(Icons.admin_panel_settings, "Admin", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddAdminPage()),
                    );
                  }),
                  _buildActionItem(Icons.person_add, "Staff", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddStaffPage()),
                    );
                  }),
                  _buildActionItem(
                    Icons.person_add_alt_sharp,
                    "Activate Staff",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ActiveStaffPage(),
                        ),
                      );
                    },
                  ),
                  _buildActionItem(Icons.wallet, "Assign Fees", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AssignFeesPage()),
                    );
                  }),
                  _buildActionItem(
                    Icons.assignment_ind_outlined,
                    "Assign Duty",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AssignRoleButton(),
                        ),
                      );
                    },
                  ),
                  _buildActionItem(Icons.add_business, "Manage Rooms", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WardsPage()),
                    );
                  }),
                  _buildActionItem(
                    Icons.add_business,
                    "Change bed & staff",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdmittedPatientsPage(),
                        ),
                      );
                    },
                  ),
                  _buildActionItem(Icons.add_business, "Manage Rooms", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WardsPage()),
                    );
                  }),
                ]),
              ),

              // ===== ADD PHARMACY =====
              _buildSection(
                "ADD PHARMACY",
                _responsiveGrid([
                  // _buildActionItem(Icons.medical_information, "Medicine", () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(builder: (_) => const MedicianPage()),
                  //   );
                  // }),
                  // _buildActionItem(Icons.vaccines, "Injection", () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (_) => const AddInjectionPage(),
                  //     ),
                  //   );
                  // }),
                  // _buildActionItem(Icons.local_drink_sharp, "Tonic", () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(builder: (_) => const TonicPage()),
                  //   );
                  // }),
                  _buildActionItem(Icons.medical_information, "Medicines", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InventoryPage(),
                      ),
                    );
                  }),
                  _buildActionItem(Icons.local_drink_sharp, "Bulk Upload", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BulkUploadPage(),
                      ),
                    );
                  }),
                  _buildActionItem(Icons.vaccines, "Stock", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StockPage(),
                      ),
                    );
                  }),
                  _buildActionItem(
                    Icons.medical_information,
                    "Reorder\nMedicine",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReorderPage(),
                        ),
                      );
                    },
                  ),
                  _buildActionItem(Icons.local_drink_sharp, "Supplier", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupplierPage(),
                      ),
                    );
                  }),
                ]),
              ),

              // ===== ADD TEST & SCAN =====
              _buildSection(
                "ADD TEST & SCAN",
                _responsiveGrid([
                  _buildActionItem(Icons.create, "Create Test&Scan", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateTestScanPage(),
                      ),
                    );
                  }),
                  _buildActionItem(Icons.medical_services, "Test", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddTestPage()),
                    );
                  }),
                  _buildActionItem(Icons.document_scanner, "Scan", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddScanPage()),
                    );
                  }),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 SECTION CARD
  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF886638),
                ),
              ),
              const SizedBox(height: 24),
              content,
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 HOSPITAL HEADER
  Widget _buildHospitalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.network(
              hospitalPhoto,
              height: 65,
              width: 65,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
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
                  hospitalName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  hospitalPlace,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 ACTION ITEM (CENTERED)
  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 70,
            width: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFCECCF), Color(0xFFF6D8A8)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFBF955E), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, size: 34, color: const Color(0xFF8B6C3A)),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
