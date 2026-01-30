import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Pages/login/widget/HospitalLoginPage.dart';
import '../../Services/admin_service.dart';
import '../../Services/auth_service.dart';
import '../../main.dart';

class AdminAppWrapper extends StatefulWidget {
  final Widget child;
  const AdminAppWrapper({super.key, required this.child});

  @override
  State<AdminAppWrapper> createState() => _AdminAppWrapperState();
}

class _AdminAppWrapperState extends State<AdminAppWrapper> {
  Timer? _statusTimer;
  Timer? countdownTimer;

  bool dialogOpen = false;
  int countdown = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startStatusCheck();
    });
  }

  // ------------------------------------------------------
  // CHECK MEDICAL STAFF STATUS EVERY 5s
  // ------------------------------------------------------
  void startStatusCheck() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        final hospitalId = prefs.getString('hospitalId');

        if (hospitalId == null || userId == null) return;

        // Load all staff
        final staffList = await AdminService().getMedicalStaff();
        if (staffList.isEmpty) return;

        // Find CURRENT user
        final currentStaff = staffList.firstWhere(
          (item) =>
              item["user_Id"].toString().trim() == userId.toString().trim(),
          orElse: () => null,
        );

        if (currentStaff == null) return;

        final status = currentStaff["status"].toString().toUpperCase();

        if (status == "ACTIVE") {
          if (dialogOpen && mounted) {
            Navigator.of(navigatorKey.currentState!.overlay!.context).pop();
          }

          dialogOpen = false;
          countdownTimer?.cancel();
          countdownTimer = null;
          countdown = 30;
          return;
        }

        if (status == "INACTIVE") {
          _showInactiveDialog();
        }
      } catch (e) {
        setState(() {});
      }
    });
  }

  // ------------------------------------------------------
  // POPUP WITH COUNTDOWN
  // ------------------------------------------------------
  void _showInactiveDialog() {
    if (dialogOpen) return;

    dialogOpen = true;
    countdown = 30;

    countdownTimer?.cancel();

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) {
        return PopScope(
          canPop: false,
          // onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (
                timer,
              ) {
                if (!dialogOpen) return;

                setDialogState(() {
                  countdown--;
                });

                if (countdown <= 0) {
                  timer.cancel();
                  _logout();
                }
              });

              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Column(
                  children: const [
                    Icon(Icons.block, size: 60, color: Colors.red),
                    SizedBox(height: 10),
                    Text(
                      "Staff Inactive",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Your account is INACTIVE.\nYou will be logged out automatically.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Auto logout in: ${countdown}s",
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _logout,
                    child: const Text(
                      "LOGOUT NOW",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------
  Future<void> _logout() async {
    dialogOpen = false;
    countdownTimer?.cancel();
    countdownTimer = null;
    _statusTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await AuthService().logout();
    await prefs.clear();

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HospitalLoginPage()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
