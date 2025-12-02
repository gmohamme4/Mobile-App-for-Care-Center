import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'login.dart';
import 'Search.dart';
import 'AddEquipment.dart';
import 'Notifications.dart';
import 'profile.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "YOUR_API_KEY",
        authDomain: "YOUR_AUTH_DOMAIN",
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_STORAGE_BUCKET",
        messagingSenderId: "YOUR_MSG_ID",
        appId: "YOUR_APP_ID",
        measurementId: "YOUR_MEASUREMENT_ID",
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
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    AddEquipmentPage(),
    NotificationsPage(),
    Container(), // Placeholder for Profile (handled separately)
  ];

  void _onItemTapped(int index) async {
    if (index == 4) {
      // Profile index
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Not logged in → go to Login
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        // Logged in → go to Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage()),
        );
      }
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  BottomNavigationBarItem _navItem(IconData icon, int index) {
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        size: _selectedIndex == index ? 30 : 24,
        color: _selectedIndex == index ? Color(0xFF6B8D45) : Colors.grey,
      ),
      label: '',
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
          _navItem(Icons.search, 1),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration:
                  BoxDecoration(color: Color(0xFF6B8D45), shape: BoxShape.circle),
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
            label: "",
          ),
          _navItem(Icons.notifications, 3),
          _navItem(Icons.person, 4),
        ],
      ),
    );
  }
}
