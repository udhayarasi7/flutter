import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DonationStatus {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Update donation status in Realtime Database
  /// When toggle is ON -> status becomes "active"
  /// When toggle is OFF -> status becomes "inactive"
  Future<bool> updateDonationStatus(bool isAvailable) async {
    try {
      if (_userId == null) {
        print('Error: No user logged in');
        return false;
      }

      final String status = isAvailable ? 'active' : 'inactive';
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Update in Realtime Database
      await _database.child('donors').child(_userId!).update({
        'donationStatus': status,
        'isDonationAvailable': isAvailable,
        'lastStatusUpdate': timestamp,
        'lastStatusUpdateDate': DateTime.now().toIso8601String(),
      });

      print('Donation status updated to: $status');
      return true;
    } catch (e) {
      print('Error updating donation status: $e');
      return false;
    }
  }

  /// Get current donation status
  Future<Map<String, dynamic>?> getDonationStatus() async {
    try {
      if (_userId == null) {
        print('Error: No user logged in');
        return null;
      }

      final snapshot = await _database.child('donors').child(_userId!).get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return {
          'status': data['donationStatus'] ?? 'inactive',
          'isAvailable': data['isDonationAvailable'] ?? false,
          'lastUpdate': data['lastStatusUpdateDate'],
        };
      }

      return null;
    } catch (e) {
      print('Error getting donation status: $e');
      return null;
    }
  }

  /// Stream to listen to donation status changes in real-time
  Stream<Map<String, dynamic>> donationStatusStream() {
    if (_userId == null) {
      return Stream.value({
        'status': 'inactive',
        'isAvailable': false,
      });
    }

    return _database.child('donors').child(_userId!).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return {
          'status': data['donationStatus'] ?? 'inactive',
          'isAvailable': data['isDonationAvailable'] ?? false,
          'lastUpdate': data['lastStatusUpdateDate'],
        };
      }
      return {
        'status': 'inactive',
        'isAvailable': false,
      };
    });
  }

  /// Get all active donors by blood type
  Future<List<Map<String, dynamic>>> getActiveDonorsByBloodType(
      String bloodType) async {
    try {
      final snapshot = await _database
          .child('donors')
          .orderByChild('bloodType')
          .equalTo(bloodType)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      List<Map<String, dynamic>> activeDonors = [];
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((key, value) {
        final donor = Map<String, dynamic>.from(value as Map);
        // Only include active donors
        if (donor['donationStatus'] == 'active' &&
            donor['isDonationAvailable'] == true) {
          donor['userId'] = key;
          activeDonors.add(donor);
        }
      });

      return activeDonors;
    } catch (e) {
      print('Error getting active donors: $e');
      return [];
    }
  }

  /// Stream of active donors by blood type
  Stream<List<Map<String, dynamic>>> activeDonorsStream(String bloodType) {
    return _database
        .child('donors')
        .orderByChild('bloodType')
        .equalTo(bloodType)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) {
        return [];
      }

      List<Map<String, dynamic>> activeDonors = [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      data.forEach((key, value) {
        final donor = Map<String, dynamic>.from(value as Map);
        // Only include active donors
        if (donor['donationStatus'] == 'active' &&
            donor['isDonationAvailable'] == true) {
          donor['userId'] = key;
          activeDonors.add(donor);
        }
      });

      return activeDonors;
    });
  }

  /// Check if user profile exists
  Future<bool> donorProfileExists() async {
    try {
      if (_userId == null) {
        return false;
      }

      final snapshot = await _database.child('donors').child(_userId!).get();
      return snapshot.exists;
    } catch (e) {
      print('Error checking donor profile: $e');
      return false;
    }
  }

  /// Set presence - mark user as online/offline
  Future<void> setUserPresence(bool isOnline) async {
    try {
      if (_userId == null) return;

      await _database.child('donors').child(_userId!).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });

      // Set up automatic offline status on disconnect
      if (isOnline) {
        _database
            .child('donors')
            .child(_userId!)
            .child('isOnline')
            .onDisconnect()
            .set(false);
        
        _database
            .child('donors')
            .child(_userId!)
            .child('lastSeen')
            .onDisconnect()
            .set(ServerValue.timestamp);
      }
    } catch (e) {
      print('Error setting user presence: $e');
    }
  }
}