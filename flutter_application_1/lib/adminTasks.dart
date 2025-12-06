import 'package:flutter/material.dart';
import 'admin_reservations.dart';
import 'adminReview.dart';

class AdminTasksPage extends StatelessWidget {
  const AdminTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Admin Dashboard",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF6B8D45),
          foregroundColor: Colors.white,
          elevation: 3,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                icon: Icon(Icons.calendar_today),
                text: "Reservations",
              ),
              Tab(
                icon: Icon(Icons.medical_services),
                text: "Equipment Review",
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tab 1 — Reservations
            AdminReservationsPage(),

            // Tab 2 — Equipment Review
            AdminEquipmentReviewPage(),
          ],
        ),
      ),
    );
  }
}
