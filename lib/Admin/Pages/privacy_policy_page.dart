import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Pages/NotificationsPage.dart';

const primaryColor = Color(0xFFBF955E);
const primaryColorShade = Color(0xFFF4D1A2);

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  /// Section Card
  Widget sectionCard({
    required int number,
    required IconData icon,
    required String title,
    required Widget child,
    String? phoneNo,
    String? email,
    String? link,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColorShade),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE ROW
            Row(
              children: [
                /// NUMBER BADGE
                Container(
                  height: 34,
                  width: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    number.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Icon(icon, color: primaryColor),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 22),

            child,

            const SizedBox(height: 10),

            Column(
              children: [
                if (phoneNo != null && phoneNo.isNotEmpty)
                  _contactTile(
                    icon: Icons.phone,
                    color: Colors.green,
                    text: phoneNo,
                    onTap: () => openWhatsApp(phoneNo),
                  ),

                if (email != null && email.isNotEmpty)
                  _contactTile(
                    icon: Icons.email,
                    color: Colors.red,
                    text: email,
                    onTap: () => openEmail(email),
                  ),

                if (link != null && link.isNotEmpty)
                  _contactTile(
                    icon: Icons.language,
                    color: Colors.blue,
                    text: link,
                    onTap: () => openWebsite(link),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile({
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              /// Icon Circle
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),

              const SizedBox(width: 12),

              /// Text
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              /// Arrow
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openWhatsApp(String phone) async {
    final Uri whatsappUri = Uri.parse("https://wa.me/$phone");

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> openWebsite(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Bullet Item
  Widget bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 7, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14.5, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget introHighlight() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColorShade),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LEFT ACCENT BAR
          Container(
            width: 4,
            height: 70,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(width: 12),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                Row(
                  children: const [
                    Icon(Icons.local_hospital, color: primaryColor, size: 25),
                    SizedBox(width: 6),
                    Text(
                      "About the Application",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// DESCRIPTION
                const Text(
                  "Ramchin Hospital Management App helps healthcare institutions manage patient records, staff operations, pharmacy services, billing, laboratory reports, and hospital administration in a secure digital environment.",
                  style: TextStyle(
                    fontSize: 14.8,
                    height: 1.6,
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

  /// Paragraph
  Widget paragraph(String text) {
    return Text(text, style: const TextStyle(fontSize: 14.5, height: 1.7));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F6F9),

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
                  const Text(
                    "Privacy Policy",
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
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// APP NAME
                Text(
                  "Ramchin Hospital\nManagement System",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                    letterSpacing: 0.4,
                  ),
                ),

                SizedBox(height: 12),

                /// DIVIDER
                SizedBox(
                  width: 60,
                  child: Divider(color: Colors.white70, thickness: 1.5),
                ),

                SizedBox(height: 12),

                /// LAST UPDATED
                Text(
                  "Last Updated • March 7, 2026",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          introHighlight(),

          const SizedBox(height: 20),

          /// SECTION 1
          sectionCard(
            number: 1,
            icon: Icons.storage,
            title: "Information We Collect",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Patient Information",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                bullet("Full name, age, gender"),
                bullet("Contact details"),
                bullet("Medical history and diagnosis"),
                bullet("Prescriptions and laboratory reports"),
                bullet("Admission and discharge records"),
                bullet("Billing and payment details"),

                const SizedBox(height: 10),

                const Text(
                  "Staff Information",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                bullet("Name and role (Doctor, Nurse, Admin, etc.)"),
                bullet("Contact details"),
                bullet("Login credentials (securely stored)"),
                bullet("Profile and department information"),

                const SizedBox(height: 10),

                const Text(
                  "System & Clinical Data",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                bullet("Treatment notes and consultation records"),
                bullet("Test results and care progress"),
                bullet("Device information and IP address"),
                bullet("Login activity and system logs"),
              ],
            ),
          ),

          /// SECTION 2
          sectionCard(
            number: 2,
            icon: Icons.analytics,
            title: "How We Use Information",
            child: Column(
              children: [
                bullet("Patient diagnosis and treatment management"),
                bullet("Maintaining electronic medical records (EMR)"),
                bullet("Appointment and consultation handling"),
                bullet("Laboratory and pharmacy operations"),
                bullet("Billing and financial processing"),
                bullet("Hospital administration and reporting"),
                bullet("System security and performance monitoring"),
              ],
            ),
          ),

          /// SECTION 3
          sectionCard(
            number: 3,
            icon: Icons.admin_panel_settings,
            title: "Role-Based Access Control",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                paragraph(
                  "Access to sensitive data is restricted based on staff roles. All access is monitored and logged to ensure security.",
                ),

                const SizedBox(height: 10),

                bullet("Doctors access medical records and prescriptions"),
                bullet("Nurses access assigned patient care data"),
                bullet("Lab staff access test requests and reports"),
                bullet("Billing staff access financial data only"),
                bullet("Administrators manage system configuration"),
              ],
            ),
          ),

          /// SECTION 4
          sectionCard(
            number: 4,
            icon: Icons.share,
            title: "Data Sharing",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                paragraph("We do not sell or misuse patient or staff data."),
                const SizedBox(height: 8),
                bullet("Shared only with authorized hospital staff"),
                bullet("Shared with patients upon proper request"),
                bullet("Shared with trusted service providers (SMS, hosting)"),
                bullet("Shared when required by law"),
              ],
            ),
          ),

          /// SECTION 5
          sectionCard(
            number: 5,
            icon: Icons.lock,
            title: "Data Security",
            child: Column(
              children: [
                bullet("Encrypted data transmission (HTTPS/TLS)"),
                bullet("Secure database storage"),
                bullet("Password encryption and authentication"),
                bullet("Role-based access restrictions"),
                bullet("Activity logging and monitoring"),
              ],
            ),
          ),

          /// SECTION 6
          sectionCard(
            number: 6,
            icon: Icons.access_time,
            title: "Data Retention",
            child: Column(
              children: [
                bullet("Maintained for patient care continuity"),
                bullet("Stored as per legal requirements"),
                bullet("Retained based on hospital policy"),
                bullet("Archived or deleted when no longer required"),
              ],
            ),
          ),

          /// SECTION 7
          sectionCard(
            number: 7,
            icon: Icons.person,
            title: "User Rights",
            child: Column(
              children: [
                bullet("Access and update profile information"),
                bullet("Request correction of inaccurate data"),
                bullet("Request data access via hospital administration"),
                bullet("Patients can obtain records through hospital"),
              ],
            ),
          ),

          /// SECTION 8
          sectionCard(
            number: 8,
            icon: Icons.child_care,
            title: "Children's Privacy",
            child: paragraph(
              "Data related to minors is handled with strict confidentiality under the supervision of authorized healthcare professionals and guardians.",
            ),
          ),

          /// SECTION 9
          sectionCard(
            number: 9,
            icon: Icons.warning,
            title: "Disclaimer",
            child: paragraph(
              "This application is a hospital management system used by healthcare professionals and does not provide direct medical advice to the public.",
            ),
          ),

          /// SECTION 10
          sectionCard(
            number: 10,
            icon: Icons.update,
            title: "Policy Updates",
            child: paragraph(
              "This Privacy Policy may be updated periodically to reflect system improvements, legal requirements, or security updates.",
            ),
          ),

          /// SECTION 11
          sectionCard(
            number: 11,
            icon: Icons.support_agent,
            title: "Contact",
            child: paragraph(
              "For questions regarding this Privacy Policy, please contact the hospital administration or the system administrator managing the Ramchin Hospital Management App.",
            ),
            phoneNo: '+91 8903972502',
            email: 'support@ramchintech.com',
            link: 'https://www.ramchintech.com/',
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
