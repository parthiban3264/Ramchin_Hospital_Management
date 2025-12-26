import 'package:flutter/material.dart';

import '../../Admin/Colors/Colors.dart';

class PatientAppbarDesktop extends StatelessWidget {
  const PatientAppbarDesktop({
    super.key,
    required this.title,
    required this.isBackEnable,
    required this.isNotificationEnable,
    this.backRoute,
    this.notificationRoute,
    required this.isDrawerEnable,
  });

  final String title;
  final bool isBackEnable;
  final bool isNotificationEnable;
  final bool isDrawerEnable;

  final Widget? backRoute;
  final Widget? notificationRoute;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        color: CustomColors.customGold,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              isDrawerEnable
                  ? IconButton(
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      icon: Icon(Icons.menu, color: Colors.white, size: 26),
                    )
                  : SizedBox(),
              isBackEnable
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => backRoute!),
                        );
                      },
                    )
                  : SizedBox(),

              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
              const Spacer(),
              isNotificationEnable
                  ? IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => notificationRoute!,
                          ),
                        );
                      },
                    )
                  : SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
