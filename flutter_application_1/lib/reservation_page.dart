
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationPage extends StatefulWidget {
  final Map<String, dynamic> equipment;
  final String equipmentId;

  const ReservationPage({super.key, required this.equipment, required this.equipmentId});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    // ... (Date Picker logic)
  }

  void _submitReservation() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _startDate == null || _endDate == null) {
      // ... (validation error)
      return;
    }

    try {
      await _firestore.collection('reservations').add({
        'equipmentId': widget.equipmentId,
        'equipmentName': widget.equipment['name'],
        'renterId': user.uid,
        'startDate': _startDate,
        'endDate': _endDate,
        'rentalPrice': widget.equipment['rentalPricePerDay'] ?? 0,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ... (success message and navigation back)
    } catch (e) {
      // ... (error handling)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reserve: ${widget.equipment['name']}"), backgroundColor: const Color(0xFF6B8D45)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (Equipment details display)
            
            // Start Date Picker UI
            ListTile(
              title: Text(_startDate == null ? "Select Start Date" : "Start Date: ${_startDate!.toString().split(' ')[0]}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            const Divider(),

            // End Date Picker UI
            ListTile(
              title: Text(_endDate == null ? "Select End Date" : "End Date: ${_endDate!.toString().split(' ')[0]}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            const Divider(),

            // ... (Total duration calculation if dates are selected)

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitReservation,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B8D45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text("Confirm Reservation", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}