import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../../../Services/admin_service.dart';
import '../OutPatient/Queue/FeesQueuePage.dart';

class CashierDashboardPage extends StatefulWidget {
  const CashierDashboardPage({super.key});

  @override
  State<CashierDashboardPage> createState() => _CashierDashboardPageState();
}

class _CashierDashboardPageState extends State<CashierDashboardPage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  String currentDate = DateFormat('MMM dd, yyyy').format(DateTime.now());

  List<int> cashierPermissionIds = [];

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _loadCashierData();
  }

  Future<void> _loadCashierData() async {
    final profile = await AdminService().getProfile();
    final List<dynamic> perms = profile?['permissions'] ?? [];

    setState(() {
      cashierPermissionIds = perms.map<int>((e) => e as int).toList();
    });

    print("Cashier Permissions Loaded: $cashierPermissionIds");
  }

  Future<void> _loadHospitalInfo() async {
    final name = await secureStorage.read(key: 'hospitalName');
    final place = await secureStorage.read(key: 'hospitalPlace');
    final photo = await secureStorage.read(key: 'hospitalPhoto');

    setState(() {
      hospitalName = name ?? "Unknown Hospital";
      hospitalPlace = place ?? "Unknown Place";
      hospitalPhoto =
          photo ??
          "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    });
  }

  Future<void> _refreshPage() async {
    await _loadHospitalInfo();
    await _loadCashierData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF7E6), Color(0xFFFFF7E6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        currentDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    color: Colors.white.withOpacity(0.95),
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              'Cashier Desk',
                              style: TextStyle(
                                color: const Color(0xFF886638),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          //-------------------------------
                          //  🔥 NEW: NO PERMISSION MESSAGE
                          //-------------------------------
                          if (!cashierPermissionIds.contains(12) &&
                              !cashierPermissionIds.contains(13))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.red.shade300,
                                  width: 1.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Text(
                                "You don't have permission",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          //-----------------------------------
                          // Existing buttons (unchanged logic)
                          //-----------------------------------
                          if (cashierPermissionIds.contains(12) ||
                              cashierPermissionIds.contains(13))
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (cashierPermissionIds.contains(12))
                                  _buildActionItem(
                                    Icons.currency_rupee,
                                    "Payment",
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const FeesQueuePage(),
                                        ),
                                      );
                                    },
                                  ),
                                if (cashierPermissionIds.contains(13))
                                  _buildActionItem(
                                    Icons.healing,
                                    "Failed Payments",
                                    () {},
                                  ),
                              ],
                            ),

                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
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

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 70,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),

              gradient: const LinearGradient(
                colors: [Color(0xFFFCECCF), Color(0xFFF6D8A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Color(0xFF83551A), width: 1.4),

              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: Center(
              child: Icon(icon, color: Color(0xFF8B6C3A), size: 34),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            label,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
