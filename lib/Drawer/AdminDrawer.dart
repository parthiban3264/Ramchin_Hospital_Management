import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Admin/Colors/custom_colors.dart';
import '../Admin/Pages/admin_edit_profile_page.dart';
import '../Admin/Pages/admin_profile_page.dart';
import '../Admin/Pages/change_password_page.dart';
import '../Pages/NotificationsPage.dart';
import '../Pages/login/widget/HospitalLoginPage.dart';
import '../Services/auth_service.dart';

class AdminMobileDrawer extends StatelessWidget {
  const AdminMobileDrawer({
    super.key,
    required this.title,
    required this.width,
  });
  final String title;
  final double width;
  @override
  Widget build(BuildContext context) {
    int selectedIndex = 0;

    // Drawer items with navigation targets
    final List<Map<String, dynamic>> drawerItems = [
      // {
      //   "icon": Icons.dashboard_outlined,
      //   "label": "Overview",
      //   "page": const OverviewPage(),
      // },
      {"icon": Icons.person, "label": "Profile", "page": const ProfilePage()},
      {
        "icon": Icons.edit_outlined,
        "label": "Edit Profile",
        "page": const EditProfilePage(),
      },

      {
        "icon": Icons.change_circle,
        "label": "Change Password",
        "page": const ChangePasswordPage(),
      },

      // {
      //   "icon": Icons.receipt_long,
      //   "label": "REGISTER",
      //   "page": PatientRegistrationPage(),
      // },
      // {
      //   "icon": Icons.healing_outlined,
      //   "label": "PAYMENTS",
      //   "page": FeesQueuePage(),
      // },
      // {
      //   "icon": Icons.healing_outlined,
      //   "label": "SYMPTOMS",
      //   "page": SymptomsQueuePage(),
      // },
      // {"icon": Icons.queue, "label": "OP QUEUE", "page": OutpatientQueuePage()},
      // // {
      // //   "icon": Icons.receipt,
      // //   "label": "LAB",
      // //   "page": const GenericPage(title: "Billing"),
      // // },
      // {
      //   "icon": Icons.medical_information,
      //   "label": "MEDICALS",
      //   "page": MedicalQueuePage(),
      // },
      // {
      //   "icon": Icons.medical_information,
      //   "label": "INJECTION",
      //   "page": const GenericPage(title: "INJECTION"),
      // },
    ];

    void onSelectItem(int index) {
      selectedIndex = index;
      Navigator.pop(context); // Close the drawer

      // Navigate to selected page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => drawerItems[index]["page"]),
      ).then((_) {
        // Return to Overview after closing the new page
        selectedIndex = 0;
      });
    }

    return Drawer(
      backgroundColor: CustomColors.customGold,
      width: width,
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 26,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Column(
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: CustomColors.customGold,
                          child: const Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: TextStyle(
                            color: CustomColors.customGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: drawerItems.length,
                itemBuilder: (context, index) {
                  final item = drawerItems[index];
                  final selected = index == selectedIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    // decoration: BoxDecoration(
                    //   color: selected
                    //       ? Colors.white.withValues(alpha:0.3)
                    //       : Colors.transparent,
                    //   borderRadius: BorderRadius.circular(10),
                    // ),
                    child: ListTile(
                      leading: Icon(
                        item["icon"],
                        color: selected ? Colors.black : Colors.white,
                      ),
                      title: Text(
                        item["label"],
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.white,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () => onSelectItem(index),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white70, thickness: 1),

            // Inside your ListTile:
            // ListTile(
            //   leading: const Icon(Icons.logout, color: Colors.white),
            //   title: const Text(
            //     "Logout",
            //     style: TextStyle(color: Colors.white),
            //   ),
            //   onTap: () async {
            //     const secureStorage = FlutterSecureStorage();
            //
            //     // Clear all stored data
            //     await secureStorage.deleteAll();
            //
            //     // Navigate to login page
            //     Navigator.pushReplacement(
            //       context,
            //       MaterialPageRoute(builder: (_) => const HospitalLoginPage()),
            //     );
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                try {
                  final prefs = await SharedPreferences.getInstance();

                  await AuthService().logout(); // logout API call
                  await prefs.clear(); // clear all local storage
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HospitalLoginPage(),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class GenericPage extends StatelessWidget {
  final String title;
  final bool showNotificationIcon;
  const GenericPage({
    super.key,
    required this.title,
    this.showNotificationIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E6),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: CustomColors.customGold,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const NotificationPage(), // your page here
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Text(
          "$title Content",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
