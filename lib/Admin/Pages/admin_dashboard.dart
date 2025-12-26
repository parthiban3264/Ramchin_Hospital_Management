import 'package:flutter/material.dart';

import '../../Drawer/AdminDrawer.dart';
import '../Appbar/admin_appbar_desktop.dart';
import '../Appbar/admin_appbar_mobile.dart';
import 'AddingPage.dart';
import 'AdminDashboardPage.dart';
import 'AdminOverviewPage.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static int selectedIndex = 1;
  Future<bool> onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.sizeOf(context).width;
    bool isMobile = screenWidth < 600;
    bool isSmallDesktop = screenWidth >= 600 && screenWidth < 800;
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(screenWidth, 100),
          child: isMobile
              ? AdminAppbarMobile(
                  title: 'Admin Dashboard',
                  isBackEnable: false,
                  isNotificationEnable: false,
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
        body: IndexedStack(
          index: selectedIndex,
          children: [
            AdminOpDashboardPage(),
            AdminOverviewPage(),


            AdminAddingPage(),
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

            BottomNavigationBarItem(
              icon: Icon(Icons.miscellaneous_services),
              label: 'Service',
            ),
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
