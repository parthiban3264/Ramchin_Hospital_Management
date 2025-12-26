import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalStorage {
  static final _storage = FlutterSecureStorage();

  static Future<Map<String, String?>> getHospitalData() async {
    return {
      'id': await _storage.read(key: 'hospitalId'),
      'name': await _storage.read(key: 'hospitalName'),
      'place': await _storage.read(key: 'hospitalPlace'),
      'photo': await _storage.read(key: 'hospitalPhoto'),
    };
  }
}

class WhatsAppBillService {
  static Future<void> sendBill({
    required String phoneNumber,
    required String patientName,
    required double totalAmount,
    required Map<String, dynamic> allConsultation,
    required List<dynamic> medicines,
    required List<dynamic> tonics,
    required List<dynamic> injections,
  }) async {
    final hospital = await HospitalStorage.getHospitalData();
    final patient = allConsultation['Patient'] ?? {};

    final billText = _generateBillText(
      hospitalName: hospital['name'] ?? 'Hospital',
      hospitalPlace: hospital['place'] ?? '',
      patientName: patientName,
      patientId: patient['id']?.toString() ?? '',
      doctorId: allConsultation['doctor_Id']?.toString() ?? '',
      totalAmount: totalAmount,
      medicines: medicines,
      tonics: tonics,
      injections: injections,
    );

    final encoded = Uri.encodeComponent(billText);
    final url = Uri.parse("https://wa.me/$phoneNumber?text=$encoded");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not open WhatsApp';
    }
  }

  // =========================================================

  static String _generateBillText({
    required String hospitalName,
    required String hospitalPlace,
    required String patientName,
    required String patientId,
    required String doctorId,
    required double totalAmount,
    required List medicines,
    required List tonics,
    required List injections,
  }) {
    const sep = '────────────────────────────';

    String bill =
        '''
*$hospitalName*
$hospitalPlace
$sep
Patient : $patientName
ID      : $patientId
Doctor  : $doctorId
Date    : ${DateTime.now().toString().split(' ')[0]}
$sep
*PRESCRIPTION*
Dose Format → Morning-Afternoon-Night
$sep
''';

    int index = 1;

    String dose(bool m, bool a, bool n, String qty) {
      return '${m ? qty : '0'} - ${a ? qty : '0'} - ${n ? qty : '0'}';
    }

    /// ================= MEDICINES =================
    for (var m in medicines) {
      if (m['selected'] == true && m['status'] != 'CANCELLED') {
        bill +=
            '$index. ${m['Medician']?['medicianName']}\n'
            '   Dose : ${dose(m['morning'] == true, m['afternoon'] == true, m['night'] == true, '${m['quantity']}')}\n'
            '   Days : ${m['days'] ?? '-'}\n'
            '   Cost : ₹${m['total']}\n\n';
        index++;
      }
    }

    /// ================= TONICS =================
    if (tonics.any((t) => t['selected'] == true)) {
      bill += '$sep\n*TONICS*\n$sep\n';
      for (var t in tonics) {
        if (t['selected'] == true && t['status'] != 'CANCELLED') {
          bill +=
              '$index. ${t['Tonic']?['tonicName']}\n'
              '   Dose : ${dose(t['morning'] == true, t['afternoon'] == true, t['night'] == true, '${t['Doase'].toString().split('.').first}ml')}\n'
              '   Days : ${t['days'] ?? '-'}\n'
              '   Cost : ₹${t['total']}\n\n';
          index++;
        }
      }
    }

    /// ================= INJECTIONS =================
    if (injections.any((i) => i['selected'] == true)) {
      bill += '$sep\n*INJECTIONS*\n$sep\n';
      for (var i in injections) {
        if (i['selected'] == true && i['status'] != 'CANCELLED') {
          bill +=
              '$index. ${i['Injection']?['injectionName']}\n'
              '   Dose : ${dose(i['morning'] == true, i['afternoon'] == true, i['night'] == true, '${i['Doase']}')}\n'
              '   Days : ${i['days'] ?? '-'}\n'
              '   Cost : ₹${i['total']}\n\n';
          index++;
        }
      }
    }

    bill +=
        '''
$sep
*TOTAL* : ₹${totalAmount.toStringAsFixed(2)}
STATUS  : PAID
$sep

Thank you for choosing
$hospitalName
''';

    return bill;
  }
}
