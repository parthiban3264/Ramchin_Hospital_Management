import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Admin/Appbar/admin_appbar_desktop.dart';
import '../../Admin/Pages/adding_page.dart';
import '../../Admin/Pages/admin_dashboard_page.dart';
import '../../Drawer/MedicalStaffDrawer.dart';
import '../../Mediacl_Staff/Appbar/MedicalStaffAppbarMobile.dart';
import '../../Mediacl_Staff/Pages/Dashboard/CashierDashboard.dart';
import '../../Mediacl_Staff/Pages/Dashboard/LabDashboard.dart';
import '../../Mediacl_Staff/Pages/Dashboard/MedicalDashboard.dart';
// === Other Roles ===
import '../../Mediacl_Staff/Pages/Dashboard/OpDashboard.dart';
// === Doctor Pages ===
import '../../Mediacl_Staff/Pages/Doctor/pages/DoctorOverviewPage.dart';
import '../../Mediacl_Staff/Pages/Doctor/pages/DrOpDashboard/AssistantDrOpDashboard.dart';
import '../../Mediacl_Staff/Pages/Doctor/pages/DrOpDashboard/DrOpDashboardPage.dart'; // === Overview Pages ===
import '../../Mediacl_Staff/Pages/Doctor/pages/DrOpOverview/AssistantDrOpOverview.dart';
import '../../Mediacl_Staff/Pages/Overview/CashierOverview.dart';
import '../../Mediacl_Staff/Pages/Overview/LabOverview.dart';
import '../../Mediacl_Staff/Pages/Overview/MedicalOverview.dart';
import '../../Mediacl_Staff/Pages/Overview/Overviewpage.dart';
import '../../Services/admin_service.dart';

class MedicalStaffDashboardPage extends StatefulWidget {
  final String designation;
  final String hospitalName;
  final String staffName;
  final String staffPhoto;

  const MedicalStaffDashboardPage({
    super.key,
    required this.designation,
    required this.hospitalName,
    required this.staffName,
    required this.staffPhoto,
  });

  @override
  State<MedicalStaffDashboardPage> createState() =>
      _MedicalStaffDashboardPageState();
}

class _MedicalStaffDashboardPageState extends State<MedicalStaffDashboardPage> {
  int selectedIndex = 0;
  List<Widget> pages = [];

  bool accessAdmin = false;

  Future<bool> onWillPop() async => false;

  @override
  void initState() {
    super.initState();
    loadAccessAndInitPages();
  }

  // ===================== LOAD ROLE (FIXED) =====================
  Future<void> loadAccessAndInitPages() async {
    final prefs = await SharedPreferences.getInstance();

    final storedUserId = prefs.getString('userId');

    bool newAccessAdmin = false;

    if (storedUserId != null) {
      final staffList = await AdminService().getMedicalStaff();

      final staff = staffList.cast<Map<String, dynamic>>().firstWhere(
        (e) => e['user_Id'].toString() == storedUserId,
        orElse: () => {},
      );

      if (staff.isNotEmpty) {
        newAccessAdmin = staff['accessAdminRole'] == true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessAdminRole', newAccessAdmin.toString());
      }
    }

    // ✅ rebuild UI safely
    // setState(() {
    //   accessAdmin = newAccessAdmin;
    //   selectedIndex = 0;
    //   _initializePages();
    // });
    setState(() {
      accessAdmin = newAccessAdmin;
      _initializePages();

      // ✅ keep index if possible
      if (selectedIndex >= pages.length) {
        selectedIndex = 0;
      }
    });
  }

  // ===================== PAGE BUILDER =====================
  void _initializePages() {
    final designation = widget.designation.trim().toLowerCase();

    switch (designation) {
      case "doctor":
        pages = accessAdmin
            ? const [
                AdminOpDashboardPage(),
                DrOverviewPage(),
                AdminAddingPage(),
              ]
            : const [DrOverviewPage(), DrOpDashboardPage()];
        break;

      case "assistant doctor":
        pages = const [AssistantDrOverviewPage(), AssistantDrOpDashboardPage()];
        break;

      case "nurse":
        pages = const [OverviewPage(), OpDashboardPage()];
        break;

      case "cashier":
        pages = const [CashierOverviewPage(), CashierDashboardPage()];
        break;

      case "medical staff":
        pages = const [MedicalOverviewPage(), MedicalDashboardPage()];
        break;

      case "lab technician":
        pages = const [LabOverviewPage(), LabDashboardPage()];
        break;

      default:
        pages = const [OverviewPage()];
    }
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isSmallDesktop = width >= 600 && width < 800;

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        onWillPop();
      },
      // onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(width, 100),
          child: isMobile
              ? MedicalStaffAppbarMobile(
                  title: widget.staffName,
                  isBackEnable: false,
                  isNotificationEnable: true,
                  isDrawerEnable: true,
                  isNotSettingEnable: true,
                )
              : const AdminAppbarDesktop(
                  title: 'Medical Staff Dashboard',
                  isBackEnable: false,
                  isNotificationEnable: true,
                  isDrawerEnable: true,
                ),
        ),
        drawer: MedicalStaffMobileDrawer(
          title: widget.staffName,
          staffPhoto: widget.staffPhoto,
          designation: widget.designation,
          width: isMobile
              ? width * 0.75
              : isSmallDesktop
              ? width / 2
              : width / 3,
        ),

        // ✅ RefreshIndicator added here
        body: RefreshIndicator(
          onRefresh: loadAccessAndInitPages,
          child: pages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(index: selectedIndex, children: pages),
        ),

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            if (index < pages.length) {
              setState(() => selectedIndex = index);
            }
          },
          items: accessAdmin
              ? const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.miscellaneous_services),
                    label: 'Service',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.manage_accounts),
                    label: 'Manage',
                  ),
                ]
              : const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Overview',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                ],
        ),
      ),
    );
  }
}
