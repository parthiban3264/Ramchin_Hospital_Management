import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../Services/admin_service.dart';
import 'DrInPatientQueuePage.dart';
import 'DrOutPatientQueuePage.dart';

class DrOpDashboardPage extends StatefulWidget {
  const DrOpDashboardPage({super.key});

  @override
  State<DrOpDashboardPage> createState() => _DrOpDashboardPageState();
}

class _DrOpDashboardPageState extends State<DrOpDashboardPage> {
  final Color primaryColor = const Color(0xFFBA8C50);

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  String currentDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
  List<int> doctorPermissionIds = [];

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _loadDrOpData();
    _loadDrOpData();
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

  Future<void> _loadDrOpData() async {
    final profile = await AdminService().getProfile();
    final List<dynamic> perms = profile?['permissions'] ?? [];

    setState(() {
      doctorPermissionIds = perms.map<int>((e) => e as int).toList();
    });
  }

  Future<void> _refreshPage() async {
    await _loadHospitalInfo();
    await _loadDrOpData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let gradient show through
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: Container(
          height: double.infinity,
          width: double.infinity,
          // 🌈 Full-screen gradient
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF7E6), Color(0xFFFFF7E6)],

              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            // 👇 Single scroll for the whole screen
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🏥 Hospital Info Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white.withOpacity(0.95),
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              hospitalPhoto ?? "",
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover,
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
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  hospitalPlace ?? "Unknown Place",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📅 Date Tag
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFBF955E),
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

                  // 📋 Action Section Card
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
                              'Doctor Desk',
                              style: TextStyle(
                                color: const Color(0xFF886638),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          if (!doctorPermissionIds.contains(6) &&
                              !doctorPermissionIds.contains(8))
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
                          if (doctorPermissionIds.contains(6) ||
                              doctorPermissionIds.contains(8))
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (doctorPermissionIds.contains(6))
                                  _buildActionItem(
                                    Icons.person,
                                    "Outpatient",
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DrOutPatientQueuePage(
                                            role: 'doctor',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                if (doctorPermissionIds.contains(8))
                                  _buildActionItem(
                                    Icons.person,
                                    "InPatient",
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const DrInPatientQueuePage(
                                                role: 'doctor',
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                // _buildActionItem(Icons.healing, "Symptoms", () {
                                //   Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (_) => const SymptomsQueuePage(),
                                //     ),
                                //   );
                                // }),
                              ],
                            ),
                          // const SizedBox(height: 25),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          //   children: [
                          //     _buildActionItem(Icons.queue, "Queue", () {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (_) => const OutpatientQueuePage(),
                          //         ),
                          //       );
                          //     }),
                          //     _buildActionItem(Icons.queue, "ECG", () {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (_) => const EcgQueuePage(),
                          //         ),
                          //       );
                          //     }),
                          //     _buildActionItem(Icons.queue, "X-Ray", () {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (_) => const XRayQueuePage(),
                          //         ),
                          //       );
                          //     }),
                          //   ],
                          // ),
                          // const SizedBox(height: 25),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          //   children: [
                          //     _buildActionItem(Icons.queue, "Lab", () {}),
                          //     _buildActionItem(Icons.queue, "MRI-Scan", () {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (_) => const MriScanQueuePage(),
                          //         ),
                          //       );
                          //     }),
                          //     _buildActionItem(Icons.queue, "CT-Scan", () {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (_) => const CtScanQueuePage(),
                          //         ),
                          //       );
                          //     }),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
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
            height: 80,
            width: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),

              // ★ FULL COLOR GRADIENT BACKGROUND
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFCECCF), // soft gold top
                  const Color(0xFFF6D8A8), // deeper gold bottom
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),

              // ★ Clean gold border
              border: Border.all(color: const Color(0xFFBF955E), width: 1.4),

              // ★ Smooth depth shadow
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: Center(
              child: Icon(
                icon,
                color: const Color(0xFF836028), // deep gold icon color
                size: 34,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            label,
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
