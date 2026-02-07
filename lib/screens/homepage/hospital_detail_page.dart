import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class HospitalDetailPage extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  const HospitalDetailPage({
    Key? key,
    required this.hospitalId,
    required this.hospitalName,
  }) : super(key: key);

  @override
  State<HospitalDetailPage> createState() => _HospitalDetailPageState();
}

class _HospitalDetailPageState extends State<HospitalDetailPage> {
  final Map<String, Map<String, dynamic>> _bloodInventory = {
    'A+': {'quantity': 10, 'maxQuantity': 20, 'color': Colors.red, 'requestCount': 0},
    'A-': {'quantity': 10, 'maxQuantity': 20, 'color': Colors.orange, 'requestCount': 0},
    'B+': {'quantity': 10, 'maxQuantity': 20, 'color': Colors.purple, 'requestCount': 0},
    'B-': {'quantity': 10, 'maxQuantity': 20, 'color': Colors.pink, 'requestCount': 0},
    'AB+': {'quantity': 10, 'maxQuantity': 20, 'color': Colors.blue, 'requestCount': 0},
    'AB-': {'quantity': 10, 'maxQuantity': 20, 'color': Colors.indigo, 'requestCount': 0},
    'O+': {'quantity': 10, 'maxQuantity': 20, 'color': Colors.green, 'requestCount': 0},
    'O-': {'quantity': 10, 'maxQuantity': 20, 'color': Colors.teal, 'requestCount': 0},
  };

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('hospital_registrations/${widget.hospitalId}/bloodInventory')
        .get();
    
    if (snapshot.exists && mounted) {
      final inventory = snapshot.value as Map;
      setState(() {
        inventory.forEach((key, value) {
          if (_bloodInventory.containsKey(key)) {
            _bloodInventory[key]!['quantity'] = value['quantity'] ?? 10;
            _bloodInventory[key]!['requestCount'] = value['requestCount'] ?? 0;
          }
        });
      });
    }
  }

  Future<void> _updateInventory(String bloodGroup, int quantity) async {
    setState(() {
      _bloodInventory[bloodGroup]!['quantity'] = quantity;
    });

    await FirebaseDatabase.instance
        .ref('hospital_registrations/${widget.hospitalId}/bloodInventory/$bloodGroup')
        .set({
          'quantity': quantity,
          'requestCount': _bloodInventory[bloodGroup]!['requestCount'],
        });

    final percentage = quantity / (_bloodInventory[bloodGroup]!['maxQuantity'] as int);
    if (percentage < 0.2) {
      _sendEmergencyToBloodBanks([bloodGroup]);
    }
  }

  Future<void> _requestDonors(String bloodGroup) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('bloodGroup', isEqualTo: bloodGroup)
          .get();

      int notificationsSent = 0;
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();

      for (var doc in usersSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .collection('notifications')
            .add({
          'message': 'Blood request: ${widget.hospitalName} wants your $bloodGroup blood group',
          'senderName': widget.hospitalName,
          'recipientBloodGroup': bloodGroup,
          'hospitalId': widget.hospitalId,
          'requestId': requestId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'accepted': false,
        });
        notificationsSent++;
      }

      setState(() {
        _bloodInventory[bloodGroup]!['requestCount'] = 
            (_bloodInventory[bloodGroup]!['requestCount'] as int) + notificationsSent;
      });

      await FirebaseDatabase.instance
          .ref('hospital_registrations/${widget.hospitalId}/bloodInventory/$bloodGroup')
          .update({'requestCount': _bloodInventory[bloodGroup]!['requestCount']});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to $notificationsSent $bloodGroup donors'),
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

  Future<void> _createEmergency() async {
    final List<String> selectedBloodGroups = [];
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Emergency Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select blood groups needed:'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _bloodInventory.keys.map((group) {
                  final isSelected = selectedBloodGroups.contains(group);
                  return InkWell(
                    onTap: () {
                      setDialogState(() {
                        if (isSelected) {
                          selectedBloodGroups.remove(group);
                        } else {
                          selectedBloodGroups.add(group);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        group,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedBloodGroups.isNotEmpty
                  ? () {
                      Navigator.pop(context);
                      _sendEmergencyToBloodBanks(selectedBloodGroups);
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Send Emergency', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmergencyToBloodBanks(List<String> bloodGroups) async {
    final bloodGroupsText = bloodGroups.join(', ');
    
    // Get current hospital location from hospitals collection
    var currentHospitalDoc = await FirebaseFirestore.instance
        .collection('hospitals')
        .doc(widget.hospitalId)
        .get();
    
    // If not in hospitals, check blood_bank collection
    if (!currentHospitalDoc.exists) {
      currentHospitalDoc = await FirebaseFirestore.instance
          .collection('blood_bank')
          .doc(widget.hospitalId)
          .get();
    }
    
    if (!currentHospitalDoc.exists) return;
    
    final currentHospitalData = currentHospitalDoc.data();
    if (currentHospitalData == null) return;
    
    final currentLat = currentHospitalData['latitude'];
    final currentLng = currentHospitalData['longitude'];
    
    if (currentLat == null || currentLng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hospital location not available. Please update your registration.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Get all hospitals
    final hospitalsSnapshot = await FirebaseFirestore.instance
        .collection('hospitals')
        .get();
    
    // Get all blood banks
    final bloodBanksSnapshot = await FirebaseFirestore.instance
        .collection('blood_bank')
        .get();

    int notificationsSent = 0;
    List<Map<String, dynamic>> nearbyHospitals = [];
    
    // Calculate distances to all hospitals
    for (var doc in hospitalsSnapshot.docs) {
      if (doc.id != widget.hospitalId) {
        final hospitalData = doc.data();
        final lat = hospitalData['latitude'];
        final lng = hospitalData['longitude'];
        
        if (lat != null && lng != null) {
          final distance = Geolocator.distanceBetween(
            currentLat,
            currentLng,
            lat,
            lng,
          );
          
          nearbyHospitals.add({
            'id': doc.id,
            'distance': distance,
          });
        }
      }
    }
    
    // Calculate distances to all blood banks
    for (var doc in bloodBanksSnapshot.docs) {
      if (doc.id != widget.hospitalId) {
        final bloodBankData = doc.data();
        final lat = bloodBankData['latitude'];
        final lng = bloodBankData['longitude'];
        
        if (lat != null && lng != null) {
          final distance = Geolocator.distanceBetween(
            currentLat,
            currentLng,
            lat,
            lng,
          );
          
          nearbyHospitals.add({
            'id': doc.id,
            'distance': distance,
          });
        }
      }
    }
    
    // Sort by distance and take nearest ones (within 50km)
    nearbyHospitals.sort((a, b) => a['distance'].compareTo(b['distance']));
    final nearestHospitals = nearbyHospitals.where((h) => h['distance'] <= 50000).toList();
    
    // Send notifications to nearest hospitals
    for (var hospital in nearestHospitals) {
      await FirebaseDatabase.instance
          .ref('hospital_registrations/${hospital['id']}/notifications')
          .push()
          .set({
        'message': 'EMERGENCY: ${widget.hospitalName} urgently needs $bloodGroupsText blood',
        'bloodGroups': bloodGroups,
        'hospitalId': widget.hospitalId,
        'hospitalName': widget.hospitalName,
        'type': 'emergency',
        'distance': (hospital['distance'] / 1000).toStringAsFixed(1),
        'timestamp': ServerValue.timestamp,
        'read': false,
      });
      notificationsSent++;
    }

    final donorsRef = FirebaseDatabase.instance.ref('donors');
    final donorsSnapshot = await donorsRef.get();
    if (donorsSnapshot.exists) {
      final donors = donorsSnapshot.value as Map;
      for (var entry in donors.entries) {
        final donorData = entry.value as Map;
        if (donorData['donationStatus'] == 'active') {
          await FirebaseDatabase.instance
              .ref('donors/${entry.key}/notifications')
              .push()
              .set({
            'message': 'EMERGENCY: ${widget.hospitalName} urgently needs $bloodGroupsText blood donors',
            'bloodGroups': bloodGroups,
            'hospitalId': widget.hospitalId,
            'hospitalName': widget.hospitalName,
            'type': 'emergency',
            'timestamp': ServerValue.timestamp,
            'read': false,
          });
          notificationsSent++;
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emergency alert sent to $notificationsSent recipients'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _getStockLevel(double percentage) {
    if (percentage >= 0.6) return 'Good';
    if (percentage >= 0.3) return 'Medium';
    return 'Low';
  }

  Color _getStockColor(double percentage) {
    if (percentage >= 0.6) return Colors.green.shade600;
    if (percentage >= 0.3) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        widget.hospitalName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.add,
                        label: 'Create Emergency',
                        color: Colors.red,
                        onTap: _createEmergency,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.inventory_2_outlined,
                        label: 'Manage Stock',
                        color: Colors.blue,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Blood Stock Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _bloodInventory.entries.map((entry) {
                      final bloodGroup = entry.key;
                      final data = entry.value;
                      final quantity = data['quantity'] as int;
                      final maxQuantity = data['maxQuantity'] as int;
                      final color = data['color'] as Color;
                      final requestCount = data['requestCount'] as int;
                      final percentage = quantity / maxQuantity;

                      return _buildBloodStockItem(
                        bloodGroup: bloodGroup,
                        quantity: quantity,
                        maxQuantity: maxQuantity,
                        color: color,
                        percentage: percentage,
                        requestCount: requestCount,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodStockItem({
    required String bloodGroup,
    required int quantity,
    required int maxQuantity,
    required Color color,
    required double percentage,
    required int requestCount,
  }) {
    final stockLevel = _getStockLevel(percentage);
    final stockColor = _getStockColor(percentage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    bloodGroup,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bloodGroup,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: quantity > 0 ? () => _updateInventory(bloodGroup, quantity - 1) : null,
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${quantity}L',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: quantity < maxQuantity ? () => _updateInventory(bloodGroup, quantity + 1) : null,
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  stockLevel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: stockColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (requestCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '$requestCount pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _requestDonors(bloodGroup),
                icon: const Icon(Icons.notifications_active, size: 16),
                label: const Text('Request Donors'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
