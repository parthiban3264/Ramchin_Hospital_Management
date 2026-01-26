import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class HospitalService {
  Future<String> getHospitalId() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  Future<String> getPatientId() async {
    final prefs = await SharedPreferences.getInstance();

    final hospitalId = prefs.getString('userId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('userId ID not found in storage');
    }
    return hospitalId;
  }

  // Future<Map<String, dynamic>> createHospital(Map<String, dynamic> data) async {
  //   final url = Uri.parse("$baseUrl/hospitals/create");
  //
  //   final res = await http.post(
  //     url,
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode(data),
  //   );
  //
  //   // decode JSON response
  //   final decoded = jsonDecode(res.body) as Map<String, dynamic>;
  //   return decoded;
  // }
  Future<Map<String, dynamic>> getHospitalById(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/hospitals/getById/$id'));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data;
      } else {
        return {
          "status": "failed",
          "error": "Server returned ${res.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "failed", "error": e.toString()};
    }
  }

  Future<Map<String, dynamic>> createHospital({
    required String hospitalId,
    required String name,
    required String address,
    required String phone,
    required String mail,
    required XFile file,
  }) async {
    var url = Uri.parse("$baseUrl/hospitals/create");

    var request = http.MultipartRequest("POST", url);

    request.fields['hospitalId'] = hospitalId;
    request.fields['name'] = name;
    request.fields['address'] = address;
    request.fields['HospitalStatus'] = "ACTIVE";
    request.fields['phone'] = phone;
    request.fields['mail'] = mail;

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    return {
      "status": response.statusCode == 201 ? "success" : "error",
      "body": responseBody,
    };
  }

  Future<List<dynamic>> getAllHospitals() async {
    final url = Uri.parse("$baseUrl/hospitals/all");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      // Return only the list inside "data"
      return body["data"] ?? [];
    }

    return [];
  }

  Future<Map<String, dynamic>?> getHospital() async {
    final hospitalId = await getHospitalId();
    final url = Uri.parse("$baseUrl/hospitals/getById/$hospitalId");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      // body["data"] is a single object
      return body["data"];
    }

    return null;
  }

  // @Get("getById/:id")
  // findOne(@Param("id") id: string) {
  // return this.hospitalService.findOne(+id);
  // }
  // ---------------------------
  // GetOne /getById/:id
  // ---------------------------
  Future<Map<String, dynamic>> getOneHospitals() async {
    final hospitalId = await getHospitalId();
    final patientId = await getPatientId();
    final url = Uri.parse("$baseUrl/hospitals/getById/$hospitalId/$patientId");
    final res = await http.get(url);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body);

      // Ensure we always return a Map
      if (body["data"] is Map<String, dynamic>) {
        return body["data"];
      }
    }

    // If error → return empty Map instead of List
    return {};
  }

  // ---------------------------
  // PATCH /updateById/:id
  //---------------------------
  Future<bool> updateHospitals(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/hospitals/updateByIdStatus/$id');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<bool> updateHospital(int id, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/hospitals/updateById/$id");

    var request = http.MultipartRequest("PATCH", url);

    // TEXT FIELDS
    request.fields["name"] = data["name"];
    request.fields["address"] = data["address"];
    request.fields["phone"] = data["phone"];
    request.fields["mail"] = data["mail"];
    request.fields["oldImage"] = data["oldImage"] ?? "";

    // NEW IMAGE (optional)
    if (data["file"] != null) {
      request.files.add(
        await http.MultipartFile.fromPath("file", data["file"].path),
      );
    }

    var response = await request.send();

    return response.statusCode == 200;
  }

  // ---------------------------
  // DELETE /deleteById/:id
  // ---------------------------
  Future<bool> deleteHospital(int id) async {
    final url = Uri.parse('$baseUrl/hospitals/deleteById/$id');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }
}
