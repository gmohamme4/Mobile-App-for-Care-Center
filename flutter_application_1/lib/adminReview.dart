import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEquipmentReviewPage extends StatelessWidget {
  const AdminEquipmentReviewPage({super.key});

  // Approve equipment
  void _approveEquipment(String equipmentId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(equipmentId)
          .update({'isApproved': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Equipment approved successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error approving equipment: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Reject equipment
  void _declineEquipment(String equipmentId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(equipmentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🗑️ Equipment rejected and removed."),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error rejecting equipment: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Equipment details UI
  Widget _buildEquipmentDetails(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['name'] ?? 'N/A',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B8D45),
            ),
          ),
          const SizedBox(height: 10),

          _infoRow("Type", data['type']),
          _infoRow("Quantity", data['quantity']?.toString()),
          _infoRow("Condition", "${data['condition'] ?? 'N/A'} / 5"),
          _infoRow("Rental Price / Day", data['rentalPricePerDay']?.toString()),
          _infoRow("Owner Email", data['ownerEmail']),
          
          const SizedBox(height: 8),

          Text(
            "Description:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['description'] ?? 'No description available',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Reusable info row widget
  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment Review"),
        centerTitle: true,
        backgroundColor: const Color(0xFF6B8D45),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('equipment')
            .where('isApproved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No new equipment to review.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              String equipmentId = doc.id;
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildEquipmentDetails(data),

                    const Divider(),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                _declineEquipment(equipmentId, context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Reject"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () =>
                                _approveEquipment(equipmentId, context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B8D45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Approve",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
