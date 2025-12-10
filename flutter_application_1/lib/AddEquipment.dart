import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEquipmentPage extends StatefulWidget {
  final String? userRole;
  const AddEquipmentPage({super.key, this.userRole});

  @override
  _AddEquipmentPageState createState() => _AddEquipmentPageState();
}

class _AddEquipmentPageState extends State<AddEquipmentPage> {

  bool get isAdmin => widget.userRole == 'Admin';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  String selectedAvailability = 'available';
  final List<String> availabilityStatuses = [
    "available",
    "rented",
    "under maintenance",
  ];

  String? selectedType;
  int selectedCondition = 5;
  final List<String> types = ["Rental", "Exchange", "Donation"];

  @override
  void initState() {
    super.initState();
    if (!isAdmin) {
      selectedType = 'Donation';
    }
  }

  void saveItem() async {
    if (nameController.text.isEmpty || descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❗Please fill in all required fields"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    if (isAdmin && selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❗Please select the Equipment Type"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    double rentalPrice = isAdmin ? (double.tryParse(priceController.text) ?? 0.0) : 0.0;
    int quantity = int.tryParse(quantityController.text) ?? 1;

    try {
      Map<String, dynamic> data = {
        'name': nameController.text.trim(),
        'description': descController.text.trim(),
        'ownerId': FirebaseAuth.instance.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'condition': selectedCondition,
        'quantity': quantity,
        'location': locationController.text.trim(),
        'tags': [],
        'isApproved': false, 
      };

      if (isAdmin) {
        data['type'] = selectedType;
        data['availabilityStatus'] = selectedAvailability;
        data['rentalPricePerDay'] = rentalPrice;
      } else {
        data['type'] = 'Donation';
        data['availabilityStatus'] = 'available';
        }

      await FirebaseFirestore.instance.collection('equipment').add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "✔ Equipment added successfully! Waiting for admin approval."),
          backgroundColor: Colors.green,
        ),
      );

      nameController.clear();
      descController.clear();
      quantityController.clear();
      locationController.clear();
      priceController.clear();
      setState(() {
        selectedCondition = 5;
        if (isAdmin) {
          selectedType = null;
          selectedAvailability = 'available';
        }
      });
    } catch (e) {
      print("Error adding equipment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to add equipment. Error: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text(isAdmin ? "Add Equipment (Admin)" : "Donate Equipment"),
        backgroundColor: const Color(0xFFBFE699),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: "Equipment Name *"),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: "Description *"),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quantity",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: locationController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: "Location (Where is the item now?)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  if (isAdmin)
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Rental Price Per Day (Optional)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (isAdmin) const SizedBox(height: 15),

                  if (isAdmin)
                    DropdownButtonFormField<String>(
                      value: selectedAvailability,
                      decoration: const InputDecoration(
                        labelText: "Availability Status",
                      ),
                      items: availabilityStatuses.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedAvailability = newValue!;
                        });
                      },
                    ),
                  if (isAdmin) const SizedBox(height: 15),

                  if (isAdmin)
                    DropdownButtonFormField<String?>(
                      value: selectedType,
                      items: types.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value;
                        });
                      },
                      decoration:
                          const InputDecoration(labelText: "Select Type *"),
                    ),
                  if (isAdmin) const SizedBox(height: 15),

                  Row(
                    children: [
                      Text("Condition (1-5):",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isAdmin ? FontWeight.normal : FontWeight.bold)),
                      const SizedBox(width: 20),
                      DropdownButton<int>(
                        value: selectedCondition,
                        items: [1, 2, 3, 4, 5].map((value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCondition = value!;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saveItem,
                      child: Text(isAdmin ? "Add Equipment" : "Submit Donation"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}