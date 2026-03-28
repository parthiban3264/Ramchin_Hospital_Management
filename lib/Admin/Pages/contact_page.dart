import 'package:flutter/material.dart';

import 'AddingPage/submit_tickets.dart';

const Color primaryColor = Color(0xFFBF955E);

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  int step = 0;

  /// CONTROLLERS
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final hospitalNameController = TextEditingController();
  final hospitalPhoneController = TextEditingController();
  final hospitalEmailController = TextEditingController();
  final addressController = TextEditingController();

  bool acceptedTerms = false;
  bool interested = false;

  final phoneRegex = RegExp(r'^[6-9]\d{9}$');
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');

  void next() {
    if (step == 0 && !acceptedTerms) {
      showMsg("Accept Terms first");
      return;
    }

    if (step == 1) {
      if (nameController.text.isEmpty) return showMsg("Enter name");
      if (!phoneRegex.hasMatch(phoneController.text)) {
        return showMsg("Invalid phone");
      }
      if (!emailRegex.hasMatch(emailController.text)) {
        return showMsg("Invalid email");
      }
    }

    if (step == 2) {
      if (hospitalNameController.text.isEmpty) {
        return showMsg("Enter hospital name");
      }
      if (!phoneRegex.hasMatch(hospitalPhoneController.text)) {
        return showMsg("Invalid hospital number");
      }
      if (!emailRegex.hasMatch(hospitalEmailController.text)) {
        return showMsg("Invalid email");
      }
      if (addressController.text.isEmpty) {
        return showMsg("Enter address");
      }

      submit();
      return;
    }

    setState(() => step++);
  }

  bool canProceed() {
    if (step == 0) {
      return acceptedTerms && interested;
    }

    if (step == 1) {
      return nameController.text.isNotEmpty &&
          phoneRegex.hasMatch(phoneController.text) &&
          emailRegex.hasMatch(emailController.text);
    }

    if (step == 2) {
      return hospitalNameController.text.isNotEmpty &&
          phoneRegex.hasMatch(hospitalPhoneController.text) &&
          addressController.text.isNotEmpty;
    }

    return false;
  }

  void back() {
    if (step > 0) setState(() => step--);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void submit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ✅ SUCCESS ICON WITH CIRCLE
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),

              const SizedBox(height: 16),

              /// 🎉 TITLE
              const Text(
                "Success!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              /// 📄 MESSAGE
              const Text(
                "Your details have been submitted successfully.\nWe will contact you shortly.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, color: Colors.black87),
              ),

              const SizedBox(height: 20),

              /// 🔘 BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    // Navigator.pop(context); // go back page (optional)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 100,
          decoration: const BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Contact Us",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.support_agent_sharp,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SubmitTicketPage()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {},
                ),
                // IconButton(
                //   icon: const Icon(Icons.home, color: Colors.white),
                //   onPressed: () {
                //     int count = 0;
                //     Navigator.popUntil(context, (route) => count++ >= 2);
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          /// 🔥 CUSTOM STEP INDICATOR
          _buildStepIndicator(),

          /// 📄 CONTENT
          // Expanded(
          //   child: AnimatedSwitcher(
          //     duration: const Duration(milliseconds: 300),
          //     child: _buildStepContent(),
          //   ),
          // ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildStepContent(),
              ),
            ),
          ),

          /// 🔘 BUTTONS
          _buildButtons(),
        ],
      ),
    );
  }

  /// ================= STEP INDICATOR =================
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (index) {
          bool active = index <= step;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 6,
              decoration: BoxDecoration(
                color: active ? primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// ================= STEP CONTENT =================
  Widget _buildStepContent() {
    switch (step) {
      case 0:
        return _termsUI();
      case 1:
        return _personalUI();
      case 2:
        return _hospitalUI();
      default:
        return Container();
    }
  }

  /// ================= TERMS =================
  Widget _termsUI() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 TITLE
            _title("Terms & Benefits"),

            const SizedBox(height: 14),

            /// 💎 HIGHLIGHT CARDS (TOP)
            Row(
              children: [
                _highlightBox("1 Month FREE", Icons.card_giftcard),
                const SizedBox(width: 8),
                _highlightBox("₹2500 / Doctor", Icons.currency_rupee),
              ],
            ),

            const SizedBox(height: 12),

            /// 📜 TERMS BOX
            Container(
              height: 260,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔐 SECURITY
                    _termItem(
                      Icons.lock,
                      "Your data is 100% secure & encrypted",
                    ),

                    /// 📞 CONTACT
                    _termItem(
                      Icons.support_agent,
                      "We may contact you for onboarding & support",
                    ),

                    /// 🚫 RULES
                    _termItem(
                      Icons.block,
                      "Strictly no misuse of hospital or patient data",
                    ),

                    /// 🎁 FREE
                    _termItem(
                      Icons.card_giftcard,
                      "1 Month FREE trial for all hospitals",
                    ),

                    /// 💰 PRICING
                    _termItem(
                      Icons.currency_rupee,
                      "₹2500 per doctor / month after trial",
                    ),

                    /// 📱 CUSTOM APP
                    _termItem(
                      Icons.phone_android,
                      "We can customize the app based on your hospital needs and workflow — No extra charges.",
                    ),

                    /// ☎️ CALL SUPPORT
                    _termItem(
                      Icons.call,
                      "Direct call support available anytime",
                    ),

                    /// 💸 NO EXTRA FEE
                    _termItem(
                      Icons.verified,
                      "No additional hidden charges or fees",
                    ),

                    /// ⏰ SUPPORT
                    _termItem(
                      Icons.access_time,
                      "24/7 customer support assistance",
                    ),

                    /// 👨‍💻 TEAM
                    _termItem(
                      Icons.groups,
                      "Dedicated & experienced developer team",
                    ),

                    /// ⚙️ FEATURES
                    _termItem(
                      Icons.settings,
                      "Regular updates with new features & improvements",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            /// ✅ ACCEPT TERMS
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: acceptedTerms
                    ? primaryColor.withOpacity(0.08)
                    : Colors.transparent,
                border: Border.all(
                  color: acceptedTerms ? primaryColor : Colors.grey.shade300,
                ),
              ),
              child: CheckboxListTile(
                value: acceptedTerms,
                activeColor: primaryColor,
                onChanged: (v) => setState(() => acceptedTerms = v!),
                title: const Text(
                  "I agree to Terms & Conditions",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// ⭐ INTERESTED
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: interested
                    ? primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: interested ? primaryColor : Colors.grey.shade300,
                ),
              ),
              child: CheckboxListTile(
                value: interested,
                activeColor: primaryColor,
                onChanged: (v) => setState(() => interested = v!),
                title: const Text(
                  "Yes, I am interested to connect with Ramchin Hospital System",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _termItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _highlightBox(String text, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: primaryColor.withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: primaryColor),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= PERSONAL =================
  Widget _personalUI() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("Personal Details"),
          const SizedBox(height: 18),

          _inputField(
            label: "Your Name",
            controller: nameController,
            icon: Icons.person,
            maxLines: 1,
          ),

          const SizedBox(height: 14),

          _inputField(
            label: "Mobile Number",
            controller: phoneController,
            icon: Icons.phone,
            isNumber: true,
            maxLines: 1,
          ),

          const SizedBox(height: 14),

          _inputField(
            label: "Email Address",
            controller: emailController,
            icon: Icons.email,
            isEmail: true,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required int maxLines,
    bool isNumber = false,
    bool isEmail = false,
  }) {
    String value = controller.text;
    String? errorText;

    /// 🔥 VALIDATION
    if (value.isNotEmpty) {
      if (isNumber && !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
        errorText = "Enter valid 10-digit number";
      }

      if (isEmail &&
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(value)) {
        errorText = "Enter valid email address";
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔥 LABEL (professional style)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          /// 🔥 INPUT FIELD
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            keyboardType: isNumber
                ? TextInputType.phone
                : TextInputType.emailAddress,
            maxLength: isNumber ? 10 : null,
            maxLines: maxLines,

            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: primaryColor),

              hintText: "Enter $label",

              filled: true,
              fillColor: Colors.white,

              counterText: "",

              /// 🔥 ERROR TEXT
              errorText: errorText,

              /// 🔥 SUCCESS ICON
              suffixIcon: value.isNotEmpty && errorText == null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,

              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 14,
              ),

              /// 🔥 BORDER STYLE
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),

              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red),
              ),

              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= HOSPITAL =================
  Widget _hospitalUI() {
    return _card(
      child: Column(
        children: [
          _title("Hospital Details"),
          const SizedBox(height: 15),

          _inputField(
            label: "Hospital Name",
            controller: hospitalNameController,
            icon: Icons.person,
            maxLines: 1,
          ),

          const SizedBox(height: 14),

          _inputField(
            label: "Hospital Mobile Number",
            controller: hospitalPhoneController,
            icon: Icons.phone,
            isNumber: true,
            maxLines: 1,
          ),

          const SizedBox(height: 14),

          _inputField(
            label: "Email Address",
            controller: hospitalEmailController,
            icon: Icons.email,
            isEmail: true,
            maxLines: 1,
          ),
          const SizedBox(height: 12),

          _inputField(
            label: "Address",
            controller: addressController,
            icon: Icons.add_location_alt,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  /// ================= COMMON UI =================
  Widget _card({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),

          /// 🔥 BORDER
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.50),
            width: 1.2,
          ),

          /// 🔥 SHADOW (more soft & professional)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 9),
            ),
          ],

          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// ================= BUTTONS =================
  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: back,
                child: const Text(
                  "Back",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),

          if (step > 0) const SizedBox(width: 10),

          Expanded(
            child: ElevatedButton(
              onPressed: canProceed() ? next : null, // 🔥 DISABLE LOGIC
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                disabledBackgroundColor: Colors.grey.shade300, // nice UI
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                step == 2 ? "Submit" : "Next",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
