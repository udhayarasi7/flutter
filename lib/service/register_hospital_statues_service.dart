import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterHospitalService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<bool> submitHospitalRegistration({
    required String hospitalName,
    required String hospitalAddress,
    required String contactNumber,
    String? licenseProofUrl,
    String? registrationCertificateUrl,
    double? latitude,
    double? longitude,
  }) async {
    if (currentUserId == null) return false;

    try {
      Map<String, dynamic> hospitalData = {
        'hospitalName': hospitalName,
        'hospitalAddress': hospitalAddress,
        'contactNumber': contactNumber,
        'userId': currentUserId,
        'userEmail': _auth.currentUser?.email ?? '',
        'status': 'approved',
        'licenseProofUrl': licenseProofUrl ?? '',
        'registrationCertificateUrl': registrationCertificateUrl ?? '',
        'submittedAt': ServerValue.timestamp,
      };

      if (latitude != null && longitude != null) {
        hospitalData['latitude'] = latitude;
        hospitalData['longitude'] = longitude;
      }

      await _database
          .ref('hospital_registrations/$currentUserId')
          .set(hospitalData);

      return true;
    } catch (e) {
      print('Error submitting registration: $e');
      return false;
    }
  }
}