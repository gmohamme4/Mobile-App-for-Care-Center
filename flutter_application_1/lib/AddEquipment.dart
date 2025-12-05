import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEquipmentPage extends StatefulWidget {
  const AddEquipmentPage({super.key});

  @override
  _AddEquipmentPageState createState() => _AddEquipmentPageState();
}

class _AddEquipmentPageState extends State<AddEquipmentPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  String? selectedType;
  int selectedCondition = 5;
  final List<String> types = ["Rental", "Exchange", "Donation"];

  void saveItem() async {
    if (nameController.text.isEmpty ||
        descController.text.isEmpty ||
        selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❗Please fill in all required fields"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      Map<String, dynamic> data = {
        'name': nameController.text.trim(),
        'description': descController.text.trim(),
        'type': selectedType,
        'ownerId': FirebaseAuth.instance.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'condition': selectedCondition,
      };

      await FirebaseFirestore.instance.collection('equipment').add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✔ Equipment added successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      nameController.clear();
      descController.clear();
      setState(() {
        selectedType = null;
        selectedCondition = 5;
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
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text("Add Equipment"),
        backgroundColor: Color(0xFFBFE699),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
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
                    decoration: InputDecoration(labelText: "Equipment Name"),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: "Description"),
                  ),
                  SizedBox(height: 15),

                  DropdownButtonFormField(
                    initialValue: selectedType,
                    items:
                        types.map((type) {
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
                    decoration: InputDecoration(labelText: "Select Type"),
                  ),
                  SizedBox(height: 15),

                  Row(
                    children: [
                      Text("Condition (1-5):", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 20),
                      DropdownButton<int>(
                        value: selectedCondition,
                        items:
                            [1, 2, 3, 4, 5].map((value) {
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

                  SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saveItem,
                      child: Text("Add Equipment"),
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
