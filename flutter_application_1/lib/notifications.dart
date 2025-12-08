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
    // Load donations and rent requests streams without assuming exact field names.
    // We'll filter client-side so the UI is resilient to slightly different schemas
    // (e.g. 'donorId' vs 'donorID' or 'userId'). For larger datasets, replace
    // with indexed server-side queries matching your schema.
    final donationsStream =
        FirebaseFirestore.instance.collection('donations').snapshots();
    final rentRequestsStream =
        FirebaseFirestore.instance.collection('rent_requests').snapshots();

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

            // Debug view: raw donations documents (helpful if a user's pending donation is not appearing)
            StreamBuilder<QuerySnapshot>(
              stream: donationsStream,
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const SizedBox.shrink();
                return ExpansionTile(
                  title: Text('Debug: ${docs.length} donations'),
                  children:
                      docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final matches =
                            (data['donorId'] == uid) ||
                            (data['donorID'] == uid) ||
                            (data['userId'] == uid) ||
                            (data['ownerId'] == uid);
                        return ListTile(
                          title: Text(d.id),
                          subtitle: Text(data.toString()),
                          trailing:
                              matches
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
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: donationsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const CircularProgressIndicator();
                final docs = snap.data?.docs ?? [];

                // Find documents that belong to this user by checking several likely id fields.
                final matching =
                    docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final possibleFields = [
                        'donorId',
                        'donorID',
                        'userId',
                        'ownerId',
                      ];
                      for (final f in possibleFields) {
                        if (data.containsKey(f) && data[f] == uid) return true;
                      }
                      return false;
                    }).toList();

                if (matching.isEmpty) {
                  // If there are donations but none match, show a hint so the user can debug.
                  if (docs.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('No donations found for your account.'),
                        const SizedBox(height: 8),
                        const Text(
                          'Tip: confirm your user id is saved on the donation document (donorId).',
                        ),
                      ],
                    );
                  }
                  return const Text('No donations found.');
                }

                return Column(
                  children:
                      matching.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final rawStatus =
                            (data['status'] ?? 'unknown').toString();
                        final status = rawStatus.toLowerCase();
                        final title =
                            data['itemName'] ?? data['title'] ?? 'Donation';
                        return ListTile(
                          title: Text('$title'),
                          subtitle: Text('Status: ${rawStatus}'),
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

                // Filter to requests belonging to this user (cover common id field names)
                final matching =
                    docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final possibleFields = ['renterId', 'renterID', 'userId'];
                      for (final f in possibleFields) {
                        if (data.containsKey(f) && data[f] == uid) return true;
                      }
                      return false;
                    }).toList();

                if (matching.isEmpty) {
                  if (docs.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No renting requests found for your account.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tip: confirm your user id is saved on the request document (renterId).',
                        ),
                      ],
                    );
                  }
                  return const Text('No renting requests found.');
                }

                return Column(
                  children:
                      matching.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final rawStatus =
                            (data['status'] ?? 'pending').toString();
                        final status = rawStatus.toLowerCase();
                        final title =
                            data['itemName'] ?? data['title'] ?? 'Request';
                        return ListTile(
                          title: Text('$title'),
                          subtitle: Text('Status: ${rawStatus}'),
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
    final adminDonationsStream =
        FirebaseFirestore.instance
            .collection('donations')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .snapshots();
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
                final docs = dSnap.hasData ? dSnap.data!.docs : [];
                final total = docs.length;
                final pending =
                    docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final s = (data['status'] ?? '').toString().toLowerCase();
                      return s == 'pending' || s == 'pending' || s.isEmpty;
                    }).length;
                final accepted =
                    docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final s = (data['status'] ?? '').toString().toLowerCase();
                      return s == 'accepted' || s == 'accepted';
                    }).length;

                return ListTile(
                  title: const Text('Donations'),
                  subtitle: Text(
                    'Total: $total • Pending: $pending • Accepted: $accepted',
                  ),
                );
              },
            ),

            const SizedBox(height: 8),
            const Text(
              'Recent Donations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: adminDonationsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const CircularProgressIndicator();
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Text('No donations yet.');
                return Column(
                  children:
                      docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final title =
                            data['itemName'] ?? data['title'] ?? 'Donation';
                        final donorName =
                            (data['donorName'] ?? data['donor'] ?? '')
                                as String;
                        final donorEmail = (data['donorEmail'] ?? '') as String;
                        final donorId =
                            (data['donorId'] ??
                                    data['donorID'] ??
                                    data['userId'] ??
                                    '')
                                as String;
                        final rawStatus =
                            (data['status'] ?? 'unknown').toString();
                        final timestamp = data['timestamp'];
                        String when = '';
                        try {
                          if (timestamp is Timestamp) {
                            when =
                                DateTime.fromMillisecondsSinceEpoch(
                                  timestamp.millisecondsSinceEpoch,
                                ).toLocal().toString();
                          } else if (timestamp is Map &&
                              timestamp['_seconds'] != null) {
                            when =
                                DateTime.fromMillisecondsSinceEpoch(
                                  (timestamp['_seconds'] as int) * 1000,
                                ).toLocal().toString();
                          }
                        } catch (_) {}

                        return ListTile(
                          title: Text('$title'),
                          subtitle: Text(
                            'Status: $rawStatus\nDonor: ${donorName.isNotEmpty ? donorName : donorId}${donorEmail.isNotEmpty ? ' • $donorEmail' : ''}\n$when',
                          ),
                          isThreeLine: true,
                        );
                      }).toList(),
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
