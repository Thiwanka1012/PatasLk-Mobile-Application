import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/user_type_screen.dart';
import '../profile/service_provider_profile_screen.dart';
import 'service_provider_notification_screen.dart';
import '../ratings/service_provider_rating_screen.dart';
import 'service_provider_support_screen.dart';
import '../../../utils/firebase_firestore_helper.dart';
import '../../../utils/firebase_auth_helper.dart'; // Add this import
import 'service_provider_home_screen.dart';

class ServiceProviderMenuScreen extends StatelessWidget {
  const ServiceProviderMenuScreen({super.key});

  // Firestore collection name for service providers
  final String _providersCollection = 'serviceProviders';

  Future<void> _showLogoutDialog(BuildContext context) {
    final FirebaseAuthHelper authHelper = FirebaseAuthHelper(); // Create instance
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Come back soon!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want\nto logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Yes, Logout',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.w500),
                    ),
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
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get Firebase Auth current user
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final FirestoreHelper firestoreHelper = FirestoreHelper();

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: SafeArea(
        child: Column(
          children: [
            // Firebase Firestore stream to get real-time service provider data
            StreamBuilder<DocumentSnapshot>(
              stream: firestoreHelper.getUserStream(
                collection: _providersCollection,
                uid: currentUser?.uid ?? '',
              ),
              builder: (context, snapshot) {
                String name = 'Provider';
                String? profileImageUrl;
                
                // Parse Firestore document data
                if (snapshot.hasData && snapshot.data!.exists) {
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
                        MaterialPageRoute(builder: (context) => const ServiceProviderProfileScreen()),
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
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 20),
            _buildMenuItem(
              Icons.home_outlined,
              'Home',
              () {
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (context) => const ServiceProviderHomeScreen()),
                );
              },
            ),
            _buildMenuItem(
              Icons.campaign,
              'Advertisement',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Advertisement feature will be available in future updates!'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF0D47A1),
                  ),
                );
              },
            ),
            _buildMenuItem(
              Icons.notifications,
              'Notification',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServiceProviderNotificationScreen()),
                );
              },
            ),
            _buildMenuItem(
              Icons.star,
              'Rate',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServiceProviderRatingScreen()),
                );
              },
            ),
            _buildMenuItem(
              Icons.support_agent,
              'Support',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServiceProviderSupportScreen()),
                );
              },
            ),
            const Spacer(),
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
