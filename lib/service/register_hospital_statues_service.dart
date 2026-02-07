import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterHospitalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
        'type': 'hospital',
        'licenseProofUrl': licenseProofUrl ?? '',
        'registrationCertificateUrl': registrationCertificateUrl ?? '',
        'submittedAt': FieldValue.serverTimestamp(),
      };

      if (latitude != null && longitude != null) {
        hospitalData['latitude'] = latitude;
        hospitalData['longitude'] = longitude;
      }

      await _firestore
          .collection('hospitals')
          .doc(currentUserId)
          .set(hospitalData);

      return true;
    } catch (e) {
      print('Error submitting registration: $e');
      return false;
    }
  }
}