import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Pages/NotificationsPage.dart';
import '../../Services/admin_service.dart';
import 'globals.dart';

const Color primaryColor = Color(0xFFBF955E);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _specialistController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _photoController;

  bool _isLoading = false;
  bool _isSaving = false;
  File? _selectedImage;
  bool _hasChanges = false;
  bool _isFormValid = true;

  Map<String, String> _initialData = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchAdminData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _specialistController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _photoController = TextEditingController();

    // 🔹 Add listeners
    _nameController.addListener(_checkForChanges);
    _specialistController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);
    _photoController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasChanges =
        _nameController.text != _initialData["name"] ||
        _specialistController.text != _initialData["specialist"] ||
        _emailController.text != _initialData["email"] ||
        _phoneController.text != _initialData["phone"] ||
        _addressController.text != _initialData["address"] ||
        _photoController.text != _initialData["photo"];

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Future<void> _fetchAdminData() async {
    try {
      final response = await _adminService.getProfile();

      if (response != null) {
        final data = response['data'] ?? response;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _specialistController.text = data['specialist'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _photoController.text =
              data['photo'] ??
              "https://cdn-icons-png.flaticon.com/512/387/387561.png";

          // 🔹 Store initial values
          _initialData = {
            "name": _nameController.text,
            "specialist": _specialistController.text,
            "email": _emailController.text,
            "phone": _phoneController.text,
            "address": _addressController.text,
            "photo": _photoController.text,
          };

          _hasChanges = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Failed to fetch admin profile")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching data: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        // _photoController.text = pickedFile.path; // store local path
        //_selectedImage = File(pickedFile.path);
        _hasChanges = true;
      });
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return "Phone number must be 10 digits";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value)) {
      return "Enter a valid email address";
    }
    return null;
  }

  Future<void> _showImagePickerDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryColor),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryColor),
              title: const Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String photoUrl = _photoController.text;
      //if user selected a new image → upload first
      // if (_selectedImage != null) {
      //   photoUrl = await _adminService.uploadProfileImage(_selectedImage!);
      // }
      if (_selectedImage != null) {
        photoUrl = await _adminService.uploadProfileImage(_selectedImage!);
        // 🔹 Add cache-busting timestamp
        photoUrl = '$photoUrl?ts=${DateTime.now().millisecondsSinceEpoch}';
      }

      final response = await _adminService.updateAdminProfile({
        "name": _nameController.text,
        "specialist": _specialistController.text,
        "email": _emailController.text,
        "phone": _phoneController.text,
        "address": _addressController.text,
        "photo": photoUrl, // ✅ IMPORTANT
        // send photo URL or local path
      });

      if (response['status'] == 'success') {
        setState(() {
          _initialData = {
            "name": _nameController.text,
            "specialist": _specialistController.text,
            "email": _emailController.text,
            "phone": _phoneController.text,
            "address": _addressController.text,
            "photo": _photoController.text,
          };
          _photoController.text = photoUrl; // 🔹 new URL with timestamp
          _initialData['photo'] = photoUrl;
          _hasChanges = false;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("staffPhoto", photoUrl);
        staffPhotoNotifier.value = photoUrl;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text(" Profile updated !")));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("⚠️ ${response['message'] ?? 'Update failed'}"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator, // 🔹 add this
    List<TextInputFormatter>? inputFormatters, // 🔹 ADD
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        validator:
            validator ??
            (val) =>
                val == null || val.trim().isEmpty ? "Required field" : null,
        inputFormatters: inputFormatters,
        onChanged: (_) {
          final isValid = _formKey.currentState?.validate() ?? false;
          if (isValid != _isFormValid) {
            setState(() => _isFormValid = isValid);
          }
        },

        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _selectedImage != null
        ? null
        : (_photoController.text.isNotEmpty
              ? _photoController.text
              : "https://cdn-icons-png.flaticon.com/512/387/387561.png");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Edit Profile",
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _isSaving
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,

                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : NetworkImage(photoUrl!) as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 4,
                              child: InkWell(
                                onTap: _showImagePickerDialog,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: primaryColor,
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        _buildTextField(
                          label: "Full Name",
                          controller: _nameController,
                          icon: Icons.person,
                        ),
                        _buildTextField(
                          label: "Specialist",
                          controller: _specialistController,
                          icon: Icons.medical_services_outlined,
                        ),
                        _buildTextField(
                          label: "Email",
                          controller: _emailController,
                          icon: Icons.email,
                          inputType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),

                        _buildTextField(
                          label: "Phone",
                          controller: _phoneController,
                          icon: Icons.phone,
                          inputType: TextInputType.phone,
                          validator: _validatePhone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),

                        _buildTextField(
                          label: "Address",
                          controller: _addressController,
                          icon: Icons.home,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save, color: Colors.white),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                (!_hasChanges || !_isFormValid || _isSaving)
                                ? null
                                : _saveProfile,

                            label: const Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
