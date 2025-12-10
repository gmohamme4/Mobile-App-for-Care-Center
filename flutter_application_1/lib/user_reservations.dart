import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class UserReservationsPage extends StatefulWidget {
  const UserReservationsPage({super.key});

  @override
  State<UserReservationsPage> createState() => _UserReservationsPageState();
}

class _UserReservationsPageState extends State<UserReservationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Add this function to manually check Firestore
  Future<void> _debugFirestoreData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    log('🔄 Debugging Firestore Data for user: ${user.uid}', name: 'Reservations');
    
    try {
      // Check all reservations
      final allReservations = await _firestore
          .collection('reservations')
          .get();
      
      log('📊 Total reservations in database: ${allReservations.docs.length}', name: 'Reservations');
      
      // Check user's specific reservations
      final userReservations = allReservations.docs
          .where((doc) {
            final data = doc.data();
            final renterId = data['renterId'];
            log('Checking doc ${doc.id}: renterId=$renterId, user=${user.uid}', name: 'Reservations');
            return renterId == user.uid;
          })
          .toList();
      
      log('✅ User-specific reservations found: ${userReservations.length}', name: 'Reservations');
      
      for (var doc in userReservations) {
        final data = doc.data();
        log('📄 Reservation: ${data['equipmentName']}, Status: ${data['status']}, ID: ${doc.id}', name: 'Reservations');
      }
      
      // Refresh the UI
      setState(() {});
      
    } catch (e) {
      log('❌ Error debugging Firestore: $e', name: 'Reservations');
    }
  }

  @override
  void initState() {
    super.initState();
    // Run debug when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugFirestoreData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Reservations')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 60, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'Please sign in to view your reservations.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 10),
              Text(
                'Your reservation data is linked to your account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    log('👤 Building reservations page for user: ${user.uid}', name: 'Reservations');

    // Stream reservations for this renter
    final reservationsStream = FirebaseFirestore.instance
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your reservations...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            log('❌ Stream error: ${snapshot.error}', name: 'Reservations');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading reservations',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _debugFirestoreData,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          log('📊 Stream returned ${docs.length} documents', name: 'Reservations');

          if (docs.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'No reservations found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'When you reserve equipment, it will appear here. '
                    'Make sure you are signed in with the same account you used to make reservations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Browse Equipment'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _debugFirestoreData,
                  icon: const Icon(Icons.search),
                  label: const Text('Check Database'),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              log('📦 Processing reservation ${index + 1}/${docs.length}: ${data['equipmentName']}', name: 'Reservations');
              
              final equipmentName = data['equipmentName'] ?? 'Unknown Equipment';
              final status = data['status'] ?? 'Pending';
              final startDate = data['startDate'];
              final endDate = data['endDate'];
              final rentalPrice = data['rentalPrice'] ?? 0;
              final renterId = data['renterId'] ?? '';

              String startDateStr = 'N/A';
              String endDateStr = 'N/A';
              int days = 0;
              double totalPrice = 0;

              try {
                if (startDate is Timestamp) {
                  startDateStr = _formatDate(startDate.toDate());
                }
                if (endDate is Timestamp) {
                  endDateStr = _formatDate(endDate.toDate());
                  if (startDate is Timestamp) {
                    days = endDate.toDate().difference(startDate.toDate()).inDays;
                    totalPrice = (rentalPrice as num).toDouble() * days;
                  }
                }
              } catch (e) {
                log('❌ Error parsing dates: $e', name: 'Reservations');
              }

              final statusColor = _getStatusColor(status);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  equipmentName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reservation ID: ${doc.id.substring(0, 8)}...',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Dates Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Start Date', startDateStr),
                            const SizedBox(height: 8),
                            _buildDetailRow('End Date', endDateStr),
                            const SizedBox(height: 8),
                            _buildDetailRow('Duration', '$days days'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Price Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Daily Rate', '\$$rentalPrice/day'),
                            const SizedBox(height: 8),
                            Divider(height: 1, color: Colors.green.shade300),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Cost',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '\$${totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF6B8D45),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Actions Section
                      if (status == 'Pending')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => _cancelReservation(context, doc.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Contact admin for modifications'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B8D45),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              child: const Text('Modify'),
                            ),
                          ],
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'returned':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelReservation(BuildContext context, String reservationId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text(
          'Are you sure you want to cancel this reservation? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Reservation'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await _firestore
                    .collection('reservations')
                    .doc(reservationId)
                    .update({'status': 'Cancelled'});
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reservation cancelled successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel Reservation', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDebugDialog(BuildContext context, String userId) async {
    try {
      final allReservations = await _firestore
          .collection('reservations')
          .get();
      
      final userReservations = allReservations.docs
          .where((doc) => doc.data()['renterId'] == userId)
          .toList();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debug Information'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('User ID: $userId'),
                const SizedBox(height: 8),
                Text('Total reservations in DB: ${allReservations.docs.length}'),
                const SizedBox(height: 8),
                Text('Your reservations: ${userReservations.length}'),
                const SizedBox(height: 16),
                const Text('Your Reservations:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                ...userReservations.map((doc) {
                  final data = doc.data();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• ${data['equipmentName']} - ${data['status']}'),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}