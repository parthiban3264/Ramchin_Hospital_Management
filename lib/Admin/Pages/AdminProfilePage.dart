import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../Pages/NotificationsPage.dart';
import '../../Services/admin_service.dart';

const Color primaryColor = Color(0xFFBF955E);

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AdminService _adminService = AdminService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _adminService.getProfile();
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  Widget _infoTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : "-",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ---------------- HEADER ---------------- //
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          height: 100,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Color(0xFFAA814A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "My Profile",
                    style: TextStyle(
                      fontSize: 23,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 26,
                    ),
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

      // ---------------- BODY ---------------- //
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _profile == null
          ? const Center(child: Text("Profile not found"))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ---------------- GLASS PROFILE CARD ---------------- //
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.9),
                          primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        /// --- Profile Avatar ---
                        Hero(
                          tag: "profile_avatar",
                          child: CircleAvatar(
                            radius: 37,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: ClipOval(
                              child: Image.network(
                                _profile!['photo'] ?? "",
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        /// --- Name, Designation & Role ---
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile!['name'] ?? "-",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _profile!['designation'] ?? "-",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),

                                  Spacer(),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _profile!['role'] ?? "-",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ---------------- PERSONAL INFO ---------------- //
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: primaryColor),
                      SizedBox(width: 8),
                      Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _infoTile(
                    "User ID",
                    _profile!['user_Id'] ?? "-",
                    Icons.badge_outlined,
                  ),
                  _infoTile(
                    "Hospital",
                    _profile!['Hospital']?['name'] ?? "-",
                    Icons.local_hospital_outlined,
                  ),
                  _infoTile(
                    "Specialist",
                    _profile!['specialist'] ?? "-",
                    Icons.medical_services_outlined,
                  ),
                  _infoTile(
                    "Phone",
                    _profile!['phone'] ?? "-",
                    Icons.phone_android,
                  ),
                  _infoTile(
                    "Email",
                    _profile!['email'] ?? "-",
                    Icons.email_outlined,
                  ),
                  _infoTile(
                    "Address",
                    _profile!['address'] ?? "-",
                    Icons.location_on_outlined,
                  ),
                  _infoTile(
                    "Gender",
                    _profile!['gender'] ?? "-",
                    Icons.person_outline,
                  ),
                  _infoTile(
                    "Status",
                    _profile!['status'] ?? "-",
                    Icons.verified_user_outlined,
                  ),
                  _infoTile(
                    "Created At",
                    _profile!['createdAt']?.toString().split("T").first ?? "-",
                    Icons.calendar_today_outlined,
                  ),
                  _infoTile(
                    "Updated At",
                    _profile!['updatedAt']?.toString().split("T").first ?? "-",
                    Icons.update_outlined,
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }
}
