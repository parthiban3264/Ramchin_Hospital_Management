import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Admin/Pages/contact_page.dart';
import 'Services/admin_service.dart';
import 'Services/auth_service.dart';

class FirstLoginWrapper extends StatefulWidget {
  final Widget child;

  const FirstLoginWrapper({super.key, required this.child});

  @override
  State<FirstLoginWrapper> createState() => _FirstLoginWrapperState();
}

class _FirstLoginWrapperState extends State<FirstLoginWrapper> {
  @override
  void initState() {
    super.initState();
    _checkFirstLogin();
  }

  String? version;

  Future<void> _checkFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLogin = prefs.getBool('isFirstLogin') ?? false;
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    if (!mounted) return;

    setState(() {
      version = currentVersion;
    });

    if (isFirstLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDialog();
      });

      /// 🔥 IMPORTANT: make it false after showing
      await prefs.setBool('isFirstLogin', false);
      final accountType = await prefs.getString('accountType');
      await _updateFirstLoginStatus(accountType);
    }
  }

  Future<void> _updateFirstLoginStatus(String? accountType) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final userId = prefs.getInt("id");

      if (userId != null && accountType != 'DEMO') {
        await AdminService().updateUser(userId, {"isFirstLogin": false});
      }

      /// ✅ ALWAYS update local (even if API fails)
      await prefs.setBool('isFirstLogin', false);
    } catch (e) {
      print("Error updating first login: $e");

      /// fallback → still prevent dialog repeat
      await prefs.setBool('isFirstLogin', false);
    }
  }

  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FirstLoginDialog(version: version),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 🎨 BRAND COLORS
const Color primaryColor = Color(0xFFBF955E);
const Color darkPrimary = Color(0xFF8B6B3F);

/// =======================
/// 🔥 MAIN DIALOG
/// =======================
class FirstLoginDialog extends StatefulWidget {
  final String? version;
  const FirstLoginDialog({super.key, this.version});

  @override
  State<FirstLoginDialog> createState() => _FirstLoginDialogState();
}

class _FirstLoginDialogState extends State<FirstLoginDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    /// 🎬 Entry Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnim = Tween(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 📄 BODY
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      /// TITLE ROW (FIXED ALIGNMENT ✅)
                      Row(
                        children: [
                          /// empty space same as close button
                          const SizedBox(width: 40),

                          /// CENTER TITLE
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  "Welcome 👋",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF222222),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  'version ${widget.version}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// ❌ CLOSE BUTTON (improved)
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      /// ✨ TYPEWRITER TEXT
                      const AnimatedTypewriterText(
                        text:
                            "Welcome to Ramchin Hospital Management System.\n\nManage patients records, doctors, nurse, staffs and hospital workflows efficiently.\n\nWould you like to connect with us for support or services?",
                      ),

                      const SizedBox(height: 26),

                      /// 🔘 BUTTON
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ContactPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 2,
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                "Contact Us",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// FOOTER
                      Text(
                        "Powered by Ramchin Technologies Pvt Ltd",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// =======================
/// ✨ TYPEWRITER ANIMATION
/// =======================
class AnimatedTypewriterText extends StatefulWidget {
  final String text;

  const AnimatedTypewriterText({super.key, required this.text});

  @override
  State<AnimatedTypewriterText> createState() => _AnimatedTypewriterTextState();
}

class _AnimatedTypewriterTextState extends State<AnimatedTypewriterText> {
  String displayed = "";
  int i = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    while (i < widget.text.length) {
      await Future.delayed(const Duration(milliseconds: 20));

      if (!mounted) return;

      setState(() {
        displayed += widget.text[i];
        i++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      displayed,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 15.5,
        height: 1.6,
        color: Colors.black87,
        letterSpacing: 0.2,
      ),
    );
  }
}
