import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> sendNotificationToUsers(List<String> userIds, String senderName, String bloodGroup) async {
    for (String userId in userIds) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        await _firestore.collection('notifications').add({
          'to': fcmToken,
          'notification': {
            'title': 'Blood Request',
            'body': '$senderName wants your $bloodGroup blood group',
          },
          'data': {
            'senderName': senderName,
            'bloodGroup': bloodGroup,
            'type': 'blood_request',
          },
        });
      }

      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'message': '$senderName wants your $bloodGroup blood group',
        'senderName': senderName,
        'senderBloodGroup': bloodGroup,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
  }
}
