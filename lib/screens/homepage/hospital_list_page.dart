import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hospital_detail_page.dart';

class HospitalListPage extends StatelessWidget {
  const HospitalListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospitals'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bloodCenters')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hospitals = snapshot.data!.docs;

          if (hospitals.isEmpty) {
            return const Center(child: Text('No hospitals registered'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              final hospital = hospitals[index];
              final data = hospital.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.local_hospital, color: Colors.red),
                  title: Text(data['centerName'] ?? 'Unknown'),
                  subtitle: Text(data['centerAddress'] ?? ''),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HospitalDetailPage(
                          hospitalId: hospital.id,
                          hospitalName: data['centerName'] ?? 'Hospital',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
