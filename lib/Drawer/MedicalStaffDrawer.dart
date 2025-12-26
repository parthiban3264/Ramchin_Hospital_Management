import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitrax/Admin/Pages/AdminProfilePage.dart';
import '../../../Pages/DrawerPages/Consulate/ConsultationPage.dart';
import '../Admin/Pages/changePasswordPage.dart';
import '../Admin/Pages/globals.dart';
import '../Mediacl_Staff/Pages/Overview/Overviewpage.dart';
import '../Mediacl_Staff/Pages/OutPatient/PatientRegistrationPage.dart';
import '../../../Pages/DrawerPages/ReceptionDeskPage.dart';
import '../../Admin/Colors/Colors.dart';
import '../Admin/Pages/AdminEditProfilePage.dart';
import '../Pages/DrawerPages/Consulate/ReceptionDeskQueue.dart';
import '../Pages/DrawerPages/TreatmentQueuePage.dart';
import '../Pages/NotificationsPage.dart';
import '../Pages/UserIdCheckPage.dart';
import '../Pages/login/widget/HospitalLoginPage.dart';
import '../Services/auth_service.dart';

class MedicalStaffMobileDrawer extends StatefulWidget {
  const MedicalStaffMobileDrawer({
    super.key,
    required this.title,
    required this.width,
    required this.designation, // added to filter drawer items by role
    required this.staffPhoto,
  });

  final String title;
  final double width;
  final String designation;
  final String staffPhoto;

  @override
  State<MedicalStaffMobileDrawer> createState() =>
      _MedicalStaffMobileDrawerState();
}

class _MedicalStaffMobileDrawerState extends State<MedicalStaffMobileDrawer> {
  int selectedIndex = 0;

  final List<Map<String, dynamic>> allDrawerItems = [
    {
      "icon": Icons.person,
      "label": "Profile",
      "page": const ProfilePage(),
      "roles": [
        "doctor",
        "nurse",
        "lab technician",
        "cashier",
        "medical staff",
        "assistant doctor",
      ],
    },
    {
      "icon": Icons.edit_outlined,
      "label": "Edit Profile",
      "page": const EditProfilePage(),
      "roles": [
        "cashier",
        "doctor",
        "nurse",
        "lab technician",
        "medical staff",
        "assistant doctor",
      ],
    },
    {
      "icon": Icons.change_circle_outlined,
      "label": "Change Password",
      "page": const ChangePasswordPage(),
      "roles": [
        "cashier",
        "doctor",
        "nurse",
        "lab technician",
        "medical staff",
        "assistant doctor",
      ],
    },
  ];

  late List<Map<String, dynamic>> drawerItems;

  @override
  void initState() {
    super.initState();
    userIdload();
    // Filter drawer items based on the user's role
    drawerItems = allDrawerItems
        .where((item) => item["roles"].contains(widget.designation))
        .toList();

    // Fallback to Overview if no item matches
    if (drawerItems.isEmpty) {
      drawerItems = [allDrawerItems.first];
    }
  }

  String? userId;

  Future<void> userIdload() async {
    final secureStorage = const FlutterSecureStorage();
    final storedUserId = await secureStorage.read(key: 'userId');

    setState(() {
      userId = storedUserId;
    });
  }

  void onSelectItem(int index) {
    setState(() {
      selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => drawerItems[index]["page"]),
    ).then(
      (_) => setState(() {
        selectedIndex = 0;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('drawer items $drawerItems ${widget.designation}');
    return Drawer(
      backgroundColor: CustomColors.customGold,
      width: widget.width,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // 🔹 Reactive CircleAvatar
                            ValueListenableBuilder<String>(
                              valueListenable:
                                  staffPhotoNotifier, // global ValueNotifier
                              builder: (context, value, child) {
                                return CircleAvatar(
                                  radius: 30,
                                  backgroundColor: CustomColors.customGold,
                                  backgroundImage: (value.isNotEmpty)
                                      ? NetworkImage(value)
                                      : null,
                                  child: (value.isEmpty)
                                      ? const Icon(
                                          Icons.local_hospital,
                                          color: Colors.white,
                                          size: 30,
                                        )
                                      : null,
                                );
                              },
                            ),

                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userId ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.designation.toUpperCase(),
                          style: TextStyle(
                            color: CustomColors.customGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
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
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
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
            // ListTile(
            //   leading: const Icon(Icons.logout, color: Colors.white),
            //   title: const Text(
            //     "Logout",
            //     style: TextStyle(color: Colors.white),
            //   ),
            //   onTap: () async {
            //     const secureStorage = FlutterSecureStorage();
            //     await AuthService().logout();
            //     await secureStorage.deleteAll();
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
                  const secureStorage = FlutterSecureStorage();
                  await AuthService().logout(); // logout API call
                  await secureStorage.deleteAll(); // clear all local storage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HospitalLoginPage(),
                    ),
                  );
                } catch (e) {
                  // Optional: show error message
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
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
                      Icons.settings,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotificationPage()),
                      );
                    },
                  ),
                  if (showNotificationIcon)
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NotificationPage()),
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
