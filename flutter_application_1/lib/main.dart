import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'signup.dart';
import 'home.dart';
import 'login.dart';
import 'AddEquipment.dart';
import 'profile.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'admin_reservations.dart';
import 'adminReview.dart';
import 'adminTasks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyB1AcSm3A2DvTsQ3UxKc9cgpi1dXkf8KkE",
        authDomain: "appfb-60b59.firebaseapp.com",
        projectId: "appfb-60b59",
        storageBucket: "appfb-60b59.firebasestorage.app",
        messagingSenderId: "332194770960",
        appId: "1:332194770960:web:29480c6509e6bc587a1a95",
        measurementId: "G-MKQVLZB88W",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Care Center App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoadingRole = true;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _pages = _buildPages();
  }

  Widget _buildAuthProtectedPage(Widget loggedInPage) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        if (user == null) {
          return LoginPage(
            onSignupTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SignupPage()),
              );
            },
          );
        } else {
          return loggedInPage;
        }
      },
    );
  }

  List<Widget> _buildPages() {
    final String? role = _userRole;
    return [
      const HomePage(),

      _buildAuthProtectedPage(
        _userRole == 'Donor' || _userRole == 'Admin'
            ? const AdminTasksPage()
            : const Center(
                child: Text('User Reservations Page (Placeholder)'),
              ),
      ),

     _buildAuthProtectedPage(
        AddEquipmentPage(userRole: role),
      ),

    _buildAuthProtectedPage(
        const ProfilePage(),
      ),
    ];
  }


  void _checkUserRole() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        try {
          DocumentSnapshot doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (doc.exists) {
            setState(() {
              _userRole = doc.get('role');
              _isLoadingRole = false;
              _pages = _buildPages();
            });
          } else {
            setState(() {
              _userRole = 'Renter';
              _isLoadingRole = false;
              _pages = _buildPages();
            });
          }
        } catch (e) {
          print("Error fetching user role: $e");
          setState(() {
            _userRole = 'Renter';
            _isLoadingRole = false;
            _pages = _buildPages();
          });
        }
      } else {
        setState(() {
          _userRole = null;
          _isLoadingRole = false;
          _pages = _buildPages();
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  BottomNavigationBarItem _navItem(IconData icon, int index) {
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        color: _selectedIndex == index ? const Color(0xFF6B8D45) : Colors.grey,
      ),
      label: "",
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6B8D45),
        items: [
          _navItem(Icons.home, 0),
          _navItem(
              _userRole == 'Admin'
                  ? Icons.supervised_user_circle
                  : Icons.calendar_today,
              1),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: Color(0xFF6B8D45), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            label: "",
          ),
          _navItem(Icons.person, 3),
        ],
      ),
    );
  }
}