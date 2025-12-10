import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Reports & Analytics"),
          backgroundColor: const Color(0xFF6B8D45),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Overdue Rentals", icon: Icon(Icons.warning_amber)),
              Tab(text: "Maintenance Logs", icon: Icon(Icons.build)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tab 1: Overdue Reservations
            _OverdueRentalsReport(),
            // Tab 2: Maintenance Logs
            _MaintenanceLogsReport(),
          ],
        ),
      ),
    );
  }
}

// ====================================================
// Widget للتقرير الأول: الإيجارات المتأخرة
// ====================================================
class _OverdueRentalsReport extends StatelessWidget {
  const _OverdueRentalsReport();

  @override
  Widget build(BuildContext context) {
    // جلب الحجوزات التي انتهى تاريخ إرجاعها ولم يتم وضع علامة "Returned" أو "Cancelled" عليها
    final overdueStream = FirebaseFirestore.instance
        .collection('reservations')
        .where('status', isEqualTo: 'Checked Out')
        .orderBy('endDate', descending: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: overdueStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

          final allDocs = snapshot.data?.docs ?? [];
          final overdueDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final endDateTimestamp = data['endDate'] as Timestamp?;
          if (endDateTimestamp == null) return false;
          
          return endDateTimestamp.toDate().isBefore(DateTime.now());
        }).toList();

        if (overdueDocs.isEmpty) {
          return const Center(
              child: Text("🎉 All checked out items are on time!"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: overdueDocs.length,
          itemBuilder: (context, index) {
            final data = overdueDocs[index].data() as Map<String, dynamic>;
            final itemName = data['itemName'] ?? 'Unknown Item';
            final renterName = data['renterName'] ?? 'Unknown User';
            final endDate = (data['endDate'] as Timestamp).toDate();
            final daysOverdue =
                DateTime.now().difference(endDate).inDays;

            return Card(
              color: Colors.red.shade50,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.timer_off, color: Colors.red),
                title: Text(itemName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    "Renter: $renterName\nDue Date: ${DateFormat.yMd().format(endDate)}"),
                trailing: Chip(
                  label: Text("Late by $daysOverdue days",
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red.shade700,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ====================================================
// Widget للتقرير الثاني: سجلات الصيانة
// ====================================================
class _MaintenanceLogsReport extends StatelessWidget {
  const _MaintenanceLogsReport();

  @override
  Widget build(BuildContext context) {
    // جلب جميع سجلات الصيانة
    final logsStream = FirebaseFirestore.instance
        .collection('maintenance_logs')
        .orderBy('dateResolved', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: logsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No maintenance records found."));
        }

        final logs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final data = logs[index].data() as Map<String, dynamic>;
            final itemName = data['itemName'] ?? 'Unknown Item';
            final dateResolved =
                (data['dateResolved'] as Timestamp?)?.toDate();
            final notes = data['notes'] ?? 'No notes provided.';

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF6B8D45)),
                title: Text(
                  itemName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notes, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(
                      "Resolved: ${dateResolved != null ? DateFormat.yMd().format(dateResolved) : 'N/A'}",
                      style:
                          TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}