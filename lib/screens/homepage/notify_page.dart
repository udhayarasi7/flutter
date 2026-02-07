import 'package:flutter/material.dart';
import 'dart:ui';
import '../../service/notify_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NotifyPage extends StatefulWidget {
  const NotifyPage({Key? key}) : super(key: key);

  @override
  State<NotifyPage> createState() => _NotifyPageState();
}

class _NotifyPageState extends State<NotifyPage> with TickerProviderStateMixin {
  final NotifyService _notifyService = NotifyService();
  late AnimationController _topRightController;
  late AnimationController _bottomLeftController;
  late AnimationController _bottomRightController;
  late Animation<Offset> _topRightAnimation;
  late Animation<Offset> _bottomLeftAnimation;
  late Animation<Offset> _bottomRightAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _topRightController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _topRightAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-15, 10),
    ).animate(CurvedAnimation(parent: _topRightController, curve: Curves.easeInOut));

    _bottomLeftController = AnimationController(
      duration: const Duration(seconds: 3, milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _bottomLeftAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(12, -18),
    ).animate(CurvedAnimation(parent: _bottomLeftController, curve: Curves.easeInOut));

    _bottomRightController = AnimationController(
      duration: const Duration(seconds: 3, milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
    _bottomRightAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-12, -15),
    ).animate(CurvedAnimation(parent: _bottomRightController, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _topRightAnimation,
            builder: (context, child) {
              return Positioned(
                top: -30 + _topRightAnimation.value.dy,
                right: -20 + _topRightAnimation.value.dx,
                child: _buildBlob(120, Colors.cyan.shade300),
              );
            },
          ),
          AnimatedBuilder(
            animation: _bottomLeftAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: -40 + _bottomLeftAnimation.value.dy,
                left: -60 + _bottomLeftAnimation.value.dx,
                child: _buildBlob(180, Colors.cyan.shade200),
              );
            },
          ),
          AnimatedBuilder(
            animation: _bottomRightAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: 150 + _bottomRightAnimation.value.dy,
                right: -30 + _bottomRightAnimation.value.dx,
                child: _buildBlob(140, Colors.blue.shade400),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 24,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _notifyService.getNotifications(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final notifications = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          final isRead = notification['read'] ?? false;
                          final isAccepted = notification['accepted'] ?? false;
                          final acceptedBy = notification['acceptedBy'];
                          final timestamp = notification['timestamp'] as Timestamp?;
                          final timeAgo = timestamp != null
                              ? _getTimeAgo(timestamp.toDate())
                              : 'Just now';

                          return Dismissible(
                            key: Key(notification['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            onDismissed: (direction) {
                              _notifyService.deleteNotification(notification['id']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification deleted'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: InkWell(
                              onTap: () {
                                if (!isRead) {
                                  _notifyService.markAsRead(notification['id']);
                                }
                              },
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? Colors.white
                                      : Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isRead
                                        ? Colors.grey.shade300
                                        : Colors.teal.shade200,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isAccepted ? Colors.grey.shade100 : Colors.red.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isAccepted ? Icons.check_circle : Icons.water_drop,
                                        color: isAccepted ? Colors.grey.shade600 : Colors.red.shade600,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  isAccepted ? 'Request Accepted' : 'Blood Request',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal.shade600,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            notification['message'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          if (isAccepted && acceptedBy != null)
                                            const SizedBox(height: 4),
                                          if (isAccepted && acceptedBy != null)
                                            Text(
                                              'Accepted by another donor',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  timeAgo,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ),
                                              if (!isAccepted)
                                                ElevatedButton(
                                                  onPressed: () => _acceptDonation(notification),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red.shade600,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: const Text('Donate', style: TextStyle(fontSize: 13)),
                                                )
                                              else
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'Closed',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade700,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptDonation(Map<String, dynamic> notification) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final notificationId = notification['id'];
      final senderName = notification['senderName'];
      final message = notification['message'];
      final hospitalId = notification['hospitalId'];
      final bloodGroup = notification['recipientBloodGroup'];
      
      // Mark current user's notification as accepted
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'accepted': true,
        'acceptedBy': currentUser.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Delete all other users' matching notifications
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      int deletedCount = 0;
      for (var doc in usersSnapshot.docs) {
        if (doc.id != currentUser.uid) {
          final userNotifications = await doc.reference.collection('notifications').get();
          for (var notifDoc in userNotifications.docs) {
            final data = notifDoc.data();
            if (data['senderName'] == senderName && data['message'] == message) {
              await notifDoc.reference.delete();
              deletedCount++;
            }
          }
        }
      }

      // Decrease hospital request count
      if (hospitalId != null && bloodGroup != null) {
        final inventoryRef = FirebaseDatabase.instance
            .ref('hospital_registrations/$hospitalId/bloodInventory/$bloodGroup');
        final snapshot = await inventoryRef.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map;
          final currentCount = data['requestCount'] ?? 0;
          if (currentCount > 0) {
            await inventoryRef.update({
              'requestCount': currentCount - deletedCount - 1,
            });
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You accepted the donation request!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  void dispose() {
    _topRightController.dispose();
    _bottomLeftController.dispose();
    _bottomRightController.dispose();
    super.dispose();
  }
}
