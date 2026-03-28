import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../utils/utils.dart';

class VersionUpdatePage extends StatefulWidget {
  const VersionUpdatePage({super.key});

  @override
  State<VersionUpdatePage> createState() => _VersionUpdatePageState();
}

class _VersionUpdatePageState extends State<VersionUpdatePage> {
  Map<String, dynamic> appVersionData = {};
  bool isLoading = true;

  String currentVersion = "0.0.0";
  bool isUpdateAvailable = false;
  bool isForceUpdate = false;

  /// 🔍 Detect platform
  String getPlatform() {
    if (kIsWeb) return "web";
    if (Platform.isAndroid) return "android";
    if (Platform.isIOS) return "ios";
    return "unknown";
  }

  /// 📱 Get app version
  Future<void> getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      currentVersion = info.version;
    } catch (e) {
      print("Version error: $e");

      /// fallback for web
      currentVersion = "1.0.0";
    }
  }

  /// 🔢 Compare versions (IMPORTANT)
  int compareVersion(String v1, String v2) {
    List<int> a = v1.split('.').map(int.parse).toList();
    List<int> b = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      int x = i < a.length ? a[i] : 0;
      int y = i < b.length ? b[i] : 0;

      if (x > y) return 1;
      if (x < y) return -1;
    }
    return 0;
  }

  /// 🌐 API CALL
  Future<void> fetchAppInfo() async {
    try {
      if (!mounted) return; // ✅
      await getAppVersion();

      final response = await http.get(
        Uri.parse("$baseUrl/users/app-info/${getPlatform()}"),
        headers: {"Content-Type": "application/json"},
      );
      print('appData ${response.body}');
      if (!mounted) return; // ✅
      final data = jsonDecode(response.body);
      final appData = data['data'] ?? {};

      final latestVersion = appData['latest_version'] ?? "0.0.0";
      final minVersion = appData['min_version'] ?? "0.0.0";
      final bool backendForceUpdate = appData['is_force_update'] ?? false;

      /// 🔥 CORRECT VERSION LOGIC

      // 1️⃣ Force update from backend OR below min version
      if (backendForceUpdate ||
          compareVersion(currentVersion, minVersion) < 0) {
        isForceUpdate = true;
        isUpdateAvailable = true;
      } else if (compareVersion(currentVersion, latestVersion) < 0) {
        isUpdateAvailable = true;
      }
      if (mounted) {
        setState(() {
          appVersionData = appData;
          isLoading = false;
        });
      }

      print("Current: $currentVersion");
      print("Latest: $latestVersion");
      print("forseUpdate ${appData['is_force_update'] ?? " "}");
    } catch (e) {
      print("Error: $e");
      if (!mounted) return; // ✅
      setState(() => isLoading = false);
    }
  }

  /// 🔗 Open store
  Future<void> openStore(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw "Could not launch $url";
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAppInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final playStoreUrl = appVersionData['playStoreUrl'] ?? '';
    final latestVersion = appVersionData['latest_version'] ?? '';
    final updateMessage =
        appVersionData['update_message'] ?? "New update available";
    final createdAt = appVersionData['createdAt'] ?? '';

    /// 🎯 BETTER MESSAGE
    String message;
    if (!isUpdateAvailable) {
      message = "You are already using the latest version ($currentVersion) 🎉";
    } else {
      message = updateMessage;
    }

    return WillPopScope(
      onWillPop: () async => !isForceUpdate, // ❌ block back if force update
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              // ✅ FIX overflow
              child: Column(
                children: [
                  /// BACK BUTTON
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          if (!isForceUpdate) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// CARD
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        /// ICON
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isForceUpdate
                                ? Colors.red.withOpacity(0.1)
                                : isUpdateAvailable
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isForceUpdate
                                ? Icons.warning_amber_rounded
                                : isUpdateAvailable
                                ? Icons.system_update_alt
                                : Icons.check_circle,
                            size: 60,
                            color: isForceUpdate
                                ? Colors.red
                                : isUpdateAvailable
                                ? Colors.blue
                                : Colors.green,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// TITLE
                        Text(
                          isForceUpdate
                              ? "Update Required ⚠️"
                              : isUpdateAvailable
                              ? "Update Available 🚀"
                              : "Up to Date 🎉",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isForceUpdate ? Colors.red : Colors.black,
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// VERSION INFO
                        Text(
                          "Your version: $currentVersion\nLatest: $latestVersion",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),

                        const SizedBox(height: 8),

                        /// DATE
                        if (createdAt != null &&
                            createdAt.toString().isNotEmpty)
                          Text(
                            "Released on: $createdAt",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),

                        const SizedBox(height: 20),

                        /// MESSAGE
                        Text(
                          isForceUpdate
                              ? "🚨 You must update the app to continue using it.\n\n$message"
                              : message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.5),
                        ),

                        const SizedBox(height: 20),

                        /// WHAT'S NEW
                        if (isUpdateAvailable)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "What's New",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              FeatureItem(text: "Improved performance"),
                              FeatureItem(text: "Bug fixes & stability"),
                              FeatureItem(text: "New features added"),
                            ],
                          ),

                        const SizedBox(height: 20),

                        /// FORCE UPDATE WARNING BOX
                        if (isForceUpdate)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.error_outline, color: Colors.red),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "This update is mandatory. You cannot continue without updating.",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// BUTTONS
                  if (isUpdateAvailable) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => openStore(playStoreUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isForceUpdate
                              ? Colors.red
                              : Colors.blue,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Text(
                          isForceUpdate
                              ? "Update Now (Required)"
                              : "Update Now",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),

                    if (!isForceUpdate)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Later",
                          style: TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.all(14),
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ Feature Item
class FeatureItem extends StatelessWidget {
  final String text;

  const FeatureItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFBF955E);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
