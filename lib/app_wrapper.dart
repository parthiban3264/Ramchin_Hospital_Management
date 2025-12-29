import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Pages/login/widget/HospitalLoginPage.dart';
import 'Services/auth_service.dart';
import 'Services/hospital_Service.dart';
import 'main.dart';

class AppWrapper extends StatefulWidget {
  final Widget child;
  const AppWrapper({super.key, required this.child});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
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
  // CHECK STATUS EVERY 5 SECONDS
  // ------------------------------------------------------
  void startStatusCheck() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        final hospitalId = prefs.getString('hospitalId');
        if (hospitalId == null) return;

        final response = await HospitalService().getHospital();

        Map<String, dynamic>? data;
        if (response is Map && response!.containsKey("data")) {
          data = response["data"];
        } else {
          data = response;
        }

        if (data == null) return;

        final status = data["HospitalStatus"]?.toString();

        // If ACTIVE and dialog is open → close it
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

        // If INACTIVE → show dialog
        if (status == "INACTIVE") {
          _showInactiveDialog();
        }
      } catch (e) {
        setState(() {});
      }
    });
  }

  // ------------------------------------------------------
  // SHOW INACTIVE POPUP WITH COUNTDOWN (ONE TIMER ONLY)
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
        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              // Start ONE timer only
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
                      "Hospital Inactive",
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
                      "Your hospital is BLOCKED / INACTIVE.\nYou will be logged out automatically.",
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
  // LOGOUT USER
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
  Widget build(BuildContext context) => widget.child;
}
