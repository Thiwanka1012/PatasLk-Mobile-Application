const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// HTTP function to check for expired bookings (can be called from an external scheduler)
exports.checkExpiredBookings = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    
    // Calculate time threshold (30 minutes ago)
    const expirationTime = new Date();
    expirationTime.setHours(expirationTime.getHours() - 12);
    
    // Query for pending bookings older than the threshold
    const snapshot = await db.collection('bookings')
      .where('status', '==', 'Pending')
      .where('createdAt', '<', admin.firestore.Timestamp.fromDate(expirationTime))
      .get();
    
    // Batch update expired bookings
    const batch = db.batch();
    const expiredBookings = [];
    
    snapshot.forEach(doc => {
      const bookingRef = db.collection('bookings').doc(doc.id);
      batch.update(bookingRef, { 
        status: 'Expired',
        expiryReason: 'Provider did not respond within 12 hours'
      });
      
      expiredBookings.push({
        id: doc.id,
        data: doc.data()
      });
    });
    
    // If no expired bookings found, return success message
    if (expiredBookings.length === 0) {
      console.log('No expired bookings found');
      res.status(200).send({success: true, message: 'No expired bookings found'});
      return;
    }
    
    // Commit all the batch updates
    await batch.commit();
    console.log(`Updated ${expiredBookings.length} expired bookings`);
    
    // Create notifications for affected customers
    const notificationBatch = db.batch();
    
    for (const booking of expiredBookings) {
      const notificationRef = db.collection('notifications').doc();
      
      notificationBatch.set(notificationRef, {
        userId: booking.data.customer_id,
        title: 'Booking Expired',
        message: `Your ${booking.data.serviceName} booking has expired because no service provider responded in time.`,
        bookingId: booking.id,
        type: 'booking_expired',
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
    
    await notificationBatch.commit();
    console.log(`Created ${expiredBookings.length} customer notifications`);
    
    // Return success response
    res.status(200).send({
      success: true, 
      message: `Processed ${expiredBookings.length} expired bookings`
    });
  } catch (error) {
    console.error('Error checking expired bookings:', error);
    res.status(500).send({
      success: false,
      error: error.message
    });
  }
});

// Note: Firestore triggers are not available on the free plan
// Uncomment this if you upgrade to the Blaze plan:
/*
exports.markExpiredBookings = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snapshot, context) => {
    // function implementation
  });
*/
