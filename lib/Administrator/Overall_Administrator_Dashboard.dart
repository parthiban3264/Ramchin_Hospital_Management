import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Admin/Appbar/admin_appbar_mobile.dart';
import '../Drawer/AdminDrawer.dart';
import '../Pages/DashboardPages/administrator_dashboard.dart';
import '../Pages/NotificationsPage.dart';
import '../Services/hospital_Service.dart';

class OverallAdministratorDashPage extends StatefulWidget {
  @override
  _OverallAdministratorDashPageState createState() =>
      _OverallAdministratorDashPageState();
}

class _OverallAdministratorDashPageState
    extends State<OverallAdministratorDashPage> {
  // STORAGE
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  bool isPhoneValid = false;
  String? phoneError;
  bool isCheckingHospitalId = false;
  bool? isHospitalIdAvailable; // null = untouched
  String? hospitalIdError;
  Timer? _debounce;

  // Create Hospital FORM
  bool expandForm = false;
  final HospitalService service = HospitalService();

  final idCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final addrCtrl = TextEditingController();
  // final photoCtrl = TextEditingController();
  final statusCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final mailCtrl = TextEditingController();

  List hospitals = [];

  // Dummy stats (replace with API later)
  int totalHospitals = 0;
  int totalAdmins = 0;
  int totalDoctors = 0;
  int totalStaff = 0;
  bool isLoading = false;
  bool isListLoading = true;
  XFile? pickedImage;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    loadHospitals();
  }

  void resetForm() {
    idCtrl.clear();
    nameCtrl.clear();
    addrCtrl.clear();
    phoneCtrl.clear();
    mailCtrl.clear();
    pickedImage = null;
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();

    hospitalName = prefs.getString('hospitalName') ?? "Unknown";
    hospitalPlace = prefs.getString('hospitalPlace') ?? "Unknown";
    hospitalPhoto =
        prefs.getString('hospitalPhoto') ??
        "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    setState(() {});
  }

  Future<void> loadHospitals() async {
    setState(() => isListLoading = true);

    final hospitalsList = await service.getAllHospitals();

    int adminCount = 0;
    int doctorCount = 0;
    int staffCount = 0;
    int activeHospitalCount = 0;

    for (var hospital in hospitalsList) {
      if (hospital["HospitalStatus"] == "ACTIVE") {
        activeHospitalCount++;
      }

      for (var admin in hospital["Admins"]) {
        if (admin["role"].toString().toLowerCase() == "admin") {
          adminCount++;
        }

        if (admin["role"].toString().toLowerCase() == "doctor") {
          doctorCount++;
        }

        if (admin["role"].toString().toLowerCase() != "doctor") {
          staffCount++;
        }
      }
    }

    setState(() {
      hospitals = hospitalsList;
      totalHospitals = activeHospitalCount;
      totalAdmins = adminCount;
      totalDoctors = doctorCount;
      totalStaff = staffCount;
      isListLoading = false; // <-- Turn off loader
    });
  }

  Future<void> saveHospital() async {
    if (pickedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select an image")));
      return;
    }

    if (nameCtrl.text.isEmpty ||
        addrCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await service.createHospital(
      hospitalId: idCtrl.text,
      name: nameCtrl.text,
      address: addrCtrl.text,
      phone: phoneCtrl.text,
      mail: mailCtrl.text,
      file: pickedImage!,
    );

    setState(() => isLoading = false);

    if (result["status"] == "success") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hospital created successfully")));
      expandForm = false;
      loadHospitals();
      resetForm();
      setState(() {});
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: ${result['body']}")));
    }
  }

  void pickPhoto() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose Image",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // CAMERA
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.orange),
                title: Text("Camera"),
                onTap: () async {
                  final img = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (img != null) {
                    setState(() => pickedImage = img);
                  }
                  Navigator.pop(context);
                },
              ),

              // GALLERY
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blue),
                title: Text("Gallery"),
                onTap: () async {
                  final img = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (img != null) {
                    setState(() => pickedImage = img);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  ImageProvider? _getImageProvider() {
    if (pickedImage != null) {
      return FileImage(File(pickedImage!.path));
    }
    return null;
  }

  // ---------------------------------------------
  // Hospital Header Card (Gold Gradient UI)
  // ---------------------------------------------
  Widget _buildHospitalCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                hospitalPhoto ?? "",
                height: 60,
                width: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.local_hospital,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospitalName ?? "Unknown Hospital",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hospitalPlace ?? "Unknown Place",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------
  // STATS CARD SINGLE
  // ---------------------------------------------
  Widget _statCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],

        // GOLD BORDER
        border: Border.all(color: Color(0xFFC59A62), width: 1.6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(width: 6),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          SizedBox(height: 4),
          Text(
            "$value",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------
  // BUILD UI
  // ---------------------------------------------
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.sizeOf(context).width;
    bool isMobile = screenWidth < 600;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AdminAppbarMobile(
          title: 'Dashboard',
          isBackEnable: false,
          isNotificationEnable: true,
          isDrawerEnable: true,
          notificationRoute: NotificationPage(),
        ),
      ),
      drawer: AdminMobileDrawer(
        title: 'Menu',
        width: isMobile
            ? MediaQuery.of(context).size.width * 0.75
            : MediaQuery.of(context).size.width / 3,
      ),
      body: RefreshIndicator(
        onRefresh: loadHospitals,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHospitalCard(),
              SizedBox(height: 15),

              // CREATE HOSPITAL CARD HEADER
              GestureDetector(
                onTap: () => setState(() => expandForm = !expandForm),
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6EB8E6), Color(0xFF5E99C3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_business, size: 30, color: Colors.white),
                      // SizedBox(width: 14),
                      Spacer(),
                      Text(
                        "Create Hospital",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 14),
                      Spacer(),
                      Icon(
                        expandForm
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 28,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              // EXPANDABLE FORM (Card Style)
              // ================= EXPANDABLE FORM ======================
              if (expandForm)
                Container(
                  margin: EdgeInsets.only(top: 14),
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Color(0xFFC59A62), width: 1.3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ⭐ PROFILE IMAGE PICKER
                      GestureDetector(
                        onTap: pickPhoto,
                        child: Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFDAC7AE),
                                    Color(0xFFCDB18B),
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                backgroundImage: _getImageProvider(),
                                child: (pickedImage == null)
                                    ? Icon(
                                        Icons.person,
                                        size: 45,
                                        color: Colors.grey.shade500,
                                      )
                                    : null,
                              ),
                            ),

                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 32,
                                width: 32,
                                decoration: BoxDecoration(
                                  color: Color(0xFFDAC7AE),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 25,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),
                      //_inputField(Icons.local_hospital, "Hospital ID", idCtrl),
                      _hospitalIdInputField(),
                      SizedBox(height: 8),
                      _inputField(
                        Icons.local_hospital,
                        "Hospital Name",
                        nameCtrl,
                      ),
                      SizedBox(height: 8),

                      _inputField(Icons.location_on, "Address", addrCtrl),
                      SizedBox(height: 8),

                      //_inputField(Icons.phone, "Phone Number", phoneCtrl),
                      _phoneInputField(),
                      SizedBox(height: 8),

                      _inputField(
                        Icons.mail,
                        "Email Address (Optional)",
                        mailCtrl,
                      ),
                      SizedBox(height: 22),

                      // ⭐ SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Color(0xFFC59A62),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          // onPressed: isLoading ? null : saveHospital,
                          // onPressed: (isLoading || !isPhoneValid)
                          //     ? null
                          //     : saveHospital,
                          onPressed:
                              (isLoading ||
                                  !isPhoneValid ||
                                  isHospitalIdAvailable != true)
                              ? null
                              : saveHospital,

                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Save Hospital",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 15),
              // STATS GRID
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          "Total Hospitals",
                          totalHospitals,
                          Icons.local_hospital,
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          "Total Admins",
                          totalAdmins,
                          Icons.admin_panel_settings,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          "Total Doctors",
                          totalDoctors,
                          Icons.medical_services,
                          Colors.red,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          "Total Staff",
                          totalStaff,
                          Icons.group,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // SizedBox(height: 15),

              // CREATE HOSPITAL BUTTON
              SizedBox(height: 15),

              // Hospital List
              isListLoading
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFFC59A62),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: hospitals.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, i) {
                        final h = hospitals[i];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdministratorDashboardPage(
                                  hospitalData: h,
                                  onHospitalUpdated: () {
                                    loadHospitals(); // refresh OverallAdministratorDashPage
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFFDF8), Color(0xFFDCDADA)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              border: Border.all(
                                color: Colors.blueGrey.withOpacity(0.35),
                                width: 1.4,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: h["HospitalStatus"] == "ACTIVE"
                                            ? [
                                                Colors.greenAccent,
                                                Colors.lightGreenAccent,
                                              ]
                                            : [
                                                Colors.redAccent.withOpacity(
                                                  0.8,
                                                ),
                                                Colors.redAccent.withOpacity(
                                                  0.7,
                                                ),
                                              ],
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.white,
                                      backgroundImage: NetworkImage(
                                        h["photo"] ?? "",
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          h["name"],
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            // Icon(
                                            //   Icons.perm_identity,
                                            //   size: 16,
                                            //   color: Colors.grey,
                                            // ),
                                            SizedBox(width: 4),
                                            Text(
                                              'ID : ${h["id"].toString()}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Spacer(),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    h["HospitalStatus"] ==
                                                        "ACTIVE"
                                                    ? Colors.green.shade100
                                                    : Colors.red.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                h["HospitalStatus"],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      h["HospitalStatus"] ==
                                                          "ACTIVE"
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              h["address"],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
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
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(IconData icon, String label, TextEditingController ctrl) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        color: Colors.grey.shade100,
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFC59A62)),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              cursorColor: Color(0xFFA57E4B),
              controller: ctrl,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.black),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneInputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: phoneError != null ? Colors.red : Colors.black12,
        ),
        color: Colors.grey.shade100,
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: Color(0xFFC59A62)),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: phoneCtrl,
              cursorColor: Color(0xFFA57E4B),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    phoneError = null;
                    isPhoneValid = false;
                  });
                } else if (value.length < 10) {
                  setState(() {
                    phoneError = "Phone number must be 10 digits";
                    isPhoneValid = false;
                  });
                } else {
                  setState(() {
                    phoneError = null;
                    isPhoneValid = true;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: "Phone Number",
                labelStyle: TextStyle(color: Colors.black),
                counterText: "",
                border: InputBorder.none,
                errorText: phoneError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> checkHospitalId(String id) async {
    if (id.isEmpty) {
      setState(() {
        isHospitalIdAvailable = null;
        hospitalIdError = null;
      });
      return;
    }

    setState(() {
      isCheckingHospitalId = true;
      isHospitalIdAvailable = null;
    });

    try {
      final result = await service.getHospitalById(id);

      if (result["status"] == "success" && result["data"] != null) {
        // Hospital exists
        setState(() {
          isHospitalIdAvailable = false;
          hospitalIdError = "Hospital ID already exists";
        });
      } else {
        // Available
        setState(() {
          isHospitalIdAvailable = true;
          hospitalIdError = null;
        });
      }
    } catch (_) {
      setState(() {
        isHospitalIdAvailable = true;
        hospitalIdError = null;
      });
    }

    setState(() => isCheckingHospitalId = false);
  }

  Widget _hospitalIdInputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hospitalIdError != null
              ? Colors.red
              : isHospitalIdAvailable == true
              ? Colors.green
              : Colors.black12,
        ),
        color: Colors.grey.shade100,
      ),
      child: Row(
        children: [
          Icon(Icons.local_hospital, color: Color(0xFFC59A62)),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: idCtrl,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(Duration(milliseconds: 600), () {
                  checkHospitalId(value);
                });
              },
              decoration: InputDecoration(
                labelText: "Hospital ID",
                border: InputBorder.none,
                errorText: hospitalIdError,
              ),
            ),
          ),

          // RIGHT ICON AREA
          if (isCheckingHospitalId)
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isHospitalIdAvailable == true)
            Icon(Icons.check_circle, color: Colors.green)
          else if (isHospitalIdAvailable == false)
            Icon(Icons.cancel, color: Colors.red),
        ],
      ),
    );
  }
}
