import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Admin/Pages/contact_page.dart';
import 'Services/admin_service.dart';
import 'Widgets/animated_text_typer.dart';

class FirstLoginWrapper extends StatefulWidget {
  final Widget child;

  const FirstLoginWrapper({super.key, required this.child});

  @override
  State<FirstLoginWrapper> createState() => _FirstLoginWrapperState();
}

class _FirstLoginWrapperState extends State<FirstLoginWrapper> {
  String? version;

  @override
  void initState() {
    super.initState();
    _checkFirstLogin();
  }

  Future<void> _checkFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLogin = prefs.getBool('isFirstLogin') ?? false;
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

      await prefs.setBool('isFirstLogin', false);
      final accountType = prefs.getString('accountType');
      await _updateFirstLoginStatus(accountType);
    }
  }

  Future<void> _updateFirstLoginStatus(String? accountType) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final userId = prefs.getInt('id');

      if (userId != null && accountType != 'DEMO') {
        await AdminService().updateUser(userId, {'isFirstLogin': false});
      }

      await prefs.setBool('isFirstLogin', false);
    } catch (e) {
      debugPrint('Error updating first login: $e');
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

const Color primaryColor = Color(0xFFBF955E);
const Color darkPrimary = Color(0xFF8B6B3F);

class FirstLoginDialog extends StatefulWidget {
  final String? version;

  const FirstLoginDialog({super.key, this.version});

  @override
  State<FirstLoginDialog> createState() => _FirstLoginDialogState();
}

class _FirstLoginDialogState extends State<FirstLoginDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _outerGlowAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _scaleAnim = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(curved);
    _outerGlowAnim = Tween<double>(begin: 0.92, end: 1).animate(curved);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalInset = screenWidth >= 1400
        ? screenWidth * 0.18
        : screenWidth >= 1100
        ? screenWidth * 0.14
        : screenWidth >= 800
        ? screenWidth * 0.1
        : 20.0;
    final dialogMaxWidth = screenWidth >= 1400
        ? 860.0
        : screenWidth >= 1100
        ? 760.0
        : screenWidth >= 800
        ? 660.0
        : 520.0;
    final outerRadius = screenWidth >= 800 ? 34.0 : 28.0;
    final innerRadius = screenWidth >= 800 ? 32.0 : 26.0;
    final contentPadding = screenWidth >= 1100
        ? 32.0
        : screenWidth >= 800
        ? 26.0
        : 18.0;
    final titleFontSize = screenWidth >= 1100
        ? 30.0
        : screenWidth >= 800
        ? 26.0
        : 22.0;
    final bodyFontSize = screenWidth >= 1100
        ? 17.8
        : screenWidth >= 800
        ? 16.6
        : 15.5;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: horizontalInset,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: dialogMaxWidth),
                child: AnimatedBuilder(
                  animation: _outerGlowAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _outerGlowAnim.value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2.2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(outerRadius),
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.95),
                          const Color(0xFFF6DFC2),
                          const Color(0xFFFCFAF7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.22),
                          blurRadius: 38,
                          spreadRadius: 4,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(innerRadius),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(contentPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: screenWidth >= 800 ? 62 : 50,
                                  height: screenWidth >= 800 ? 62 : 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFE9C9),
                                        Color(0xFFF1CA90),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.local_hospital_rounded,
                                    color: darkPrimary,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome👋',
                                        style: TextStyle(
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF222222),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Version ${widget.version ?? '-'}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: screenWidth >= 800
                                              ? 14
                                              : 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
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
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth >= 800 ? 22 : 16,
                                vertical: screenWidth >= 800 ? 20 : 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: const Color(0xFFFAF7F2),
                              ),
                              child: AnimatedTypewriterText(
                                text:
                                    'Welcome to Ramchin Hospital Management System.\n\nManage patients records, doctors, nurse, staffs and hospital workflows efficiently.\n\nWould you like to connect with us for support or services?',
                                fontSize: bodyFontSize,
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
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
                                  elevation: 0,
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenWidth >= 800 ? 18 : 14,
                                  ),
                                ),
                                child: Text(
                                  'Contact Us',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth >= 800 ? 15 : 14,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Powered by Ramchin Technologies Pvt Ltd',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth >= 800 ? 12 : 11,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
