import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEquipmentReviewPage extends StatelessWidget {
  const AdminEquipmentReviewPage({super.key});

  // ✅ Approve equipment and send notification to user
  Future<void> _approveEquipment(
    String equipmentId,
    String ownerId,
    String itemName,
    BuildContext context,
  ) async {
    try {
      print("Approving equipment: $equipmentId for owner: $ownerId");

      // 1. Update equipment status to Approved
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(equipmentId)
          .update({
            'isApproved': true,
            'availabilityStatus': 'available',
          });

      print("Equipment approved in database");

      // 2. Send notification to user
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUserId': ownerId,
        'title': '✅ Donation Accepted',
        'message': 'Your donation "$itemName" has been approved and is now available on the platform.',
        'type': 'donation_approved',
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Notification sent to user: $ownerId");

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Equipment approved & user notified!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Optional: Refresh the list
      // You might want to use a state management solution for this

    } catch (e) {
      print("Error approving equipment: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ Reject equipment and send notification to user
  Future<void> _declineEquipment(
    String equipmentId,
    String ownerId,
    String itemName,
    String reason,
    BuildContext context,
  ) async {
    try {
      print("Rejecting equipment: $equipmentId");

      // 1. First, send notification to user
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUserId': ownerId,
        'title': '❌ Donation Declined',
        'message': 'Your donation "$itemName" has been declined. Reason: $reason',
        'type': 'donation_declined',
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Rejection notification sent");

      // 2. Then delete equipment
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(equipmentId)
          .delete();

      print("Equipment deleted from database");

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🗑️ Equipment rejected. User has been notified."),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      print("Error rejecting equipment: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ Show dialog for rejection reason
  void _showRejectionDialog(
    String equipmentId,
    String ownerId,
    String itemName,
    BuildContext context,
  ) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Equipment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for rejecting "$itemName"'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Item does not meet quality standards',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim().isNotEmpty
                  ? reasonController.text.trim()
                  : 'The item did not meet our requirements.';
              
              Navigator.pop(context);
              
              await _declineEquipment(
                equipmentId,
                ownerId,
                itemName,
                reason,
                context,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ Fetch owner email for better notification
  Future<String?> _getOwnerEmail(String ownerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['email'] as String?;
      }
      return null;
    } catch (e) {
      print("Error fetching owner email: $e");
      return null;
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
          _infoRow("Location", data['location']),
          
          const SizedBox(height: 8),

          const Text(
            "Description:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['description'] ?? 'No description available',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Reusable info row widget
  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
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
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B8D45),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No pending equipment to review.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    "All donations have been reviewed!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final equipmentId = doc.id;
              final data = doc.data() as Map<String, dynamic>;
              final ownerId = data['ownerId'] ?? '';
              final itemName = data['name'] ?? 'Equipment';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildEquipmentDetails(data),

                    const Divider(height: 1),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Reject button
                          OutlinedButton(
                            onPressed: () => _showRejectionDialog(
                              equipmentId,
                              ownerId,
                              itemName,
                              context,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: const Text("Reject"),
                          ),
                          const SizedBox(width: 12),
                          // Approve button
                          ElevatedButton(
                            onPressed: () => _approveEquipment(
                              equipmentId,
                              ownerId,
                              itemName,
                              context,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B8D45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: const Text(
                              "Approve",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
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