import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class RegisterBloodCenterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> registerBloodCenter({
    required String centerName,
    required String centerAddress,
    required String contactNumber,
    required String email,
    File? licenseFile,
    File? certificateFile,
    File? accreditationFile,
    double? latitude,
    double? longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    Map<String, dynamic> data = {
      'userId': user.uid,
      'hospitalName': centerName,
      'hospitalAddress': centerAddress,
      'contactNumber': contactNumber,
      'email': email,
      'type': 'blood_center',
      'licenseUrl': '',
      'certificateUrl': '',
      'accreditationUrl': '',
      'status': 'approved',
      'submittedAt': FieldValue.serverTimestamp(),
    };

    if (latitude != null && longitude != null) {
      data['latitude'] = latitude;
      data['longitude'] = longitude;
    }

    await _firestore.collection('blood_bank').doc(user.uid).set(data);

    return true;
  }
}
