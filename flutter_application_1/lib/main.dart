import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/signup.dart';
import 'home.dart';
import 'login.dart';
import 'AddEquipment.dart';
import 'profile.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
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
      title: 'Medical Equipment App',
      theme: ThemeData(
        primaryColor: Color(0xFF6B8D45),
        scaffoldBackgroundColor: Color(0xFFF6F6F6),
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(),
      AddEquipmentPage(),
      Builder(builder: (_) {
        User? user = FirebaseAuth.instance.currentUser;
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
          return ProfilePage();
        }
      }),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  BottomNavigationBarItem _navItem(IconData icon, int index) {
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        color: _selectedIndex == index ? Color(0xFF6B8D45) : Colors.grey,
      ),
      label: "",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF6B8D45),
        items: [
          _navItem(Icons.home, 0),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration:
                  BoxDecoration(color: Color(0xFF6B8D45), shape: BoxShape.circle),
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
            label: "",
          ),
          _navItem(Icons.person, 2),
        ],
      ),
    );
  }
}