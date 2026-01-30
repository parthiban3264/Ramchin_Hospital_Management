import 'package:flutter/material.dart';
import 'package:hospitrax/Pages/NotificationsPage.dart';

import '../../Admin/Appbar/admin_appbar_desktop.dart';
import '../../Admin/Appbar/admin_appbar_mobile.dart';
import '../../Drawer/AdminDrawer.dart';
import '../../Patient/Pages/Patient_Home.dart';
import '../../Patient/Pages/Patient_manage.dart';
import '../../Services/hospital_Service.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => PatientDashboardPageState();

  // 🔥 Allow children (PatientHome) to call refresh
  static PatientDashboardPageState? of(BuildContext context) =>
      context.findAncestorStateOfType<PatientDashboardPageState>();
}

class PatientDashboardPageState extends State<PatientDashboardPage> {
  final HospitalService hospitalService = HospitalService();

  static int selectedIndex = 0;

  bool isListLoading = false;

  Map<String, dynamic> hospitals = {};

  @override
  void initState() {
    super.initState();
    loadHospitals();
  }

  Future<void> loadHospitals() async {
    setState(() => isListLoading = true);

    final hospitalsList = await hospitalService.getOneHospitals();

    setState(() {
      hospitals = hospitalsList;
      isListLoading = false;
    });
  }

  // 🔥 Called from child widget (PatientHome)
  Future<void> refreshFromChild() async {
    await loadHospitals();
  }

  Future<bool> onWillPop() async {
    Navigator.pop(context);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.sizeOf(context).width;

    bool isMobile = screenWidth < 600;
    bool isSmallDesktop = screenWidth >= 600 && screenWidth < 800;

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        onWillPop();
      },
      // onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(screenWidth, 100),
          child: isMobile
              ? AdminAppbarMobile(
                  title: 'Patient Dashboard',
                  isBackEnable: false,
                  onBack: () {
                    onWillPop();
                  },
                  isNotificationEnable: true,
                  notificationRoute: NotificationPage(),
                  isDrawerEnable: true,
                )
              : AdminAppbarDesktop(
                  title: 'Patient Dashboard',
                  isBackEnable: false,
                  isNotificationEnable: true,
                  isDrawerEnable: true,
                ),
        ),

        drawer: AdminMobileDrawer(
          title: 'Menu',
          width: isMobile
              ? MediaQuery.of(context).size.width * 0.75
              : isSmallDesktop
              ? MediaQuery.of(context).size.width / 2
              : MediaQuery.of(context).size.width / 3,
        ),

        body: isListLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: selectedIndex,
                children: [
                  PatientHome(hospitalData: hospitals),
                  PatientManage(hospitalData: hospitals),
                ],
              ),

        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          currentIndex: selectedIndex,
          elevation: 10,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts),
              label: 'Manage',
            ),
          ],
        ),
      ),
    );
  }
}
