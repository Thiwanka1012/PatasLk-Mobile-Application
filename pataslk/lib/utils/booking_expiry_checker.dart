import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingExpiryChecker {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Checks and updates expired bookings for the current user
  Future<void> checkExpiredBookings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Get current time
      final now = DateTime.now();
      
      // Query for pending bookings where expiresAt is earlier than now
      final snapshot = await _firestore.collection('bookings')
        .where('customer_id', isEqualTo: user.uid)
        .where('status', isEqualTo: 'Pending')
        .where('expiresAt', isLessThan: Timestamp.fromDate(now))
        .get();
      
      if (snapshot.docs.isEmpty) return;
      
      // Update expired bookings
      final batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        final bookingRef = _firestore.collection('bookings').doc(doc.id);
        batch.update(bookingRef, {
          'status': 'Expired',
          'expiryReason': 'Provider did not respond within 24 hours',
        });
        
        // Create notification about expiration
        final notificationRef = _firestore.collection('notifications').doc();
        final serviceName = doc.data()['serviceName'] ?? 'Unknown service';
        
        batch.set(notificationRef, {
          'userId': user.uid,
          'title': 'Booking Expired',
          'message': 'Your $serviceName booking has expired because no service provider responded in time.',
          'bookingId': doc.id,
          'type': 'booking_expired',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      print('Error checking expired bookings: $e');
    }
  }
}
