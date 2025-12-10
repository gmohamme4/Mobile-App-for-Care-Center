import 'package:flutter/material.dart';
import 'admin_reservations.dart';
import 'adminReview.dart';
import 'admin_reports.dart';


class AdminTasksPage extends StatelessWidget {
  const AdminTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: "Reservations"),
              Tab(icon: Icon(Icons.medical_services), text: "Equipment Review"),
              Tab(icon: Icon(Icons.analytics), text: "Reports"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminReservationsPage(),

            AdminEquipmentReviewPage(),

            AdminReportsPage(),
          ],
        ),
      ),
    );
  }
}
