import 'package:flutter/material.dart';
import 'package:hospitrax/Pages/NotificationsPage.dart';

import '../../Admin/Appbar/admin_appbar_desktop.dart';
import '../../Admin/Appbar/admin_appbar_mobile.dart';
import '../../Administrator/administrator_home.dart';
import '../../Administrator/administrator_manage.dart';
import '../../Drawer/AdminDrawer.dart';

class AdministratorDashboardPage extends StatefulWidget {
  final dynamic hospitalData;
  final VoidCallback? onHospitalUpdated;
  const AdministratorDashboardPage({
    super.key,
    required this.hospitalData,
    this.onHospitalUpdated,
  });

  @override
  State<AdministratorDashboardPage> createState() =>
      _AdministratorDashboardPageState();
}

class _AdministratorDashboardPageState
    extends State<AdministratorDashboardPage> {
  static int selectedIndex = 0;
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
      //onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(screenWidth, 100),
          child: isMobile
              ? AdminAppbarMobile(
                  title: widget.hospitalData['name'],
                  isBackEnable: true,
                  onBack: () {
                    onWillPop();
                  },
                  isNotificationEnable: true,
                  notificationRoute: NotificationPage(),
                  isDrawerEnable: false,
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
        body: IndexedStack(
          index: selectedIndex,
          children: [
            AdministratorHome(hospitalData: widget.hospitalData),
            AdministratorManagePage(
              hospitalData: widget.hospitalData,
              onHospitalUpdated: () {
                widget.onHospitalUpdated?.call(); // refresh top-level
                setState(() {}); // rebuild this intermediate page
              },
            ),
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
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts),
              label: 'Manage',
            ),
            // BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Manage'),
          ],
        ),
      ),
    );
  }
}
