import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'user_reservations.dart'; // User's main activity hub
import 'adminReview.dart';
import 'admin_reservations.dart'; // Admin tasks page

// Converted to a StatefulWidget to add the "mark as read" feature
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ======================\
  // Main Build Function
  // ======================\
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please log in to see your notifications.'),
              const SizedBox(height: 12),
              // Using popUntil to navigate back to the initial/login screen
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Go to Login Page'),
              ),
            ],
          ),
        ),
      );
    }

    // Fetch user role to determine the appropriate view
    final roleStream = _firestore.collection('users').doc(user.uid).snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: roleStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Safe check for data and user role
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final role = data?['role'] ?? 'Renter'; // Safe default value

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            backgroundColor: const Color(0xFF6B8D45),
            foregroundColor: Colors.white,
          ),
          body: role == 'Admin'
              ? _buildAdminView(user.uid)
              : _buildUserView(user.uid),
        );
      },
    );
  }

Future<void> checkAndSendOverdueNotifications() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final now = DateTime.now();
  
  final overdueReservations = await FirebaseFirestore.instance
      .collection('reservations')
      .where('renterId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'Checked Out')
      .where('endDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
      .get();

  for (var doc in overdueReservations.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final equipmentName = data['equipmentName'] ?? 'equipment';
    final endDate = (data['endDate'] as Timestamp).toDate();
    final overdueDays = now.difference(endDate).inDays;

    final today = DateTime(now.year, now.month, now.day);
    final notificationExists = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: user.uid)
        .where('type', isEqualTo: 'overdue_alert')
        .where('relatedReservationId', isEqualTo: doc.id)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .get();

    if (notificationExists.docs.isEmpty && overdueDays > 0) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUserId': user.uid,
        'title': '⚠️ OVERDUE RENTAL',
        'message': 'Your rental for "$equipmentName" is $overdueDays days overdue. Please return immediately.',
        'type': 'overdue_alert',
        'relatedReservationId': doc.id,
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('📨 Sent overdue notification for: $equipmentName');
    }
  }
}



Widget _buildUserView(String uid) {
  print("👤 Building notifications for user: $uid");

   WidgetsBinding.instance.addPostFrameCallback((_) {
    checkAndSendOverdueNotifications();
  });

  
  final notificationStream = FirebaseFirestore.instance
      .collection('notifications')
      .where('toUserId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots();

  return StreamBuilder<QuerySnapshot>(
    stream: notificationStream,
    builder: (context, snapshot) {
      print("🔄 Stream state: ${snapshot.connectionState}");
      print("📊 Has data: ${snapshot.hasData}");
      
      if (snapshot.connectionState == ConnectionState.waiting) {
        print("⏳ Waiting for data...");
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        print("❌ Stream error: ${snapshot.error}");
        return Center(child: Text("Error: ${snapshot.error}"));
      }

      final docs = snapshot.data?.docs ?? [];
      print("📄 Number of notifications: ${docs.length}");
      
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        print("📨 Notification: ${data['title']} - ${data['type']}");
      }

      if (docs.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No notifications yet",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                "You'll see notifications here when you get them",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          final data = doc.data() as Map<String, dynamic>;
          final isRead = data['status'] == 'read';

          return _buildNotificationCard(
            id: doc.id,
            title: data['title'] ?? 'Notification',
            message: data['message'] ?? '',
            timestamp: _formatTimestamp(data['createdAt']),
            icon: _getIconForType(data['type']),
            isRead: isRead,
            type: data['type'],
            onTap: () {
              if (!isRead) {
                _markAsRead(doc.id);
              }
              
              _handleNotificationTap(data['type'], context);
            },
          );
        },
      );
    },
  );
}

Widget _buildNotificationCard({
  required String id,
  required String title,
  required String message,
  required String timestamp,
  required IconData icon,
  required bool isRead,
  required String? type,
  required VoidCallback onTap,
}) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: isRead ? Colors.white : const Color(0xFFE8F5E9),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRead 
                  ? Colors.grey.shade200 
                  : _getNotificationColor(type),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isRead ? Colors.grey : Colors.white,
                size: 20,
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
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 16,
                            color: isRead ? Colors.grey.shade700 : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timestamp,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Color _getNotificationColor(String? type) {
  switch (type) {
    case 'donation_approved':
    case 'reservation_approved':
      return Colors.green;
    case 'donation_declined':
    case 'reservation_declined':
      return Colors.red;
    default:
      return const Color(0xFF6B8D45);
  }
}


void _handleNotificationTap(String? type, BuildContext context) {
  switch (type) {
    case 'donation_approved':
    case 'donation_declined':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserReservationsPage(),
        ),
      );
      break;
    case 'reservation_approved':
    case 'reservation_declined':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserReservationsPage(),
        ),
      );
      break;
    default:
      break;
  }
}


  Widget _buildAdminView(String uid) {
  return ListView(
    padding: const EdgeInsets.all(12),
    children: [
      _sectionTitle('Admin Tasks & Reviews'),
      const Text(
        'Tasks requiring your review as an administrator are shown here.',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      ),
      const SizedBox(height: 16),

      // 1. Pending Reservation Requests Notifications
      _buildAdminAlerts(
        'Pending Reservation Requests',
        'reservations',
        'status',
        'Pending',
        Icons.calendar_today,
        const AdminReservationsPage(),
      ),
      const SizedBox(height: 16),

      // 2. New Donations (Unapproved Equipment) Notifications
      _buildAdminAlerts(
        'New Donations for Review',
        'equipment',
        'isApproved',
        false,
        Icons.medical_services,
        const AdminEquipmentReviewPage(),
      ),
      const SizedBox(height: 16),

      // 3. Quick Stats
      _sectionTitle('Quick Statistics'),
      _buildStatsSection(),
    ],
  );
}
  // ======================\
  // Admin Alert Widget (Pending Reservations/Unapproved Equipment)
  // ======================\
  Widget _buildAdminAlerts(
  String title,
  String collection,
  String field,
  dynamic value,
  IconData icon,
  Widget destinationPage,
) {
  return StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .limit(5)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final docs = snapshot.data?.docs ?? [];
      final count = docs.length;

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: count > 0 ? Colors.red.shade50 : Colors.green.shade50,
        child: ListTile(
          leading: Icon(
            icon,
            color: count > 0 ? Colors.red : const Color(0xFF6B8D45),
            size: 30,
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            count > 0 ? 'There are $count pending requests for review.' : 'No new requests.',
            style: TextStyle(
              color: count > 0 ? Colors.red : Colors.green.shade700,
            ),
          ),
          trailing: count > 0
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : const Icon(Icons.check, color: Colors.green),
          onTap: () {
            if (count > 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destinationPage),
              );
            }
          },
        ),
      );
    },
  );
}
Widget _buildStatsSection() {
  final equipmentStream = _firestore
      .collection('equipment')
      .where('isApproved', isEqualTo: true)
      .snapshots();

  return StreamBuilder<QuerySnapshot>(
    stream: equipmentStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final totalEquipment = snapshot.data?.docs.length ?? 0;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBox('Total Equipment', totalEquipment, const Color(0xFF6B8D45)),
          _statBox('Active Users', 24, Colors.blue),
          _statBox('Monthly Rentals', 15, Colors.orange),
        ],
      );
    },
  );
}

Widget _statBox(String title, int value, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    width: MediaQuery.of(context).size.width / 3.5,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

  // ======================\
  // Function to update notification status to "read"
  // ======================\
  void _markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'status': 'read',
      });
    } catch (e) {
      // Ignore error to maintain user experience
    }
  }

  // ======================\
  // Timestamp Formatting Function
  // ======================\
  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'N/A';

    final date = (ts as Timestamp).toDate();
    // Use a simple localized format (set locale to en_US for standard AM/PM)
    return DateFormat('yyyy/MM/dd - h:mm a', 'en_US').format(date);
  }

  // ======================\
  // Function to determine icon based on notification type
  // ======================\
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'reservation_approved':
        return Icons.check_circle_outline;
      case 'reservation_declined':
        return Icons.cancel_outlined;
      case 'donation_approved':
        return Icons.card_giftcard;
      case 'reservation_return_due':
        return Icons.warning_amber;
      default:
        return Icons.notifications_none;
    }
  }

  // =========================
  // Reusable Widgets
  // =========================

  Widget _notificationCard({
    required String id,
    required String title,
    required String message,
    required String timestamp,
    required IconData icon,
    required bool isRead,
    // ⭐ ADDED TYPE HERE
    String? type, 
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: isRead ? Colors.white : Colors.blue.shade50, // Highlight unread notifications
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRead ? Colors.grey : const Color(0xFF6B8D45),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 4),
            Text(
              timestamp,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        onTap: () {
          // Mark as read upon tap
          if (!isRead) {
            _markAsRead(id);
          }

          // ⭐ CONDITIONAL NAVIGATION LOGIC
          Widget destinationPage = const UserReservationsPage();

          // Determine the destination based on the notification type
          if (type == 'donation_approved') {
            // For donation approvals, navigate to the user's main hub
            destinationPage = const UserReservationsPage(); 
          } else if (type != null && type.startsWith('reservation')) {
            // For all reservation-related notifications
            destinationPage = const UserReservationsPage();
          }

          // Navigate to the determined page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationPage),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

}