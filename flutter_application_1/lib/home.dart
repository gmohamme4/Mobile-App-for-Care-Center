import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "All";
  final PageController _pageController = PageController();
  int currentIndex = 0;
  bool isLoading = true;

  String? _userName;

  List<Map<String, dynamic>> _equipment = [];

  @override
  void initState() {
    super.initState();
    fetchItems();
    _checkUserAndFetchName();
  }

  Future<void> fetchItems() async {
    try {
      final data = await FirebaseFirestore.instance.collection("equipment").get();
      setState(() {
        _equipment = data.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching equipment: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkUserAndFetchName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          setState(() {
            _userName = userData.data()?['name'] ?? user.email; 
          });
        }
      } catch (e) {
        print("Error fetching user name: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredEquipment = _equipment.where((item) {
      bool matchesSearch = item['name'] != null &&
          (item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
           (item['description']?.toLowerCase() ?? "").contains(_searchQuery.toLowerCase()));
      bool matchesFilter = _selectedFilter == "All" ? true : item['type'] == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    Widget buildServiceChip(String label, IconData icon, bool isSelected) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          width: 110,
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFBFE699) : Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: isSelected ? Colors.white : Colors.grey[800]),
              SizedBox(height: 5),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
        ),
      );
    }

    Widget promoItem(String imageUrl) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              // Header
              Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Welcome to Pharmacy App,", 
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            if (_userName != null)
              Text(
                _userName!,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              )
            else
              Text(
                "Guest",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
          ],
        );
      },
    ),
  ],
),
              SizedBox(height: 20),

              // Search Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Search equipment...",
                    prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                    border: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Promo Carousel
              Container(
                height: 160,
                child: Stack(
                  children: [
                    PageView(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => currentIndex = index),
                      children: [
                        promoItem("https://picsum.photos/500/160?1"),
                        promoItem("https://picsum.photos/500/160?2"),
                        promoItem("https://picsum.photos/500/160?3"),
                        promoItem("https://picsum.photos/500/160?4"),
                      ],
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: 4,
                          effect: ExpandingDotsEffect(
                            activeDotColor: Color(0xFFBFE699),
                            dotColor: Colors.white.withOpacity(0.6),
                            dotHeight: 8,
                            dotWidth: 8,
                            expansionFactor: 3,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 25),

              // Services
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Popular services", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    buildServiceChip("All", Icons.apps, _selectedFilter == "All"),
                    SizedBox(width: 10),
                    buildServiceChip("Rental", Icons.shopping_cart, _selectedFilter == "Rental"),
                    SizedBox(width: 10),
                    buildServiceChip("Exchange", Icons.swap_horiz, _selectedFilter == "Exchange"),
                    SizedBox(width: 10),
                    buildServiceChip("Donation", Icons.favorite, _selectedFilter == "Donation"),
                  ],
                ),
              ),
              SizedBox(height: 25),

              // Last Equipments
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Last Equipments", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              SizedBox(height: 10),

              // Equipment Grid
       Expanded(
  child: isLoading
      ? Center(child: CircularProgressIndicator())
      : filteredEquipment.isEmpty
          ? Center(child: Text("No equipment found", style: TextStyle(fontSize: 16)))
          : GridView.builder(
              itemCount: filteredEquipment.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final item = filteredEquipment[index];
                int rating = item['condition'] ?? 0;

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => print("Clicked on ${item['name']}"),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          Text(
                            item['description'] ?? '',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),

                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFFBFE699),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item['type'] ?? '',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),

                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                Icons.star,
                                size: 16,
                                color: i < rating
                                    ? Color(0xFF6B8D45)
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
),

            ],
          ),
        ),
      ),
    );
  }
}
