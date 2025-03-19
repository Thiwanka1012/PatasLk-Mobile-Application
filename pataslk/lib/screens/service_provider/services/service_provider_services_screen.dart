import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'service_provider_order_detail_screen.dart';

class ServiceProviderServicesScreen extends StatefulWidget {
  const ServiceProviderServicesScreen({Key? key}) : super(key: key);

  @override
  State<ServiceProviderServicesScreen> createState() =>
      _ServiceProviderServicesScreenState();
}

class _ServiceProviderServicesScreenState
    extends State<ServiceProviderServicesScreen> {
  // Firebase Auth: Get current authenticated user
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Track processed status changes to avoid duplicates
  final Map<String, String> _processedStatusChanges = {};

  @override
  void initState() {
    super.initState();
    _listenForBookingStatusChanges();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your bookings.'),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Bookings',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: const Color(0xFF0D47A1),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF0D47A1),
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
              Tab(text: 'Draft'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // UPCOMING: Only show active states
            _buildBookingsList(
              statusList: ['Pending', 'InProgress', 'PendingApproval'],
              emptyTitle: 'No Upcoming Order',
              emptyMessage:
                  'Currently you don\'t have any upcoming order.\nPlace and track your orders from here.',
            ),

            // HISTORY: Add Expired to History tab
            _buildBookingsList(
              statusList: ['Completed', 'Incomplete', 'Expired'],
              emptyTitle: 'No History Order',
              emptyMessage:
                  'Currently you don\'t have any completed order.\nPlace and track your orders from here.',
            ),

            // DRAFT: Draft (unchanged)
            _buildBookingsList(
              statusList: ['Draft'],
              emptyTitle: 'No Draft Order',
              emptyMessage:
                  'Currently you don\'t have any draft order.\nPlace and track your orders from here.',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a list of bookings from Firestore for the current provider
  /// that match the given [statusList].
  Widget _buildBookingsList({
    required List<String> statusList,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    return StreamBuilder<QuerySnapshot>(
      // Firebase Firestore: Query bookings collection with multiple filters
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('provider_id', isEqualTo: _currentUser!.uid)
          .where('status', whereIn: statusList)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _buildEmptyState(emptyTitle, emptyMessage);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _buildBookingCard(doc);
          },
        );
      },
    );
  }

  /// Builds an empty state widget with an image, title, message, and button.
  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/Assets-main/Assets-main/service png.png',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate back to home
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Go to Home',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a booking card for the "Upcoming" or "History" or "Draft" tab.
  Widget _buildBookingCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final bookingId = doc.id;
    final serviceName = data['serviceName'] ?? 'Unknown';
    final serviceType = data['serviceType'] ?? '';
    final status = data['status'] ?? 'InProgress';
    final bookingDateTs = data['bookingDate'] as Timestamp?;
    final bookingDate =
        bookingDateTs != null ? bookingDateTs.toDate() : DateTime.now();
    final bookingTime = data['bookingTime'] ?? '';
    
    // Handle the location data which could be either a String or a Map
    String locationDisplay = 'No location';
    if (data['location'] != null) {
      if (data['location'] is Map) {
        // New format: location is a map with address key
        final locationMap = data['location'] as Map<String, dynamic>;
        locationDisplay = locationMap['address'] as String? ?? 'No location';
      } else if (data['location'] is String) {
        // Old format: location is directly a string
        locationDisplay = data['location'] as String;
      }
    } else if (data['address'] != null && data['address'] is String) {
      // Fallback to address field if it exists
      locationDisplay = data['address'] as String;
    }
    
    final description = data['description'] ?? 'No description';
    final amount = data['amount'] ?? 0.0;
    final imageUrl = data['imageUrl'] as String?;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceProviderOrderDetailScreen(
              bookingId: bookingId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 2,
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
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
                    // Title row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            serviceName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Show service type if available
                    if (serviceType.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        serviceType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    // Date/Time
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          _formatSchedule(bookingDate, bookingTime),
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
                            locationDisplay, // Use locationDisplay instead of location
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
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
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Amount
                    Text(
                      'Rs $amount',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // If status is "InProgress" => show "Complete" button
                    if (status == 'InProgress')
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => _markAsPendingApproval(bookingId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Mark as Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                    // If status is "PendingApproval" => show a note
                    if (status == 'PendingApproval')
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber[700], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Waiting for customer to approve completion',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mark booking as Pending Approval (waiting for customer to approve completion)
  Future<void> _markAsPendingApproval(String bookingId) async {
    try {
      // Check if we already have a notification for this status
      final statusKey = '$bookingId:PendingApproval';
      if (_processedStatusChanges.containsKey(statusKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already marked as complete')),
        );
        return;
      }

      // Firebase Firestore: Get booking document by ID
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();
      
      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final serviceName = bookingData['serviceName'] ?? 'Unknown Service';
      final customerId = bookingData['customer_id'];
      
      // Firebase Firestore: Update booking status
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'PendingApproval'});
      
      // Create notifications for service provider and customer
      await _createProviderNotification(
        title: 'Job Marked as Complete',
        message: 'You marked $serviceName as complete. Awaiting customer approval.',
        bookingId: bookingId,
        type: 'status_change',
      );
      
      if (customerId != null) {
        await _createCustomerNotification(
          customerId: customerId,
          title: 'Job Completion Approval Required', 
          message: 'Your service provider has marked the $serviceName job as complete. Please review and approve.',
          bookingId: bookingId,
          type: 'approval',
        );
      }
      
      // Mark this status change as processed
      _processedStatusChanges[statusKey] = DateTime.now().toString();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job marked as complete. Waiting for customer approval.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('Error marking as pending approval: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to complete booking.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Create a notification for the service provider
  Future<void> _createProviderNotification({
    required String title,
    required String message,
    required String bookingId,
    required String type,
    double? amount,
  }) async {
    try {
      // Firebase Firestore: Add new provider notification document
      await FirebaseFirestore.instance.collection('provider_notifications').add({
        'providerId': _currentUser!.uid,
        'title': title,
        'message': message,
        'bookingId': bookingId,
        'type': type,
        'amount': amount,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(), // Firebase server timestamp
      });
    } catch (e) {
      debugPrint('Error creating provider notification: $e');
    }
  }

  /// Create a notification for the customer
  Future<void> _createCustomerNotification({
    required String customerId,
    required String title,
    required String message,
    required String bookingId,
    required String type,
  }) async {
    try {
      // Firebase Firestore: Add new customer notification document
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': customerId,
        'title': title,
        'message': message,
        'bookingId': bookingId,
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(), // Firebase server timestamp
      });
    } catch (e) {
      debugPrint('Error creating customer notification: $e');
    }
  }
  
  /// Listen for booking status changes that affect the service provider
  void _listenForBookingStatusChanges() {
    if (_currentUser == null) return;
    
    // Firebase Firestore: Real-time listener for booking changes
    FirebaseFirestore.instance
      .collection('bookings')
      .where('provider_id', isEqualTo: _currentUser!.uid)
      .snapshots()
      .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          // Only process modified documents
          if (change.type == DocumentChangeType.modified) {
            final bookingData = change.doc.data() as Map<String, dynamic>;
            final status = bookingData['status'] as String?;
            final bookingId = change.doc.id;
            
            // Skip if we've already processed this status for this booking
            final statusKey = '$bookingId:$status';
            if (_processedStatusChanges.containsKey(statusKey)) {
              continue;
            }
            
            // Process completed status change
            if (status == 'Completed') {
              final serviceName = bookingData['serviceName'] ?? 'Unknown Service';
              final amount = (bookingData['amount'] as num?)?.toDouble() ?? 0.0;
              
              _createProviderNotification(
                title: 'Payment Received',
                message: 'Customer approved completion of $serviceName service.',
                bookingId: bookingId,
                type: 'payment',
                amount: amount,
              );
              
              // Mark this status change as processed
              _processedStatusChanges[statusKey] = DateTime.now().toString();
              
              // Limit the size of the tracking map to prevent memory issues
              if (_processedStatusChanges.length > 100) {
                final oldestKey = _processedStatusChanges.keys.first;
                _processedStatusChanges.remove(oldestKey);
              }
            }
          }
        }
      });
  }

  /// Helper to format date/time.
  String _formatSchedule(DateTime date, String timeStr) {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    if (timeStr.isNotEmpty) {
      return '$timeStr, $dateStr';
    } else {
      return dateStr;
    }
  }

  /// Returns a color for each status.
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'InProgress':
        return Colors.blue;
      case 'PendingApproval':
        return Colors.amber;
      case 'Completed':
        return Colors.green;
      case 'Draft':
        return Colors.grey;
      case 'Incomplete':
        return Colors.red;
      case 'Expired':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
  
  /// Returns a display text for each status
  String _getStatusText(String status) {
    switch (status) {
      case 'PendingApproval':
        return 'Pending Approval';
      case 'InProgress':
        return 'In Progress';
      case 'Incomplete':
        return 'Incomplete';
      case 'Expired':
        return 'Expired';
      default:
        return status;
    }
  }
}
