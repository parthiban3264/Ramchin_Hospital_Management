import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Admin/Colors/custom_colors.dart';
import '../Admin/Pages/admin_edit_profile_page.dart';
import '../Admin/Pages/admin_profile_page.dart';
import '../Admin/Pages/change_password_page.dart';
import '../Admin/Pages/contact_page.dart';
import '../Admin/Pages/flow_instruction_page.dart';
import '../Admin/Pages/globals.dart';
import '../Admin/Pages/privacy_policy_page.dart';
import '../Admin/Pages/terms_conditions_page.dart';
import '../Admin/Pages/version_update_page.dart';
import '../Pages/NotificationsPage.dart';
import '../Pages/login/widget/HospitalLoginPage.dart';
import '../Services/auth_service.dart';

class AdminMobileDrawer extends StatefulWidget {
  final String title;
  final double width;
  final String designation;
  final String staffPhoto;

  const AdminMobileDrawer({
    super.key,
    required this.title,
    required this.width,
    required this.designation,
    required this.staffPhoto,
  });

  @override
  State<AdminMobileDrawer> createState() => _AdminMobileDrawerState();
}

class _AdminMobileDrawerState extends State<AdminMobileDrawer> {
  String? userId;

  @override
  void initState() {
    super.initState();
    loadUserId();
    grtAccountType();
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  String? accountType;

  Future<void> grtAccountType() async {
    final prefs = await SharedPreferences.getInstance();
    final accountType = prefs.getString('accountType');
    if (!mounted) return;
    setState(() {
      this.accountType = accountType;
    });
  }

  @override
  Widget build(BuildContext context) {
    int selectedIndex = 0;

    // Drawer items with navigation targets
    final List<Map<String, dynamic>> drawerItems = [
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
      {
        "icon": Icons.policy,
        "label": "Privacy policy",
        "page": const PrivacyPolicyPage(),
      },
      {
        "icon": Icons.privacy_tip_outlined,
        "label": "Terms & Conditions",
        "page": const TermsConditionsPage(),
      },
      {
        "icon": Icons.integration_instructions,
        "label": "FlowChart & Instruction",
        "page": FlowChartInstructionPage(),
      },
      {
        "icon": Icons.contact_phone,
        "label": accountType == 'DEMO' ? "Contact Us" : "Submit Ticket",
        "page": ContactPage(),
      },
      {
        "icon": Icons.update,
        "label": "App Version Check",
        "page": VersionUpdatePage(),
      },
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
      width: widget.width,
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔝 TOP BAR
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// 🏷 DESIGNATION (clean + aligned)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              /// 🔸 Accent Pill Line (better than flat line)
                              Icon(
                                Icons.menu_open_rounded,
                                size: 23,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),

                              const SizedBox(width: 4),

                              /// 📝 TEXT
                              Flexible(
                                child: Text(
                                  widget.designation.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors
                                        .black87, // 👈 softer, more premium
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    letterSpacing: 0.4,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          /// ❌ CLOSE BUTTON (refined)
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// subtle spacing
                    const SizedBox(height: 2),

                    /// ➖ DIVIDER
                    Divider(
                      color: Colors.grey.shade200,
                      thickness: 1.5,
                      height: 1,
                    ),
                    const SizedBox(height: 6),

                    /// 👤 PROFILE SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          /// 🧑 AVATAR
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CustomColors.customGold.withOpacity(
                                  0.35,
                                ),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ValueListenableBuilder<String>(
                              valueListenable: staffPhotoNotifier,
                              builder: (context, photo, _) {
                                final imageUrl = (photo.isNotEmpty)
                                    ? photo
                                    : "https://www.shutterstock.com/image-vector/stylized-doctor-vector-260nw-163380338.jpg";

                                return CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey.shade100,
                                  backgroundImage: NetworkImage(imageUrl),
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          /// 📝 TEXT
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// NAME
                                Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                /// USER ID
                                Text(
                                  userId ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),
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
