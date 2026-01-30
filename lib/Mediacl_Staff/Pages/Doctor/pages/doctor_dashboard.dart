import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../appbar/doctor_appbar_mobile.dart';
import '../service/doctor_service.dart';
import '../widgets/build_hospital_profile.dart';
import '../widgets/doctor_home_page.dart';
import '../widgets/doctor_patient_page.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => DoctorDashboardState();
}

class DoctorDashboardState extends State<DoctorDashboard> {
  List<dynamic> consultations = [];
  static int selectedIndex = 0;

  bool isLoading = true;

  String? hospitalId;
  String? doctorId;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => isLoading = true);

    // Fetch hospitalId and doctorId from secure storage
    hospitalId = prefs.getString('hospitalId');
    doctorId = prefs.getString('userId');
    if (hospitalId != null && doctorId != null) {
      // Fetch consultations for this doctor
      final allConsultations = await DoctorServices.getConsultationsByDoctorId(
        hospitalId: int.parse(hospitalId!),
        doctorId: doctorId!,
      );

      // Filter by PENDING or ONGOING
      consultations = allConsultations
          .where((c) => c['status'] == 'PENDING' || c['status'] == 'ONGOING')
          .toList();
    }

    setState(() => isLoading = false);
  }

  Future<bool> _onWillPop() async {
    // Prevent back navigation
    return false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.sizeOf(context).width;

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        _onWillPop();
      },
      // onWillPop: _onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(screenWidth, 100),
          child: const DoctorAppbarMobile(
            title: 'Doctor Dashboard',
            isDrawerEnable: false,
            isBackEnable: false,
            isNotificationEnable: false,
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const BuildHospitalProfile(),
                    IndexedStack(
                      index: selectedIndex,
                      children: [
                        // Home Page
                        if (hospitalId != null && doctorId != null)
                          DoctorHomePage(
                            hospitalId: int.parse(hospitalId!),
                            doctorId: doctorId!,
                          )
                        else
                          const Center(child: Text('Unable to load Home Page')),

                        // Patient Page
                        if (hospitalId != null && doctorId != null)
                          DoctorPatientPage(
                            hospitalId: int.parse(hospitalId!),
                            doctorId: doctorId!,
                            consultations: consultations,
                          )
                        else
                          const Center(
                            child: Text('Unable to load Patient Page'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          currentIndex: selectedIndex,
          onTap: (val) {
            setState(() {
              selectedIndex = val;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Patient'),
          ],
        ),
      ),
    );
  }
}
