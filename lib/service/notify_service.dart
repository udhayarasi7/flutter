import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotifyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<int> getUnreadCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }
}
