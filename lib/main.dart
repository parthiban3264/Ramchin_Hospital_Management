// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// import 'Admin/Pages/admin_dashboard.dart';
// import 'Administrator/Overall_Administrator_Dashboard.dart';
// import 'Pages/DashboardPages/administrator_dashboard.dart';
// import 'Pages/DashboardPages/patient_dashboard.dart';
// import 'Pages/login/widget/HospitalLoginPage.dart';
// import 'Services/hospital_Service.dart';
// import 'app_wrapper.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Hospital Management',
//       home: AppWrapper(
//         // 👈 WRAP YOUR WHOLE APP
//         child: SplashPage(),
//       ), // Decide page on startup
//     );
//   }
// }
//
// /// ✅ SplashPage checks login status and role
// class SplashPage extends StatefulWidget {
//   const SplashPage({super.key});
//
//   @override
//   State<SplashPage> createState() => _SplashPageState();
// }
//
// class _SplashPageState extends State<SplashPage> {
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//   final HospitalService hospitalService = HospitalService();
//   late List hospital = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _checkLoginStatus();
//     // loadHospitalStatus();
//   }
//
//   // Future<void> loadHospitalStatus() async {
//   //   final hospital = await hospitalService.getHospital();
//   //   hospitalStatus = hospital['']
//   // }
//
//   Future<void> _checkLoginStatus() async {
//     String? isLogged = await secureStorage.read(key: 'isLogged');
//     String? role = await secureStorage.read(key: 'role');
//     String? hospitalStatus = await secureStorage.read(key: 'hospitalStatus');
//
//     if (isLogged == 'true' && role != null && hospitalStatus != null) {
//       // ✅ Navigate based on role
//       Widget page;
//
//       if (role.toLowerCase() == "admin" ||
//           role.toLowerCase() == "doctor" &&
//               hospitalStatus.toUpperCase() == 'ACTIVE') {
//         page = const AdminDashboardPage();
//       } else if (role.toLowerCase() == "patient") {
//         page = const PatientDashboardPage();
//       } else if (role.toLowerCase() == "administrator") {
//         page = OverallAdministratorDashPage();
//       } else {
//         // Unknown role, go to login page
//         page = const HospitalLoginPage();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Unknown user role, please login again"),
//           ),
//         );
//       }
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => page),
//       );
//     } else {
//       // ❌ Not logged in, go to Login page
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const HospitalLoginPage()),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Simple loading screen while checking login
//     return const Scaffold(body: Center(child: CircularProgressIndicator()));
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Admin/Pages/admin_dashboard.dart';
import 'Administrator/Overall_Administrator_Dashboard.dart';
import 'Pages/DashboardPages/patient_dashboard.dart';
import 'Pages/login/widget/HospitalLoginPage.dart';
import 'app_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(AppWrapper(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Hospital Management',
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // final hospitalId = prefs.getString('hospitalId');
    String? isLogged = prefs.getString('isLogged') ?? 'false';
    String? role = prefs.getString('role');
    String? status = prefs.getString('hospitalStatus');
    // String? staffStatus = prefs.getString('staffStatus');

    if (isLogged == 'true' && role != null && status != null) {
      Widget dashboard;

      if ((role.toLowerCase() == "admin" && status.toUpperCase() == 'ACTIVE')) {
        dashboard = const AdminDashboardPage();
      } else if (role.toLowerCase() == "patient") {
        dashboard = const PatientDashboardPage();
      } else if (role.toLowerCase() == "administrator") {
        dashboard = OverallAdministratorDashPage();
      } else {
        dashboard = const HospitalLoginPage();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => dashboard),
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HospitalLoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
