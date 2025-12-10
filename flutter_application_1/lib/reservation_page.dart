import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:developer';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSubmitting = false;
  
  // Add a flag to track if reservation was created
  bool _reservationCreated = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
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
          if (_startDate != null && _startDate!.isAfter(picked)) {
            _startDate = picked.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  // Add debug function to verify data before submission
  Future<void> _debugCurrentUser() async {
    final user = _auth.currentUser;
    log('👤 Current User Debug:', name: 'Reservation');
    log('   User ID: ${user?.uid}', name: 'Reservation');
    log('   Email: ${user?.email}', name: 'Reservation');
    log('   Display Name: ${user?.displayName}', name: 'Reservation');
    log('   Equipment ID: ${widget.equipmentId}', name: 'Reservation');
    log('   Equipment Name: ${widget.equipment['name']}', name: 'Reservation');
  }

  Future<void> _submitReservation() async {
    if (_reservationCreated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation already submitted. Please wait.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

    // Check if start date is in the past
    if (_startDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date cannot be in the past.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Call debug function before submission
    await _debugCurrentUser();

    setState(() {
      _isSubmitting = true;
      _reservationCreated = false;
    });

    log('🚀 Starting reservation submission...', name: 'Reservation');
    log('   Dates: $_startDate to $_endDate', name: 'Reservation');
    log('   User ID: ${user.uid}', name: 'Reservation');
    log('   Equipment ID: ${widget.equipmentId}', name: 'Reservation');

    try {
      // First, check if equipment is still available
      final equipmentDoc = await _firestore
          .collection('equipment')
          .doc(widget.equipmentId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!equipmentDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment no longer available.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final equipmentData = equipmentDoc.data() as Map<String, dynamic>;
      final isApproved = equipmentData['isApproved'] as bool? ?? false;
      final isAvailable = equipmentData['availabilityStatus'] == 'available';

      if (!isApproved || !isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This equipment is not available for reservation.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Prepare reservation data
      final reservationData = {
        'equipmentId': widget.equipmentId,
        'equipmentName': widget.equipment['name'] ?? 'Unknown Equipment',
        'equipmentType': widget.equipment['type'] ?? 'Rental',
        'renterId': user.uid,
        'renterName': user.displayName ?? user.email?.split('@').first ?? 'User',
        'renterEmail': user.email ?? '',
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'rentalPrice': (widget.equipment['rentalPricePerDay'] ?? 0).toDouble(),
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'durationDays': _endDate!.difference(_startDate!).inDays,
        'totalPrice': ((widget.equipment['rentalPricePerDay'] ?? 0).toDouble() * 
                      _endDate!.difference(_startDate!).inDays).toStringAsFixed(2),
      };

      log('📝 Reservation data prepared:', name: 'Reservation');
      log('   Data: $reservationData', name: 'Reservation');

      // Submit reservation
      final docRef = await _firestore
          .collection('reservations')
          .add(reservationData)
          .timeout(const Duration(seconds: 10));

      log('✅ Reservation created with ID: ${docRef.id}', name: 'Reservation');
      
      // Update equipment status to rented
      await _firestore
          .collection('equipment')
          .doc(widget.equipmentId)
          .update({
            'availabilityStatus': 'rented',
            'lastReserved': FieldValue.serverTimestamp(),
          });

      // Send notification to user
      await _firestore.collection('notifications').add({
        'toUserId': user.uid,
        'title': '✅ Reservation Submitted',
        'message': 'Your reservation for "${widget.equipment['name']}" has been submitted and is pending admin approval.',
        'type': 'reservation_submitted',
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
        'relatedReservationId': docRef.id,
      });

      setState(() {
        _reservationCreated = true;
      });

      if (!mounted) return;

      // Show success message with more details
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Reservation Successful!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your reservation for "${widget.equipment['name']}" has been submitted.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildReservationDetail('Dates', 
                      '${_startDate!.toString().split(' ')[0]} to ${_endDate!.toString().split(' ')[0]}'),
                    _buildReservationDetail('Duration', 
                      '${_endDate!.difference(_startDate!).inDays} days'),
                    _buildReservationDetail('Total Cost', 
                      '\$${((widget.equipment['rentalPricePerDay'] ?? 0).toDouble() * _endDate!.difference(_startDate!).inDays).toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can view and manage your reservations in "My Reservations" section.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close reservation page
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close reservation page
                // Optionally navigate to reservations page
              },
              child: const Text('View My Reservations'),
            ),
          ],
        ),
      );

    } on TimeoutException catch (te) {
      log('⏰ Timeout submitting reservation: $te', name: 'Reservation');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network timeout. Please check your connection and try again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } on FirebaseException catch (e) {
      log('🔥 Firebase error: ${e.code} - ${e.message}', name: 'Reservation');
      if (!mounted) return;
      
      String errorMessage = 'Error submitting reservation';
      if (e.code == 'permission-denied') {
        errorMessage = 'You don\'t have permission to make reservations.';
      } else if (e.code == 'unavailable') {
        errorMessage = 'Network unavailable. Please check your connection.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e, st) {
      log('❌ Error submitting reservation: $e', name: 'Reservation');
      log('Stack trace: $st', name: 'Reservation');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildReservationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final equipmentName = widget.equipment['name'] ?? 'Equipment';
    final description = widget.equipment['description'] ?? '';
    final rentalPrice = (widget.equipment['rentalPricePerDay'] ?? 0).toDouble();
    final equipmentType = widget.equipment['type'] ?? 'Rental';
    final condition = widget.equipment['condition'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reserve: ${equipmentName.length > 20 ? '${equipmentName.substring(0, 20)}...' : equipmentName}'),
        backgroundColor: const Color(0xFF6B8D45),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _debugCurrentUser,
            tooltip: 'Debug Info',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipmentName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Equipment Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Type', style: TextStyle(color: Colors.grey)),
                      Chip(
                        label: Text(equipmentType),
                        backgroundColor: const Color(0xFFBFE699),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Condition', style: TextStyle(color: Colors.grey)),
                      Row(
                        children: List.generate(5, (index) => Icon(
                          Icons.star,
                          size: 16,
                          color: index < condition ? Colors.orange : Colors.grey[300],
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daily Rate', style: TextStyle(color: Colors.grey)),
                      Text(
                        '\$$rentalPrice/day',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B8D45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date Selection
            const Text(
              'Select Rental Dates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose the period you want to reserve this equipment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Start Date Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B8D45).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF6B8D45),
                  ),
                ),
                title: Text(
                  _startDate == null
                      ? 'Select Start Date'
                      : 'Start Date',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _startDate == null
                      ? 'Tap to select'
                      : _startDate!.toString().split(' ')[0],
                ),
                trailing: _startDate == null
                    ? const Icon(Icons.arrow_forward_ios, size: 16)
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _startDate = null),
                      ),
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(height: 12),

            // End Date Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B8D45).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF6B8D45),
                  ),
                ),
                title: Text(
                  _endDate == null
                      ? 'Select End Date'
                      : 'End Date',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _endDate == null
                      ? 'Tap to select'
                      : _endDate!.toString().split(' ')[0],
                ),
                trailing: _endDate == null
                    ? const Icon(Icons.arrow_forward_ios, size: 16)
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _endDate = null),
                      ),
                onTap: () => _selectDate(context, false),
              ),
            ),
            const SizedBox(height: 24),

            // Summary Card (when dates are selected)
            if (_startDate != null && _endDate != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Reservation Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Duration', 
                      '${_endDate!.difference(_startDate!).inDays} days'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Daily Rate', '\$$rentalPrice/day'),
                    const Divider(height: 24, thickness: 1),
                    _buildSummaryRow(
                      'Total Cost',
                      '\$${(rentalPrice * _endDate!.difference(_startDate!).inDays).toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_startDate != null && _endDate != null && !_isSubmitting)
                    ? _submitReservation
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B8D45),
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_clock, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Confirm Reservation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            // Help Text
            if (_startDate == null || _endDate == null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Please select both start and end dates to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'What happens next?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Your reservation will be submitted for admin approval\n'
                    '2. You\'ll receive a notification when approved\n'
                    '3. View and manage all reservations in "My Reservations"\n'
                    '4. Contact admin for any modifications or cancellations',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? const Color(0xFF6B8D45) : Colors.black,
          ),
        ),
      ],
    );
  }
}