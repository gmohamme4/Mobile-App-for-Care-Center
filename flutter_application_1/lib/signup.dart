import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  void signup() async {
    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❗The password and password confirmation do not match"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❗Please fill in all the required fields"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✔ Registration successful"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, "/");

    } on FirebaseAuthException catch (e) {
      String errorMessage;

      if (e.code == 'weak-password') {
        errorMessage = "❗The password is too weak. It must be at least 6 characters long";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "❗This email address is already in use. Please log in or use another email address";
      } else if (e.code == 'invalid-email') {
        errorMessage = "❗The email format is invalid";
      } else {
        errorMessage = "❗Registration failed. Code: ${e.code}.message: ${e.message}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.green),
    ),
    
    body: SingleChildScrollView( 
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo / Icon
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(Icons.person_add, size: 60, color: Colors.green),
              ),
              SizedBox(height: 30),

              // Card for Form
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Create Account",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 25),

                    // Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    SizedBox(height: 15),

                    // Email
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    SizedBox(height: 15),

                    // Phone
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(Icons.phone),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    SizedBox(height: 15),

                    // Password
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    SizedBox(height: 15),

                    // Confirm Password
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        prefixIcon: Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    SizedBox(height: 25),

                    // Signup Button with Gradient
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                            colors: [Color(0xFF6B8D45), Color(0xFFBFE699)]),
                      ),
                      child: ElevatedButton(
                        onPressed: signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                    // Login link
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Already have an account? Login",
                        style: TextStyle(
                            color: Colors.green,
                            decoration: TextDecoration.underline),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}