import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Admin/Pages/admin_dashboard.dart';
import 'Admin/Pages/globals.dart';
import 'Administrator/Overall_Administrator_Dashboard.dart';
import 'Pages/DashboardPages/patient_dashboard.dart';
import 'Pages/login/widget/HospitalLoginPage.dart';
import 'app_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadStaffPhoto();
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
    bool isLogged = prefs.getBool('isLogged') ?? false;
    String? role = prefs.getString('role');
    String? status = prefs.getString('hospitalStatus');
    String? staffName = prefs.getString('staffName') ?? '';
    String? staffPhoto = prefs.getString('staffPhoto') ?? '';
    prefs.setBool('isLogged', true);
    if (isLogged && role != null && status != null) {
      Widget dashboard;
      if ((role.toLowerCase() == "admin" && status.toUpperCase() == 'ACTIVE')) {
        dashboard = AdminDashboardPage(
          staffName: staffName,
          staffPhoto: staffPhoto,
        );
      } else if (role.toLowerCase() == "patient") {
        dashboard = const PatientDashboardPage();
      } else if (role.toLowerCase() == "administrator") {
        dashboard = OverallAdministratorDashPage(
          staffName: staffName,
          staffPhoto: staffPhoto,
        );
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
