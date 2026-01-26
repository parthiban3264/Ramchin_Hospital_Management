import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Pages/NotificationsPage.dart';
import '../../../Services/admin_service.dart';

class AddStaffPage extends StatefulWidget {
  const AddStaffPage({super.key});

  @override
  State<AddStaffPage> createState() => _AddStaffPageState();
}

class _AddStaffPageState extends State<AddStaffPage> {
  final _formKey = GlobalKey<FormState>();
  bool formOpen = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController specialistController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final TextEditingController drAmountController = TextEditingController();
  final TextEditingController passwordController = TextEditingController(
    text: 'abc123',
  );
  final TextEditingController roleController = TextEditingController();
  final TextEditingController userIdController = TextEditingController();

  String? selectedDesignation;
  String? selectedRole;

  String? selectedGender;
  File? _profileImage;
  bool _isLoading = false; // <-- Add this at the top of your state class
  bool _isFormValid = false;
  bool _checkingUserId = false;
  bool _userIdChecked = false;
  bool _obscurePassword = true; // Add this in your State class

  String? _userIdError;
  List<dynamic> staffs = [];
  @override
  void initState() {
    super.initState();
    loadDoctorData();
    fetchStaffs();
  }

  Future<void> fetchStaffs() async {
    setState(() {
      _isLoading = true;
    });
    final a = await AdminService().getMedicalStaff();

    // filter staff whose role is NOT ADMIN
    staffs = a.where((staff) => staff['role'] != 'ADMIN').toList();
    setState(() {
      _isLoading = false;
    });
  }

  final List<String> designation = [
    "Doctor",
    "Nurse",
    "Cashier",

    'Lab Technician',
    'Medical Staff',
    'Non-Medical',
  ];
  final List<String> role = [
    "DOCTOR",
    "NURSE",
    "CASHIER",
    'LAB TECHNICIAN',
    'MEDICAL STAFF',
    'ASSISTANT DOCTOR',
    'NON-MEDICAL STAFF',
  ];

  // final List<String> roles = ["Doctor", "Nurse", "Admin", "Staff"];
  final List<String> genders = ["Male", "Female", "Other"];

  List<String> doctorNames = [];
  Map<String, String> doctorIdByName = {};
  String? selectedDoctorId;
  String? selectedDoctorName;

  @override
  void dispose() {
    nameController.dispose();
    designationController.dispose();
    specialistController.dispose();
    phoneController.dispose();
    emailController.dispose();

    roleController.dispose();
    addressController.dispose();
    drAmountController.dispose();
    super.dispose();
  }

  // Future<void> _pickImage() async {
  //   final picker = ImagePicker();
  //   final picked = await picker.pickImage(source: ImageSource.gallery);
  //   if (picked != null) {
  //     setState(() => _profileImage = File(picked.path));
  //   }
  // }

  void _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;

    // Initial required fields
    bool requiredFilled =
        nameController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        selectedGender != null &&
        selectedRole != null;

    // Conditional: if role is DOCTOR, specialist is also required
    if (selectedRole == 'DOCTOR') {
      requiredFilled =
          requiredFilled && specialistController.text.trim().isNotEmpty;
    }

    setState(() {
      _isFormValid = isValid && requiredFilled;
    });
  }

  Future<void> checkUserIdAvailability() async {
    final String userId = userIdController.text.trim().isEmpty
        ? phoneController.text.trim()
        : userIdController.text.trim();

    //final userId = userIdController.text.trim();

    // 🔹 EMPTY → reset state
    if (userId.isEmpty) {
      setState(() {
        _userIdChecked = false;
        _userIdError = null;
      });
      return;
    }

    setState(() {
      _checkingUserId = true;
      _userIdChecked = false;
    });

    try {
      final exists = await AdminService().checkUserIdExists(userId: userId);

      setState(() {
        _userIdError = exists ? 'User ID already exists' : null;
        _userIdChecked = true;
      });
    } finally {
      setState(() => _checkingUserId = false);
    }
  }

  Future<void> loadDoctorData() async {
    try {
      final doctorData = await AdminService().getMedicalStaff();

      doctorNames.clear();
      doctorIdByName.clear();

      for (var staff in doctorData) {
        if ((staff['role'] ?? '').toString().toUpperCase() == 'DOCTOR') {
          final id = staff['user_Id'].toString();
          final name = staff['name'].toString();

          doctorNames.add(name);
          doctorIdByName[name] = id;
        }
      }

      setState(() {});
    } catch (e) {
      setState(() {});
    }
  }

  void _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true); // 🔹 Show loading spinner

    try {
      final prefs = await SharedPreferences.getInstance();
      final hospitalId = prefs.getString('hospitalId');

      final String userIdToSave = userIdController.text.trim().isEmpty
          ? phoneController.text.trim()
          : userIdController.text.trim();

      final userData = {
        "name": nameController.text.trim(),
        'user_Id': userIdToSave,
        'hospital_Id': int.parse(hospitalId!),
        "designation": designationController.text.trim(), //selectedDesignation,
        "password": passwordController.text.trim(),
        "role": selectedRole,
        "assignDoctorId": selectedDoctorId ?? '',
        "specialist": specialistController.text.trim(),
        "doctorAmount": double.tryParse(drAmountController.text) ?? 0,

        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "address": addressController.text.trim(),
        "gender": selectedGender,
        "profile": _profileImage?.path,
      };

      final result = await AdminService().createAdmin(userData);

      if (result["success"] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Staff successfully added!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      if (mounted) Navigator.pop(context);

      _formKey.currentState!.reset();
      setState(() {
        nameController.clear();
        passwordController.clear();
        userIdController.clear();
        designationController.clear();
        specialistController.clear();
        phoneController.clear();
        emailController.clear();
        selectedDesignation = null;
        selectedRole = null;
        selectedGender = null;
        _profileImage = null;
        _userIdError = null;
        _checkingUserId = false;
        _userIdChecked = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("failed to add Staff"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false); // 🔹 Hide loading spinner
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFBF955E);

    //final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      // backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: gold,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),

                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Add Staff",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
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
      body: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 400,
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              if (formOpen) form(),

              const SizedBox(height: 10),

              // Staff list should take remaining space
              if (!formOpen) Expanded(child: staffListWidget(staffs)),
              //if (!formOpen) const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: !formOpen ? Colors.blue : Colors.red,
        foregroundColor: Colors.white,
        child: Icon(!formOpen ? Icons.add : Icons.close),
        //label: Text(!formOpen ? 'Add' : 'Close'),
        onPressed: () {
          setState(() {
            formOpen = !formOpen;
          });
        },
      ),
    );
  }

  Widget form() {
    const Color gold = Color(0xFFBF955E);
    return Expanded(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,

          onChanged: () {
            final isValid = _formKey.currentState?.validate() ?? false;

            // Required fields check
            final requiredFilled =
                nameController.text.trim().isNotEmpty &&
                phoneController.text.trim().isNotEmpty &&
                passwordController.text.trim().isNotEmpty &&
                selectedGender != null &&
                selectedRole != null;

            setState(() {
              _isFormValid = isValid && requiredFilled;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTextField(
                controller: userIdController,
                keyboardType: TextInputType.visiblePassword,
                label: "User Id",
                icon: Icons.person_outline,
                color: gold,
                onChanged: (_) => {checkUserIdAvailability()},
                onFieldSubmitted: (_) => checkUserIdAvailability(),
                // Show icon only if User ID is being checked
                suffixIcon: userIdController.text.trim().isEmpty
                    ? null
                    : _checkingUserId
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                    : _userIdChecked
                    ? (_userIdError != null
                          ? const Icon(Icons.error, color: Colors.red)
                          : const Icon(Icons.check_circle, color: Colors.green))
                    : null,
              ),

              const SizedBox(height: 2),

              // _buildTextField(
              //   controller: phoneController,
              //   label: "Phone *",
              //   icon: Icons.phone,
              //   keyboardType: TextInputType.phone,
              //   color: gold,
              //   prefixText: '+91 ',
              //   maxLength: 10,
              //   digitsOnly: true,
              // ),
              _buildTextField(
                controller: phoneController,
                label: "Phone *",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                color: gold,
                prefixText: '+91 ',

                maxLength: 10,
                digitsOnly: true,
                onFieldSubmitted: (_) => checkUserIdAvailability(),
                onChanged: (_) {
                  if (userIdController.text.trim().isEmpty) {
                    checkUserIdAvailability();
                  }
                },
                // Show icon only if phone is being checked
                suffixIcon: userIdController.text.trim().isEmpty
                    ? (_checkingUserId
                          ? const Padding(
                              padding: EdgeInsets.all(15),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                            )
                          : _userIdChecked
                          ? (_userIdError != null
                                ? const Icon(Icons.error, color: Colors.red)
                                : const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ))
                          : null)
                    : null,
              ),

              const SizedBox(height: 2),
              _buildTextField(
                controller: nameController,
                label: "Full Name *",
                icon: Icons.person_outline,
                color: gold,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
              const SizedBox(height: 2),

              // _buildTextField(
              //   controller: phoneController,
              //   label: "Phone *",
              //   icon: Icons.phone,
              //   keyboardType: TextInputType.phone,
              //   color: gold,
              //   prefixText: '+91 ',
              // ),
              _buildTextField(
                controller: passwordController,
                label: "Password *",
                icon: Icons.password,
                color: gold,
                obscureText: _obscurePassword, // hide/show password
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword; // toggle visibility
                    });
                  },
                ),
              ),

              const SizedBox(height: 2),

              _buildDropdown(
                value: selectedGender,
                label: "Gender *",
                icon: Icons.wc,
                color: gold,
                items: genders,

                //onChanged: (val) => setState(() => selectedGender = val),
                onChanged: (val) {
                  setState(() => selectedGender = val);
                  _validateForm(); // immediately update button
                },
              ),

              // const SizedBox(height: 24),
              //
              // const Divider(thickness: 1.2, color: Color(0xFFE0E0E0)),
              const SizedBox(height: 2),

              // Text(
              //   "Professional Information",
              //   style: TextStyle(
              //     color: gold,
              //     fontSize: 20,
              //     fontWeight: FontWeight.bold,
              //     letterSpacing: 0.8,
              //   ),
              // ),
              // const SizedBox(height: 18),
              // _buildTextField(
              //   controller: designationController,
              //   label: "Designation",
              //   icon: Icons.work_outline,
              //   color: gold,
              // ),
              // const SizedBox(height: 16),
              //
              _buildDropdown(
                value: selectedRole,
                label: "Role *",
                icon: Icons.account_tree_outlined,
                color: gold,
                items: role,
                //onChanged: (val) => setState(() => selectedRole = val),
                onChanged: (val) {
                  setState(() => selectedRole = val);
                  _validateForm(); // immediately update button
                },

                //validator: (v) => v == null ? "Please select Role" : null,
              ),
              if (selectedRole == 'DOCTOR') ...[
                const SizedBox(height: 2),
                _buildTextField(
                  controller: specialistController,
                  label: "Specialist *",
                  icon: Icons.local_hospital_outlined,
                  color: gold,
                ),
                const SizedBox(height: 2),
                _buildTextField(
                  controller: drAmountController,
                  label: "Dr Fees ( optional )",
                  icon: Icons.currency_rupee,
                  color: gold,
                ),
              ],

              const SizedBox(height: 2),

              if (selectedRole == 'ASSISTANT DOCTOR') ...[
                // DropdownButtonFormField<String>(
                //   value: selectedDoctorId,
                //   decoration: InputDecoration(labelText: "Assign Doctor *"),
                //   items: doctors.map((doctor) {
                //     return DropdownMenuItem<String>(
                //       value: doctor['id'], // ✅ selected ID
                //       child: Text(doctor['name']!), // 👁 display name
                //     );
                //   }).toList(),
                //   onChanged: (val) {
                //     setState(() {
                //       selectedDoctorId = val;
                //     });
                //     _validateForm();
                //   },
                // ),
                _buildDropdown(
                  value: selectedDoctorName,
                  label: "Assign Doctor",
                  icon: Icons.account_tree_outlined,
                  color: gold,
                  items: doctorNames,
                  onChanged: (val) {
                    setState(() {
                      selectedDoctorName = val;
                      selectedDoctorId = doctorIdByName[val];
                    });
                    _validateForm();
                  },
                ),
              ],

              // _buildDropdown(
              //   value: selectedDesignation,
              //   label: "Designation ",
              //   icon: Icons.account_tree_outlined,
              //   color: gold,
              //   items: designation,
              //   onChanged: (val) =>
              //       setState(() => selectedDesignation = val),
              //   validator: (v) =>
              //       v == null ? "Please select Designation" : null,
              // ),
              // if (selectedDesignation == 'Doctor') ...[
              //   const SizedBox(height: 10),
              //   _buildTextField(
              //     controller: specialistController,
              //     label: "Specialist",
              //     icon: Icons.local_hospital_outlined,
              //     color: gold,
              //   ),
              //   const SizedBox(height: 10),
              //   _buildTextField(
              //     controller: drAmountController,
              //     label: "Dr Fees ( optional )",
              //     icon: Icons.currency_rupee,
              //     color: gold,
              //   ),
              // ],
              _buildTextField(
                controller: designationController,
                label: "Designation",
                icon: Icons.account_tree_outlined,
                maxLines: 1,
                color: gold,
              ),
              const SizedBox(height: 2),
              _buildTextField(
                controller: emailController,
                label: "Email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                color: gold,
              ),

              const SizedBox(height: 2),
              _buildTextField(
                controller: addressController,
                label: "Address",
                icon: Icons.home_outlined,
                maxLines: 2,
                color: gold,
                inputFormatters: [UpperCaseTextFormatter()],
              ),

              // const Divider(thickness: 1.2, color: Color(0xFFE0E0E0)),
              const SizedBox(height: 2),

              // Text(
              //   "Contact Information",
              //   style: TextStyle(
              //     color: gold,
              //     fontSize: 20,
              //     fontWeight: FontWeight.bold,
              //     letterSpacing: 0.8,
              //   ),
              // ),

              //
              const SizedBox(height: 20),
              // Save Button
              ElevatedButton(
                onPressed:
                    (_isLoading ||
                        !_isFormValid ||
                        (_userIdError?.isNotEmpty ?? false))
                    ? null
                    : _saveUser,

                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Add Staff",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Common Text Field Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? prefixText,

    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,

    // 🔹 logic only
    int? maxLength,
    bool digitsOnly = false,

    // 🆕 new
    void Function(String)? onFieldSubmitted,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),

            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        cursorColor: color,
        maxLines: maxLines,
        keyboardType: keyboardType,

        obscureText: obscureText,

        // 🔹 logic
        maxLength: maxLength,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: [
          ...inputFormatters ?? [],
          if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],

        // 🆕 callbacks
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          height: 1.3,
        ),

        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),

          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 10),
            child: Icon(icon, color: color, size: 22),
          ),

          suffixIcon: suffixIcon, // 🆕 here

          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),

          prefixText: prefixText,
          prefixStyle: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),

          filled: true,
          fillColor: Colors.white,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: color, width: 2),
          ),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),

          counterText: "",
        ),
        onFieldSubmitted: onFieldSubmitted,
        onChanged: onChanged,

        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return null;
          }
          if (label.contains("Phone") && value.length < 10) {
            return "Phone number must be 10 digits";
          }
          if (label.contains("Email")) {
            final emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            );
            if (!emailRegex.hasMatch(value.trim())) {
              return "Enter a valid email address";
            }
          }
          return null;
        },
      ),
    );
  }

  // Common Dropdown Builder
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required Color color,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    String? value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),

            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: color, size: 22),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        icon: Icon(Icons.arrow_drop_down_rounded, color: color, size: 32),

        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),

        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),

        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget staffListWidget(List staffs) {
    if (staffs.isEmpty) {
      return const Center(
        child: Text('No staff found', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 60, top: 2),
      itemCount: staffs.length,
      itemBuilder: (context, index) {
        final staff = staffs[index];
        final bool isInactive = staff['status'] == 'INACTIVE';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 3,
          color: isInactive ? Colors.red.shade50 : Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: staff['photo'] != null
                  ? NetworkImage(staff['photo'])
                  : null,
              child: staff['photo'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(
              staff['name'] ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isInactive ? Colors.red.shade900 : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (staff['user_Id'] != null &&
                    staff['user_Id'].toString().isNotEmpty)
                  Text('User Id: ${staff['user_Id']}'),
                Text(
                  'Role: ${staff['role']}',
                  style: TextStyle(
                    color: isInactive ? Colors.red.shade700 : Colors.black87,
                  ),
                ),
                Text('Phone: ${staff['phone'] ?? '-'}'),
                if (isInactive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'INACTIVE',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: isInactive
                ? null
                : IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, staff),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Map staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${staff['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteStaff(context, staff['id']);
    }
  }

  Future<void> _deleteStaff(BuildContext context, int staffId) async {
    final res = await AdminService().deleteAdmin(staffId);

    if (res['status'] == 'success') {
      fetchStaffs();
    } else {
      _showDeleteFailedDialog(context, staffId);
    }
  }

  void _showDeleteFailedDialog(BuildContext context, int staffId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Delete'),
        content: const Text(
          'Failed to delete staff due to usage.\n\nYou can deactivate the staff instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
            ),
            onPressed: () async {
              Navigator.pop(context);

              final res = await AdminService().updateStatus(staffId, false);

              if (res['status'] == 'success') {
                fetchStaffs();
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Staff deactivated successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );

                fetchStaffs(); // refresh list
              } else {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to deactivate staff'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },

            child: const Text(
              'Deactivate Staff',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
