import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user profile exists
  Future<bool> profileExists() async {
    if (currentUserId == null) return false;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking profile existence: $e');
      return false;
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create or update user profile
  Future<bool> saveUserProfile({
    required String name,
    String? age,
    String? gender,
    String? bloodGroup,
    String? phone,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    if (currentUserId == null) {
      print('UserProfileService: No current user ID');
      return false;
    }

    try {
      print('UserProfileService: Starting save for user $currentUserId');
      
      Map<String, dynamic> profileData = {
        'name': name,
        'age': age ?? '',
        'gender': gender ?? '',
        'bloodGroup': bloodGroup ?? '',
        'phone': phone ?? '',
        'location': location ?? '',
        'email': _auth.currentUser?.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add coordinates if available (optional)
      if (latitude != null && longitude != null) {
        profileData['latitude'] = latitude;
        profileData['longitude'] = longitude;
        print('UserProfileService: Adding coordinates - Lat: $latitude, Lng: $longitude');
      }

      // Only set createdAt on first creation
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (!doc.exists) {
        profileData['createdAt'] = FieldValue.serverTimestamp();
        print('UserProfileService: Creating new profile (first time)');
      } else {
        print('UserProfileService: Updating existing profile');
      }

      print('UserProfileService: Profile data to save: $profileData');

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set(profileData, SetOptions(merge: true));

      print('UserProfileService: Profile saved successfully');
      return true;
    } catch (e) {
      print('UserProfileService ERROR saving profile: $e');
      print('UserProfileService ERROR stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Update only specific fields
  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    if (currentUserId == null) return false;

    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update(updates);

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Delete user profile
  Future<bool> deleteUserProfile() async {
    if (currentUserId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting user profile: $e');
      return false;
    }
  }

  // Stream user profile for real-time updates
  Stream<DocumentSnapshot>? streamUserProfile() {
    if (currentUserId == null) return null;

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots();
  }
}