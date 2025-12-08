import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please sign in to see your notifications.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Stream the user's role document so the UI adapts for Admin vs others
    final roleDoc =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: roleDoc,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role =
            (snapshot.hasData && snapshot.data!.exists)
                ? (snapshot.data!.get('role') as String?)
                : null;

        if (role == 'Admin') {
          return _buildAdminView(context);
        } else {
          return _buildUserView(context, user.uid);
        }
      },
    );
  }

  Widget _buildUserView(BuildContext context, String uid) {
    // Donations where this user is donor
    final donationsStream =
        FirebaseFirestore.instance
            .collection('donations')
            .where('donorId', isEqualTo: uid)
            .snapshots();

    // Rent requests where this user is renter
    final rentRequestsStream =
        FirebaseFirestore.instance
            .collection('rent_requests')
            .where('renterId', isEqualTo: uid)
            .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Donations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: donationsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const CircularProgressIndicator();
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Text('No donations found.');
                return Column(
                  children:
                      docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'unknown';
                        final title =
                            data['itemName'] ?? data['title'] ?? 'Donation';
                        return ListTile(
                          title: Text('$title'),
                          subtitle: Text('Status: $status'),
                          trailing:
                              status == 'accepted'
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                  : null,
                        );
                      }).toList(),
                );
              },
            ),

            const SizedBox(height: 16),
            const Text(
              'Rent Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: rentRequestsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const CircularProgressIndicator();
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty)
                  return const Text('No renting requests found.');
                return Column(
                  children:
                      docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'pending';
                        final title =
                            data['itemName'] ?? data['title'] ?? 'Request';
                        return ListTile(
                          title: Text('$title'),
                          subtitle: Text('Status: $status'),
                          trailing:
                              status == 'accepted'
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                  : null,
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminView(BuildContext context) {
    final donationsStream =
        FirebaseFirestore.instance.collection('donations').snapshots();
    final rentRequestsStream =
        FirebaseFirestore.instance.collection('rent_requests').snapshots();

    // Also look at rentals or rent_requests for commonly rented items
    final rentalsStream =
        FirebaseFirestore.instance.collection('rent_requests').snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications (Admin)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: donationsStream,
              builder: (context, dSnap) {
                final count = dSnap.hasData ? dSnap.data!.docs.length : 0;
                return ListTile(
                  title: const Text('Donations'),
                  subtitle: Text('Total donations: $count'),
                );
              },
            ),

            StreamBuilder<QuerySnapshot>(
              stream: rentRequestsStream,
              builder: (context, rSnap) {
                final count = rSnap.hasData ? rSnap.data!.docs.length : 0;
                return ListTile(
                  title: const Text('Renting Requests'),
                  subtitle: Text('Total requests: $count'),
                );
              },
            ),

            const SizedBox(height: 12),
            const Text(
              'Commonly Rented Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: rentalsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const CircularProgressIndicator();
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty)
                  return const Text('No rental data available.');

                final Map<String, int> counts = {};
                for (final d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final name =
                      (data['itemName'] ?? data['title'] ?? 'Unnamed')
                          as String;
                  counts[name] = (counts[name] ?? 0) + 1;
                }

                final items =
                    counts.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                return Column(
                  children:
                      items
                          .take(10)
                          .map(
                            (e) => ListTile(
                              title: Text(e.key),
                              trailing: Text('${e.value}'),
                            ),
                          )
                          .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
