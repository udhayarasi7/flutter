import 'package:flutter/material.dart';
import 'dart:ui';
import '../../service/notify_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                                        color: Colors.red.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.water_drop,
                                        color: Colors.red.shade600,
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
                                                  'Blood Request',
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
                                          const SizedBox(height: 8),
                                          Text(
                                            timeAgo,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
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
