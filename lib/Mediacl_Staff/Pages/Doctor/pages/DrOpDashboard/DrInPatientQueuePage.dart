import 'package:flutter/material.dart';

import '../../../../../Pages/NotificationsPage.dart';

class DrInPatientQueuePage extends StatefulWidget {
  const DrInPatientQueuePage({super.key});

  @override
  State<DrInPatientQueuePage> createState() => _DrInPatientQueuePageState();
}

class _DrInPatientQueuePageState extends State<DrInPatientQueuePage> {
  final Color primaryColor = const Color(0xFFBF955E);
  String? selectedIndex;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
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
                    "InPatient Queue",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.group_rounded, color: Colors.white),
                    tooltip: "Show All Patients",
                    onPressed: () {
                      setState(() => selectedIndex = null);
                    },
                  ),
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
      ),
      body: Center(child: Text("Coming Soon . . .")),
    );
  }
}
