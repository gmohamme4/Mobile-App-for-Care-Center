import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ReservationPage extends StatefulWidget {
  final Map<String, dynamic> equipment;
  final String equipmentId;

  const ReservationPage({
    super.key,
    required this.equipment,
    required this.equipmentId,
  });

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubmitting = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isStart
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now().add(const Duration(days: 1))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitReservation() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to make a reservation.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date must be before end date.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _firestore
          .collection('reservations')
          .add({
            'equipmentId': widget.equipmentId,
            'equipmentName': widget.equipment['name'] ?? 'Unknown',
            'renterId': user.uid,
            'startDate': _startDate,
            'endDate': _endDate,
            'rentalPrice': widget.equipment['rentalPricePerDay'] ?? 0,
            'status': 'Pending',
            'timestamp': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation submitted! Check your reservations page.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on TimeoutException catch (te) {
      print('Timeout submitting reservation: $te');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timeout submitting reservation. Check your network.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e, st) {
      print('Error submitting reservation: $e');
      print(st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentName = widget.equipment['name'] ?? 'Equipment';
    final description = widget.equipment['description'] ?? '';
    final rentalPrice = widget.equipment['rentalPricePerDay'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reserve: $equipmentName'),
        backgroundColor: const Color(0xFF6B8D45),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              equipmentName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (description.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(description),
                  const SizedBox(height: 20),
                ],
              ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rental Price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$$rentalPrice/day',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Select Rental Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF6B8D45),
                ),
                title: Text(
                  _startDate == null
                      ? 'Select Start Date'
                      : 'Start: ${_startDate!.toString().split(' ')[0]}',
                ),
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF6B8D45),
                ),
                title: Text(
                  _endDate == null
                      ? 'Select End Date'
                      : 'End: ${_endDate!.toString().split(' ')[0]}',
                ),
                onTap: () => _selectDate(context, false),
              ),
            ),
            const SizedBox(height: 20),

            if (_startDate != null && _endDate != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duration'),
                        Text(
                          '${_endDate!.difference(_startDate!).inDays} days',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Cost'),
                        Text(
                          '\$${(rentalPrice * _endDate!.difference(_startDate!).inDays).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B8D45),
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Confirm Reservation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
