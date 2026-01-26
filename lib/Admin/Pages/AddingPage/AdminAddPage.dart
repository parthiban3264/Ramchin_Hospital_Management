import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Pages/NotificationsPage.dart';
import '../../../Services/admin_service.dart';

class AddAdminPage extends StatefulWidget {
  const AddAdminPage({super.key});

  @override
  State<AddAdminPage> createState() => _AddAdminPageState();
}

class _AddAdminPageState extends State<AddAdminPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final TextEditingController passwordController = TextEditingController(
    text: 'abc123',
  );
  final TextEditingController userIdController = TextEditingController();

  String? selectedGender;
  File? _profileImage;

  bool _isLoading = false;

  bool _obscurePassword = true;
  bool _isFormValid = false;
  bool _checkingUserId = false;
  bool _userIdChecked = false;
  bool _defaultList = true;
  String? _userIdError;
  String? errorText;

  final List<String> genders = ["Male", "Female", "Other"];

  bool get isFormValid {
    return nameController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty &&
        selectedGender != null;
  }

  @override
  void initState() {
    super.initState();
    _adminLoad();

    // Live validation listeners
    nameController.addListener(() => setState(() {}));
    phoneController.addListener(() => setState(() {}));
    emailController.addListener(() => setState(() {}));
    addressController.addListener(() => setState(() {}));

    passwordController.addListener(() => setState(() {}));
    selectedGender = null;
  }

  @override
  void dispose() {
    nameController.dispose();
    designationController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();

    passwordController.dispose();
    userIdController.dispose();
    super.dispose();
  }

  List<dynamic> admins = [];

  void _adminLoad() async {
    final allStaff = await AdminService().getMedicalStaff();

    setState(() {
      admins = allStaff
          .where((e) => e["role"]?.toString().toUpperCase() == "ADMIN")
          .toList();
    });
  }

  void _validateForm() {
    // 🔥 Force validation every time

    final isValid = _formKey.currentState?.validate() ?? false;

    bool requiredFilled =
        nameController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        selectedGender != null;

    setState(() {
      _isFormValid = isValid && requiredFilled;
    });
  }

  // Future<void> _pickImage() async {
  //   final picker = ImagePicker();
  //   final picked = await picker.pickImage(source: ImageSource.gallery);
  //   if (picked != null) {
  //     setState(() => _profileImage = File(picked.path));
  //   }
  // }

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
      // =======
      //     super.dispose();
      //   }
      //
      //   Future<void> _pickImage() async {
      //     final picker = ImagePicker();
      //     final picked = await picker.pickImage(source: ImageSource.gallery);
      //     if (picked != null) {
      //       setState(() => _profileImage = File(picked.path));
      // >>>>>>> 3f063fbf1fae91f45feca0bca76a410ab6083f20
    }
  }

  // ---------------------------------------------------------------
  // SAVE USER
  // ---------------------------------------------------------------
  void _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final hospitalId = prefs.getString('hospitalId');

      final String userIdToSave = userIdController.text.trim().isEmpty
          ? phoneController.text.trim()
          : userIdController.text.trim();

      if (hospitalId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Hospital ID not found. Please login again."),
              backgroundColor: Colors.red,
            ),
          );
        }

        return;
      }

      final userData = {
        "name": nameController.text.trim(),

        "user_Id": userIdToSave,
        "hospital_Id": int.parse(hospitalId),
        "password": passwordController.text.trim(),

        "designation": designationController.text.trim(),
        "role": "ADMIN",
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "address": addressController.text.trim(),
        "gender": selectedGender,
        "photo": _profileImage?.path,
      };

      final result = await AdminService().createAdmin(userData);

      if (result["success"] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result["message"] ?? "Admin created successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }

        // CLEAR FORM
        _formKey.currentState!.reset();
        setState(() {
          nameController.clear();
          passwordController.clear();
          userIdController.clear();
          phoneController.clear();
          selectedGender = null;
          _profileImage = null;
          _checkingUserId = false;
          _userIdChecked = false;
          _userIdError = null;
          _isFormValid = false;
        });
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result["message"] ?? "Failed to create admin"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFBF955E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Add Admin",
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

      body: _defaultList ? _adminList(admins) : _addForm(gold),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _defaultList ? Colors.blue : Colors.redAccent,
        child: Icon(
          _defaultList ? Icons.add : Icons.close,
          color: Colors.white,
        ),
        onPressed: () {
          setState(() {
            _defaultList = !_defaultList;

            // when closing form → refresh admin list
            if (_defaultList) {
              _adminLoad();
            }
          });
        },
      ),
    );
  }

  Widget _addForm(Color gold) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // _buildTextField(
                //   controller: userIdController,
                //   label: "userId",
                //   icon: Icons.phone,
                //   keyboardType: TextInputType.phone,
                //   color: gold,
                // ),
                _buildTextField(
                  controller: userIdController,
                  keyboardType: TextInputType.visiblePassword,
                  label: "User Id",
                  icon: Icons.person_outline,
                  color: gold,
                  onChanged: (_) => checkUserIdAvailability(),
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
                            : const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ))
                      : null,
                ),
                const SizedBox(height: 16),

                // _buildTextField(
                //   controller: phoneController,
                //   label: "Phone *",
                //   icon: Icons.phone,
                //   keyboardType: TextInputType.phone,
                //   color: gold,
                //   prefixText: "+91 ",
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
                  onChanged: (_) {
                    _validateForm();
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
                const SizedBox(height: 16),

                _buildTextField(
                  controller: nameController,
                  label: "Full Name *",
                  icon: Icons.person_outline,
                  color: gold,

                  inputFormatters: [UpperCaseTextFormatter()],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: passwordController,
                  label: "Password *",
                  icon: Icons.password,
                  color: gold,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                _buildDropdown(
                  value: selectedGender,
                  label: "Gender *",
                  icon: Icons.wc,
                  color: gold,
                  items: genders,

                  onChanged: (val) {
                    setState(() => selectedGender = val);
                    _validateForm(); // immediately update button
                  },
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: designationController,
                  label: "Designation",
                  icon: Icons.work_outline,
                  color: gold,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  color: gold,
                  onChanged: (_) => _validateForm(),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: addressController,

                  label: "Address",
                  icon: Icons.home_outlined,
                  maxLines: 2,
                  color: gold,
                  inputFormatters: [UpperCaseTextFormatter()],
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed:
                      (_isLoading ||
                          !_isFormValid ||
                          (_userIdError?.isNotEmpty ?? false))
                      ? null
                      : _saveUser,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: (!_isLoading && isFormValid)
                        ? gold
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Add Admin",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _adminList(List staffs) {
    if (admins.isEmpty) {
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
      _adminLoad();
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
                _adminLoad();
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Staff deactivated successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );

                _adminLoad(); // refresh list
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

  // ----------------------------------------------------------------
  // TEXT FIELD WIDGET
  // ----------------------------------------------------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? prefixText,

    bool obscureText = false,
    // 🔹 logic only
    int? maxLength,
    bool digitsOnly = false,
    void Function(String)? onFieldSubmitted,
    void Function(String)? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,

    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,

      obscureText: obscureText,
      maxLength: maxLength,
      textCapitalization: textCapitalization,

      autovalidateMode: AutovalidateMode.disabled,
      inputFormatters: [
        ...inputFormatters ?? [],
        if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],

      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        errorText: errorText,

        prefixIcon: Icon(icon, color: color),
        prefixText: prefixText,
        labelStyle: TextStyle(color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // 🆕 callbacks
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      validator: (value) {
        final text = value?.trim() ?? "";

        // 📞 Phone validation
        if (label.contains("Phone")) {
          if (text.isEmpty) return "Phone number is required";
          if (text.length != 10) return "Phone number must be 10 digits";
        }

        // 📧 Email validation
        if (label.contains("Email") && text.isNotEmpty) {
          final emailRegex = RegExp(
            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
          );
          if (!emailRegex.hasMatch(text)) {
            return "Enter a valid email address";
          }
        }

        // 🔐 Password validation
        if (label.contains("Password")) {
          if (text.length < 6) {
            return "Password must be at least 6 characters";
          }
        }

        return null;
      },
    );
  }

  // ----------------------------------------------------------------
  // DROPDOWN WIDGET
  // ----------------------------------------------------------------
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required Color color,
    required List<String> items,
    required void Function(String?) onChanged,
    required String? value,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        labelStyle: TextStyle(color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
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
