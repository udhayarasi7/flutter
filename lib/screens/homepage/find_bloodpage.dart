import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../service/notification_service.dart';

class FindBloodPage extends StatefulWidget {
  const FindBloodPage({Key? key}) : super(key: key);

  @override
  State<FindBloodPage> createState() => _FindBloodPageState();
}

class _FindBloodPageState extends State<FindBloodPage> with TickerProviderStateMixin {
  late AnimationController _topRightController;
  late AnimationController _bottomLeftController;
  late AnimationController _bottomRightController;

  late Animation<Offset> _topRightAnimation;
  late Animation<Offset> _bottomLeftAnimation;
  late Animation<Offset> _bottomRightAnimation;

  final MapController _mapController = MapController();
  LatLng _currentCenter = LatLng(28.6139, 77.2090);
  bool _isLoadingLocation = false;
  bool _showSearch = false;
  bool _showNotifySheet = false;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _selectedBloodGroups = [];
  bool _showDonors = false;
  bool _showBanks = false;
  List<Map<String, dynamic>> _matchedUsers = [];
  bool _isSearching = false;
  bool _isSendingNotification = false;
  int _selectedDistance = 5; // Default to 5 KM
  final List<int> _distanceOptions = [5, 10, 15, 20, 25, 30]; // Distance filter options
  late Map<String, dynamic> _tempNotifyUser; // Temporary variable to store user being notified
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestLocationPermissionOnLoad();
  }

  /// Request location permission when page opens
  Future<void> _requestLocationPermissionOnLoad() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog(
          'Location Services Disabled',
          'Please enable location services to find blood donors near you.',
          () => Geolocator.openLocationSettings(),
        );
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationDialog(
            'Location Permission Required',
            'Location permission is needed to find blood donors near you.',
            () => Navigator.pop(context),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationDialog(
          'Location Permission Denied',
          'Location permission is permanently denied. Please enable it in app settings.',
          () => Geolocator.openAppSettings(),
        );
        return;
      }

      // Permission granted, get current location
      _getCurrentLocation();
    } catch (e) {
      print('Error requesting location permission: $e');
    }
  }

  /// Show location permission dialog
  void _showLocationDialog(String title, String message, VoidCallback onPrimaryAction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onPrimaryAction();
              },
              child: const Text(
                'Enable',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _searchUsers() async {
    if (!_showDonors && !_showBanks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a search category (Blood Donors or Blood Banks)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_showDonors && _selectedBloodGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one blood group for Blood Donors search'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      List<Map<String, dynamic>> matched = [];

      // Search for Blood Donors
      if (_showDonors) {
        final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
        final donorsRef = FirebaseDatabase.instance.ref('donors');

        for (var doc in usersSnapshot.docs) {
          final data = doc.data();
          final bloodGroup = data['bloodGroup'];
          final latitude = data['latitude'];
          final longitude = data['longitude'];
          final name = data['name'] ?? 'Unknown';

          if (bloodGroup != null && 
              _selectedBloodGroups.contains(bloodGroup) &&
              latitude != null && 
              longitude != null) {
            
            final donorSnapshot = await donorsRef.child(doc.id).get();
            if (donorSnapshot.exists) {
              final donorData = donorSnapshot.value as Map;
              final donationStatus = donorData['donationStatus'];
              
              if (donationStatus == 'active') {
                matched.add({
                  'id': doc.id,
                  'name': name,
                  'bloodGroup': bloodGroup,
                  'latitude': latitude,
                  'longitude': longitude,
                  'type': 'donor',
                });
              }
            }
          }
        }
      }

      // Search for Blood Banks
      if (_showBanks) {
        final bloodBanksSnapshot = await FirebaseFirestore.instance.collection('blood_bank').get();

        for (var doc in bloodBanksSnapshot.docs) {
          final data = doc.data();
          final latitude = data['latitude'];
          final longitude = data['longitude'];
          final name = data['hospitalName'] ?? 'Blood Bank';

          if (latitude != null && longitude != null) {
            matched.add({
              'id': doc.id,
              'name': name,
              'latitude': latitude,
              'longitude': longitude,
              'type': 'blood_bank',
            });
          }
        }
      }

      setState(() {
        _matchedUsers = matched;
        _isSearching = false;
        _showSearch = false;
      });

      if (matched.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_showBanks && !_showDonors 
              ? 'No blood banks found' 
              : 'No active donors found matching your criteria'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        if (mounted) {
          _showLocationDialog(
            'Location Services Disabled',
            'Please enable location services to find blood donors near you.',
            () => Geolocator.openLocationSettings(),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentCenter, 15.0);
        
        // Start live location tracking
        _startLiveLocationTracking();
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      print('Error getting location: $e');
    }
  }

  /// Start tracking location changes in real-time
  void _startLiveLocationTracking() {
    // Cancel existing stream if any
    _positionStream?.cancel();
    
    // Listen to location changes every 5 seconds
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when user moves 10 meters
        timeLimit: Duration(seconds: 5),
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
        });
        // Move map smoothly to new location
        _mapController.move(_currentCenter, _mapController.camera.zoom);
      }
    }, onError: (e) {
      print('Error tracking location: $e');
    });
  }

  /// Center map to current location with loading indicator
  Future<void> _centerMapToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      // Get fresh location first
      Position position = await Geolocator.getCurrentPosition();
      
      if (mounted) {
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
        });
        
        // Move map to current location with zoom
        _mapController.move(_currentCenter, 17.0); // Zoom in to 17 to see user location clearly
        
        // Hide loading only after location is found and map moved
        setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      print('Error centering map: $e');
    }
  }

  /// Calculate distance between two coordinates in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius of Earth in km
    final double dLat = (lat2 - lat1) * 3.14159 / 180;
    final double dLon = (lon2 - lon1) * 3.14159 / 180;
    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * 3.14159 / 180) * cos(lat2 * 3.14159 / 180) * (sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Send notification to individual user
  void _showNotifyConfirmDialog(String personName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Send Notification?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Send notification to $personName?',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendNotificationToUser(_tempNotifyUser);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifyAllConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Send Notifications?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Send notification to all ${_matchedUsers.length} users?',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotificationToUser(Map<String, dynamic> user) async {
    setState(() => _isSendingNotification = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!currentUserDoc.exists) {
        throw Exception('User data not found');
      }

      final senderName = currentUserDoc.data()?['name'] ?? 'Someone';
      final bloodGroup = user['bloodGroup'] ?? 'blood';

      final notification = {
        'message': '$senderName needs your $bloodGroup blood group',
        'senderName': senderName,
        'recipientBloodGroup': bloodGroup,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user['id'])
          .collection('notifications')
          .add(notification);

      setState(() => _isSendingNotification = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text(
              'Notification Sent!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            content: Text(
              'Notification sent to ${user['name']}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSendingNotification = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            content: Text(
              'Failed to send notification: $e',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Show bottom sheet with available donors
  void _showNotifyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Notify All button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showNotifyAllConfirmDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Notify All',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Donors list
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        // Filter users by selected distance
                        final filteredUsers = _matchedUsers.where((user) {
                          final userLat = user['latitude'] is double 
                            ? user['latitude'] as double 
                            : (user['latitude'] as num?)?.toDouble() ?? 0.0;
                          final userLon = user['longitude'] is double 
                            ? user['longitude'] as double 
                            : (user['longitude'] as num?)?.toDouble() ?? 0.0;
                          
                          final distance = _calculateDistance(
                            _currentCenter.latitude,
                            _currentCenter.longitude,
                            userLat,
                            userLon,
                          );
                          
                          return distance <= _selectedDistance;
                        }).toList();

                        if (filteredUsers.isEmpty) {
                          return Center(
                            child: Text(
                              'No donors found within ${_selectedDistance}km',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            
                            // Ensure coordinates are doubles
                            final userLat = user['latitude'] is double 
                              ? user['latitude'] as double 
                              : (user['latitude'] as num?)?.toDouble() ?? 0.0;
                            final userLon = user['longitude'] is double 
                              ? user['longitude'] as double 
                              : (user['longitude'] as num?)?.toDouble() ?? 0.0;
                            
                            final distance = _calculateDistance(
                              _currentCenter.latitude,
                              _currentCenter.longitude,
                              userLat,
                              userLon,
                            );

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Donor name
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    user['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Distance with styled pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.teal.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${distance.toStringAsFixed(1)} KM',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Notify button
                                ElevatedButton(
                                  onPressed: () {
                                    _tempNotifyUser = user;
                                    _showNotifyConfirmDialog(user['name'] ?? 'User');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade700,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'Notify',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
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
            );
          },
        );
      },
    );
  }

  Future<void> _sendNotifications() async {
    if (_matchedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No users to notify. Please search first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSendingNotification = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!currentUserDoc.exists) {
        throw Exception('User data not found');
      }

      final senderName = currentUserDoc.data()?['name'] ?? 'Someone';

      // Filter users by selected distance
      for (var user in _matchedUsers) {
        final userLat = user['latitude'] is double 
          ? user['latitude'] as double 
          : (user['latitude'] as num?)?.toDouble() ?? 0.0;
        final userLon = user['longitude'] is double 
          ? user['longitude'] as double 
          : (user['longitude'] as num?)?.toDouble() ?? 0.0;
        
        final distance = _calculateDistance(
          _currentCenter.latitude,
          _currentCenter.longitude,
          userLat,
          userLon,
        );

        // Only notify if within selected distance
        if (distance > _selectedDistance) continue;

        final recipientBloodGroup = user['bloodGroup'];
        final notification = {
          'message': '$senderName wants your $recipientBloodGroup blood group',
          'senderName': senderName,
          'recipientBloodGroup': recipientBloodGroup,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user['id'])
            .collection('notifications')
            .add(notification);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
        'lastNotificationSent': FieldValue.serverTimestamp(),
        'notificationsSent': FieldValue.increment(1),
      }, SetOptions(merge: true));

      setState(() => _isSendingNotification = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text(
              'Notifications Sent!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            content: Text(
              'Notifications sent to all users within ${_selectedDistance}km',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Close notify sheet too
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSendingNotification = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            content: Text(
              'Failed to send notifications: $e',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    }
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
                top: -30+_topRightAnimation.value.dy,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 60,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.arrow_back_rounded,
                                        size: 24,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showSearch = !_showSearch;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Search',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: _showSearch ? Colors.teal.shade700 : Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _showSearch = !_showSearch;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.search,
                                        size: 24,
                                        color: _showSearch ? Colors.teal.shade700 : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_showSearch) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Blood Groups',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _bloodGroups.map((group) => _buildChip(
                                        group,
                                        _selectedBloodGroups.contains(group),
                                        () {
                                          setState(() {
                                            if (_selectedBloodGroups.contains(group)) {
                                              _selectedBloodGroups.remove(group);
                                            } else {
                                              _selectedBloodGroups.add(group);
                                            }
                                          });
                                        },
                                        Icons.water_drop,
                                      )).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Search For',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildChip(
                                          'Blood Donors',
                                          _showDonors,
                                          () => setState(() => _showDonors = !_showDonors),
                                          Icons.person,
                                        ),
                                        _buildChip(
                                          'Blood Banks',
                                          _showBanks,
                                          () => setState(() => _showBanks = !_showBanks),
                                          Icons.local_hospital,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Distance Range',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: _distanceOptions.map((distance) {
                                          final isSelected = _selectedDistance == distance;
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() => _selectedDistance = distance);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? Colors.teal.shade700 : Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: isSelected
                                                      ? Border.all(color: Colors.teal.shade900, width: 2)
                                                      : null,
                                                ),
                                                child: Text(
                                                  '${distance}km',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isSearching ? null : _searchUsers,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal.shade700,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isSearching
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Search',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_selectedBloodGroups.isNotEmpty || _showDonors || _showBanks)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ..._selectedBloodGroups.map((group) => Chip(
                            label: Text(group),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() => _selectedBloodGroups.remove(group));
                            },
                            backgroundColor: Colors.white,
                          )),
                          if (_showDonors)
                            Chip(
                              label: const Text('Blood Donors'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setState(() => _showDonors = false),
                              backgroundColor: Colors.white,
                            ),
                          if (_showBanks)
                            Chip(
                              label: const Text('Blood Banks'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setState(() => _showBanks = false),
                              backgroundColor: Colors.white,
                            ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentCenter,
                              initialZoom: 13.0,
                              onPositionChanged: (position, hasGesture) {
                                // Don't update _currentCenter on user drag
                                // Let user freely drag the map
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.firstapp',
                              ),
                              MarkerLayer(
                                markers: [
                                  ..._matchedUsers.map((user) => Marker(
                                    point: LatLng(user['latitude'], user['longitude']),
                                    width: 80,
                                    height: 80,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            user['name'],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          user['type'] == 'blood_bank' ? Icons.local_hospital : Icons.person_pin_circle,
                                          color: user['type'] == 'blood_bank' ? Colors.green.shade600 : Colors.blue.shade600,
                                          size: 30,
                                        ),
                                      ],
                                    ),
                                  )),
                                  // Current user location marker (on top/front)
                                  Marker(
                                    point: _currentCenter,
                                    width: 80,
                                    height: 80,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.red.shade900,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade900,
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'You',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Notify button - only show when blood donors are found
                          if (_matchedUsers.isNotEmpty && _showDonors)
                            Positioned(
                              bottom: 20,
                              left: 20,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showNotifyBottomSheet(),
                                        borderRadius: BorderRadius.circular(15),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.notifications_outlined,
                                                color: Colors.teal.shade700,
                                                size: 20,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Notify',
                                                style: TextStyle(
                                                  color: Colors.teal.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 110,
                            right: 20,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _centerMapToCurrentLocation,
                                      borderRadius: BorderRadius.circular(15),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.my_location_rounded,
                                          color: Colors.teal.shade700,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Loading text overlay - shows when searching for user location
                          if (_isLoadingLocation)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade700,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Finding your location...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Opening directions...'),
                                            backgroundColor: Colors.blue,
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(15),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.directions,
                                              color: Colors.teal.shade700,
                                              size: 20,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Directions',
                                              style: TextStyle(
                                                color: Colors.teal.shade700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, IconData icon) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.teal.shade700 : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
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
    _searchController.dispose();
    _topRightController.dispose();
    _bottomLeftController.dispose();
    _bottomRightController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }
}
