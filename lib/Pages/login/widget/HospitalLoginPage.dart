import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../Admin/Pages/Admin_App_Wrapper.dart';
import '../../../Administrator/Overall_Administrator_Dashboard.dart';
import '../../../Mediacl_Staff/Pages/Doctor/pages/doctor_dashboard.dart';
import '../../../Services/auth_service.dart';
import '../../../Admin/Pages/admin_dashboard.dart';
import '../../../app_wrapper.dart';
import '../../DashboardPages/administrator_dashboard.dart';
import '../../DashboardPages/medicalStaff_dashboard.dart';
import '../../DashboardPages/patient_dashboard.dart';

class HospitalLoginPage extends StatefulWidget {
  const HospitalLoginPage({super.key});

  @override
  State<HospitalLoginPage> createState() => _HospitalLoginPageState();
}

class _HospitalLoginPageState extends State<HospitalLoginPage> {
  final TextEditingController _hospitalIdController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final AuthService userService = AuthService();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAlreadyLoggedIn();
  }

  Future<void> _checkAlreadyLoggedIn() async {
    String? isLogged = await secureStorage.read(key: 'isLogged');
    String? role = await secureStorage.read(key: 'role');
    String? designation = await secureStorage.read(key: 'designation');
    String? hospitalName = await secureStorage.read(key: 'hospitalName');
    String? hospitalId = await secureStorage.read(key: 'hospitalId');
    String? hospitalStatus = await secureStorage.read(key: 'hospitalStatus');
    String? staffStatus = await secureStorage.read(key: 'staffStatus');

    String? staffName = await secureStorage.read(key: 'staffName');
    String? staffPhoto = await secureStorage.read(key: 'staffPhoto');


    if (isLogged == 'true' && role != null) {
      _navigateToDashboard(
        role,

        designation ?? '',
        hospitalName ?? '',
        hospitalStatus ?? '',
        staffStatus ?? '',
        staffName ?? '',
        staffPhoto ?? '',

      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // const SizedBox(height: 10),
                      // Image.asset('assets/logo121.png', height: 80, width: 250),
                      AnimatedOpacity(
                        duration: const Duration(seconds: 1),
                        opacity: 1.0,
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            SizedBox(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  'HOSPITAL\nMANAGEMENT',
                                  style: TextStyle(
                                    color: Color(0xFF8A6A41),
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Good Times',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // ===== Login Container =====
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 60,
                              color: Color(0xFFBF955E),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Welcome',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _hospitalIdController,
                              label: 'Hospital ID',
                              icon: Icons.local_hospital,

                              keyboardType: TextInputType.number,

                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _userIdController,
                              label: 'User ID',
                              icon: Icons.person,

                              keyboardType: TextInputType.visiblePassword,

                            ),
                            const SizedBox(height: 15),
                            _buildPasswordField(),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBF955E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: _handleLogin,
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: Color(0xFFBF955E)),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Text(
                        '© 2025 Ramchin Technologies Pvt Ltd.',
                        style: TextStyle(
                          color: Color(0xFFBF955E),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      inputFormatters: label == 'Hospital ID'
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,

      keyboardType: keyboardType,
      controller: controller,
      cursorColor: Color(0xFF8B6B3F),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color(0xFFBF955E)),
        labelText: label,
        labelStyle: TextStyle(color: Colors.black, fontSize: 18),
        // 🟡 BORDER STYLE
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFBF955E), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF8B6B3F), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      cursorColor: Color(0xFF8B6B3F),
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock, color: Color(0xFFBF955E)),
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.black, fontSize: 18),

        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFBF955E), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF8B6B3F), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFFBF955E),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    String hospitalId = _hospitalIdController.text;
    String userId = _userIdController.text;
    String password = _passwordController.text;

    String deviceId = await AuthService().getDeviceId();

    // if (hospitalId.isEmpty || userId.isEmpty || password.isEmpty) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
    //   return;
    // }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await userService.login(
      hospitalId: hospitalId,
      userId: userId,
      password: password,
      deviceId: deviceId,
    );

    Navigator.pop(context); // hide loading

    if (result["success"]) {
      final token = result["data"]["access_token"];
      final user = result["data"]["user"];
      print('user$user');
      if (token == null || user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid response from server")),
        );
        return;
      }
      print('Admin${user["admin"]}');

      final role = user["role"] ?? "Unknown";
      final designation = user["admin"] != null
          ? user["Admin"][0]["designation"] ?? role


          : role;
      final staffName = user["admin"] != null
          ? user["Admin"][0]["name"] ?? role
          : role;
      final staffPhoto = user["admin"] != null
          ? user["Admin"][0]["photo"] ?? role
          : role;
      final staffStatus = user["admin"] != null
          ? user["Admin"][0]["status"] ?? "INACTIVE"
          : role;
      final assistantDoctorId = user["admin"] != null
          ? user["Admin"][0]["assignDoctorId"] ?? ""
          : '0';
      // Get hospital name properly
      final String hospitalStatus = user["Hospital"] != null
          ? (user["Hospital"]["HospitalStatus"] ?? "Unknown Status")
          : "Unknown Status";
      final String hospitalName = user["Hospital"] != null
          ? (user["Hospital"]["name"] ?? "Unknown Hospital")
          : "Unknown Hospital";
      final String hospitalPlace = user["Hospital"] != null
          ? (user["Hospital"]["address"] ?? "Unknown Place")
          : "Unknown Place";

      final String hospitalPhoto = user["Hospital"] != null
          ? (user["Hospital"]["photo"] ??
                "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg")
          : "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";

      // Save login info securely
      await secureStorage.write(key: 'isLogged', value: 'true');
      await secureStorage.write(key: 'role', value: role);
      await secureStorage.write(key: 'designation', value: designation);
      await secureStorage.write(key: 'hospitalName', value: hospitalName);
      await secureStorage.write(key: 'hospitalPlace', value: hospitalPlace);
      await secureStorage.write(key: 'hospitalPhoto', value: hospitalPhoto);
      await secureStorage.write(key: 'accessToken', value: token);
      // await secureStorage.write(key: 'userId', value: userId);
      // await secureStorage.write(key: 'hospitalId', value: hospitalId);
      await secureStorage.write(key: 'hospitalStatus', value: hospitalStatus);

      await secureStorage.write(key: 'staffName', value: staffName);
      await secureStorage.write(key: 'staffPhoto', value: staffPhoto);
      await secureStorage.write(
        key: 'assistantDoctorId',
        value: assistantDoctorId,
      );

      if (hospitalStatus.toUpperCase() == 'ACTIVE' &&
          staffStatus.toUpperCase() == 'ACTIVE') {
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text("Login successful as $role")));

      }

      _navigateToDashboard(
        role,
        designation,
        hospitalName,
        hospitalStatus,
        staffStatus,

        staffName,
        staffPhoto,

      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Login failed")),
      );
    }
  }

  void _navigateToDashboard(
    String role,
    String designation,
    String hospitalName,
    String hospitalStatus,
    String staffStatus,

    String staffName,
    String staffPhoto,
  ) async {
    print(' role $role');

    print(designation);
    print(hospitalStatus);
    print(staffStatus);

    if (hospitalStatus.toUpperCase() != 'ACTIVE') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Hospital is not active")));
      return;
    }

    await secureStorage.write(key: 'staffStatus', value: staffStatus);

    if (role.toUpperCase() != 'ADMIN' &&
        role.toUpperCase() != 'ADMINISTRATOR') {

      if (staffStatus.toUpperCase() != 'ACTIVE') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("staffStatus is not active")),
        );
        return;
      }
    }

    // // Only show success when hospital is active
    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(SnackBar(content: Text("Login successful as $role")));

    Widget page;

    switch (role.toLowerCase()) {

      // case "medical staff":
      //   page = AppWrapper(
      //     child: AdminAppWrapper(
      //       child: MedicalStaffDashboardPage(
      //         designation: designation,
      //         hospitalName: hospitalName,
      //       ),
      //     ),
      //   );
      //   break;
      case "doctor":
        page = AppWrapper(
          child: AdminAppWrapper(
            child: MedicalStaffDashboardPage(
              designation: "doctor",
              hospitalName: hospitalName,
              staffName: staffName,
              staffPhoto: staffPhoto,
            ),
          ),
        );
        break;
      case "nurse":
        page = AppWrapper(
          child: AdminAppWrapper(
            child: MedicalStaffDashboardPage(
              designation: "nurse",
              hospitalName: hospitalName,
              staffName: staffName,
              staffPhoto: staffPhoto,
            ),
          ),
        );
        break;
      case "lab technician":
        page = AppWrapper(
          child: AdminAppWrapper(
            child: MedicalStaffDashboardPage(
              designation: "lab technician",
              hospitalName: hospitalName,
              staffName: staffName,
              staffPhoto: staffPhoto,
            ),
          ),
        );
        break;

      case "medical staff":
        page = AppWrapper(
          child: AdminAppWrapper(
            child: MedicalStaffDashboardPage(

              designation: "medical staff",
              hospitalName: hospitalName,
              staffName: staffName,
              staffPhoto: staffPhoto,
            ),
          ),
        );
        break;
      case "cashier":
        page = AppWrapper(
          child: AdminAppWrapper(
            child: MedicalStaffDashboardPage(
              designation: "cashier",
              hospitalName: hospitalName,
              staffName: staffName,
              staffPhoto: staffPhoto,
            ),
          ),
        );
        break;
      case "assistant doctor":
        page = AppWrapper(
          child: AdminAppWrapper(
            child: MedicalStaffDashboardPage(
              designation: "assistant doctor",
              hospitalName: hospitalName,
              staffName: staffName,
              staffPhoto: staffPhoto,

            ),
          ),
        );
        break;

      case "patient":
        page = const PatientDashboardPage();
        break;

      case "admin":
        page = const AppWrapper(child: AdminDashboardPage());
        break;

      case "administrator":
        page = OverallAdministratorDashPage();
        break;

      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Unknown user role")));
        return;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }
}
