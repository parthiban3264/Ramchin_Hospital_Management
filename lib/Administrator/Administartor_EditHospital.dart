import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Pages/NotificationsPage.dart';
import '../Services/hospital_Service.dart';

class AdministratorEditHospital extends StatefulWidget {
  final Map<String, dynamic> hospitalData;
  final VoidCallback? onHospitalUpdated;

  const AdministratorEditHospital({
    super.key,
    required this.hospitalData,
    this.onHospitalUpdated,
  });

  @override
  State<AdministratorEditHospital> createState() =>
      _AdministratorEditHospitalState();
}

class _AdministratorEditHospitalState extends State<AdministratorEditHospital> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _photoController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  File? _pickedImage;
  bool _isLoading = false;

  final HospitalService hospitalService = HospitalService();
  final Color primaryColor = const Color(0xFFBF955E);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hospitalData["name"]);
    _addressController = TextEditingController(
      text: widget.hospitalData["address"],
    );
    _photoController = TextEditingController(
      text: widget.hospitalData["photo"],
    );
    _phoneController = TextEditingController(
      text: widget.hospitalData["phone"],
    );
    _emailController = TextEditingController(
      text: widget.hospitalData["mail"].toString(),
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        _photoController.text = picked.path; // store local path temporarily
      });
    }
  }

  // Future<void> _saveChanges() async {
  //   if (!_formKey.currentState!.validate()) return;
  //
  //   setState(() => _isLoading = true);
  //
  //   final updatedData = {
  //     "name": _nameController.text.trim(),
  //     "address": _addressController.text.trim(),
  //     "phone": _phoneController.text.trim(),
  //     "mail": _emailController.text.trim(),
  //     "file": _pickedImage,
  //   };
  //
  //   bool success = await hospitalService.updateHospital(
  //     widget.hospitalData["id"],
  //     updatedData,
  //   );
  //
  //   setState(() => _isLoading = false);
  //
  //   if (success) {
  //     // 1️⃣ Update local hospitalData so this page rebuilds
  //     setState(() {
  //       widget.hospitalData['name'] = updatedData["name"]!;
  //       widget.hospitalData['address'] = updatedData["address"]!;
  //       widget.hospitalData['phone'] = updatedData["phone"]!;
  //       widget.hospitalData['mail'] = updatedData["mail"]!;
  //     });
  //
  //     // 2️⃣ Notify parent page / top-level dashboard
  //     widget.onHospitalUpdated?.call();
  //
  //     // 3️⃣ Show success message
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text("Hospital Updated!")));
  //
  //     // 4️⃣ Pop current page
  //     Navigator.pop(context, true);
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Failed to Update Hospital")),
  //     );
  //   }
  // }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedData = {
      "name": _nameController.text.trim(),
      "address": _addressController.text.trim(),
      "phone": _phoneController.text.trim(),
      "mail": _emailController.text.trim(),
      "file": _pickedImage, // NEW IMAGE
      "oldImage": widget.hospitalData["photo"], // OLD IMAGE URL
    };
    // print('hospi ${widget.hospitalData["id"]}');
    bool success = await hospitalService.updateHospital(
      widget.hospitalData["id"],
      updatedData,
    );

    setState(() => _isLoading = false);

    if (success) {
      widget.onHospitalUpdated?.call();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Hospital Updated!")));

      // Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to Update Hospital")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
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
                  const Spacer(),
                  const Text(
                    "Edit Hospital",
                    overflow: TextOverflow.ellipsis,
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

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // -------- TOP CIRCLE IMAGE -------- //
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF9F9382), // Gold border
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,

                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (_photoController.text.isNotEmpty &&
                                _photoController.text != "null")
                          ? NetworkImage(_photoController.text)
                          : null,

                      // IMAGE HANDLING
                      child:
                          _pickedImage == null &&
                              (_photoController.text.isEmpty ||
                                  _photoController.text == "null")
                          ? const Icon(
                              Icons.photo_camera_rounded,
                              size: 40,
                              color: Color(0xFFBF955E),
                            )
                          : null,
                    ),
                  ),

                  // CAMERA BUTTON
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFBF955E),
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
            ),

            const SizedBox(height: 15),

            // -------- FORM CARD -------- //
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _inputField("Hospital Name", _nameController),
                    _inputField("Address", _addressController),
                    // _inputField("Photo URL", _photoController),
                    _inputField("Phone", _phoneController),
                    _inputField("Email", _emailController),

                    const SizedBox(height: 6),

                    // -------- SAVE BUTTON -------- //
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "Save Changes",
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
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10, top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        cursorColor: Color(0xFFBF955E),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFBF955E),
            fontWeight: FontWeight.w700,
          ),
          labelStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),

          // Inner padding
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),

          // Focused outline
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFBF955E), width: 2),
          ),

          // Default border (hidden)
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
          ),

          // Error state
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),

          // Keep border visible when error + focused
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),

        validator: (value) => value!.isEmpty ? "$label cannot be empty" : null,
      ),
    );
  }
}
