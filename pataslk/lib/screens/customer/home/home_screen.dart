// Firebase Firestore package for database operations
import 'package:cloud_firestore/cloud_firestore.dart';
// Firebase Authentication package for user authentication
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'menu_screen.dart';
import 'notification_screen.dart';
import '../services/all_categories_screen.dart';
import '../services/service_category_screen.dart';
import '../services_screen.dart';
import '../profile/profile_screen.dart'; // Add import for profile screen
// Helper utility for Firebase Firestore operations
import '../../../utils/firebase_firestore_helper.dart';
// Add this import
import '../../../utils/booking_expiry_checker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase Firestore helper instance
  final FirestoreHelper _firestoreHelper = FirestoreHelper();
  // Firebase Authentication: Get current logged in user
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  int _unreadNotificationCount = 0;
  // Firebase Firestore: Stream for real-time notification updates
  Stream<QuerySnapshot>? _notificationStream;
  final BookingExpiryChecker _expiryChecker = BookingExpiryChecker();

  @override
  void initState() {
    super.initState();
    _initNotificationStream();
    _checkExpiredBookings();
  }

  Future<void> _checkExpiredBookings() async {
    await _expiryChecker.checkExpiredBookings();
  }

  void _initNotificationStream() {
    if (_currentUser != null) {
      // Firebase Firestore: Create real-time stream of unread notifications
      _notificationStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('read', isEqualTo: false)
          .snapshots();
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) { // Notification tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationScreen()),
      );
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ServicesScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CustomerMenuScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in.')),
      );
    }
    // Firebase Firestore: Stream user data for real-time updates
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreHelper.getUserStream(collection: 'customers', uid: _currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error fetching data.')),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Firebase Firestore: Get user data from document snapshot
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        var firstName = userData['firstName'] ?? 'User';
        String? profileImageUrl = userData['profileImageUrl'];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CustomerMenuScreen()),
                );
              },
            ),
            title: Text(
              'Hello, $firstName',
              style: const TextStyle(color: Colors.black, fontSize: 18),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomerProfileScreen()),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: profileImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              imageUrl: profileImageUrl,
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                              placeholder: (context, url) => const CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                              errorWidget: (context, url, error) => 
                                  const Icon(Icons.person, color: Colors.grey),
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'What are you looking for today?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search what you need...',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Image.asset(
                              'assets/Assets-main/Assets-main/search icon.png',
                              height: 24,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  // Service Categories Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildServiceCategory(
                          'AC Repair',
                          'assets/Assets-main/Assets-main/Ac Repair.png',
                          const Color(0xFFFFE5D6),
                        ),
                        _buildServiceCategory(
                          'Beauty',
                          'assets/Assets-main/Assets-main/Beauty.png',
                          const Color(0xFFE4DEFF),
                        ),
                        _buildServiceCategory(
                          'Appliance',
                          'assets/Assets-main/Assets-main/Appliance.png',
                          const Color(0xFFDCF4FF),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AllCategoriesScreen()),
                            );
                          },
                          child: Text(
                            'See All',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Offer Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/Assets-main/Assets-main/Offer.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    // Firebase Firestore: Stream notifications for real-time badge updates
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationStream,
      builder: (context, snapshot) {
        int notificationCount = 0;
        if (snapshot.hasData && !snapshot.hasError) {
          // Firebase Firestore: Count unread notifications
          notificationCount = snapshot.data!.docs.length;
        }

        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0D47A1),
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (notificationCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          notificationCount > 9 ? '9+' : '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Notifications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: 'Menu',
            ),
          ],
        );
      },
    );
  }

  Widget _buildServiceCategory(String title, String imageUrl, Color backgroundColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ServiceCategoryScreen(serviceName: title)),
        );
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                imageUrl,
                width: 45,
                height: 45,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
