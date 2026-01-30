import 'package:flutter/material.dart';

import '../Admin/Pages/admin_edit_profile_page.dart';
import '../Pages/NotificationsPage.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final BuildContext pageContext;
  final bool showBackButton;
  final bool showNotificationIcon;
  final bool showHomeIcon;
  final VoidCallback? onHomeClicked;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.pageContext,
    this.showBackButton = true,
    this.showNotificationIcon = false,
    this.showHomeIcon = false,
    this.onHomeClicked,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
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
            color: Colors.black.withValues(alpha: 0.15),
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
              if (showHomeIcon)
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: onHomeClicked,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
