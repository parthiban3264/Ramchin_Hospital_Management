import 'package:flutter/material.dart';

import 'SettingPage.dart';

const Color customGold = Color(0xFFBF955E);

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  PreferredSizeWidget _notificationAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Container(
        height: 100,
        decoration: const BoxDecoration(
          color: customGold,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
              //aa
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 26,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAF4E7),
      appBar: _notificationAppBar(context),
      body: const Center(
        child: Text("No new notifications!", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}




