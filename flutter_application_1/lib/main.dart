import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart';
import 'home.dart';
import 'login.dart';
import 'AddEquipment.dart';
import 'profile.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'notifications.dart';
import 'adminTasks.dart';
import 'user_reservations.dart';

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
      routes: {'/': (context) => MainScreen()},
      onGenerateRoute: (settings) {
        if (settings.name == '/notifications') {
          return MaterialPageRoute(builder: (_) => const NotificationsPage());
        }
        return null;
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
  int _unreadNotificationsCount = 0;
  StreamSubscription? _notificationsSubscription;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _pages = _buildPages();
    _startNotificationsListener();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _startNotificationsListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _subscribeToNotifications(user.uid);
      } else {
        setState(() {
          _unreadNotificationsCount = 0;
        });
      }
    });
  }

  void _subscribeToNotifications(String userId) {
    _notificationsSubscription?.cancel();
    
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = snapshot.docs.length;
        });
        print("📊 Unread notifications: $_unreadNotificationsCount");
      }
    }, onError: (error) {
      print("❌ Error listening to notifications: $error");
    });
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
            : const UserReservationsPage(),
      ),
      _buildAuthProtectedPage(AddEquipmentPage(userRole: role)),
      _buildAuthProtectedPage(const NotificationsPage()),
      _buildAuthProtectedPage(const ProfilePage()),
    ];
  }

  void _checkUserRole() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _userRole = null;
          _isLoadingRole = false;
          _pages = _buildPages();
        });
        return;
      }

      final uid = user.uid;
      if (uid.isEmpty) {
        if (!mounted) return;
        setState(() {
          _userRole = 'Renter';
          _isLoadingRole = false;
          _pages = _buildPages();
        });
        return;
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (!mounted) return;

        if (doc.exists) {
          final roleValue =
              (doc.data() is Map) ? (doc.get('role') as String?) : null;
          setState(() {
            _userRole = roleValue ?? 'Renter';
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
      } on TimeoutException catch (te) {
        print('Timeout fetching user role: $te');
        if (!mounted) return;
        setState(() {
          _userRole = 'Renter';
          _isLoadingRole = false;
          _pages = _buildPages();
        });
      } catch (e, st) {
        print('Error fetching user role: $e');
        print(st);
        if (!mounted) return;
        setState(() {
          _userRole = 'Renter';
          _isLoadingRole = false;
          _pages = _buildPages();
        });
      }
    });
  }

  void _onItemTapped(int index) {
    // إذا نقر على تبويب الإشعارات، امسح العداد
    if (index == 3 && _unreadNotificationsCount > 0) {
      _markAllNotificationsAsRead();
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _markAllNotificationsAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('toUserId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'unread')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'read',
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
        print("✅ Marked ${snapshot.docs.length} notifications as read");
      }
    } catch (e) {
      print("❌ Error marking notifications as read: $e");
    }
  }

  BottomNavigationBarItem _navItem(IconData icon, int index, {bool isNotification = false}) {
    return BottomNavigationBarItem(
      icon: isNotification && _unreadNotificationsCount > 0
          ? Stack(
              children: [
                Icon(
                  icon,
                  color: _selectedIndex == index ? const Color(0xFF6B8D45) : Colors.grey,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotificationsCount > 9 
                        ? '9+' 
                        : _unreadNotificationsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          : Icon(
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Care Center'),
        actions: [
          if (_unreadNotificationsCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadNotificationsCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
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
            1,
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF6B8D45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            label: "",
          ),
          _navItem(Icons.notifications, 3, isNotification: true),
          _navItem(Icons.person, 4),
        ],
      ),
    );
  }
}