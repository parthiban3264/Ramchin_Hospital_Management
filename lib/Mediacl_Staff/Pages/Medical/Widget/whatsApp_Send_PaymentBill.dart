import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

/// 🔹 Hospital Storage
class HospitalStorage {
  static Future<Map<String, String?>> getHospitalData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getString('hospitalId'),
      'name': prefs.getString('hospitalName'),
      'place': prefs.getString('hospitalPlace'),
      'photo': prefs.getString('hospitalPhoto'),
    };
  }
}

/// 🔹 WhatsApp Bill Sender (REG + TEST)
/// temperature: temperature,
//                 bloodPressure: bloodPressure,
//                 sugar: sugar,
//                 height: height,
//                 weight: weight,
//                 BMI: BMI,
//                 PK: PK,
//                 SpO2: SpO2,
class WhatsAppSendPaymentBill {
  /// ================= REGISTRATION BILL =================
  static Future<void> sendRegistrationBill({
    required String phoneNumber,
    required String patientName,
    required String patientId,
    required String tokenNo,
    required String age,
    // required String temperature,
    required String bloodPressure,
    required String sugar,
    required String height,
    required String weight,
    required String BMI,
    required String PK,
    required String SpO2,
    required String address,
    required num registrationFee,
    required num consultationFee,
    required num emergencyFee,
    required num sugarTestFee,
  }) async {
    /// ---------- VALIDATION ----------
    bool isValid(String? value) {
      return value != null &&
          value.trim().isNotEmpty &&
          value.trim().toLowerCase() != 'null' &&
          value.trim() != '0' &&
          value.trim() != 'N/A' &&
          value.trim() != '-' &&
          value.trim() != '_' &&
          value.trim() != '-mg/dL';
    }

    /// ---------- FETCH HOSPITAL DATA ----------
    final hospital = await HospitalStorage.getHospitalData();
    final date = DateFormat('dd-MM-yyyy').format(DateTime.now());

    /// ---------- VITALS ----------
    final List<String> vitalsLines = [];

    if (isValid(sugar)) {
      vitalsLines.add("Sugar            : $sugar mg/dL");
    }
    // if (isValid(temperature)) {
    //   vitalsLines.add("Temperature      : $temperature °F");
    // }
    if (isValid(bloodPressure)) {
      vitalsLines.add("Blood Pressure   : $bloodPressure");
    }
    if (isValid(height)) {
      vitalsLines.add("Height           : $height cm");
    }
    if (isValid(weight)) {
      vitalsLines.add("Weight           : $weight kg");
    }
    if (isValid(BMI)) {
      vitalsLines.add("BMI              : $BMI");
    }
    if (isValid(PK)) {
      vitalsLines.add("PR               : $PK bpm");
    }
    if (isValid(SpO2)) {
      vitalsLines.add("SpO2             : $SpO2 %");
    }

    final String vitalsSection = vitalsLines.isNotEmpty
        ? '''
━━━━━━━━━━━━━━━━━━━
🩺 *VITALS*
━━━━━━━━━━━━━━━━━━━
${vitalsLines.join('\n')}
'''
        : '';

    /// ---------- FEES ----------
    final List<String> feeLines = [];

    if (registrationFee > 0) {
      feeLines.add("• Registration Fee     : ₹$registrationFee");
    }
    if (consultationFee > 0) {
      feeLines.add("• Consultation Fee    : ₹$consultationFee");
    }
    if (emergencyFee > 0) {
      feeLines.add("• Emergency Fee       : ₹$emergencyFee");
    }
    if (sugarTestFee > 0) {
      feeLines.add("• Sugar Test Fee      : ₹$sugarTestFee");
    }

    final total =
        registrationFee + consultationFee + emergencyFee + sugarTestFee;

    /// ---------- BILL TEXT ----------
    final billText =
        '''
🧾 *INVOICE / HOSPITAL BILL*

🏥 *${hospital['name'] ?? 'Hospital'}*
📍 ${hospital['place'] ?? '-'}

📅 *Date:* $date
🎟️ *Token No:* $tokenNo

$vitalsSection
━━━━━━━━━━━━━━━━━━━
👤 *PATIENT DETAILS*
━━━━━━━━━━━━━━━━━━━
Name    : $patientName
PID     : $patientId
Age     : $age
Address : $address

━━━━━━━━━━━━━━━━━━━
💳 *CHARGE DETAILS*
━━━━━━━━━━━━━━━━━━━
${feeLines.isNotEmpty ? feeLines.join('\n') : '• No charges'}

━━━━━━━━━━━━━━━━━━━
💰 *TOTAL AMOUNT* : ₹ $total
━━━━━━━━━━━━━━━━━━━

✅ *PAYMENT STATUS:* PAID

🙏 Thank you for visiting
${hospital['name'] ?? 'Hospital'}
''';

    /// ---------- SEND TO WHATSAPP ----------
    await _sendToWhatsApp(phoneNumber, billText);
  }

  /// ================= ADVANCED BILL =================
  static Future<void> sendAdvanceBill({
    required String phoneNumber,
    required String patientName,
    required String patientId,
    required String tokenNo,
    required String age,
    required String address,
    required String advancedFee,
  }) async {
    /// ---------- FETCH HOSPITAL DATA ----------
    final hospital = await HospitalStorage.getHospitalData();
    final date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final hasAdvance = advancedFee.isNotEmpty && advancedFee != '0';

    /// ---------- BILL TEXT ----------
    final billText =
        '''
🧾 *INVOICE / HOSPITAL BILL*

🏥 *${hospital['name'] ?? 'Hospital'}*
📍 ${hospital['place'] ?? '-'}

📅 *Date:* $date
🎟️ *Token No:* $tokenNo

━━━━━━━━━━━━━━━━━━━
👤 *PATIENT DETAILS*
━━━━━━━━━━━━━━━━━━━
Name    : $patientName
PID     : $patientId
Age     : $age
Address : $address

━━━━━━━━━━━━━━━━━━━━
💳 *PAYMENT DETAILS*
━━━━━━━━━━━━━━━━━━━━
${hasAdvance ? '• Advance Fee : ₹ $advancedFee' : '• No charges'}

━━━━━━━━━━━━━━━━━━━
💰 *TOTAL AMOUNT* : ₹ $advancedFee
━━━━━━━━━━━━━━━━━━━

✅ *PAYMENT STATUS:* PAID

🙏 Thank you for visiting
${hospital['name'] ?? 'Hospital'}
''';

    /// ---------- SEND TO WHATSAPP ----------
    await _sendToWhatsApp(phoneNumber, billText);
  }

  static Future<void> sendDischargeBill({
    required final Map<String, dynamic> fee,
    required String phoneNumber,
    required String patientName,
    required String patientId,
    required String tokenNo,
    required String age,
    required String address,
    required String advancedFee,
  }) async {
    /// ---------- FETCH HOSPITAL DATA ----------
    final hospital = await HospitalStorage.getHospitalData();
    final date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final hasAdvance = advancedFee.isNotEmpty && advancedFee != '0';
    final admitId = fee['Admission']['id'].toString();
    final bedNo = fee['Admission']['bed']['bedNo'].toString();
    final wardName =
        '${fee['Admission']['bed']['ward']['name']} - '
        '${fee['Admission']['bed']['ward']['type']}';
    final wardNo = fee['Admission']['bed']['ward']['id'].toString();
    final admitDate = fee['Admission']['admitTime'].toString().split('T').first;
    final dischargeDate = fee['Admission']['dischargeTime']
        .toString()
        .split('T')
        .first;

    /// ---------- BILL TEXT ----------
    final billText =
        '''
🧾 *INVOICE / HOSPITAL BILL*

🏥 *${hospital['name'] ?? 'Hospital'}*
📍 ${hospital['place'] ?? '-'}

📅 *Date:* $date
🎟️ *Token No:* $tokenNo

━━━━━━━━━━━━━━━━━━━
👤 *PATIENT DETAILS*
━━━━━━━━━━━━━━━━━━━
Name    : $patientName
PID     : $patientId
Age     : $age
Address : $address

━━━━━━━━━━━━━━━━━━━
👤 *ADMISSION DETAILS*
━━━━━━━━━━━━━━━━━━━
Admit ID  : $admitId
Ward Name : $wardName
Ward No   : $wardNo
Bed No    : $bedNo
Admit Date : $admitDate
Discharge Date : $dischargeDate

━━━━━━━━━━━━━━━━━━━━
💳 *PAYMENT DETAILS*
━━━━━━━━━━━━━━━━━━━━
${hasAdvance ? '• Advance Fee : ₹ $advancedFee' : '• No charges'}

━━━━━━━━━━━━━━━━━━━
💰 *TOTAL AMOUNT* : ₹ $advancedFee
━━━━━━━━━━━━━━━━━━━

✅ *PAYMENT STATUS:* PAID

🙏 Thank you for visiting
${hospital['name'] ?? 'Hospital'}
''';

    /// ---------- SEND TO WHATSAPP ----------
    await _sendToWhatsApp(phoneNumber, billText);
  }

  /// ================= TESTING & SCANNING BILL =================
  static Future<void> sendTestingBill({
    required String phoneNumber,
    required String patientName,
    required String tokenNo,
    required Map<String, dynamic> fee,
    required String patientId,
    required String age,
    required String address,
    required List<Map<String, dynamic>> tests,
  }) async {
    final consultation = fee['Consultation'] ?? {};
    final hospital = await HospitalStorage.getHospitalData();
    final date = DateFormat('dd-MM-yyyy').format(DateTime.now());

    final bool isTestOnly = consultation['isTestOnly'] ?? false;
    final String referredDoctorName =
        consultation['referredByDoctorName']?.toString() ?? '-';

    final List<String> testLines = [];
    num total = 0;

    for (final t in tests) {
      final String title = t['title']?.toString() ?? 'Test';
      final num testAmount = t['amount'] ?? 0;
      final dynamic selectedOption = t['selectedOptionAmounts'];

      testLines.add('*$title*');

      bool hasOptions = false;

      if (selectedOption is Map) {
        selectedOption.forEach((key, value) {
          final num amt = num.tryParse(value.toString()) ?? 0;
          if (amt > 0) {
            hasOptions = true;
            total += amt;
            testLines.add('  ${key.padRight(22)} ₹$amt');
          }
        });
      } else if (selectedOption is List) {
        for (final o in selectedOption) {
          if (o is Map) {
            final String name = o['name']?.toString() ?? '';
            final num amt = o['amount'] ?? 0;
            if (name.isNotEmpty && amt > 0) {
              hasOptions = true;
              total += amt;
              testLines.add('  ${name.padRight(22)} ₹$amt');
            }
          }
        }
      }

      if (!hasOptions && testAmount > 0) {
        total += testAmount;
        testLines.add('  ${"Amount".padRight(22)} ₹$testAmount');
      }

      testLines.add('');
    }

    String billText =
        '''
🧾 *INVOICE / HOSPITAL BILL*

🏥 *${hospital['name'] ?? 'Hospital'}*
📍 ${hospital['place'] ?? '-'}

📅 *Date:* $date
       *TokenNO:* $tokenNo
━━━━━━━━━━━━━━━━━━━━━━
👤 *PATIENT DETAILS*
━━━━━━━━━━━━━━━━━━━━━━
Name    : $patientName
PID     : $patientId
Age     : $age
Address : $address
━━━━━━━━━━━━━━━━━━━━━━
''';

    // ✅ Show only when isTestOnly == true
    if (isTestOnly) {
      billText +=
          '''
Referred Dr : $referredDoctorName
━━━━━━━━━━━━━━━━━━━━━━
''';
    }

    billText +=
        '''
🧪 *TESTING & SCANNING*
━━━━━━━━━━━━━━━━━━━━━━
Test / Option              Amount
---------------------------------------------
${testLines.isNotEmpty ? testLines.join('\n') : 'No tests'}
---------------------------------------------

━━━━━━━━━━━━━━━━━━━━━━
💰 *TOTAL AMOUNT* : ₹ $total
━━━━━━━━━━━━━━━━━━━━━━

✅ *PAYMENT STATUS:* PAID

🙏 Thank you for visiting
${hospital['name'] ?? 'Hospital'}
''';

    await _sendToWhatsApp(phoneNumber, billText);
  }

  /// ================= Supplementary BILL =================
  static Future<void> sendSupplementaryBill({
    required String phoneNumber,
    required String patientName,
    required String tokenNo,
    required Map<String, dynamic> fee,
    required String patientId,
    required String age,
    required String address,
  }) async {
    // final consultation = fee['Consultation'] ?? {};
    final hospital = await HospitalStorage.getHospitalData();
    final date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final supplementaryFee = fee['supplementaryFee'] ?? [];

    final List<dynamic> supplementaryLines = [];
    num total = 0;

    String billText =
        '''
🧾 *INVOICE / HOSPITAL BILL*

🏥 *${hospital['name'] ?? 'Hospital'}*
📍 ${hospital['place'] ?? '-'}

📅 *Date:* $date
       *TokenNO:* $tokenNo
━━━━━━━━━━━━━━━━━━━━━━
👤 *PATIENT DETAILS*
━━━━━━━━━━━━━━━━━━━━━━
Name    : $patientName
PID     : $patientId
Age     : $age
Address : $address
━━━━━━━━━━━━━━━━━━━━━━
''';

    billText +=
        '''
🧪 *TESTING & SCANNING*
━━━━━━━━━━━━━━━━━━━━━━
Test / Option              Amount
---------------------------------------------
${supplementaryFee.isNotEmpty ? supplementaryLines.join('\n') : 'No tests'}
---------------------------------------------

━━━━━━━━━━━━━━━━━━━━━━
💰 *TOTAL AMOUNT* : ₹ $total
━━━━━━━━━━━━━━━━━━━━━━

✅ *PAYMENT STATUS:* PAID

🙏 Thank you for visiting
${hospital['name'] ?? 'Hospital'}
''';

    await _sendToWhatsApp(phoneNumber, billText);
  }

  // /// ================= COMMON =================
  // static Future<void> _sendToWhatsApp(
  //   String phoneNumber,
  //   String message,
  // ) async {
  //   final encodedText = Uri.encodeComponent(message);
  //   final whatsappUrl = "whatsapp://send?phone=$phoneNumber&text=$encodedText";
  //
  //   if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
  //     await launchUrl(Uri.parse(whatsappUrl));
  //   } else {
  //     throw Exception("WhatsApp not installed");
  //   }
  // }

  static Future<void> _sendToWhatsApp(String phone, String message) async {
    final encodedMessage = Uri.encodeComponent(message);

    final Uri url =
        // kIsWeb
        //     ? Uri.parse("https://wa.me/$phone?text=$encodedMessage")
        //     :
        Uri.parse("whatsapp://send?phone=$phone&text=$encodedMessage");

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
