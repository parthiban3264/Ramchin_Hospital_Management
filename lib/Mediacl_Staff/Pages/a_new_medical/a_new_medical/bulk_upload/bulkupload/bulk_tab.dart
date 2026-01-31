import 'package:flutter/material.dart';
import 'bulk_tab_exist.dart';
import 'bulk_tab_new_medicine.dart';

class BulkUploadPage extends StatefulWidget {
  const BulkUploadPage({super.key});

  @override
  State<BulkUploadPage> createState() => _BulkUploadPageState();
}

class _BulkUploadPageState extends State<BulkUploadPage> {
  int _selectedIndex = 0;

  final Color royal = const Color(0xFF875C3F);

  final List<String> _appBarTitles = const [
    "New Medicine Bulk Upload",
    "Exist Medicine Bulk Upload",
  ];

  final List<Widget> _pages = const [
    BulkUploadNewTabsPage(),
    BulkUploadExistTabsPage(), // 👈 nested tabs here
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: royal,
        title: Text(
          _appBarTitles[_selectedIndex],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        backgroundColor: royal, // Olive Green 🌿
        selectedItemColor: Colors.white, // Muted Tan 🏺
        unselectedItemColor: Colors.white.withValues(
          alpha: 0.7,
        ), // lighter tan for unselected
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            label: "New_Medicine",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: "Exist_Medicine",
          ),
        ],
      ),
    );
  }
}
