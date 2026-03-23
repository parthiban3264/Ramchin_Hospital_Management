import 'package:flutter/material.dart';
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

  Future<void> _checkFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLogin = prefs.getBool('isFirstLogin') ?? false;

    if (isFirstLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDialog();
      });

      /// 🔥 IMPORTANT: make it false after showing
      await prefs.setBool('isFirstLogin', false);
      await _updateFirstLoginStatus();
    }
  }

  Future<void> _updateFirstLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final userId = prefs.getInt("id");

      if (userId != null) {
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
      builder: (_) => const FirstLoginDialog(),
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
  const FirstLoginDialog({super.key});

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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🔶 HEADER (GOLD THEME)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    gradient: LinearGradient(
                      colors: [primaryColor, darkPrimary],
                    ),
                  ),
                  child: Row(
                    children: [
                      /// 🏥 ICON
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.local_hospital,
                          size: 16,
                          color: primaryColor,
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// TEXT
                      const Expanded(
                        child: Text(
                          "Ramchin Hospital Management",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      /// VERSION BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "v3.0.3",
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                /// 📄 BODY
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      /// TITLE
                      const Text(
                        "Welcome 👋",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// ✨ TYPEWRITER TEXT
                      const AnimatedTypewriterText(
                        text:
                            "Welcome to Ramchin Hospital Management System.\n\nManage patients records, doctors, nurse, staffs and hospital workflows efficiently.\n\nWould you like to connect with us for support or services?",
                      ),

                      const SizedBox(height: 28),

                      /// 🔘 BUTTONS
                      Row(
                        children: [
                          /// SKIP
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                              child: const Text(
                                "Skip",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          /// CONTACT
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

                                // 👉 Add WhatsApp / call here
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 3,
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                              child: const Text(
                                "Contact Us",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      /// FOOTER
                      Text(
                        "Powered by Ramchin Technologies Pvt Ltd",
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
