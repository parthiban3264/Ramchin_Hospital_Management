import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Administartor_EditHospital.dart';
import 'Administrator_AddPage.dart';
import 'Administrator_Block.dart';
import 'Adminstrator_Payment_Histroy.dart';
import 'Adminstrator_Tickets.dart';

class AdministratorManagePage extends StatefulWidget {
  final Map<String, dynamic> hospitalData;
  final VoidCallback? onHospitalUpdated;
  const AdministratorManagePage({
    super.key,
    required this.hospitalData,
    this.onHospitalUpdated,
  });

  @override
  State<AdministratorManagePage> createState() =>
      _AdministratorManagePageState();
}

class _AdministratorManagePageState extends State<AdministratorManagePage> {
  String currentDate = DateFormat('MMM dd, yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🏥 Hospital Info Header
              const SizedBox(height: 20),

              // 📋 Management Action Section
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
                          'Management Desk',
                          style: TextStyle(
                            color: const Color(0xFF886638),
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
                            "Add Admins",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdministratorAddAdmin(
                                  hospitalData: widget.hospitalData,
                                  onHospitalUpdated: widget.onHospitalUpdated,
                                ),
                              ),
                            ),
                          ),
                          _buildActionItem(
                            Icons.block,
                            "Block Hospital",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdministratorBlock(
                                  hospitalData: widget.hospitalData,
                                  onHospitalUpdated: () {
                                    widget.onHospitalUpdated
                                        ?.call(); // refresh top-level
                                    setState(
                                      () {},
                                    ); // rebuild this intermediate page
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionItem(
                            Icons.edit_outlined,
                            "Edit Hospital",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdministratorEditHospital(
                                  hospitalData: widget.hospitalData,
                                  onHospitalUpdated: () {
                                    widget.onHospitalUpdated
                                        ?.call(); // refresh top-level
                                    setState(
                                      () {},
                                    ); // rebuild this intermediate page
                                  },
                                ),
                              ),
                            ),
                          ),
                          _buildActionItem(
                            Icons.receipt_long_rounded,
                            "Tickets",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdministratorTickets(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionItem(
                            Icons.history,
                            "Payment History",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionHistoryPage(
                                  hall: widget.hospitalData,
                                  // onHospitalUpdated: () {
                                  //   widget.onHospitalUpdated
                                  //       ?.call(); // refresh top-level
                                  //   setState(
                                  //     () {},
                                  //   ); // rebuild this intermediate page
                                  // },
                                ),
                              ),
                            ),
                          ),
                          // _buildActionItem(
                          //   Icons.receipt_long_rounded,
                          //   "Tickets",
                          //   () => Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (_) => const AdministratorTickets(),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // SINGLE ACTION ITEM WIDGET
  // ---------------------------
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
                colors: [
                  Color(0xFFFCECCF), // soft gold
                  Color(0xFFF6D8A8), // deep gold
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Color(0xFFBF955E), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: const Color(0xFF8B6C3A), size: 34),
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
