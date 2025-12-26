import 'package:flutter/material.dart';

const Color customGold = Color(0xFFBF955E);

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
                // IconButton(
                //   icon: const Icon(Icons.settings, color: Colors.white),
                //   onPressed: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (_) => const SettingsPage()),
                //     );
                //   },
                // ),
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
        child: Text("No create SettingPage", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
