import 'package:flutter/material.dart';

import '../../../../Admin/Colors/Colors.dart';

class DoctorAppbarMobile extends StatefulWidget {
  const DoctorAppbarMobile({
    super.key,
    required this.title,
    required this.isBackEnable,
    required this.isNotificationEnable,
    required this.isDrawerEnable,
    this.onBack,
    this.notificationRoute,
  });
  final String title;
  final bool isBackEnable;
  final bool isNotificationEnable;
  final bool isDrawerEnable;

  final VoidCallback? onBack;
  final Widget? notificationRoute;
  @override
  State<DoctorAppbarMobile> createState() => _DoctorAppbarMobileState();
}

class _DoctorAppbarMobileState extends State<DoctorAppbarMobile> {
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
              widget.isDrawerEnable
                  ? IconButton(
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      icon: Icon(Icons.menu, color: Colors.white, size: 26),
                    )
                  : SizedBox(),
              widget.isBackEnable
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: widget.onBack,
                    )
                  : SizedBox(),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
              ),
              const Spacer(),
              widget.isNotificationEnable
                  ? IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => widget.notificationRoute!,
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
