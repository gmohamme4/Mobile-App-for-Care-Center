import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'reservation_page.dart';

class EquipmentDetailPage extends StatefulWidget {
  final Map<String, dynamic> equipment;
  final String equipmentId;

  const EquipmentDetailPage({
    super.key,
    required this.equipment,
    required this.equipmentId,
  });

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  late int _selectedQuantity;
  String? _userRole;
  late Map<String, dynamic> _equipmentLocal;

  @override
  void initState() {
    super.initState();
    _selectedQuantity = 1;
    _checkUserRole();
    _equipmentLocal = Map<String, dynamic>.from(widget.equipment);
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userData.exists) {
          setState(() {
            _userRole = userData.data()?['role'];
          });
        }
      } catch (e) {
        print("Error fetching user role: $e");
      }
    }
  }

  Future<void> _deleteEquipment() async {
    final id = widget.equipmentId?.toString() ?? '';
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid equipment id'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 10));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✔ Equipment deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (e is TimeoutException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Operation timed out. Check network and try again.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error deleting equipment: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _approveEquipment() async {
    final id = widget.equipmentId?.toString() ?? '';
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid equipment id'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(id)
          .update({'isApproved': true})
          .timeout(const Duration(seconds: 10));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✔ Equipment approved successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (e is TimeoutException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Operation timed out. Check network and try again.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error approving equipment: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showEditDialog() async {
    final current = Map<String, dynamic>.from(_equipmentLocal);

    final nameCtrl = TextEditingController(
      text: (current['name'] ?? '').toString(),
    );
    final descCtrl = TextEditingController(
      text: (current['description'] ?? '').toString(),
    );
    final typeCtrl = TextEditingController(
      text: (current['type'] ?? '').toString(),
    );
    final locationCtrl = TextEditingController(
      text: (current['location'] ?? '').toString(),
    );
    final conditionCtrl = TextEditingController(
      text: (current['condition'] ?? '').toString(),
    );
    final quantityCtrl = TextEditingController(
      text: (current['quantity'] ?? '').toString(),
    );
    final priceCtrl = TextEditingController(
      text: (current['rentalPricePerDay'] ?? '').toString(),
    );
    final availabilityCtrl = TextEditingController(
      text: (current['availabilityStatus'] ?? '').toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Equipment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                TextField(
                  controller: conditionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Condition (0-5)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: quantityCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Rental Price Per Day',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: availabilityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Availability Status',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Build updated map
                final updated = <String, dynamic>{
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'type': typeCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                  'condition':
                      int.tryParse(conditionCtrl.text.trim()) ??
                      (current['condition'] ?? 0),
                  'quantity':
                      int.tryParse(quantityCtrl.text.trim()) ??
                      (current['quantity'] ?? 0),
                  'rentalPricePerDay':
                      double.tryParse(priceCtrl.text.trim()) ??
                      (current['rentalPricePerDay'] ?? 0),
                  'availabilityStatus': availabilityCtrl.text.trim(),
                };

                try {
                  final id = widget.equipmentId?.toString() ?? '';
                  if (id.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Invalid equipment id'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('equipment')
                      .doc(id)
                      .update(updated)
                      .timeout(const Duration(seconds: 10));

                  setState(() {
                    // merge updates into local equipment map
                    _equipmentLocal.addAll(updated);
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✔ Equipment updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error updating equipment: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final equipment = _equipmentLocal;
    final int condition = equipment['condition'] ?? 0;
    final int quantity = equipment['quantity'] ?? 0;
    final double rentalPrice = (equipment['rentalPricePerDay'] ?? 0).toDouble();
    final String type = equipment['type'] ?? 'Unknown';
    final String availability = equipment['availabilityStatus'] ?? 'Unknown';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text("Equipment Details"),
        backgroundColor: const Color(0xFF6B8D45),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Name
            Text(
              equipment['name'] ?? 'Unknown Equipment',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFBFE699),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                type,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rating Stars
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    size: 20,
                    color:
                        i < condition
                            ? const Color(0xFF6B8D45)
                            : Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Condition: $condition/5",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description Section
            Text(
              "Description",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              equipment['description'] ?? 'No description available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Details Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    "Location",
                    equipment['location'] ?? 'Not specified',
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    "Availability",
                    availability,
                    statusColor: _getAvailabilityColor(availability),
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    "Available Quantity",
                    "$quantity ${quantity == 1 ? 'unit' : 'units'}",
                  ),
                  if (type == 'Rental') ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      "Rental Price",
                      "\$${rentalPrice.toStringAsFixed(2)}/day",
                      isPrice: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quantity Selector (for rental/exchange)
            if (type != 'Donation' && quantity > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Quantity",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuantityButton(Icons.remove, () {
                        if (_selectedQuantity > 1) {
                          setState(() => _selectedQuantity--);
                        }
                      }),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Text(
                          _selectedQuantity.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildQuantityButton(Icons.add, () {
                        if (_selectedQuantity < quantity) {
                          setState(() => _selectedQuantity++);
                        }
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // Action Buttons
            if (type == 'Rental')
              _buildReservationButton(context)
            else if (type == 'Exchange')
              _buildExchangeButton()
            else
              _buildDonationButton(),

            // Admin Approve Button (only show if not approved)
            if (_userRole == 'Admin' &&
                !(equipment['isApproved'] as bool? ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _approveEquipment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      "Approve Equipment",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Admin Delete Button
            if (_userRole == 'Admin')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text("Delete Equipment"),
                              content: const Text(
                                "Are you sure you want to delete this equipment? This action cannot be undone.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteEquipment();
                                  },
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete),
                    label: const Text(
                      "Delete Item",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Admin Edit Button
            if (_userRole == 'Admin')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _showEditDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text(
                      "Edit Item",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? statusColor,
    bool isPrice = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color:
                statusColor ??
                (isPrice ? const Color(0xFF6B8D45) : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: const Color(0xFF6B8D45),
      ),
    );
  }

  Widget _buildReservationButton(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAvailable =
        (_equipmentLocal['availabilityStatus'] ?? '')
            .toString()
            .toLowerCase() ==
        'available';

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            isAvailable && user != null
                ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ReservationPage(
                            equipment: _equipmentLocal,
                            equipmentId: widget.equipmentId,
                          ),
                    ),
                  );
                }
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B8D45),
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isAvailable ? "Reserve Now" : "Not Available",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Exchange feature coming soon!"),
              backgroundColor: Colors.blue,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B8D45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Request Exchange",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDonationButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Donation request submitted!"),
              backgroundColor: Colors.green,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B8D45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Request Donation",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getAvailabilityColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'rented':
        return Colors.orange;
      case 'under maintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
