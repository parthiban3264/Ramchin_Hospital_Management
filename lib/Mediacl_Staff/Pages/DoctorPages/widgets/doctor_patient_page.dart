import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorPatientPage extends StatefulWidget {
  const DoctorPatientPage({
    super.key,
    required this.hospitalId,
    required this.doctorId,
    required this.consultations,
  });
  final int hospitalId;
  final String doctorId;
  final List<dynamic> consultations;
  @override
  State<DoctorPatientPage> createState() => _DoctorPatientPageState();
}

class _DoctorPatientPageState extends State<DoctorPatientPage> {
  int calculateExactAge(String dobString) {
    DateTime dob = DateTime.parse(dobString);
    DateTime today = DateTime.now();

    int age = today.year - dob.year;

    // Subtract 1 if birthday hasn't occurred yet this year
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    return age;
  }

  @override
  Widget build(BuildContext context) {
    var consultations = widget.consultations;
    return consultations.isEmpty
        ? const Center(child: Text('No consultations found'))
        : SizedBox(
            height: MediaQuery.sizeOf(context).height,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: consultations.length,
              itemBuilder: (context, index) {
                final consultation = consultations[index];
                final patient = consultation['Patient'] ?? {};
                final patientName = patient['name'] ?? 'Unknown';
                final dob = DateFormat(
                  'yyyy-MM-dd',
                ).format(DateTime.parse(patient['dob']));
                var age = calculateExactAge(patient['dob']);

                final gender = patient['gender'] ?? 'N/A';
                // final symptoms = consultation['symptoms'] == 'null'
                //     ? 'Not specified'
                //     : consultation['symptoms'] ?? 'Not specified';
                final purpose = consultation['purpose'] ?? 'No details';
                // final patientId = patient['user_Id'] ?? '';

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ListTile(
                      enabled: consultation['status'] == 'ONGOING'
                          ? false
                          : true,
                      // leading: CircleAvatar(
                      //   backgroundImage: patient['photo'] != null &&
                      //       patient['photo'] != 'null'
                      //       ? NetworkImage(patient['photo'])
                      //       : const AssetImage('assets/default_avatar.png')
                      //   as ImageProvider,
                      // ),
                      title: Text(
                        patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('DOB: $dob'),
                              SizedBox(width: 10),
                              Text('Age: $age'),
                            ],
                          ),
                          Text('Gender: $gender'),
                          const SizedBox(height: 6),
                          Text('Chief Complaints: $purpose'),
                        ],
                      ),
                      trailing: consultation['status'] == 'ONGOING'
                          ? const Text(
                              'Under Progress',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () {
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (_) => PatientDescriptionPage(
                                //       consultation: consultation,
                                //     ),
                                //   ),
                                // );
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text(
                                'View',
                                style: TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          );
  }
}
