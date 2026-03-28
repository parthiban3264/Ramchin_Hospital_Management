import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../utils/utils.dart';

class AppVersionAdminPage extends StatefulWidget {
  const AppVersionAdminPage({super.key});

  @override
  State<AppVersionAdminPage> createState() => _AppVersionAdminPageState();
}

class _AppVersionAdminPageState extends State<AppVersionAdminPage> {
  List versions = [];
  bool isPageLoading = true;
  String errorMessage = "";

  String selectedPlatform = "android";
  String latestVersion = "1.0.0";
  String minVersion = "1.0.0";
  bool isLoading = false;

  final messageController = TextEditingController();
  final playStoreUrlController = TextEditingController();
  bool isForce = false;

  @override
  void initState() {
    super.initState();
    getAll();
    _updateTime();
  }

  String? _dateTime;
  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  /// 📥 GET ALL
  // Future<void> getAll() async {
  //   final res = await http.get(Uri.parse("$baseUrl/users/app-version"));
  //   final data = jsonDecode(res.body);
  //
  //   setState(() {
  //     versions = data['data'] ?? [];
  //   });
  // }

  Future<void> getAll() async {
    setState(() {
      isPageLoading = true;
      errorMessage = "";
    });

    try {
      final res = await http.get(Uri.parse("$baseUrl/users/app-version"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          versions = data['data'] ?? [];
        });
      } else {
        setState(() {
          errorMessage = "Failed to load data";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Something went wrong";
      });
    } finally {
      setState(() {
        isPageLoading = false;
      });
    }
  }

  /// 🔍 PLATFORM CHECK
  bool hasPlatform(String p) {
    return versions.any((e) => e['platform'] == p);
  }

  List<String> get availablePlatforms {
    List<String> all = ["android", "ios"];
    return all.where((p) => !hasPlatform(p)).toList();
  }

  bool get canCreate => availablePlatforms.isNotEmpty;

  /// 🔢 VERSION COMPARE
  int compareVersion(String v1, String v2) {
    List<int> a = v1.split('.').map(int.parse).toList();
    List<int> b = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (a[i] > b[i]) return 1;
      if (a[i] < b[i]) return -1;
    }
    return 0;
  }

  /// ➕ CREATE
  Future<void> createVersion() async {
    if (compareVersion(latestVersion, minVersion) < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Latest must be ≥ Min")));
      return;
    }

    setState(() => isLoading = true);

    try {
      await http.post(
        Uri.parse("$baseUrl/users/app-version"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "platform": selectedPlatform,
          "latest_version": latestVersion,
          "min_version": minVersion,
          "playStoreUrl": playStoreUrlController.text,
          "is_force_update": isForce,
          "update_message": messageController.text,
          "createdAt": _dateTime.toString(),
        }),
      );

      Navigator.pop(context);
      getAll();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ✏ UPDATE
  Future<void> updateVersion(int id) async {
    setState(() => isLoading = true);

    try {
      await http.put(
        Uri.parse("$baseUrl/users/app-version/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "latest_version": latestVersion,
          "min_version": minVersion,
          "is_force_update": isForce,
          "update_message": messageController.text,
          "playStoreUrl": playStoreUrlController.text,
          "createdAt": _dateTime.toString(),
          "updatedAt": _dateTime.toString(),
        }),
      );

      Navigator.pop(context);
      getAll();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Update failed")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ❌ DELETE
  Future<void> deleteVersion(int id) async {
    setState(() => isLoading = true);

    try {
      await http.delete(Uri.parse("$baseUrl/users/app-version/$id"));

      Navigator.pop(context);
      getAll();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Delete failed")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔼 VERSION +
  String inc(String v) {
    var p = v.split('.').map(int.parse).toList();
    p[2]++;
    return "${p[0]}.${p[1]}.${p[2]}";
  }

  /// 🔽 VERSION -
  String dec(String v) {
    var p = v.split('.').map(int.parse).toList();
    if (p[2] > 0) p[2]--;
    return "${p[0]}.${p[1]}.${p[2]}";
  }

  /// 🔥 SHEET
  void openSheet({Map? data}) {
    if (data != null) {
      selectedPlatform = data['platform'];
      latestVersion = data['latest_version'];
      minVersion = data['min_version'];
      playStoreUrlController.text = data['playStoreUrl'] ?? '';
      isForce = data['is_force_update'] ?? false;
      messageController.text = data['update_message'] ?? '';
    } else {
      selectedPlatform = availablePlatforms.first;
      latestVersion = "1.0.0";
      minVersion = "1.0.0";
      isForce = false;
      playStoreUrlController.clear();
      messageController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 12,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F9FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    /// 🔘 HANDLE
                    Container(
                      width: 45,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.arrow_back_ios),
                        ),
                      ],
                    ),

                    /// 🧊 HEADER
                    if (data == null)
                      /// ✅ CREATE MODE → SELECTABLE TOGGLE
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.indigo],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: availablePlatforms.map((p) {
                            final isSelected = selectedPlatform == p;
                            final isAndroid = p == "android";

                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setModal(() => selectedPlatform = p);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isAndroid ? Icons.android : Icons.apple,
                                        size: 18,
                                        color: isSelected
                                            ? (isAndroid
                                                  ? Colors.green
                                                  : Colors.black)
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        p.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    else
                      /// ❌ UPDATE MODE → STATIC DISPLAY
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selectedPlatform == "android"
                                  ? Icons.android
                                  : Icons.apple,
                              color: selectedPlatform == "android"
                                  ? Colors.green
                                  : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedPlatform.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),

                    /// 📱 PLATFORM CARD
                    // _card(
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       _title("Platform"),
                    //       const SizedBox(height: 10),
                    //
                    //       if (data == null)
                    //         Wrap(
                    //           spacing: 8,
                    //           children: availablePlatforms.map((p) {
                    //             return ChoiceChip(
                    //               label: Text(p.toUpperCase()),
                    //               selected: selectedPlatform == p,
                    //               selectedColor: Colors.blue,
                    //               labelStyle: TextStyle(
                    //                 color: selectedPlatform == p
                    //                     ? Colors.white
                    //                     : Colors.black,
                    //               ),
                    //               onSelected: (_) =>
                    //                   setModal(() => selectedPlatform = p),
                    //             );
                    //           }).toList(),
                    //         )
                    //       else
                    //         Chip(
                    //           label: Text(selectedPlatform.toUpperCase()),
                    //           backgroundColor: Colors.blue.shade100,
                    //         ),
                    //     ],
                    //   ),
                    // ),

                    /// 🔢 VERSION CARD
                    _card(
                      child: Column(
                        children: [
                          _title("Version Control", Colors.black),
                          const SizedBox(height: 10),

                          modernStepper(
                            "Latest",
                            latestVersion,
                            () => setModal(
                              () => latestVersion = inc(latestVersion),
                            ),
                            () => setModal(
                              () => latestVersion = dec(latestVersion),
                            ),
                          ),

                          modernStepper(
                            "Minimum",
                            minVersion,
                            () => setModal(() => minVersion = inc(minVersion)),
                            () => setModal(() => minVersion = dec(minVersion)),
                          ),
                        ],
                      ),
                    ),

                    /// 🔗 URL + MESSAGE
                    _card(
                      child: Column(
                        children: [
                          _inputField(
                            controller: playStoreUrlController,
                            label: "Play Store URL",
                            icon: Icons.link,
                          ),
                          const SizedBox(height: 12),
                          _inputField(
                            controller: messageController,
                            label: "Update Message",
                            icon: Icons.message,
                          ),
                        ],
                      ),
                    ),

                    /// 🔥 FORCE UPDATE
                    _card(
                      child: SwitchListTile(
                        value: isForce,
                        activeColor: Colors.red,
                        onChanged: (v) => setModal(() => isForce = v),
                        title: const Text("Force Update"),
                        subtitle: const Text("Users must update app"),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// 🚀 ACTION BUTTONS
                    Column(
                      children: [
                        /// PRIMARY BUTTON (GRADIENT)
                        InkWell(
                          onTap: isLoading
                              ? null
                              : () {
                                  if (data == null) {
                                    createVersion();
                                  } else {
                                    updateVersion(data['id']);
                                  }
                                },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.blue, Colors.indigo],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: isLoading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          data == null
                                              ? "Creating..."
                                              : "Updating...",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      data == null
                                          ? "Create Version"
                                          : "Update Version",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// DELETE BUTTON (OUTLINE)
                        if (data != null)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: isLoading
                                ? null
                                : () => deleteVersion(data['id']),
                            child: isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Deleting...",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    "Delete Version",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  ////////////////////////////////////////////////////////////
  /// 🔹 REUSABLE UI COMPONENTS

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: child,
    );
  }

  Widget _title(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// 🔥 MODERN STEPPER
  Widget modernStepper(
    String title,
    String value,
    VoidCallback inc,
    VoidCallback dec,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          IconButton(onPressed: dec, icon: const Icon(Icons.remove_circle)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(onPressed: inc, icon: const Icon(Icons.add_circle)),
        ],
      ),
    );
  }

  /// 🔹 INPUT FIELD
  Widget stepper(
    String title,
    String value,
    VoidCallback inc,
    VoidCallback dec,
  ) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: dec, icon: const Icon(Icons.remove)),
            IconButton(onPressed: inc, icon: const Icon(Icons.add)),
          ],
        ),
      ),
    );
  }

  /// 📱 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 100,
          decoration: const BoxDecoration(
            color: Color(0xFFBF955E),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "App Version Manage",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                //const Spacer(),
                // IconButton(
                //   icon: const Icon(Icons.notifications, color: Colors.white),
                //   onPressed: () {},
                // ),
                // IconButton(
                //   icon: const Icon(Icons.home, color: Colors.white),
                //   onPressed: () {
                //     Navigator.pop(context);
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: canCreate
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.indigo],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => openSheet(),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Add Version",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,

      body: isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  Text(errorMessage),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: getAll, child: const Text("Retry")),
                ],
              ),
            )
          : versions.isEmpty
          ? const Center(child: Text("No versions found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: versions.length,
              itemBuilder: (_, i) {
                final v = versions[i];

                final isAndroid = v['platform'] == "android";

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => openSheet(data: v),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🔷 HEADER ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /// PLATFORM BADGE
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isAndroid
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isAndroid ? Icons.android : Icons.apple,
                                    size: 16,
                                    color: isAndroid
                                        ? Colors.green
                                        : Colors.black87,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    v['platform'].toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isAndroid
                                          ? Colors.green
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// EDIT ICON
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 16),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// 🔢 VERSION ROW
                        Row(
                          children: [
                            Expanded(
                              child: modernInfoBox(
                                title: "Latest",
                                value: v['latest_version'],
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: modernInfoBox(
                                title: "Min",
                                value: v['min_version'],
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        /// ⚠ FORCE UPDATE BADGE
                        if (v['is_force_update'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "⚠ Force Update Enabled",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),

                        /// 💬 MESSAGE
                        if ((v['update_message'] ?? "").toString().isNotEmpty)
                          Text(
                            v['update_message'],
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget modernInfoBox({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget infoBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
