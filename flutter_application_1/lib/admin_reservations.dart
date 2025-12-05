
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

      // ... (Success message)
    } catch (e) {
      // ... (Error message)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin: Manage Reservations"), backgroundColor: const Color(0xFF6B8D45)),
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
              
              // ... (Date formatting)

              return Card(
                child: Column(
                  // ... (Reservation details display)
                  children: [
                    // ... (Details)
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
              );
            },
          );
        },
      ),
    );
  }
}