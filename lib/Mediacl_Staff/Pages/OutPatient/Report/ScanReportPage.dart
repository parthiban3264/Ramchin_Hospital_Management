import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanReportCard extends StatefulWidget {
  final Map<String, dynamic> scanData;
  final String? hospitalLogo;
  final int mode;

  const ScanReportCard({
    super.key,
    required this.scanData,
    required this.hospitalLogo,
    required this.mode,
  });

  @override
  State<ScanReportCard> createState() => _ScanReportCardState();
}

class _ScanReportCardState extends State<ScanReportCard> {
  String? hospitalName;

  @override
  void initState() {
    super.initState();
    loadHospitalName();
  }

  void loadHospitalName() async {
    final prefs = await SharedPreferences.getInstance();
    hospitalName = prefs.getString('hospitalName');
    setState(() {}); // update UI
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.scanData["Patient"];

    // Pick first non-test item (like a scan)
    // final testDetails =
    //     ((scanData['testDetails'] as List<dynamic>? ?? []).firstWhere(
    //       (item) => item['type']?.toString().toLowerCase() != 'tests',
    //       orElse: () => null,
    //     ) ??
    //     (scanData['TeatingAndScanningPatient'] as List<dynamic>? ?? [])
    //         .firstWhere(
    //           (item) => item['type']?.toString().toLowerCase() != 'tests',
    //           orElse: () => null,
    //         ));
    //
    // // Get scan images safely
    // final images = List<String>.from(testDetails?["scanImages"] ?? []);
    //
    // // Get options safely
    // List<Map<String, dynamic>> options = [];
    // if (testDetails != null) {
    //   if (testDetails["options"] is List && testDetails["options"].isNotEmpty) {
    //     options = List<Map<String, dynamic>>.from(testDetails["options"]);
    //   } else if (testDetails["selectedOptions"] is List &&
    //       testDetails["selectedOptions"].isNotEmpty) {
    //     options = List<Map<String, dynamic>>.from(
    //       testDetails["selectedOptions"],
    //     );
    //   }
    // }

    // 1️⃣ Collect only scan details (skip type == tests)
    /// 1️⃣ Merge all scan sources (testDetails + TeatingAndScanningPatient)
    // ----------------- helper -----------------
    bool _isValidSelectedOption(dynamic val) {
      if (val == null) return false;

      // normalize: remove common separators and whitespace, then uppercase
      final s = val
          .toString()
          .replaceAll(RegExp(r'[\s\-_/\\]+'), '')
          .toUpperCase();

      if (s.isEmpty) return false;

      // blacklist common "no value" tokens after normalization
      const invalid = {'NA', 'N', 'NONE', 'NIL', 'NULL', 'NO'};

      if (invalid.contains(s)) return false;

      // if it's just some single-character N-variation (like "N/") it will become "N" and filtered above
      // else accept
      return true;
    }

    // ----------------- collect & filter -----------------
    // 1) Merge all scan sources
    final List<dynamic> allScanItems = [
      ...(widget.scanData['testDetails'] as List<dynamic>? ?? []),
      ...(widget.scanData['TeatingAndScanningPatient'] as List<dynamic>? ?? []),
    ];

    // 2) Keep only scan-type items (exclude 'tests' types)
    final List<dynamic> testDetails = allScanItems.where((item) {
      final typeStr = item['type']?.toString().toLowerCase() ?? '';
      return typeStr != 'tests';
    }).toList();

    // 3) Collect all images (unchanged)
    final List<Map<String, String>> imagesWithType = [];
    for (var scan in testDetails) {
      final type =
          scan['title']?.toString() ?? scan['type']?.toString() ?? 'Scan';
      if (scan['scanImages'] is List) {
        for (var img in scan['scanImages']) {
          imagesWithType.add({
            'url': img.toString(),
            'type': type, // store type per image
          });
        }
      }
    }

    // 4) Collect ONLY valid selectedOptions (skip all N/A-like values)
    // Use a Set to avoid duplicates (by name + selectedOption)
    final List<Map<String, dynamic>> options = [];
    final Set<String> seen = {};

    for (var item in testDetails) {
      // from "options" array
      if (item['options'] is List) {
        for (var opt in item['options']) {
          final dynamic selRaw = opt['selectedOption'];
          if (_isValidSelectedOption(selRaw)) {
            final name = (opt['name'] ?? '').toString();
            final sel = opt['selectedOption'].toString();
            final key = '$name|$sel';
            if (!seen.contains(key)) {
              seen.add(key);
              options.add(Map<String, dynamic>.from(opt));
            }
          } else {}
        }
      }

      // from "selectedOptions" array
      if (item['selectedOptions'] is List) {
        for (var opt in item['selectedOptions']) {
          final dynamic selRaw = opt['selectedOption'];
          if (_isValidSelectedOption(selRaw)) {
            final name = (opt['name'] ?? '').toString();
            final sel = opt['selectedOption'].toString();
            final key = '$name|$sel';
            if (!seen.contains(key)) {
              seen.add(key);
              options.add(Map<String, dynamic>.from(opt));
            }
          } else {}
        }
      }
    }

    // 5) Group scans by title (prefer title, fallback to type)
    final Map<String, List<dynamic>> groupedScans = {};
    for (var scan in testDetails) {
      final type =
          scan['title']?.toString() ?? scan['type']?.toString() ?? 'Unknown';
      groupedScans.putIfAbsent(type, () => []).add(scan);
    }

    // Now `options` contains only valid selectedOptions (no N/A variants)
    // and `groupedScans` groups scans by their readable title (CT-Scan, X-Ray etc.)

    return SingleChildScrollView(
      // padding: const EdgeInsets.all(2),
      // child: Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     // _buildHospitalHeader(),
      //     // const SizedBox(height: 20),
      //     // _buildSectionTitle("PATIENT INFORMATION"),
      //     // _buildInfoCard([
      //     //   ["Name", patient["name"]],
      //     //   ["Gender", patient["gender"]],
      //     //   ["Age", getAge(patient)],
      //     //   ["Blood Group", patient["bldGrp"]],
      //     //   ["Phone", patient["phone"]],
      //     //])
      //     Center(
      //       child: Text(
      //         hospitalName ?? '',
      //         style: const TextStyle(
      //           fontWeight: FontWeight.bold,
      //           fontSize: 22,
      //           color: Color(0xFF0E3B7D),
      //           letterSpacing: 0.5,
      //         ),
      //       ),
      //     ),
      //     const SizedBox(height: 1),
      //     Divider(color: Colors.grey.shade400, thickness: 1),
      //     _patientInfoSection(patient, [
      //       ["Age", getAge(patient)],
      //     ]),
      //     // const SizedBox(height: 20),
      //     // _buildSectionTitle("SCAN DETAILS"),
      //     // _buildInfoCard([
      //     //   ["Scan Type", testDetails["title"]],
      //     //   ["Result", testDetails["results"]],
      //     //   ["Date", scanData["createdAt"]],
      //     // ]),
      //     const SizedBox(height: 20),
      //     // _buildSectionTitle("X-RAY RESULT DETAILS"),
      //     // _buildResultTable(options),
      //     _buildSectionTitle("SCAN RESULT DETAILS"),
      //     _buildGroupedScanResults(
      //       groupedScans,
      //       _isValidSelectedOption, // <-- REQUIRED
      //     ),
      //
      //     const SizedBox(height: 20),
      //     _buildSectionTitle("SCAN IMAGES"),
      //
      //     imagesWithType.isEmpty
      //         ? const Text(
      //             "No images available",
      //             style: TextStyle(fontSize: 16),
      //           )
      //         : _buildImageGrid(imagesWithType),
      //
      //     const SizedBox(height: 10),
      //     if (widget.mode == 2) ...[
      //       const SizedBox(height: 5),
      //       _buildActionButtons(context),
      //       const SizedBox(height: 60),
      //     ],
      //   ],
      // ),
      child: Column(
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // _buildHospitalHeader(),
                  // const SizedBox(height: 20),
                  // _buildSectionTitle("PATIENT INFORMATION"),
                  // _buildInfoCard([
                  //   ["Name", patient["name"]],
                  //   ["Gender", patient["gender"]],
                  //   ["Age", getAge(patient)],
                  //   ["Blood Group", patient["bldGrp"]],
                  //   ["Phone", patient["phone"]],
                  // ])
                  SizedBox(height: 5),
                  Center(
                    child: Text(
                      hospitalName ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF0E3B7D),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 1),
                  Divider(color: Colors.grey.shade400, thickness: 1),

                  _patientInfoSection(patient),

                  // const SizedBox(height: 20),
                  // _buildSectionTitle("SCAN DETAILS"),
                  // _buildInfoCard([
                  //   ["Scan Type", testDetails["title"]],
                  //   ["Result", testDetails["results"]],
                  //   ["Date", scanData["createdAt"]],
                  // ]),
                  const SizedBox(height: 2),

                  // _buildSectionTitle("X-RAY RESULT DETAILS"),
                  // _buildResultTable(options),
                  _buildSectionTitle("SCAN RESULT DETAILS"),
                  _buildGroupedScanResults(
                    groupedScans,
                    _isValidSelectedOption,
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle("SCAN IMAGES"),

                  imagesWithType.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(height: 10),
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: 38,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "No images available",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildImageGrid(imagesWithType),
                  const SizedBox(height: 8),
                  const Text(
                    " IMPRESSION ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF0E3B7D),
                    ),
                  ),

                  const SizedBox(height: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < testDetails.length; i++) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          // spacing between sections
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${testDetails[i]['title'] ?? '-'} : ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0E3B7D),
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // 🧠 Impression
                              Expanded(
                                child: Text(
                                  testDetails[i]['results'] ?? '-',
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (widget.mode == 2) ...[
                    const SizedBox(height: 5),
                    _buildActionButtons(context),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
          if (widget.mode == 2) const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _patientInfoSection(Map<String, dynamic> patient) {
    String getAge(Map<String, dynamic> patient) {
      if (patient["age"] != null) {
        return patient["age"].toString();
      } else if (patient["dob"] != null) {
        try {
          final dob = DateTime.parse(patient["dob"]);
          final today = DateTime.now();
          int age = today.year - dob.year;
          if (today.month < dob.month ||
              (today.month == dob.month && today.day < dob.day)) {
            age--;
          }
          return age.toString();
        } catch (_) {
          return "-"; // fallback if parsing fails
        }
      } else {
        return "-"; // fallback if neither is provided
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 Gender Icon + Name + ID (First Row)
          Row(
            children: [
              Icon(
                (patient['gender'] ?? '').toString().toLowerCase() == 'male'
                    ? Icons.male
                    : Icons.female,
                color:
                    (patient['gender'] ?? '').toString().toLowerCase() == 'male'
                    ? Colors.blue
                    : Colors.pink,
                size: 30,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (patient['name'] ?? '').length > 10
                      ? '${patient['name'].substring(0, 10)}...'
                      : patient['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E3B7D),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  patient['patient_Id'] ?? patient['id'].toString() ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(thickness: 0.8, color: Colors.grey.shade500),
          const SizedBox(height: 2),

          // 📞 Cell No + 🎂 Age
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone, color: Color(0xFF0E3B7D), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    patient['phone'] ?? '-',
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.cake, color: Color(0xFF0E3B7D), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "${getAge(patient)} yrs",
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 📍 Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Color(0xFF0E3B7D), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  patient['address']?['Address'] ?? '',
                  style: const TextStyle(fontSize: 13.5, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 📅 Date
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFF0E3B7D),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                patient['createdAt'] ?? widget.scanData['createdAt'] ?? '-',
                style: const TextStyle(fontSize: 13.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildInfoCard(List<List<String>> data) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(10),
  //       boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
  //     ),
  //     child: Column(
  //       children: data.map((row) {
  //         return Padding(
  //           padding: const EdgeInsets.symmetric(vertical: 6),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 row[0],
  //                 style: const TextStyle(fontWeight: FontWeight.bold),
  //               ),
  //               Flexible(child: Text(row[1], textAlign: TextAlign.right)),
  //             ],
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

  // Widget _buildResultTable(List<Map<String, dynamic>> options) {
  //   final filteredOptions = options.where((e) {
  //     final selected = e["selectedOption"];
  //     if (selected == null) return false;
  //     final str = selected.toString().trim().toUpperCase();
  //     return str != "N/A" && str.isNotEmpty;
  //   }).toList();
  //
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(10),
  //       boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
  //     ),
  //     child: Column(
  //       children: [
  //         Row(
  //           children: const [
  //             Expanded(
  //               child: Text(
  //                 "Scan Name",
  //                 style: TextStyle(fontWeight: FontWeight.bold),
  //               ),
  //             ),
  //             Expanded(
  //               child: Text(
  //                 "Result",
  //                 style: TextStyle(fontWeight: FontWeight.bold),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const Divider(),
  //         ...filteredOptions.map((e) {
  //           return Padding(
  //             padding: const EdgeInsets.symmetric(vertical: 8),
  //             child: Row(
  //               children: [
  //                 Expanded(
  //                   child: Text(
  //                     e["selectedOption"].toString().split('(').first,
  //                   ),
  //                 ),
  //                 Expanded(
  //                   child: Text(
  //                     e["result"] ?? "-",
  //                     style: const TextStyle(fontWeight: FontWeight.w600),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         }).toList(),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildGroupedScanResults(
    Map<String, List<dynamic>> groupedScans,
    bool Function(dynamic) isValidOption,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ), // outer border
      ),
      child: Column(
        children: [
          // COMMON HEADER
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300, width: 1),
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: const Text(
                    "Test",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: const Text(
                    "Result",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),

          // EACH GROUP
          ...groupedScans.entries.map((group) {
            final type = group.key;
            final scans = group.value;

            List<Map<String, dynamic>> results = [];

            for (var s in scans) {
              if (s["selectedOptions"] is List) {
                results.addAll(
                  List<Map<String, dynamic>>.from(
                    s["selectedOptions"],
                  ).where((e) => isValidOption(e["selectedOption"])),
                );
              }

              if (s["options"] is List) {
                results.addAll(
                  List<Map<String, dynamic>>.from(
                    s["options"],
                  ).where((e) => isValidOption(e["selectedOption"])),
                );
              }
            }

            if (results.isEmpty) return const SizedBox();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Group Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: const Color(0xFFD8ECFF),
                  child: Text(
                    "$type REPORT RESULTS",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Rows
                ...results.asMap().entries.map((entry) {
                  final row = entry.value;
                  final isLastRow = entry.key == results.length - 1;

                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              bottom: isLastRow
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                            ),
                          ),
                          child: Text(
                            row["name"] ?? "-",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: isLastRow
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                            ),
                          ),
                          child: Text(
                            row["result"] ?? "-",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0C4C8A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<Map<String, String>> imagesWithType) {
    if (imagesWithType.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              "No images available",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Map to keep track of counts per type
    final Map<String, int> typeCounters = {};

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: imagesWithType.length,
      itemBuilder: (context, index) {
        final imgData = imagesWithType[index];
        final url = imgData['url']!;
        final type = imgData['type']!;

        // increment counter for this type
        typeCounters[type] = (typeCounters[type] ?? 0) + 1;
        final displayIndex = typeCounters[type]!;

        return GestureDetector(
          onTap: () => _openFullImageGallery(
            context,
            imagesWithType.map((e) => e['url']!).toList(),
            index,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  /// IMAGE
                  Positioned.fill(
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),

                  /// CAMERA ICON OVERLAY
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  /// LABEL OVERLAY
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.black45,
                      child: Text(
                        "$type ($displayIndex)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openFullImageGallery(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    PageController controller = PageController(initialPage: initialIndex);

    showDialog(
      context: context,
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black.withValues(alpha: 0.9),
            child: PageView.builder(
              controller: controller,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    panEnabled: true,
                    child: Image.network(images[index], fit: BoxFit.contain),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    bool isGeneratingPdf = false;
    bool isSharingPdf = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                ),
                icon: isGeneratingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: isGeneratingPdf
                    ? const Text("", style: TextStyle(color: Colors.white))
                    : const Text(
                        "View PDF",
                        style: TextStyle(color: Colors.white),
                      ),
                onPressed: isGeneratingPdf
                    ? null
                    : () async {
                        setState(() => isGeneratingPdf = true);
                        try {
                          final pdf = await _generatePdf();
                          final bytes = await pdf.save();
                          await Printing.layoutPdf(onLayout: (format) => bytes);
                        } finally {
                          setState(() => isGeneratingPdf = false);
                        }
                      },
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              width: 120,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                ),
                icon: isSharingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.share, color: Colors.white),
                label: isSharingPdf
                    ? const Text("", style: TextStyle(color: Colors.white))
                    : const Text(
                        "Share ",
                        style: TextStyle(color: Colors.white),
                      ),
                onPressed: isSharingPdf
                    ? null
                    : () async {
                        setState(() => isSharingPdf = true);
                        try {
                          final pdf = await _generatePdf();
                          final bytes = await pdf.save();
                          await Printing.sharePdf(
                            bytes: bytes,
                            filename: 'scan_report.pdf',
                          );
                        } finally {
                          setState(() => isSharingPdf = false);
                        }
                      },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<pw.Document> _generatePdf() async {
    final ttf = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();
    final blue = PdfColor.fromHex("#0A3D91");
    final lightBlue = PdfColor.fromHex("#1E5CC4");
    final pdf = pw.Document();

    final patient = widget.scanData["Patient"] ?? {};
    final testDetails =
        (widget.scanData["testDetails"] != null &&
            widget.scanData["testDetails"].isNotEmpty)
        ? widget.scanData["testDetails"][0]
        : {};
    final options = List<Map<String, dynamic>>.from(
      testDetails["options"] ?? [],
    );
    final images = List<String>.from(testDetails["scanImages"] ?? []);

    // Load fonts
    // pw.Font bodyFont;
    // pw.Font boldFont;
    // try {
    //   final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    //   final fontBoldData = await rootBundle.load(
    //     "assets/fonts/Roboto-Bold.ttf",
    //   );
    //   bodyFont = pw.Font.ttf(fontData);
    //   boldFont = pw.Font.ttf(fontBoldData);
    // } catch (e) {
    //   bodyFont = pw.Font.helvetica();
    //   boldFont = pw.Font.helveticaBold();
    // }

    // Load hospital logo for PDF header
    pw.ImageProvider? logoProvider;
    try {
      if (widget.hospitalLogo != null && widget.hospitalLogo!.isNotEmpty) {
        final uri = Uri.tryParse(widget.hospitalLogo!);
        if (uri != null) {
          final resp = await http.get(uri);
          if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
            logoProvider = pw.MemoryImage(resp.bodyBytes);
          }
        }
      }
    } catch (_) {}

    // Prepare scan images widgets for PDF
    final List<pw.Widget> imageWidgets = [];
    for (var img in images) {
      try {
        final uri = Uri.tryParse(img);
        if (uri != null) {
          final response = await http.get(uri);
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            final imageProvider = pw.MemoryImage(response.bodyBytes);

            imageWidgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Container(
                  width: 140, // square width
                  height: 130, // square height
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.FittedBox(
                      fit: pw.BoxFit.cover, // forces perfect square crop
                      child: pw.Image(imageProvider),
                    ),
                  ),
                ),
              ),
            );
          }
        }
      } catch (e) {
        // ignore errors gracefully
      }
    }

    // Filter the options except "N/A"
    final filteredOptions = options.where((e) {
      final selected = e["selectedOption"];
      if (selected == null) return false;
      final str = selected.toString().trim().toUpperCase();
      return str != "N/A" && str.isNotEmpty;
    }).toList();

    // final theme = pw.ThemeData.withFont(base: bodyFont, bold: boldFont);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        // margin: const pw.EdgeInsets.fromLTRB(32, 50, 32, 40),
        // theme: theme,
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logoProvider != null)
                pw.Container(
                  width: 120,
                  height: 50,
                  child: pw.Image(logoProvider, fit: pw.BoxFit.cover),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    widget.scanData['Hospital']?['name'] ?? '',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    widget.scanData['Hospital']?['address'] ?? '',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    "Accurate | Caring | Instant",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),

          // pw.Center(
          //   child: pw.Text(
          //     "SCAN REPORT",
          //     style: pw.TextStyle(
          //       fontSize: 18,
          //       fontWeight: pw.FontWeight.bold,
          //       decoration: pw.TextDecoration.underline,
          //     ),
          //   ),
          // ),
          // pw.SizedBox(height: 12),

          // Patient and Scan details in two columns for better layout
          _sectionBox(
            title: " Patient Details",
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                /// LEFT COLUMN
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _infoRow("Name", patient["name"] ?? "-"),
                      _infoRow("Gender", patient["gender"] ?? "-"),
                      _infoRow("Age", patient["age"]?.toString() ?? "-"),
                    ],
                  ),
                ),

                pw.SizedBox(width: 10),

                /// CENTER COLUMN
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _infoRow("Blood Group", patient["bldGrp"] ?? "-"),
                      _infoRow("Phone", patient["phone"] ?? "-"),
                      _infoRow(
                        "Address",
                        patient["address"]?['Address'] ?? "-",
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(width: 10),

                /// RIGHT COLUMN
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _infoRow("Scan Type", testDetails["title"] ?? "-"),
                      _infoRow("Result", testDetails["results"] ?? "-"),
                      _infoRow("Date", widget.scanData["createdAt"] ?? "-"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(colors: [blue, lightBlue]),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Center(
              child: pw.Text(
                '${widget.scanData['type'].toString().toUpperCase()} RESULT DETAILS',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          // X-ray details table
          _tableSection(
            headers: const ["Test Name", "Result"],
            data: filteredOptions
                .map(
                  (e) => [
                    (e["name"] ?? "-").toString(),
                    (e["result"] ?? "-").toString(),
                  ],
                )
                .toList(),
          ),

          if (imageWidgets.isNotEmpty) pw.SizedBox(height: 16),

          if (imageWidgets.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Scan Images",
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Wrap(spacing: 8, runSpacing: 8, children: imageWidgets),
              ],
            ),

          pw.SizedBox(height: 24),

          // Signature or footer note area
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Doctor Signature",

                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Container(
                    width: 120,
                    height: 0.5,
                    color: PdfColors.grey600,
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "This is a system generated report.",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    "No signature required.",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min, // compact row
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "$label: ",
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5),
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 10.5)),
        ],
      ),
    );
  }

  /// PDF helper: box section with label/value pairs
  pw.Widget _sectionBox({required String title, required pw.Widget child}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Divider(color: PdfColors.grey500, thickness: 0.7),
          pw.SizedBox(height: 4),
          child, // <-- IMPORTANT
        ],
      ),
    );
  }

  /// PDF helper: titled table with borders
  pw.Widget _tableSection(
  //String title,
  {required List<String> headers, required List<List<String>> data}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // pw.Text(
        //   title,
        //   style: pw.TextStyle(
        //     fontSize: 16,
        //     fontWeight: pw.FontWeight.bold,
        //     color: PdfColors.blue800,
        //   ),
        // ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data
              .map((row) => row.map((cell) => cell.toString()).toList())
              .toList(),
          headerStyle: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
          cellStyle: const pw.TextStyle(fontSize: 11),
          headerAlignment: pw.Alignment.centerLeft,
          cellAlignment: pw.Alignment.centerLeft,
          border: pw.TableBorder(
            horizontalInside: const pw.BorderSide(
              color: PdfColors.grey400,
              width: 0.5,
            ),
            verticalInside: const pw.BorderSide(
              color: PdfColors.grey400,
              width: 0.5,
            ),
            top: const pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            bottom: const pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            left: const pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            right: const pw.BorderSide(color: PdfColors.grey400, width: 0.5),
          ),
          cellPadding: const pw.EdgeInsets.symmetric(
            vertical: 7,
            horizontal: 7,
          ),
        ),
      ],
    );
  }
}
