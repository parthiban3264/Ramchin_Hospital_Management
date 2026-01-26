import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hospitrax/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Mediacl_Staff/Pages/OutPatient/Page/InjectionPage.dart';
import '../../../Pages/NotificationsPage.dart';

class SubmitTicketPage extends StatefulWidget {
  const SubmitTicketPage({super.key});

  @override
  State<SubmitTicketPage> createState() => _SubmitTicketPageState();
}

class _SubmitTicketPageState extends State<SubmitTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _issueController = TextEditingController();
  bool _isLoading = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: primaryColor, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryColor, width: 2),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final hospitalId = prefs.getString("hospitalId");
      final userId = prefs.getString("userId");

      if (hospitalId == null || userId == null) {
        _showMessage("❌ Hospital ID or User ID not found");
        setState(() => _isLoading = false);
        return;
      }

      final body = {
        "admin_Id": userId,
        "description": _issueController.text.trim(),
      };

      final response = await http.post(
        Uri.parse("$baseUrl/submit-ticket/create/$hospitalId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage("✅ Ticket submitted successfully");
        _issueController.clear();
      } else {
        _showMessage("❌ Failed: ${response.body}");
      }
    } catch (e) {
      _showMessage("❌ Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
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
                    "Submit Ticket",
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

      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 6,
                shadowColor: primaryColor.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 28,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 🔔 Header Icon
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: primaryColor,
                            size: 36,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 🧾 Title
                        const Text(
                          "Submit a Support Ticket",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 📝 Subtitle
                        Text(
                          "Describe the issue you are facing. Our support team will review and get back to you shortly.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.black.withValues(alpha: 0.7),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 🖊 Issue Input
                        TextFormField(
                          controller: _issueController,
                          maxLines: 5,
                          cursorColor: primaryColor,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: "Issue Description",
                            alignLabelWithHint: true,
                            labelStyle: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            hintText:
                                "Example: Unable to login, OTP not received, page not loading...",
                            hintStyle: TextStyle(
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: primaryColor.withValues(alpha: 0.06),
                            contentPadding: const EdgeInsets.all(16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: primaryColor.withValues(alpha: 0.4),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 1.8,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? "Please describe the issue"
                              : null,
                        ),

                        const SizedBox(height: 26),

                        // 🚀 Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading ? null : _submitTicket,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Submit Ticket",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ℹ Helper Note
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Don’t worry — our support team will get back to you within 24 hours.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Colors.black.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
