// import 'package:flutter/material.dart';
// import 'package:hospitrax/Pages/NotificationsPage.dart';
// import 'package:hospitrax/Pages/SettingPage.dart';
// import '../../Admin/Colors/custom_colors.dart';
//
// class MedicalStaffAppbarMobile extends StatelessWidget {
//   const MedicalStaffAppbarMobile({
//     super.key,
//     required this.title,
//     required this.isBackEnable,
//     required this.isNotificationEnable,
//     required this.isNotSettingEnable,
//     this.onBack,
//     this.notificationRoute,
//     this.settingRoute,
//     required this.isDrawerEnable,
//   });
//
//   final String title;
//   final bool isBackEnable;
//   final bool isNotificationEnable;
//   final bool isNotSettingEnable;
//   final bool isDrawerEnable;
//
//   final VoidCallback? onBack;
//   final Widget? settingRoute;
//   final Widget? notificationRoute;
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 100,
//       decoration: const BoxDecoration(
//         color: CustomColors.customGold,
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(12),
//           bottomRight: Radius.circular(12),
//         ),
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: Row(
//             children: [
//               isDrawerEnable
//                   ? IconButton(
//                       onPressed: () {
//                         Scaffold.of(context).openDrawer();
//                       },
//                       icon: Icon(Icons.menu, color: Colors.white, size: 26),
//                     )
//                   : SizedBox(),
//               isBackEnable
//                   ? IconButton(
//                       icon: const Icon(
//                         Icons.arrow_back_ios,
//                         color: Colors.white,
//                       ),
//                       onPressed: onBack,
//                     )
//                   : SizedBox(),
//               const SizedBox(width: 8),
//               Padding(
//                 padding: const EdgeInsets.only(left: 10),
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 24,
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               isNotificationEnable
//                   ? IconButton(
//                       icon: const Icon(
//                         Icons.notifications,
//                         color: Colors.white,
//                       ),
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => NotificationPage(),
//                           ),
//                         );
//                       },
//                     )
//                   : SizedBox(),
//               SizedBox(width: 2),
//               isNotSettingEnable
//                   ? IconButton(
//                       icon: const Icon(Icons.settings, color: Colors.white),
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => SettingsPage(),
//                           ),
//                         );
//                       },
//                     )
//                   : SizedBox(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:hospitrax/Pages/NotificationsPage.dart';
import 'package:hospitrax/Pages/SettingPage.dart';
import '../../Admin/Colors/custom_colors.dart';

class MedicalStaffAppbarMobile extends StatelessWidget {
  const MedicalStaffAppbarMobile({
    super.key,
    required this.title,
    required this.isBackEnable,
    required this.isNotificationEnable,
    required this.isNotSettingEnable,
    this.onBack,
    this.notificationRoute,
    this.settingRoute,
    required this.isDrawerEnable,
  });

  final String title;
  final bool isBackEnable;
  final bool isNotificationEnable;
  final bool isNotSettingEnable;
  final bool isDrawerEnable;

  final VoidCallback? onBack;
  final Widget? settingRoute;
  final Widget? notificationRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        color: CustomColors.customGold,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              /// ☰ Drawer
              if (isDrawerEnable)
                IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                ),

              /// ← Back
              if (isBackEnable)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: onBack,
                ),

              const SizedBox(width: 6),

              /// 🏷 TITLE (FIXED AREA)
              Expanded(
                child: Text(
                  title,
                  maxLines: 1, // ✅ prevents overflow
                  overflow: TextOverflow.ellipsis, // ✅ adds "..."
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20, // slightly reduced for safety
                  ),
                ),
              ),

              /// 🔔 Notification
              if (isNotificationEnable)
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationPage(),
                      ),
                    );
                  },
                ),

              /// ⚙ Settings
              if (isNotSettingEnable)
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
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
