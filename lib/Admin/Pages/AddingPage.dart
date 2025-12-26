import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/OutPatient/PatientRegistrationPage.dart';
import 'package:intl/intl.dart';

import 'AddingPage/ActiveStaff.dart';

import 'AddingPage/AddingScanData.dart';
import 'AddingPage/AddingTestData.dart';
import 'AddingPage/AdminAddPage.dart';
import 'AddingPage/AssignFeesPage.dart';
import 'AddingPage/AssignRoleButton.dart';
import 'AddingPage/InjectionAddPage.dart';
import 'AddingPage/Medicine/MedicineAddPage.dart';
import 'AddingPage/Medicine/MedicinePage.dart';
import 'AddingPage/Scan_TestAddPage.dart';
import 'AddingPage/StaffAddPage.dart';
import 'AddingPage/Tonic/TonicAddPage.dart';
import 'AddingPage/Tonic/TonicPage.dart';


class AdminAddingPage extends StatefulWidget {
  const AdminAddingPage({super.key});

  @override
  State<AdminAddingPage> createState() => _AdminAddingPageState();
}

class _AdminAddingPageState extends State<AdminAddingPage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  String currentDate = DateFormat('MMM dd, yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let gradient show through
      body: Container(
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHospitalCard(),
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
                            'MANAGE',
                            style: TextStyle(
                              color: Color(0xFF886638),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionItem(
                              Icons.admin_panel_settings,
                              "Admin",
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddAdminPage(),
                                  ),
                                );
                              },
                            ),
                            _buildActionItem(Icons.person_add, "Staff", () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddStaffPage(),
                                ),
                              );
                            }),
                            // _buildActionItem(
                            //   Icons.person_add_alt_sharp,
                            //   "Patient",
                            //   () {
                            //     Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (_) =>
                            //             const PatientRegistrationPage(),
                            //       ),
                            //     );
                            //   },
                            // ),
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
                          ],
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionItem(Icons.wallet, "Assign Fees", () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AssignFeesPage(),
                                ),
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
                            // _buildActionItem(
                            //   Icons.smart_button,
                            //   "Assign Btn",
                            //   () {
                            //     Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (_) => const AssignRoleButton(),
                            //       ),
                            //     );
                            //   },
                            // ),
                            // _buildActionItem(
                            //   Icons.local_drink_sharp,
                            //   "Tonic",
                            //       () {
                            //     Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (_) => const AddTonicPage(),
                            //       ),
                            //     );
                            //   },
                            // ),
                          ],
                        ),
                      ],
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
                            'ADD PHARMACY',
                            style: TextStyle(
                              color: Color(0xFF886638),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionItem(
                              Icons.medical_information,
                              "Medicine",
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(

                                    builder: (_) => const MedicianPage(),

                                  ),
                                );
                              },
                            ),
                            _buildActionItem(Icons.vaccines, "Injection", () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddInjectionPage(),
                                ),
                              );
                            }),
                            _buildActionItem(
                              Icons.local_drink_sharp,
                              "Tonic",
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(

                                    builder: (_) => const TonicPage(),

                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        // const SizedBox(height: 25),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //   children: [
                        //     _buildActionItem(
                        //       Icons.document_scanner,
                        //       "Test&Scan",
                        //       () {
                        //         Navigator.push(
                        //           context,
                        //           MaterialPageRoute(
                        //             builder: (_) => const AddScanAndTestPage(),
                        //           ),
                        //         );
                        //       },
                        //     ),
                        //     // _buildActionItem(Icons.vaccines, "Injection", () {
                        //     //   Navigator.push(
                        //     //     context,
                        //     //     MaterialPageRoute(
                        //     //       builder: (_) => const AddInjectionPage(),
                        //     //     ),
                        //     //   );
                        //     // }),
                        //     // _buildActionItem(
                        //     //   Icons.local_drink_sharp,
                        //     //   "Tonic",
                        //     //       () {
                        //     //     Navigator.push(
                        //     //       context,
                        //     //       MaterialPageRoute(
                        //     //         builder: (_) => const AddTonicPage(),
                        //     //       ),
                        //     //     );
                        //     //   },
                        //     // ),
                        //   ],
                        // ),
                      ],
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
                            'ADD TEST & SCAN',
                            style: TextStyle(
                              color: Color(0xFF886638),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [

                            _buildActionItem(
                              Icons.medical_services,
                              "Test",
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddTestPage(),
                                  ),
                                );
                              },
                            ),
                            _buildActionItem(
                              Icons.document_scanner,
                              "Scan",
// =======
//                             _buildActionItem(Icons.wallet, "Assign Fees", () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => const AssignFeesPage(),
//                                 ),
//                               );
//                             }),
//                             _buildActionItem(
//                               Icons.document_scanner,
//                               "Test&Scan",
// >>>>>>> 3f063fbf1fae91f45feca0bca76a410ab6083f20
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(

                                    builder: (_) => const AddScanPage(),

                                  ),
                                );
                              },
                            ),

                            // _buildActionItem(
                            //   Icons.local_drink_sharp,
                            //   "Tonic",
                            //   () {
                            //     Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (_) => const TonicPage(),

                            //       ),
                            //     );
                            //   },
                            // ),
                          ],
                        ),

                        //const SizedBox(height: 25),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //   children: [
                        //     _buildActionItem(
                        //       Icons.document_scanner,
                        //       "Test&Scan",
                        //           () {
                        //         Navigator.push(
                        //           context,
                        //           MaterialPageRoute(
                        //             builder: (_) => const AddScanAndTestPage(),
                        //           ),
                        //         );
                        //       },
                        //     ),
                        //     // _buildActionItem(Icons.vaccines, "Injection", () {
                        //     //   Navigator.push(
                        //     //     context,
                        //     //     MaterialPageRoute(
                        //     //       builder: (_) => const AddInjectionPage(),
                        //     //     ),
                        //     //   );
                        //     // }),
                        //     // _buildActionItem(
                        //     //   Icons.local_drink_sharp,
                        //     //   "Tonic",
                        //     //       () {
                        //     //     Navigator.push(
                        //     //       context,
                        //     //       MaterialPageRoute(
                        //     //         builder: (_) => const AddTonicPage(),
                        //     //       ),
                        //     //     );
                        //     //   },
                        //     // ),
                        //   ],
                        // ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard() {
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
                color: const Color(0xFF8B6C3A), // deep gold icon color
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
