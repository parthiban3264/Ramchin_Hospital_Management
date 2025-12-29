import 'package:flutter/material.dart';

import '../../../../Pages/NotificationsPage.dart';
import 'TonicAddPage.dart';
import 'expiry_tonic_page.dart';
import 'modify_tonic_page.dart';

class TonicPage extends StatefulWidget {
  const TonicPage({super.key});

  @override
  State<TonicPage> createState() => _TonicPageState();
}

class _TonicPageState extends State<TonicPage> {
  int _currentIndex = 0;
  static const Color gold = Color(0xFFBF955E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: const [AddTonicPage(), ModifyTonicPage(), ExpiryTonicPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: gold,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Add",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: "Modify"),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber),
            label: "Expiry",
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Container(
        height: 100,
        decoration: const BoxDecoration(
          color: gold,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Tonic Management",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
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
      ),
    );
  }
}
