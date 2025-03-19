import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this import
import '../../../utils/firebase_firestore_helper.dart';
import 'service_provider_menu_screen.dart';
import 'service_provider_notification_screen.dart';
import '../services/service_provider_services_screen.dart';
import '../services/service_provider_order_detail_screen.dart';
import '../profile/service_provider_profile_screen.dart'; // Add this import

class ServiceProviderHomeScreen extends StatefulWidget {
  const ServiceProviderHomeScreen({Key? key}) : super(key: key);

  @override
  State<ServiceProviderHomeScreen> createState() =>
      _ServiceProviderHomeScreenState();
}

class _ServiceProviderHomeScreenState extends State<ServiceProviderHomeScreen> {
  // Firebase Auth reference to get current user
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirestoreHelper _firestoreHelper = FirestoreHelper();
  int _selectedIndex = 0;
  // Firebase Firestore stream for unread notifications
  Stream<QuerySnapshot>? _notificationStream;

  @override
  void initState() {
    super.initState();
    _initNotificationStream();
  }

  // Initialize Firebase notification stream for real-time updates
  void _initNotificationStream() {
    if (_currentUser != null) {
      _notificationStream = FirebaseFirestore.instance
          .collection('provider_notifications')
          .where('providerId', isEqualTo: _currentUser!.uid)
          .where('read', isEqualTo: false)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in.")),
      );
    }

    // Firebase Firestore stream for service provider data
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreHelper.getUserStream(
        collection: 'serviceProviders',
        uid: _currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Error fetching user data.")),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Parse Firestore document data
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final firstName = userData['firstName'] ?? 'Worker';
        final jobRole = userData['jobRole'] ?? 'Unknown Role';
        final profileImageUrl = userData['profileImageUrl']; // Get profile image URL
        final providerDistrict = userData['district']; // Get provider's district

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServiceProviderMenuScreen(),
                  ),
                );
              },
            ),
            title: Text(
              firstName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    // Navigate to profile screen when profile picture is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ServiceProviderProfileScreen(),
                      ),
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
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Greeting / Banner
                _buildBannerSection(firstName),
                // Now build the "Pending" jobs that match the provider's job role and district
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Bookings for $jobRole',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (providerDistrict != null && providerDistrict.isNotEmpty)
                        Text(
                          'Location: $providerDistrict',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildBookingsList(jobRole, providerDistrict),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  /// Builds the greeting/banner section at the top.
  Widget _buildBannerSection(String firstName) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'HELLO, $firstName',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              const Text('👋', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.work, color: Colors.brown, size: 24),
              const SizedBox(width: 8),
              Text(
                'Get More\nCustomers & Earn\nMore!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              'assets/Assets-main/Assets-main/service pro home.png',
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a list of "Pending" bookings matching the provider's jobRole and district.
  Widget _buildBookingsList(String jobRole, String? providerDistrict) {
    // If provider hasn't set their district yet, show a message to update profile
    if (providerDistrict == null || providerDistrict.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Please set your service location in your profile',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiceProviderProfileScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                ),
                child: const Text('Update Profile'),
              )
            ],
          ),
        ),
      );
    }
    
    // Firebase Firestore query for filtered bookings with real-time updates
    // Now also filtering by district
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceName', isEqualTo: jobRole)
          .where('status', isEqualTo: 'Pending')
          .where('district', isEqualTo: providerDistrict)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Error fetching bookings."),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 200,
              alignment: Alignment.center,
              child: Text(
                'No Pending Bookings for $jobRole in $providerDistrict',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _buildBookingCard(doc);
          },
        );
      },
    );
  }

  /// Builds a card for a single booking doc.
  Widget _buildBookingCard(DocumentSnapshot doc) {
    // Convert Firestore document to Map
    final data = doc.data() as Map<String, dynamic>;

    final referenceCode = data['referenceCode'] ?? doc.id;
    // Parse Firestore timestamp to DateTime
    final bookingDateTs = data['bookingDate'] as Timestamp?;
    final bookingDate =
        bookingDateTs != null ? bookingDateTs.toDate() : DateTime.now();
    final bookingTime = data['bookingTime'] ?? '';
    final description = data['description'] ?? 'No description';
    
    // Handle the location data which could be either a String or a Map
    String locationDisplay = 'Unknown location';
    if (data['location'] != null) {
      if (data['location'] is Map) {
        // New format: location is a map with address key
        final locationMap = data['location'] as Map<String, dynamic>;
        locationDisplay = locationMap['address'] as String? ?? 'Unknown location';
      } else if (data['location'] is String) {
        // Old format: location is directly a string
        locationDisplay = data['location'] as String;
      }
    } else if (data['address'] != null && data['address'] is String) {
      // Fallback to address field if it exists and is a string
      locationDisplay = data['address'] as String;
    }

    final imageUrl = data['imageUrl'] as String?; // Get image URL from document

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display image if available
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    height: 180,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + reference
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data['serviceName'] ?? 'Unknown Service',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ref: #${referenceCode.toString().substring(0, 6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Date/Time
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _formatBookingTime(bookingDate, bookingTime),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationDisplay, // Use the new variable here
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to order detail with doc.id
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceProviderOrderDetailScreen(
                              bookingId: doc.id,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(color: Colors.white),
                      ),
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

  /// Helper to format the date/time from booking doc.
  String _formatBookingTime(DateTime date, String bookingTime) {
    final dateStr = '${date.day}-${date.month}-${date.year}';
    if (bookingTime.isEmpty) return dateStr;
    return '$bookingTime, $dateStr';
  }

  /// Build bottom navigation bar with notification badge
  Widget _buildBottomNavigationBar() {
    // Firebase Firestore stream for unread notifications count
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationStream,
      builder: (context, snapshot) {
        int notificationCount = 0;
        if (snapshot.hasData && !snapshot.hasError) {
          notificationCount = snapshot.data!.docs.length;
        }

        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0D47A1),
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServiceProviderServicesScreen(),
                ),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ServiceProviderNotificationScreen(),
                ),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServiceProviderMenuScreen(),
                ),
              );
            }
          },
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
}
