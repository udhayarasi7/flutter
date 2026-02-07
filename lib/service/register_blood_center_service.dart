import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';

class RegisterBloodCenterService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> registerBloodCenter({
    required String centerName,
    required String centerAddress,
    required String contactNumber,
    required String email,
    File? licenseFile,
    File? certificateFile,
    File? accreditationFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _database.ref('hospital_registrations/${user.uid}').set({
      'userId': user.uid,
      'hospitalName': centerName,
      'hospitalAddress': centerAddress,
      'contactNumber': contactNumber,
      'email': email,
      'licenseUrl': '',
      'certificateUrl': '',
      'accreditationUrl': '',
      'status': 'approved',
      'submittedAt': ServerValue.timestamp,
    });

    return true;
  }
}
