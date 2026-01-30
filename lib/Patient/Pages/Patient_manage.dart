import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Patient_Appointment.dart';
import 'Patient_Scan.dart';
import 'Patient_Tests.dart';
import 'Patient_medication.dart';
import 'Patient_payment.dart';

class PatientManage extends StatefulWidget {
  final Map<String, dynamic> hospitalData;
  const PatientManage({super.key, required this.hospitalData});

  @override
  State<PatientManage> createState() => _PatientManageState();
}

class _PatientManageState extends State<PatientManage> {
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
              // 📋 Management Action Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                color: Colors.white.withValues(alpha: 0.95),
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
                          'Records',
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
                            Icons.medical_information,
                            "Medications",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientMedication(
                                  hospitalData: widget.hospitalData,
                                ),
                              ),
                            ),
                          ),
                          _buildActionItem(
                            Icons.payments,
                            "Payments",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientPayment(
                                  hospitalData: widget.hospitalData,
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
                            Icons.history,
                            "Appointment History",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientAppointmentHistory(
                                  hospitalData: widget.hospitalData,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 🏥 Hospital Info Header
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                color: Colors.white.withValues(alpha: 0.95),
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
                          'Reports',
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
                          // _buildActionItem(
                          //   Icons.medical_information,
                          //   "Medical",
                          //   () => Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (_) => const AddAdminPage(),
                          //     ),
                          //   ),
                          // ),
                          _buildActionItem(
                            Icons.document_scanner_outlined,
                            "Scan",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientScan(
                                  hospitalData: widget.hospitalData,
                                ),
                              ),
                            ),
                          ),
                          _buildActionItem(
                            Icons.receipt_long_rounded,
                            "Tests",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientTests(
                                  hospitalData: widget.hospitalData,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 25),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      //   children: [
                      //     _buildActionItem(
                      //       Icons.receipt_long_rounded,
                      //       "",
                      //       () => Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder: (_) => const AdministratorTickets(),
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // const SizedBox(height: 25),
              // // 📋 Management Action Section
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
                  color: Colors.brown.withValues(alpha: 0.15),
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
