import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hospitrax/Pages/login/widget/HospitalLoginPage.dart';
import 'package:hospitrax/utils/utils.dart';
import 'package:http/http.dart' as http;

import '../../../Admin/Pages/AdminEditProfilePage.dart';
import '../../NotificationsPage.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _hospitalController = TextEditingController();
  final _userController = TextEditingController();
  bool _isLoading = false;
  bool _emailNotFound = false;
  String _emailErrorMessage = '';

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool obscure = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        cursorColor: primaryColor,
        keyboardType: keyboard,
        style: const TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryColor),
          labelText: label,
          labelStyle: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: primaryColor.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send_otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hospitalId': int.parse(_hospitalController.text.trim()),
          'userId': _userController.text.trim(),
          'otp': (100000 + (DateTime.now().millisecondsSinceEpoch % 899999))
              .toString(),
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage("✅ OTP sent successfully", success: true);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(
              hospitalId: int.parse(_hospitalController.text.trim()),
              userId: _userController.text.trim(),
            ),
          ),
        );
        // } else {
        //   _showMessage(data['message'] ?? "❌ Failed to send OTP");
        // }
      } else {
        final message = data['message']?.toString() ?? '';
        final code = data['code']?.toString() ?? '';

        if (code == 'EMAIL_NOT_FOUND' ||
            message.toLowerCase().contains('email')) {
          setState(() {
            _emailNotFound = true;
            _emailErrorMessage =
                'No email is associated with this account.\n'
                'Please contact your system admin to reset your password.';
          });
        } else {
          _showMessage(message.isNotEmpty ? message : '❌ Failed to send OTP');
        }
      }
    } catch (e) {
      if (mounted) _showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

                  const Text(
                    "Forgot Password",
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600
              ? 480
              : constraints.maxWidth * 0.95;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: maxWidth,
                child: _emailNotFound
                    ? Center(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.orange.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.orange,
                                    size: 26,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Action Required",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _emailErrorMessage,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Steps to reset your password",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                SizedBox(height: 12),

                                Text(
                                  "1. Enter your Hospital ID",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 6),

                                Text(
                                  "2. Enter your User ID",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 6),

                                Text(
                                  "3. An OTP will be sent to your registered email address",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 6),

                                Text(
                                  "4. Enter the OTP to continue resetting your password",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: const BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 25,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _hospitalController,
                                      icon: Icons.home_work_rounded,
                                      label: "Hospital ID",
                                      keyboard: TextInputType.number,
                                      validator: (v) => v == null || v.isEmpty
                                          ? "Enter Hospital ID"
                                          : null,
                                    ),
                                    const SizedBox(height: 6),
                                    _buildTextField(
                                      controller: _userController,
                                      icon: Icons.person_outline,
                                      label: "User ID",
                                      validator: (v) => v == null || v.isEmpty
                                          ? "Enter User ID"
                                          : null,
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: _isLoading ? null : _sendOtp,
                                        child: _isLoading
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : const Text("Send OTP"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  final int hospitalId;
  final String userId;

  const ResetPasswordPage({
    super.key,
    required this.hospitalId,
    required this.userId,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: success ? Colors.green[700] : Colors.red[700],
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool obscure = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        cursorColor: primaryColor,
        keyboardType: keyboard,
        style: const TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryColor),
          labelText: label,
          labelStyle: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: primaryColor.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/update_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hospitalId': widget.hospitalId,
          'userId': widget.userId,
          'newPassword': _passwordController.text.trim(),
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage("✅ Password reset successful!", success: true);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HospitalLoginPage()),
          (route) => false,
        );
      } else {
        _showMessage(data['message'] ?? "❌ Failed to reset password");
      }
    } catch (e) {
      if (mounted) _showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

                  const Text(
                    "Reset Password",
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600
              ? 480
              : constraints.maxWidth * 0.95;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: maxWidth,
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: primaryColor, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _otpController,
                            icon: Icons.lock_outline,
                            label: "OTP",
                            keyboard: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter OTP" : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            icon: Icons.key_rounded,
                            label: "New Password",
                            obscure: true,
                            validator: (v) => v == null || v.isEmpty
                                ? "Enter password"
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmController,
                            icon: Icons.check_circle_outline,
                            label: "Confirm Password",
                            obscure: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return "Confirm password";
                              }
                              if (v != _passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isLoading ? null : _resetPassword,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text("Reset Password"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
