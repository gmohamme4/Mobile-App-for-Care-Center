import 'package:flutter/material.dart';
import 'admin_reservations.dart';
import 'adminReview.dart';
import 'admin_reports.dart';


class AdminTasksPage extends StatelessWidget {
  const AdminTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // <== غيّر الطول إلى 3
      child: Scaffold(
        appBar: AppBar(
          // ... (بقية خصائص الـ AppBar)
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: "Reservations"),
              Tab(icon: Icon(Icons.medical_services), text: "Equipment Review"),
              Tab(icon: Icon(Icons.analytics), text: "Reports"), // <== أضف علامة التبويب الثالثة
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tab 1 — Reservations
            AdminReservationsPage(),

            // Tab 2 — Equipment Review
            AdminEquipmentReviewPage(),

            // Tab 3 — Reports <== أضف صفحة التقارير هنا
            AdminReportsPage(),
          ],
        ),
      ),
    );
  }
}
