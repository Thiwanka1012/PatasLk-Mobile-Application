import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Helper class for Firebase Firestore operations
class FirestoreHelper {
  // Firebase Firestore: Initialize firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Saves (or updates) user data in the specified [collection] using [uid] as the document ID.
  Future<void> saveUserData({
    required String collection,
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrint("Firestore: Saving data to $collection/$uid");
      // Add timestamp to track when this data was last updated
      final dataWithTimestamp = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Firebase Firestore: Write document with merge option to prevent overwriting existing fields
      await _firestore.collection(collection).doc(uid).set(
        dataWithTimestamp,
        SetOptions(merge: true)
      );
      
      debugPrint("Firestore: Data saved successfully to $collection/$uid");
    } catch (e) {
      debugPrint("Firestore: Error saving data to $collection/$uid: $e");
      rethrow; // Re-throw to allow proper error handling upstream
    }
  }

  /// Checks if a user exists in [collection] with the given [email].
  Future<bool> doesUserExist({
    required String collection,
    required String email,
  }) async {
    // Firebase Firestore: Query documents with where filter
    QuerySnapshot snapshot = await _firestore
        .collection(collection)
        .where('email', isEqualTo: email)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Checks if a customer exists in the "customers" collection with the given [phone].
  Future<bool> doesCustomerExistByPhone({required String phone}) async {
    // Firebase Firestore: Query customers collection by phone number
    QuerySnapshot snapshot = await _firestore
        .collection('customers')
        .where('phone', isEqualTo: phone)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Checks if a service provider exists in the "serviceProviders" collection with the given [phone].
  Future<bool> doesServiceProviderExistByPhone({required String phone}) async {
    // Firebase Firestore: Query serviceProviders collection by phone number
    QuerySnapshot snapshot = await _firestore
        .collection('serviceProviders')
        .where('phone', isEqualTo: phone)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Returns a stream of a user document from the given [collection] and [uid].
  Stream<DocumentSnapshot> getUserStream({
    required String collection,
    required String uid,
  }) {
    // Firebase Firestore: Create real-time document stream
    return _firestore.collection(collection).doc(uid).snapshots();
  }

  /// Get the user document as a snapshot
  Future<DocumentSnapshot?> getUserDocument({
    required String collection,
    required String uid,
  }) async {
    try {
      final docSnapshot = await _firestore.collection(collection).doc(uid).get();
      return docSnapshot.exists ? docSnapshot : null;
    } catch (e) {
      debugPrint("Firestore: Error getting user document: $e");
      rethrow;
    }
  }

  /// Adds a new notification, checking for duplicates before adding
  Future<void> addNotification({
    required String collectionName, // 'notifications' or 'provider_notifications'
    required String userId,
    required String title,
    required String message,
    String? type,
    String? bookingId,
    double? amount,
  }) async {
    try {
      // Check for duplicates in the last hour with the same title, message, and bookingId
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      
      QuerySnapshot existingNotifications = await _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .where('title', isEqualTo: title)
          .where('bookingId', isEqualTo: bookingId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .get();
      
      // If a duplicate exists, don't create another one
      if (existingNotifications.docs.isNotEmpty) {
        debugPrint('Duplicate notification prevented for $title to $userId');
        return;
      }
      
      // Create the notification with a unique ID
      DocumentReference notificationRef = _firestore.collection(collectionName).doc();
      
      await notificationRef.set({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type ?? 'general',
        'bookingId': bookingId,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'notificationId': notificationRef.id, // Include ID in the document for easy reference
      });
      
      debugPrint('Notification added to $collectionName: $title for $userId');
    } catch (e) {
      debugPrint('Error adding notification: $e');
      rethrow;
    }
  }
  
  /// Marks all unread notifications as read for a specific user
  Future<void> markAllNotificationsAsRead({
    required String collectionName,
    required String userId,
  }) async {
    try {
      QuerySnapshot unreadNotifications = await _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      
      // Use a batch for efficient updates
      WriteBatch batch = _firestore.batch();
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'read': true});
      }
      
      await batch.commit();
      debugPrint('Marked ${unreadNotifications.docs.length} notifications as read for $userId');
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }
  
  /// Counts unread notifications for a user
  Future<int> getUnreadNotificationCount({
    required String collectionName,
    required String userId,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
          
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error counting unread notifications: $e');
      return 0;
    }
  }

  /// Delete a notification by ID
  Future<void> deleteNotification({
    required String collectionName,
    required String notificationId,
  }) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(notificationId)
          .delete();
          
      debugPrint('Deleted notification $notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }
}
