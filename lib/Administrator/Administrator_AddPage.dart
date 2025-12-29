import 'dart:io';

import 'package:flutter/material.dart';

import '../../../Pages/NotificationsPage.dart';
import '../../../Services/admin_service.dart';

class AdministratorAddAdmin extends StatefulWidget {
  final Map<String, dynamic> hospitalData;
  final VoidCallback? onHospitalUpdated;

  const AdministratorAddAdmin({
    super.key,
    required this.hospitalData,
    this.onHospitalUpdated,
  });

  @override
  State<AdministratorAddAdmin> createState() => _AdministratorAddAdminState();
}

class _AdministratorAddAdminState extends State<AdministratorAddAdmin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedGender;
  File? _profileImage;

  bool _isLoading = false;

  final List<String> genders = ["Male", "Female", "Other"];

  bool get isFormValid {
    return nameController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty &&
        //Controller.text.trim().isNotEmpty &&
        selectedGender != null;
  }

  @override
  void initState() {
    super.initState();

    nameController.addListener(() => setState(() {}));
    phoneController.addListener(() => setState(() {}));
    emailController.addListener(() => setState(() {}));
    addressController.addListener(() => setState(() {}));

    designationController.addListener(() => setState(() {}));
    userIdController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameController.dispose();

    userIdController.dispose();

    designationController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  // Future<void> _pickImage() async {
  //   final picker = ImagePicker();
  //   final picked = await picker.pickImage(source: ImageSource.gallery);
  //   if (picked != null) {
  //     setState(() => _profileImage = File(picked.path));
  //   }
  // }

  // ---------------------------------------------------------------
  // SAVE USER
  // ---------------------------------------------------------------

  void _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final hospitalId = await widget.hospitalData['id'];

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
        "user_Id": userIdController.text.trim(),
        "name": nameController.text.trim(),
        'password': passwordController.text.trim(),

        "hospital_Id": hospitalId,
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
        widget.onHospitalUpdated?.call();

        _formKey.currentState!.reset();
        setState(() {
          selectedGender = null;
          _profileImage = null;
        });

        if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFBF955E);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,

          padding: const EdgeInsets.symmetric(horizontal: 12),

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

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  NumericInputBox(
                    controller: userIdController,
                    label: "User ID",
                    icon: Icons.perm_identity,
                    color: gold,
                  ),
                  const SizedBox(height: 12),

                  NumericInputBox(
                    controller: nameController,
                    label: "Full Name *",
                    icon: Icons.person_outline,
                    color: gold,
                  ),

                  const SizedBox(height: 12),

                  NumericInputBox(
                    controller: passwordController,
                    label: "Password *",
                    icon: Icons.lock_outline,
                    isPassword: true, // <--- ENABLE PASSWORD MODE
                    color: gold,
                  ),

                  const SizedBox(height: 12),

                  NumericDropdown(
                    label: "Gender *",
                    icon: Icons.wc,
                    value: selectedGender,
                    color: gold,
                    items: genders,
                    validator: (v) => v == null ? "Please select gender" : null,
                    onChanged: (v) => setState(() => selectedGender = v),
                  ),
                  const SizedBox(height: 12),
                  NumericInputBox(
                    controller: phoneController,
                    label: "Phone *",
                    icon: Icons.phone,

                    keyboardType: TextInputType.phone,
                    color: gold,
                  ),
                  const SizedBox(height: 12),

                  NumericInputBox(
                    controller: designationController,
                    label: "Designation",
                    icon: Icons.work_outline,
                    color: gold,
                  ),

                  const SizedBox(height: 12),

                  NumericInputBox(
                    controller: emailController,
                    label: "Email",

                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    color: gold,
                  ),

                  const SizedBox(height: 12),

                  NumericInputBox(
                    controller: addressController,
                    label: "Address",

                    icon: Icons.home_outlined,
                    maxLines: 2,
                    color: gold,
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: (!_isLoading && isFormValid) ? _saveUser : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (!_isLoading && isFormValid)
                          ? gold
                          : Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}

class NumericInputBox extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final TextInputType keyboardType;
  final int maxLines;
  final String? prefixText;
  final bool isPassword;

  const NumericInputBox({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.prefixText,
    this.isPassword = false,
  });

  @override
  State<NumericInputBox> createState() => _NumericInputBoxState();
}

class _NumericInputBoxState extends State<NumericInputBox> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white,
              blurRadius: 6,
              offset: Offset(-3, -3),
            ),
          ],
        ),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          obscureText: widget.isPassword ? _obscureText : false,
          decoration: InputDecoration(
            hintText: widget.label,
            prefixIcon: Icon(widget.icon, color: widget.color),
            prefixText: widget.prefixText,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: widget.color,
                    ),
                    onPressed: () {
                      setState(() => _obscureText = !_obscureText);
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 20,
            ),
          ),
          validator: (val) {
            if (widget.label.contains("*") &&
                (val == null || val.trim().isEmpty)) {
              return "Required field";
            }
            return null;
          },
        ),
      ),
    );
  }
}

class NumericDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> items;
  final String? value;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;

  const NumericDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, color: color),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
      // =======
      //
      //   // ----------------------------------------------------------------
      //   // TEXT FIELD WIDGET
      //   // ----------------------------------------------------------------
      //   Widget _buildTextField({
      //     required TextEditingController controller,
      //     required String label,
      //     required IconData icon,
      //     required Color color,
      //     TextInputType keyboardType = TextInputType.text,
      //     int maxLines = 1,
      //     String? prefixText,
      //   }) {
      //     return TextFormField(
      //       controller: controller,
      //       maxLines: maxLines,
      //       keyboardType: keyboardType,
      //       decoration: InputDecoration(
      //         labelText: label,
      //         prefixIcon: Icon(icon, color: color),
      //         prefixText: prefixText,
      //         labelStyle: TextStyle(color: color),
      //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      //         focusedBorder: OutlineInputBorder(
      //           borderSide: BorderSide(color: color, width: 2),
      //           borderRadius: BorderRadius.circular(12),
      //         ),
      //       ),
      //       validator: (val) {
      //         if (label.contains("*") && (val == null || val.trim().isEmpty)) {
      //           return "Required field";
      //         }
      //         return null;
      //       },
      //     );
      //   }
      //
      //   // ----------------------------------------------------------------
      //   // DROPDOWN WIDGET
      //   // ----------------------------------------------------------------
      //   Widget _buildDropdown({
      //     required String label,
      //     required IconData icon,
      //     required Color color,
      //     required List<String> items,
      //     required void Function(String?) onChanged,
      //     required String? value,
      //     String? Function(String?)? validator,
      //   }) {
      //     return DropdownButtonFormField<String>(
      //       value: value,
      //       decoration: InputDecoration(
      //         labelText: label,
      //         prefixIcon: Icon(icon, color: color),
      //         labelStyle: TextStyle(color: color),
      //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      //         focusedBorder: OutlineInputBorder(
      //           borderSide: BorderSide(color: color, width: 2),
      //           borderRadius: BorderRadius.circular(14),
      //         ),
      //       ),
      //       items: items
      //           .map((item) => DropdownMenuItem(value: item, child: Text(item)))
      //           .toList(),
      //       onChanged: onChanged,
      //       validator: validator,
      // >>>>>>> 3f063fbf1fae91f45feca0bca76a410ab6083f20
    );
  }
}
