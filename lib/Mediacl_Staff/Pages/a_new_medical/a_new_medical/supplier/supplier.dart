import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../Admin/Pages/AdminEditProfilePage.dart';
import '../../../../Appbar/MobileAppbar.dart';
import '../../../../utils/utils.dart';
import '../medicines/widget/widget.dart';

const Color aRoyalBlue = Color(0xFF854929);
const Color aRoyalLight = Color(0xFF916542);

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _addressFocus = FocusNode();

  bool _isLoading = false;
  bool _isLoadingSuppliers = true;
  bool _showForm = false;
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  List<Map<String, dynamic>> _suppliers = [];
  int? editingSupplierId;
  Map<String, String> initialSupplierValues = {};
  bool isSupplierDirty = false;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
    _loadHospitalInfo();
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: primaryColor)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryColor, width: 2),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  bool get _isDesktop {
    return MediaQuery.of(context).size.width >= 800;
  }

  Future<void> _callSupplier(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showMessage("Could not open dialer");
    }
  }

  Future<void> _fetchSuppliers() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('hospitalId');
    if (shopId == null) return;

    try {
      final url = Uri.parse("$baseUrl/suppliers/$shopId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _suppliers = List<Map<String, dynamic>>.from(
            jsonDecode(response.body),
          );
        });
      }
    } catch (e) {
      _showMessage("Error loading suppliers");
    } finally {
      setState(() => _isLoadingSuppliers = false);
    }
  }

  void _confirmDeleteSupplier({required int id, required String name}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Supplier",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: primaryColor, fontSize: 15),
            children: [
              const TextSpan(text: "Are you sure you want to delete "),
              TextSpan(
                text: name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const TextSpan(text: " ?\n\nThis action cannot be undone."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteSupplier(id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString("hospitalId");
    if (shopId == null) return;

    try {
      final url = Uri.parse("$baseUrl/suppliers/$shopId");
      final body = jsonEncode({
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "email": _emailController.text.trim(),
        "address": _addressController.text.trim(),
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showMessage("✅ Supplier created");
        _formKey.currentState!.reset();
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
        _addressController.clear();
        setState(() => _showForm = false);
        await _fetchSuppliers();
      } else {
        _showMessage(response.body);
      }
    } catch (e) {
      _showMessage("Error creating supplier");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSupplier(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString("hospitalId");
    if (shopId == null) return;

    try {
      final url = Uri.parse("$baseUrl/suppliers/$shopId/$id");
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        setState(() {
          _suppliers.removeWhere((s) => s["id"] == id);
        });
        _showMessage("Supplier deleted");
      }
    } catch (e) {
      _showMessage("Error deleting supplier");
    }
  }

  bool get _canSubmitSupplier {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    return name.isNotEmpty && (phone.isNotEmpty || email.isNotEmpty);
  }

  Widget _supplierForm() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _isDesktop ? 800 : double.infinity,
        ),
        child: Card(
          elevation: 8,
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: primaryColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  labeledTanRow(
                                    label: "NAME",
                                    controller: _nameController,
                                    focusNode: _nameFocus,
                                    nextFocusNode: _phoneFocus,
                                    hintText: "Enter Supplier Name",
                                    onChanged: (_) {
                                      _checkSupplierDirty();
                                      setState(() {});
                                    },
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? "Name is required"
                                        : null,
                                  ),
                                  labeledTanRow(
                                    label: "PHONE",
                                    controller: _phoneController,
                                    inputType: TextInputType.phone,
                                    focusNode: _phoneFocus,
                                    nextFocusNode: _emailFocus,
                                    hintText: "Enter Phone Number",
                                    maxLength: 10,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    onChanged: (_) {
                                      _checkSupplierDirty();
                                      setState(() {});
                                    },
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return "Phone number required";
                                      }
                                      if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                                        return "10 digits required";
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 50),
                            Expanded(
                              child: Column(
                                children: [
                                  labeledTanRow(
                                    label: "EMAIL",
                                    controller: _emailController,
                                    inputType: TextInputType.emailAddress,
                                    hintText: "Enter Email Address",
                                    focusNode: _emailFocus,
                                    nextFocusNode: _addressFocus,
                                    onChanged: (_) {
                                      _checkSupplierDirty();
                                      setState(() {});
                                    },
                                    validator: (v) {
                                      if (v != null &&
                                          v.isNotEmpty &&
                                          !RegExp(
                                            r'^[\w.-]+@[\w.-]+\.\w+$',
                                          ).hasMatch(v)) {
                                        return "Enter a valid email";
                                      }
                                      return null;
                                    },
                                  ),
                                  labeledTanRow(
                                    label: "ADDRESS",
                                    controller: _addressController,
                                    hintText: "Enter Supplier Address",
                                    focusNode: _addressFocus,
                                    onChanged: (_) {
                                      _checkSupplierDirty();
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            labeledTanRow(
                              label: "NAME",
                              controller: _nameController,
                              focusNode: _nameFocus,
                              nextFocusNode: _phoneFocus,
                              hintText: "Enter Supplier Name",
                              onChanged: (_) {
                                _checkSupplierDirty();
                                setState(() {});
                              },
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? "Name is required"
                                  : null,
                            ),
                            labeledTanRow(
                              label: "PHONE",
                              controller: _phoneController,
                              inputType: TextInputType.phone,
                              hintText: "Enter Phone Number",
                              focusNode: _phoneFocus,
                              nextFocusNode: _emailFocus,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              onChanged: (_) {
                                _checkSupplierDirty();
                                setState(() {});
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Phone number required";
                                }
                                if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                                  return "10 digits required";
                                }
                                return null;
                              },
                            ),
                            labeledTanRow(
                              label: "EMAIL",
                              controller: _emailController,
                              inputType: TextInputType.emailAddress,
                              hintText: "Enter Email Address",
                              focusNode: _emailFocus,
                              nextFocusNode: _addressFocus,
                              onChanged: (_) {
                                _checkSupplierDirty();
                                setState(() {});
                              },
                              validator: (v) {
                                if (v != null &&
                                    v.isNotEmpty &&
                                    !RegExp(
                                      r'^[\w.-]+@[\w.-]+\.\w+$',
                                    ).hasMatch(v)) {
                                  return "Enter a valid email";
                                }
                                return null;
                              },
                            ),
                            labeledTanRow(
                              label: "ADDRESS",
                              controller: _addressController,
                              hintText: "Enter Supplier Address",
                              focusNode: _addressFocus,
                              onChanged: (_) {
                                _checkSupplierDirty();
                                setState(() {});
                              },
                            ),
                          ],
                        ),

                  const SizedBox(height: 24),

                  /// 🔘 BUTTONS (Same UX as Admin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 48,
                        width: 180,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              _isLoading ||
                                  !_canSubmitSupplier ||
                                  (editingSupplierId != null &&
                                      !isSupplierDirty)
                              ? null
                              : editingSupplierId == null
                              ? _createSupplier
                              : _updateSupplier,

                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  editingSupplierId == null
                                      ? "Save Supplier"
                                      : "Update Supplier",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        height: 48,
                        width: 90,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _resetForm,
                          child: const Text("Close"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString("hospitalId");
    if (shopId == null || editingSupplierId == null) return;

    try {
      final url = Uri.parse("$baseUrl/suppliers/$shopId/$editingSupplierId");
      final body = jsonEncode({
        "name": _nameController.text.trim().toString(),
        "phone": _phoneController.text.trim().toString(),
        "email": _emailController.text.trim().toString(),
        "address": _addressController.text.trim().toString(),
      });

      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        _showMessage("✅ Supplier updated");
        _resetForm();
        await _fetchSuppliers();
      } else {
        _showMessage(response.body);
      }
    } catch (e) {
      _showMessage("Error updating supplier");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();

    setState(() {
      editingSupplierId = null;
      _showForm = false;
    });
  }

  void _editSupplier(Map<String, dynamic> s) {
    setState(() {
      editingSupplierId = s["id"];
      _showForm = true;

      _nameController.text = s["name"] ?? "";
      _phoneController.text = s["phone"] ?? "";
      _emailController.text = s["email"] ?? "";
      _addressController.text = s["address"] ?? "";

      // 👇 store original values
      initialSupplierValues = {
        "name": _nameController.text,
        "phone": _phoneController.text,
        "email": _emailController.text,
        "address": _addressController.text,
      };

      isSupplierDirty = false;
    });
  }

  Widget _supplierCard(Map<String, dynamic> s) {
    return Card(
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: primaryColor.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 🔹 Supplier Icon / Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: aRoyalLight.withValues(alpha: 0.15),
              child: Icon(
                Icons.local_shipping_rounded,
                color: primaryColor,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            // 🔹 Supplier Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    s["name"] ?? "-",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Phone
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: aRoyalLight),
                      const SizedBox(width: 6),
                      Text(
                        s["phone"] ?? "-",
                        style: TextStyle(color: primaryColor),
                      ),
                    ],
                  ),

                  // Optional Email
                  if (s["email"] != null && s["email"].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.email, size: 16, color: aRoyalLight),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s["email"],
                              style: TextStyle(color: primaryColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Optional Address
                  if (s["address"] != null &&
                      s["address"].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, size: 16, color: aRoyalLight),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s["address"],
                              style: TextStyle(color: primaryColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 🔹 Action Buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.blueGrey,
                  tooltip: "Edit",
                  onPressed: () => _editSupplier(s),
                ),
                // Call
                IconButton(
                  icon: const Icon(Icons.call),
                  color: Colors.green,
                  tooltip: "Call",
                  onPressed: () => _callSupplier(s["phone"]),
                ),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: "Delete",
                  onPressed: () => _confirmDeleteSupplier(
                    id: s["id"],
                    name: s["name"] ?? "this supplier",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget labeledTanRow({
    required String label,
    TextEditingController? controller,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
    bool obscureText = false,
    bool showPasswordToggle = false,
    void Function(String)? onChanged,
    List<DropdownMenuItem<String>>? dropdownItems,
    String? dropdownValue,
    void Function(String?)? onDropdownChanged,
    double labelWidthFactor = 0.3,
    int? maxLength,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: dropdownItems != null
                ? DropdownButtonFormField<String>(
                    // initialValue: dropdownValue,
                    onChanged: onDropdownChanged,
                    items: dropdownItems,
                    style: TextStyle(color: primaryColor),
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: aRoyalLight.withValues(alpha: 0.05),
                    ),
                  )
                : TextFormField(
                    controller: controller,
                    validator: validator,
                    keyboardType: inputType,
                    obscureText: obscureText,
                    onChanged: onChanged,
                    cursorColor: primaryColor,
                    style: TextStyle(color: primaryColor),
                    maxLength: maxLength,
                    focusNode: focusNode,
                    onFieldSubmitted: (_) {
                      if (nextFocusNode != null) {
                        FocusScope.of(context).requestFocus(nextFocusNode);
                      } else {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    inputFormatters: inputFormatters,
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: hintText,
                      hintStyle: TextStyle(color: aRoyalLight),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.redAccent,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: aRoyalLight.withValues(alpha: 0.05),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersResponsive(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // breakpoint (same idea as Admin)
    final isWide = screenWidth >= 700;

    // card width
    final cardWidth = isWide
        ? (screenWidth - 16 * 2 - 12) /
              2 // 2 per row
        : screenWidth;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _suppliers.map((supplier) {
        return SizedBox(
          width: isWide ? cardWidth : double.infinity,
          child: _supplierCard(supplier),
        );
      }).toList(),
    );
  }

  void _checkSupplierDirty() {
    final isDirty =
        _nameController.text.trim() != (initialSupplierValues["name"] ?? "") ||
        _phoneController.text.trim() !=
            (initialSupplierValues["phone"] ?? "") ||
        _emailController.text.trim() !=
            (initialSupplierValues["email"] ?? "") ||
        _addressController.text.trim() !=
            (initialSupplierValues["address"] ?? "");

    if (isDirty != isSupplierDirty) {
      setState(() => isSupplierDirty = isDirty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Suppliers',
        pageContext: context,
        showBackButton: true,
        showNotificationIcon: true,
      ),

      body: _isLoadingSuppliers
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildHospitalCard(
                    hospitalName: hospitalName,
                    hospitalPlace: hospitalPlace,
                    hospitalPhoto: hospitalPhoto,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          if (!_showForm)
                            SizedBox(
                              height: 48,
                              width: 200,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 3,
                                ),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Add Supplier",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showForm = true; // 👈 only open form
                                    editingSupplierId = null;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_showForm) _supplierForm(),
                  const SizedBox(height: 16),
                  _buildSuppliersResponsive(context),
                ],
              ),
            ),
    );
  }
}
