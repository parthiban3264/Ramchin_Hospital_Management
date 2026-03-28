// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:package_info_plus/package_info_plus.dart';
//
// import '../../../Admin/Pages/version_update_page.dart';
//
// class VersionService {
//   static Future<Map<String, dynamic>> check({required List appVersions}) async {
//     final info = await PackageInfo.fromPlatform();
//     final currentVersion = info.version;
//
//     final platform = Platform.isIOS ? "ios" : "android";
//
//     Map<String, dynamic>? versionData;
//
//     for (var v in appVersions) {
//       if (v["platform"] == platform) {
//         versionData = Map<String, dynamic>.from(v);
//         break;
//       }
//     }
//
//     if (versionData == null) {
//       return {"status": "ok"};
//     }
//
//     final latest = versionData["latest_version"] ?? "0.0.0";
//     final min = versionData["min_version"] ?? "0.0.0";
//     final force =
//         versionData["is_force_update"] == true ||
//         versionData["is_force_update"] == 1;
//
//     final url = versionData["playStoreUrl"] ?? "";
//     final message = versionData["update_message"] ?? "";
//
//     bool isLower(String c, String t) {
//       List<int> cv = c.split('.').map(int.parse).toList();
//       List<int> tv = t.split('.').map(int.parse).toList();
//
//       int max = cv.length > tv.length ? cv.length : tv.length;
//
//       for (int i = 0; i < max; i++) {
//         int cVal = i < cv.length ? cv[i] : 0;
//         int tVal = i < tv.length ? tv[i] : 0;
//
//         if (cVal < tVal) return true;
//         if (cVal > tVal) return false;
//       }
//       return false;
//     }
//
//     final belowMin = isLower(currentVersion, min);
//     final belowLatest = isLower(currentVersion, latest);
//
//     if (force && belowMin) {
//       return {"status": "force", "url": url, "message": message};
//     }
//
//     if (belowLatest) {
//       return {"status": "optional", "url": url, "message": message};
//     }
//
//     return {"status": "ok"};
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 👈 add this
import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static Future<Map<String, dynamic>> check({required List appVersions}) async {
    // 👉 Skip for web
    if (kIsWeb) {
      return {"status": "ok"};
    }

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    final platform = Platform.isIOS ? "ios" : "android";

    Map<String, dynamic>? versionData;

    for (var v in appVersions) {
      if (v["platform"] == platform) {
        versionData = Map<String, dynamic>.from(v);
        break;
      }
    }

    if (versionData == null) {
      return {"status": "ok"};
    }

    final latest = versionData["latest_version"] ?? "0.0.0";
    final min = versionData["min_version"] ?? "0.0.0";
    final force =
        versionData["is_force_update"] == true ||
        versionData["is_force_update"] == 1;

    final url = versionData["playStoreUrl"] ?? "";
    final message = versionData["update_message"] ?? "";

    bool isLower(String c, String t) {
      List<int> cv = c.split('.').map(int.parse).toList();
      List<int> tv = t.split('.').map(int.parse).toList();

      int max = cv.length > tv.length ? cv.length : tv.length;

      for (int i = 0; i < max; i++) {
        int cVal = i < cv.length ? cv[i] : 0;
        int tVal = i < tv.length ? tv[i] : 0;

        if (cVal < tVal) return true;
        if (cVal > tVal) return false;
      }
      return false;
    }

    final belowMin = isLower(currentVersion, min);
    final belowLatest = isLower(currentVersion, latest);

    if (force && belowMin) {
      return {"status": "force", "url": url, "message": message};
    }

    if (belowLatest) {
      return {"status": "optional", "url": url, "message": message};
    }

    return {"status": "ok"};
  }
}
