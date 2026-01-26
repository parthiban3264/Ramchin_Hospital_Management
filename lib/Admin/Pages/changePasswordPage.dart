import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Pages/NotificationsPage.dart';
import '../../Services/auth_service.dart';

const Color primaryColor = Color(0xFFBF955E);

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController reNewPasswordController = TextEditingController();

  bool isOldPasswordObscured = true;
  bool isNewPasswordObscured = true;
  bool isReNewPasswordObscured = true;

  bool isLoading = false;
  bool isCheckingOldPassword = false;

  bool isOldPasswordWrong = false;
  bool isRePasswordMismatch = false;
  bool isRePasswordMatch = false;

  int? backendUserId;

  final FocusNode oldPasswordFocusNode = FocusNode();
  final FocusNode newPasswordFocusNode = FocusNode();
  final FocusNode reNewPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadUserIdFirst();

    oldPasswordFocusNode.addListener(() async {
      if (!oldPasswordFocusNode.hasFocus) {
        await _autoCheckOldPassword();
      }
    });
  }

  Future<void> _loadUserIdFirst() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final hospitalId = prefs.getString('hospitalId');

    final user = await AuthService().getById(hospitalId!, userId!);
    if (user != null && user['id'] != null) {
      setState(() {
        backendUserId = user['id'];
      });
    }
  }

  Future<void> _autoCheckOldPassword() async {
    if (backendUserId == null || oldPasswordController.text.isEmpty) {
      setState(() {
        isOldPasswordWrong = false;
      });
      return;
    }

    setState(() {
      isCheckingOldPassword = true;
    });

    bool isCorrect = await AuthService().checkOldPassword(
      backendUserId!,
      oldPasswordController.text,
    );
    setState(() {
      isOldPasswordWrong = !isCorrect;
      isCheckingOldPassword = false;
    });
  }

  Future<void> _changePassword() async {
    if (backendUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not loaded.")));
      return;
    }

    setState(() => isLoading = true);

    bool isOldCorrect = await AuthService().checkOldPassword(
      backendUserId!,
      oldPasswordController.text,
    );

    if (!isOldCorrect) {
      setState(() {
        isLoading = false;
        isOldPasswordWrong = true;
      });
      return;
    }

    if (newPasswordController.text == oldPasswordController.text) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New password cannot be same as old password"),
        ),
      );
      return;
    }

    if (newPasswordController.text != reNewPasswordController.text) {
      setState(() {
        isLoading = false;
        isRePasswordMismatch = true;
      });
      return;
    }

    bool changed = await AuthService().changePassword(
      backendUserId!,
      newPasswordController.text,
    );

    setState(() => isLoading = false);

    if (changed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully")),
      );
      oldPasswordController.clear();
      newPasswordController.clear();
      reNewPasswordController.clear();
      setState(() {
        isOldPasswordWrong = false;
        isRePasswordMismatch = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to change password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Change Password",
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
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: oldPasswordController,
                  label: "Old Password",
                  isObscured: isOldPasswordObscured,
                  stateColor: _getOldPasswordBorderColor(),
                  focusNode: oldPasswordFocusNode,
                  onToggle: () {
                    setState(() {
                      isOldPasswordObscured = !isOldPasswordObscured;
                    });
                  },
                  isChecking: isCheckingOldPassword,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: newPasswordController,
                  label: "New Password",
                  isObscured: isNewPasswordObscured,
                  stateColor: _getNewPasswordBorderColor(),
                  focusNode: newPasswordFocusNode,
                  onToggle: () {
                    setState(() {
                      isNewPasswordObscured = !isNewPasswordObscured;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: reNewPasswordController,
                  label: "Re-enter New Password",
                  isObscured: isReNewPasswordObscured,
                  stateColor: _getRePasswordBorderColor(),
                  focusNode: reNewPasswordFocusNode,
                  onToggle: () {
                    setState(() {
                      isReNewPasswordObscured = !isReNewPasswordObscured;
                    });
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : _changePassword,
                    child: isLoading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Change Password",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------- UPDATED BORDER COLOR LOGIC -----------------
  Color _getOldPasswordBorderColor() {
    if (oldPasswordController.text.isEmpty) return Colors.grey;
    if (isOldPasswordWrong) return Colors.red;
    return Colors.green;
  }

  Color _getNewPasswordBorderColor() {
    if (newPasswordController.text.isEmpty) return Colors.grey;
    return Colors.green;
  }

  Color _getRePasswordBorderColor() {
    if (reNewPasswordController.text.isEmpty) return Colors.grey;
    if (isRePasswordMismatch) return Colors.red;
    if (isRePasswordMatch) return Colors.green;
    return Colors.grey;
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required Color stateColor,
    required VoidCallback onToggle,
    FocusNode? focusNode,
    bool isChecking = false,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: stateColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: stateColor, width: 2),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isChecking)
              const SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              icon: Icon(
                isObscured ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
          ],
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      // onChanged: (_) {
      //   setState(() {
      //     if (label == "Re-enter New Password") {
      //       isRePasswordMismatch =
      //           reNewPasswordController.text.isNotEmpty &&
      //           newPasswordController.text != reNewPasswordController.text;
      //
      //       isRePasswordMatch =
      //           newPasswordController.text == reNewPasswordController.text &&
      //           reNewPasswordController.text.isNotEmpty;
      //     }
      //   });
      // },
      onChanged: (_) {
        if (label == "Old Password") {
          setState(() {
            isOldPasswordWrong = false; // ✅ reset red immediately
          });
        }

        if (label == "Re-enter New Password") {
          setState(() {
            isRePasswordMismatch =
                reNewPasswordController.text.isNotEmpty &&
                newPasswordController.text != reNewPasswordController.text;

            isRePasswordMatch =
                newPasswordController.text == reNewPasswordController.text &&
                reNewPasswordController.text.isNotEmpty;
          });
        }
      },
    );
  }
}
