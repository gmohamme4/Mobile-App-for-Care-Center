import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReservationsPage extends StatelessWidget {
  const AdminReservationsPage({super.key});

  void _updateReservationStatus(String reservationId, String newStatus, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .update({'status': newStatus});

      // ✅ إرسال إشعار للمستخدم عند تغيير حالة الحجز
      final reservationDoc = await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .get();
      
      if (reservationDoc.exists) {
        final data = reservationDoc.data() as Map<String, dynamic>;
        final renterId = data['renterId'] ?? '';
        final equipmentName = data['equipmentName'] ?? 'Equipment';
        
        String notificationTitle = '';
        String notificationMessage = '';
        String notificationType = '';

        switch (newStatus) {
          case 'Checked Out':
            notificationTitle = '✅ Reservation Approved';
            notificationMessage = 'Your reservation for "$equipmentName" has been approved.';
            notificationType = 'reservation_approved';
            break;
          case 'Declined':
            notificationTitle = '❌ Reservation Declined';
            notificationMessage = 'Your reservation for "$equipmentName" has been declined.';
            notificationType = 'reservation_declined';
            break;
        }

        if (notificationTitle.isNotEmpty) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'toUserId': renterId,
            'title': notificationTitle,
            'message': notificationMessage,
            'type': notificationType,
            'status': 'unread',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Reservation $newStatus successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin: Manage Reservations"), 
        backgroundColor: const Color(0xFF6B8D45)
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No pending reservations."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              String reservationId = snapshot.data!.docs[index].id;
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              
              // تنسيق التواريخ
              String formatDate(Timestamp? timestamp) {
                if (timestamp == null) return 'N/A';
                return timestamp.toDate().toString().split(' ')[0];
              }

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['equipmentName'] ?? 'Unknown Equipment',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Renter: ${data['renterName'] ?? 'Unknown'}'),
                      Text('Start Date: ${formatDate(data['startDate'])}'),
                      Text('End Date: ${formatDate(data['endDate'])}'),
                      Text('Price: \$${data['rentalPrice'] ?? 0}/day'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _updateReservationStatus(reservationId, 'Declined', context),
                            child: const Text("Decline", style: TextStyle(color: Colors.red)),
                          ),
                          ElevatedButton(
                            onPressed: () => _updateReservationStatus(reservationId, 'Checked Out', context),
                            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6B8D45)),
                            child: const Text("Accept & Check Out", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
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