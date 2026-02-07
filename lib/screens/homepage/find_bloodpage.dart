import 'package:flutter/material.dart';
import 'dart:ui';
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
  final TextEditingController _searchController = TextEditingController();
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _selectedBloodGroups = [];
  bool _showDonors = false;
  bool _showBanks = false;
  List<Map<String, dynamic>> _matchedUsers = [];
  bool _isSearching = false;
  bool _isSendingNotification = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
  }

  Future<void> _searchUsers() async {
    if (_selectedBloodGroups.isEmpty || (!_showDonors && !_showBanks)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one blood group and search category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final donorsRef = FirebaseDatabase.instance.ref('donors');
      List<Map<String, dynamic>> matched = [];

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
              });
            }
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
          const SnackBar(
            content: Text('No active donors found matching your criteria'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching users: $e'),
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
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      _mapController.move(_currentCenter, 15.0);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
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

      for (var user in _matchedUsers) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notifications sent to ${_matchedUsers.length} user(s)!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSendingNotification = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notifications: $e'),
            backgroundColor: Colors.red,
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
                                if (hasGesture) {
                                  setState(() {
                                    _currentCenter = position.center!;
                                  });
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.firstapp',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _currentCenter,
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.red.shade600,
                                      size: 40,
                                    ),
                                  ),
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
                                          Icons.location_on,
                                          color: Colors.blue.shade600,
                                          size: 30,
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ],
                          ),
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
                                      onTap: _isSendingNotification ? null : _sendNotifications,
                                      borderRadius: BorderRadius.circular(15),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _isSendingNotification
                                                ? SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.teal.shade700,
                                                    ),
                                                  )
                                                : Icon(
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
                                      onTap: _isLoadingLocation ? null : _getCurrentLocation,
                                      borderRadius: BorderRadius.circular(15),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: _isLoadingLocation
                                            ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.teal.shade700,
                                                ),
                                              )
                                            : Icon(
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
    super.dispose();
  }
}
