import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserReservationsPage extends StatelessWidget {
  const UserReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Reservations')),
        body: const Center(
          child: Text('Please sign in to view your reservations.'),
        ),
      );
    }

    // Stream rent_requests for this renter
    final reservationsStream =
        FirebaseFirestore.instance
            .collection('reservations')
            .where('renterId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        backgroundColor: const Color(0xFF6B8D45),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: reservationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No reservations yet. Start by reserving an item!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final equipmentName =
                  data['equipmentName'] ?? 'Unknown Equipment';
              final status = data['status'] ?? 'Unknown';
              final startDate = data['startDate'];
              final endDate = data['endDate'];
              final rentalPrice = data['rentalPrice'] ?? 0;

              String startDateStr = 'N/A';
              String endDateStr = 'N/A';

              try {
                if (startDate is Timestamp) {
                  startDateStr = startDate.toDate().toString().split(' ')[0];
                }
                if (endDate is Timestamp) {
                  endDateStr = endDate.toDate().toString().split(' ')[0];
                }
              } catch (_) {}

              final statusColor = _getStatusColor(status);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              equipmentName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              border: Border.all(color: statusColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Start Date', startDateStr),
                      const SizedBox(height: 8),
                      _buildDetailRow('End Date', endDateStr),
                      const SizedBox(height: 8),
                      _buildDetailRow('Rental Price', '\$$rentalPrice/day'),
                      const SizedBox(height: 12),
                      if (status == 'Pending')
                        ElevatedButton.icon(
                          onPressed:
                              () => _cancelReservation(context, docs[index].id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel Reservation'),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'checked out':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelReservation(
    BuildContext context,
    String reservationId,
  ) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Reservation?'),
            content: const Text(
              'Are you sure you want to cancel this reservation?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await FirebaseFirestore.instance
                        .collection('reservations')
                        .doc(reservationId)
                        .update({'status': 'Cancelled'});
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reservation cancelled.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error cancelling reservation: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: const Text('Yes', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
