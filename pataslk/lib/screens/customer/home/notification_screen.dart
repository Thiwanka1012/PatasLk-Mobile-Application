import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services_screen.dart';
import '../booking/order_status_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _sortBy = 'recent';

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications')),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Notification',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Text(
              _sortBy == 'recent' ? 'Recent' : 'Oldest',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'recent',
                child: Text('Recent'),
              ),
              const PopupMenuItem(
                value: 'oldest',
                child: Text('Oldest'),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: _sortBy == 'recent')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final notifications = snapshot.data?.docs ?? [];
          
          _markNotificationsAsRead(notifications);
          
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          
          return ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              return _buildNotificationCard(
                notification: notification,
                notificationId: notifications[index].id,
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildNotificationCard({
    required Map<String, dynamic> notification, 
    required String notificationId
  }) {
    final DateTime createdAt = (notification['createdAt'] as Timestamp).toDate();
    final String formattedTime = DateFormat('dd MMM, hh:mm a').format(createdAt);
    final String title = notification['title'] ?? 'Notification';
    final String message = notification['message'] ?? '';
    final String type = notification['type'] ?? 'general';
    final String? bookingId = notification['bookingId'];
    
    IconData notificationIcon;
    Color iconColor;
    
    switch (type) {
      case 'completed':
        notificationIcon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'inProgress':
        notificationIcon = Icons.engineering;
        iconColor = Colors.blue;
        break;
      case 'approval':
        notificationIcon = Icons.pending_actions;
        iconColor = Colors.orange;
        break;
      default:
        notificationIcon = Icons.notifications;
        iconColor = Colors.blue;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          if (bookingId != null) {
            _navigateToBookingDetails(bookingId);
          }
        },
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(notificationIcon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 8),
            Text(
              formattedTime,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () {
                _deleteNotification(notificationId);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/Assets-main/Assets-main/No notofications.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          const Text(
            'No Notifications!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You don\'t have any notifications yet. Please\nplace order',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ServicesScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'View all services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _markNotificationsAsRead(List<QueryDocumentSnapshot> notifications) async {
    final batch = FirebaseFirestore.instance.batch();
    
    for (final doc in notifications) {
      final notificationData = doc.data() as Map<String, dynamic>;
      if (notificationData['read'] != true) {
        batch.update(doc.reference, {'read': true});
      }
    }
    
    await batch.commit();
  }
  
  Future<void> _deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }
  
  void _navigateToBookingDetails(String bookingId) async {
    try {
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();
          
      if (bookingDoc.exists && context.mounted) {
        final data = bookingDoc.data() as Map<String, dynamic>;
        
        final serviceName = data['serviceName'] ?? 'Unknown Service';
        final serviceType = data['serviceType'] ?? '';
        final bookingDateTs = data['bookingDate'] as Timestamp?;
        final bookingDate = bookingDateTs != null ? bookingDateTs.toDate() : null;
        final bookingTimeStr = data['bookingTime'] as String?;
        final description = data['description'] ?? '';
        final address = data['location'] ?? '';
        final imageUrl = data['imageUrl'] as String?;
        
        if (bookingDate != null && bookingTimeStr != null) {
          final timeString = bookingTimeStr.split(' ')[0];
          final timeParts = timeString.split(':');
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final timeOfDay = TimeOfDay(hour: hour, minute: minute);
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderStatusScreen(
                bookingId: bookingId,
                address: address,
                serviceType: serviceType,
                jobRole: serviceName,
                selectedDate: bookingDate,
                selectedTime: timeOfDay,
                description: description,
                uploadedImageUrl: imageUrl,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error navigating to booking details: $e');
    }
  }
}
