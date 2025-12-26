import 'package:flutter/material.dart';
import '../Pages/NotificationsPage.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final BuildContext pageContext;
  final bool showBackButton;
  final bool showNotificationIcon;
  final bool showHomeIcon;
  final Widget? homePage; // 👈 NEW: dynamic home page widget

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.pageContext,
    this.showBackButton = true,
    this.showNotificationIcon = false,
    this.showHomeIcon = false,
    this.homePage, // 👈 optional parameter
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.blue;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(pageContext),
                ),
              if (!showBackButton)
                if (showHomeIcon && homePage != null)
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        pageContext,
                        MaterialPageRoute(builder: (_) => homePage!),
                        (route) => false,
                      );
                    },
                  ),
              if (showBackButton)
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              const Spacer(),
              if (showNotificationIcon)
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      pageContext,
                      MaterialPageRoute(
                        builder: (_) => const NotificationPage(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// appBar: CustomAppBar(
// title: 'Doctor Prescription',
// pageContext: context,
// showHomeIcon: true,
// homePage: const (), // 👈 specific home page
// ),

// truncate table consultation;
// truncate table fees;
//
// truncate table injection;
// truncate table medician;
// truncate table medicineandinjection;
// truncate table payment;
// truncate table roomsavailable;
// truncate table testingandscanninghospital;
// truncate table testingandscanningpatient;
// truncate table treatment;
// truncate table patient;
// truncate table admin;
// truncate table adminstrator;
// truncate table user;
// truncate table hospital;
