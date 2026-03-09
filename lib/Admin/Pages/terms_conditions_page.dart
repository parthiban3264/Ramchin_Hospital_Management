import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Pages/NotificationsPage.dart';

const primaryColor = Color(0xFFBF955E);

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  Widget section({
    required int number,
    required String title,
    required String content,
    String? phoneNo,
    String? email,
    String? link,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withOpacity(.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

          const SizedBox(width: 14),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  height: 2,
                  width: 40,
                  color: primaryColor.withOpacity(.4),
                ),

                const SizedBox(height: 10),

                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
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
        ],
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
                  color: color.withOpacity(0.15),
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

  Widget termsIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ICON
          // Container(
          //   padding: const EdgeInsets.all(8),
          //   decoration: BoxDecoration(
          //     color: primaryColor,
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: const Icon(
          //     Icons.description_outlined,
          //     color: Colors.white,
          //     size: 20,
          //   ),
          // ),
          const SizedBox(width: 12),

          /// TEXT
          const Expanded(
            child: Text(
              "These Terms and Conditions govern the use of the Ramchin Hospital Management App. "
              "By accessing or using this application, you agree to comply with these terms.",
              style: TextStyle(
                fontSize: 14.8,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

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
                    "Terms & Conditions",
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
                colors: [primaryColor, primaryColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.25),
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

          termsIntro(),

          const SizedBox(height: 24),

          /// SECTIONS
          section(
            number: 1,
            title: "Purpose of the Application",
            content:
                "The RAMCHIN Hospital Management App helps hospitals manage patient records, OP/IP consultations, pharmacy, laboratory reports, billing, and staff operations.",
          ),

          section(
            number: 2,
            title: "User Roles and Access",
            content:
                "Access to the system is restricted to authorized hospital staff such as Administrators, Doctors, Nurses, Cashiers, Laboratory Technicians, and Pharmacy staff.",
          ),

          section(
            number: 3,
            title: "Doctor Responsibilities",
            content:
                "Doctors may manage OP consultations, IP records, prescriptions, test orders, review reports, and monitor patient treatment progress.",
          ),

          section(
            number: 4,
            title: "Doctor Promotion",
            content:
                "Doctors may receive administrative privileges when granted by hospital administrators for managing hospital operations.",
          ),

          section(
            number: 5,
            title: "Patient Management",
            content:
                "Authorized staff can manage patient registration, consultations, treatment documentation, medical history, and admission/discharge records.",
          ),

          section(
            number: 6,
            title: "Ward and Bed Management",
            content:
                "The system allows assigning beds, tracking ward location, managing transfers, and monitoring in-patient treatment progress.",
          ),

          section(
            number: 7,
            title: "Billing and Payments",
            content:
                "The application supports hospital billing including consultation fees, pharmacy purchases, laboratory tests, and room charges.",
          ),

          section(
            number: 8,
            title: "User Responsibilities",
            content:
                "Users must protect login credentials, enter accurate data, maintain patient privacy, and follow healthcare regulations.",
          ),

          section(
            number: 9,
            title: "Prohibited Activities",
            content:
                "Users must not hack the system, access unauthorized data, distribute confidential information, or misuse the application.",
          ),

          section(
            number: 10,
            title: "System Availability",
            content:
                "Service interruptions may occur due to maintenance, updates, technical issues, or network problems.",
          ),

          section(
            number: 11,
            title: "Support",
            content:
                "Users may submit support tickets for login issues, system errors, feature requests, or technical assistance.",
          ),

          section(
            number: 12,
            title: "Data Security",
            content:
                "Security measures include authentication, role-based access, restricted patient data access, and secure data storage.",
          ),

          section(
            number: 13,
            title: "Limitation of Liability",
            content:
                "The developers are not responsible for medical decisions, incorrect user data, financial input errors, or service interruptions.",
          ),

          section(
            number: 14,
            title: "System Modifications",
            content:
                "We may update or modify the application and these Terms to improve functionality, security, or compliance.",
          ),

          section(
            number: 15,
            title: "Termination of Access",
            content:
                "Administrators may suspend or terminate accounts if users violate these Terms or pose security risks.",
          ),

          section(
            number: 16,
            title: "Governing Law",
            content:
                "These Terms are governed by the applicable laws of the jurisdiction where the hospital operates.",
          ),

          section(
            number: 17,
            title: "Contact Information",
            content:
                "For questions regarding these Terms, please contact the hospital administration or system administrator.",
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
