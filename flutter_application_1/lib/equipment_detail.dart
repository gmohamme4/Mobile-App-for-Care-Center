import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedQuantity = 1;
    _checkUserRole();
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
            _isLoadingRole = false;
          });
        }
      } catch (e) {
        print("Error fetching user role: $e");
        setState(() {
          _isLoadingRole = false;
        });
      }
    } else {
      setState(() {
        _isLoadingRole = false;
      });
    }
  }

  Future<void> _deleteEquipment() async {
    try {
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(widget.equipmentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✔ Equipment deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error deleting equipment: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipment = widget.equipment;
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
    final isAvailable = widget.equipment['availabilityStatus'] == 'available';

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
                            equipment: widget.equipment,
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
