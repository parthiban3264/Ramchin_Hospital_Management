import 'package:flutter/material.dart';

class VersionUpdatePage extends StatelessWidget {
  // final bool isUpdateAvailable;

  const VersionUpdatePage({
    super.key,
    // this.isUpdateAvailable = true, // toggle for demo
  });
  final bool isUpdateAvailable = false;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFBF955E);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              //const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black,
                      size: 26,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              Spacer(),

              /// 🎯 Main Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    /// Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isUpdateAvailable
                            ? Colors.blueAccent.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUpdateAvailable
                            ? Icons.system_update_alt_rounded
                            : Icons.check_circle,
                        size: 60,
                        color: isUpdateAvailable
                            ? Colors.blueAccent
                            : Colors.green,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Title
                    Text(
                      isUpdateAvailable
                          ? "New Update Available"
                          : "You're Up to Date 🎉",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// Version
                    Text(
                      isUpdateAvailable
                          ? "Version 2.1.0 available"
                          : "You are using the latest version",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Description
                    Text(
                      isUpdateAvailable
                          ? "We’ve improved performance, fixed bugs, and added new features for better hospital management."
                          : "Your application is fully updated with the latest features and security improvements.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),

                    const SizedBox(height: 25),

                    /// Feature list (only for update)
                    if (isUpdateAvailable)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          FeatureItem(text: "Improved speed & performance"),
                          FeatureItem(text: "Doctor schedule updates"),
                          FeatureItem(text: "Bug fixes & stability"),
                        ],
                      ),
                  ],
                ),
              ),

              const Spacer(),

              /// 🔘 Buttons
              if (isUpdateAvailable) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Update Now",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Later",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
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
