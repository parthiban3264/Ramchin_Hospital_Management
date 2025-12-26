import 'package:flutter/material.dart';
import '../../Admin/Colors/Colors.dart';

class AdminAppbarMobile extends StatelessWidget {
  const AdminAppbarMobile({
    super.key,
    required this.title,
    required this.isBackEnable,
    required this.isNotificationEnable,
    this.onBack,
    this.notificationRoute,
    required this.isDrawerEnable,
  });

  final String title;
  final bool isBackEnable;
  final bool isNotificationEnable;
  final bool isDrawerEnable;

  final VoidCallback? onBack;
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
              // Drawer
              isDrawerEnable
                  ? IconButton(
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 26,
                      ),
                    )
                  : const SizedBox(),

              // Back button
              isBackEnable
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: onBack,
                    )
                  : const SizedBox(),

              const Spacer(),

              // Title (px warning removed)
              Padding(
                padding: const EdgeInsets.only(left: 1),
                child: Text(
                  title,

                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // const SizedBox(width: 10),
              const Spacer(),

              // Notification button
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
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
