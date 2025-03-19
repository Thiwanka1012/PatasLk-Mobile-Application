// Firebase Firestore package for database operations
import 'package:cloud_firestore/cloud_firestore.dart';
// Firebase Authentication package for user authentication
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/user_type_screen.dart';
import 'home_screen.dart';
import '../profile/profile_screen.dart';
import '../ratings/rating_screen.dart';
import '../referral/refer_friend_screen.dart';
import 'contact_us_screen.dart';
import 'notification_screen.dart';
import '../payment/payment_methods_screen.dart';
// Helper utility for Firebase Firestore operations
import '../../../utils/firebase_firestore_helper.dart';
import '../../../utils/firebase_auth_helper.dart'; // Add Firebase Auth Helper import

class CustomerMenuScreen extends StatelessWidget {
  const CustomerMenuScreen({super.key});

  // Firebase Firestore: Collection name for customers
  final String _customersCollection = 'customers';

  Future<void> _showLogoutDialog(BuildContext context) {
    final FirebaseAuthHelper authHelper = FirebaseAuthHelper(); // Create instance
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE67E22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Come back soon!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want\nto logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    // Sign out the user first, then navigate
                    await authHelper.signOut();
                    
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const UserTypeScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Yes, Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Firebase Authentication: Get the current user
    final User? currentUser = FirebaseAuth.instance.currentUser;
    // Firebase Firestore: Helper for database operations
    final FirestoreHelper firestoreHelper = FirestoreHelper();

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: SafeArea(
        child: Column(
          children: [
            // Profile Section with fetched name and profile image from Firebase
            StreamBuilder<DocumentSnapshot>(
              // Firebase Firestore: Stream user profile for real-time updates
              stream: firestoreHelper.getUserStream(
                collection: _customersCollection,
                uid: currentUser?.uid ?? '',
              ),
              builder: (context, snapshot) {
                String name = 'Your Name';
                String? profileImageUrl;
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  // Firebase Firestore: Extract user data from document snapshot
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  name = data['firstName'] ?? name;
                  profileImageUrl = data['profileImageUrl'];
                }
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerProfileScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white54,
                            child: profileImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: CachedNetworkImage(
                                      imageUrl: profileImageUrl,
                                      fit: BoxFit.cover,
                                      width: 60,
                                      height: 60,
                                      placeholder: (context, url) => const CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                      errorWidget: (context, url, error) => 
                                          const Icon(Icons.person, size: 40, color: Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 20),
            // Menu Items
            _buildMenuItem(
              Icons.home_outlined,
              'Home',
              () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
            ),
            _buildMenuItem(
              Icons.payment_outlined,
              'Payments Methods',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
                );
              },
            ),
            _buildMenuItem(
              Icons.notifications_outlined,
              'Notifications',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
            _buildMenuItem(
              Icons.star_outline,
              'Rate',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RatingScreen()),
                );
              },
            ),
            _buildMenuItem(
              Icons.person_add_outlined,
              'Refer a Friend',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReferFriendScreen()),
                );
              },
            ),
            _buildMenuItem(
              Icons.support_agent_outlined,
              'Support',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactUsScreen()),
                );
              },
            ),
            const Spacer(),
            // Logout Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.white, size: 24),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onTap: () => _showLogoutDialog(context),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
