import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceListPage extends StatelessWidget {
  const MaintenanceListPage({super.key});

  void _markAsAvailable(
      String equipmentId, String itemName, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(equipmentId)
          .update({
        'availability': 'available',
        'isApproved': true,
      });

      await FirebaseFirestore.instance.collection('maintenance_logs').add({
        'equipmentId': equipmentId,
        'itemName': itemName,
        'status': 'Repaired',
        'dateResolved': FieldValue.serverTimestamp(),
        'adminId': 'admin_user_id',
        'notes': 'Maintenance completed and item returned to inventory.',
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Item marked as Available and log recorded."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error updating status: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceStream = FirebaseFirestore.instance
        .collection('equipment')
        .where('availability', isEqualTo: 'under maintenance')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Maintenance List"),
        backgroundColor: const Color(0xFF6B8D45),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: maintenanceStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("No equipment currently under maintenance."));
          }

          final equipmentDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: equipmentDocs.length,
            itemBuilder: (context, index) {
              final data =
                  equipmentDocs[index].data() as Map<String, dynamic>;
              final equipmentId = equipmentDocs[index].id;
              final itemName = data['name'] ?? 'Unnamed Equipment';
              final condition = data['condition'] ?? 'N/A';
              final location = data['location'] ?? 'N/A';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Condition: $condition / 5"),
                      Text("Location: $location"),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _markAsAvailable(
                              equipmentId, itemName, context),
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.white),
                          label: const Text(
                            "Mark as Available",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B8D45),
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
    );
  }
}