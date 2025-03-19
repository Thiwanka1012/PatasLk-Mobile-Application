import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart'; // Add this import
import 'package:url_launcher/url_launcher.dart'; // Add this import
import '../home/service_provider_home_screen.dart';
import 'booking_location_map_screen.dart'; // Add this import

class ServiceProviderOrderDetailScreen extends StatefulWidget {
  final String bookingId;

  const ServiceProviderOrderDetailScreen({Key? key, required this.bookingId})
      : super(key: key);

  @override
  State<ServiceProviderOrderDetailScreen> createState() =>
      _ServiceProviderOrderDetailScreenState();
}

class _ServiceProviderOrderDetailScreenState
    extends State<ServiceProviderOrderDetailScreen> {
  // Firebase Auth: Get current authenticated user
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  DocumentSnapshot? _bookingDoc;
  bool _isLoading = false;
  String? _customerPhone;

  @override
  void initState() {
    super.initState();
    _fetchBooking();
  }

  /// Fetch the booking document to display its details.
  Future<void> _fetchBooking() async {
    setState(() => _isLoading = true);
    try {
      // Firebase Firestore: Get booking document by ID
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();
      if (doc.exists) {
        setState(() => _bookingDoc = doc);
        await _fetchCustomerPhone();
      }
    } catch (e) {
      print('Error fetching booking: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Fetch the customer's phone number using the customer_id from the booking
  Future<void> _fetchCustomerPhone() async {
    if (_bookingDoc == null) return;

    try {
      final data = _bookingDoc!.data() as Map<String, dynamic>;
      final customerId = data['customer_id'];

      if (customerId != null) {
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(customerId)
            .get();

        if (customerDoc.exists) {
          final customerData = customerDoc.data() as Map<String, dynamic>;
          setState(() {
            _customerPhone = customerData['phone'] as String?;
          });
        }
      }
    } catch (e) {
      print('Error fetching customer phone: $e');
    }
  }

  /// Make a phone call to the customer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch phone dialer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Navigate to the location map screen
  void _viewLocationOnMap(Map<String, dynamic> data) {
    // Extract coordinates for the map view
    double? latitude;
    double? longitude;
    String locationDisplay = 'Unknown location';

    if (data['location'] is Map) {
      final locationMap = data['location'] as Map<String, dynamic>;
      latitude = locationMap['latitude'] is num
          ? (locationMap['latitude'] as num).toDouble()
          : null;
      longitude = locationMap['longitude'] is num
          ? (locationMap['longitude'] as num).toDouble()
          : null;
      locationDisplay =
          locationMap['address'] as String? ?? 'Unknown location';
    } else {
      // Try the direct latitude/longitude fields as fallback
      latitude = data['latitude'] is num
          ? (data['latitude'] as num).toDouble()
          : null;
      longitude = data['longitude'] is num
          ? (data['longitude'] as num).toDouble()
          : null;

      if (data['address'] != null && data['address'] is String) {
        locationDisplay = data['address'] as String;
      } else if (data['location'] is String) {
        locationDisplay = data['location'] as String;
      }
    }

    // Check if we have location data
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location coordinates not available for this booking'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create a LatLng object from the booking data
    final location = LatLng(latitude, longitude);
    final customerName = data['customerName'] ?? 'Customer';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingLocationMapScreen(
          location: location,
          address: locationDisplay,
          bookingId: widget.bookingId,
          customerName: customerName,
        ),
      ),
    );
  }

  /// Accept the job => update the booking doc with provider info and status.
  Future<void> _acceptJob() async {
    if (_currentUser == null || _bookingDoc == null) return;
    try {
      // Firebase Firestore: Get provider data from serviceProviders collection
      final providerDoc = await FirebaseFirestore.instance
          .collection('serviceProviders')
          .doc(_currentUser!.uid)
          .get();
      final providerData = providerDoc.data() as Map<String, dynamic>?;

      final providerName = providerData != null
          ? providerData['firstName'] ?? 'Unknown'
          : 'Unknown';

      // Firebase Firestore: Update booking document with provider information
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'provider_id': _currentUser!.uid,
        'providerName': providerName,
        'status': 'InProgress',
      });

      _showConfirmationDialog();
    } catch (e) {
      print('Error accepting job: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept job.')),
      );
    }
  }

  /// Show a success dialog: "Job Confirmed!"
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Job Confirmed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Excited for this new opportunity!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ServiceProviderHomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_bookingDoc == null) {
      return const Scaffold(
        body: Center(child: Text('No booking found.')),
      );
    }

    final data = _bookingDoc!.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'Pending';
    final bookingTime = data['bookingTime'] ?? 'N/A';
    final bookingDateTs = data['bookingDate'] as Timestamp?;
    final bookingDate = bookingDateTs != null
        ? '${bookingDateTs.toDate().day}-${bookingDateTs.toDate().month}-${bookingDateTs.toDate().year}'
        : 'N/A';

    // Handle the location data which could be either a String or a Map
    String locationDisplay = 'Unknown location';
    if (data['location'] != null) {
      if (data['location'] is Map) {
        // New format: location is a map with address key
        final locationMap = data['location'] as Map<String, dynamic>;
        locationDisplay =
            locationMap['address'] as String? ?? 'Unknown location';
      } else if (data['location'] is String) {
        // Old format: location is directly a string
        locationDisplay = data['location'] as String;
      }
    } else if (data['address'] != null && data['address'] is String) {
      // Fallback to address field if it exists
      locationDisplay = data['address'] as String;
    }

    final description = data['description'] ?? 'No description';
    final imageUrl = data['imageUrl'] as String?; // Get the image URL

    // Extract coordinates for the map view
    double? latitude;
    double? longitude;

    if (data['location'] is Map) {
      final locationMap = data['location'] as Map<String, dynamic>;
      latitude = locationMap['latitude'] is num
          ? (locationMap['latitude'] as num).toDouble()
          : null;
      longitude = locationMap['longitude'] is num
          ? (locationMap['longitude'] as num).toDouble()
          : null;
    } else {
      // Try the direct latitude/longitude fields as fallback
      latitude = data['latitude'] is num
          ? (data['latitude'] as num).toDouble()
          : null;
      longitude = data['longitude'] is num
          ? (data['longitude'] as num).toDouble()
          : null;
    }

    // Check if location coordinates are available for the map button
    final bool hasLocationData = latitude != null && longitude != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the image if available
            if (imageUrl != null && imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  height: 250,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey, size: 60),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  Row(
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'Pending'
                              ? Colors.orange[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'Pending'
                                ? Colors.orange[700]
                                : Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Date & Time
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$bookingTime, $bookingDate',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Add Phone Number section with Call button
                  if (_customerPhone != null) ...[
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Contact',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _customerPhone!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _makePhoneCall(_customerPhone!),
                                icon: const Icon(Icons.call, size: 16),
                                label: const Text('Call'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Location with View on Map button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location header
                      const Text(
                        'Location',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Location display card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show location address
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    locationDisplay, // Use locationDisplay instead of data['location']
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // View on Map button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.map),
                                label: const Text('View Location on Map'),
                                onPressed: hasLocationData
                                    ? () => _viewLocationOnMap(data)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey[400],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),

                            // Show warning if no coordinates
                            if (!hasLocationData)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Exact location coordinates not available',
                                        style: TextStyle(fontSize: 12),
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

                  const SizedBox(height: 32),
                  // Job Description
                  const Text(
                    'Job Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Payment or advanced Payment if needed
                  const Text(
                    'Advanced Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs.${data['amount'] ?? 0.0}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Accept or skip buttons
                  if (status == 'Pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ServiceProviderHomeScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _acceptJob,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // If status != Pending, show status message
                    const SizedBox(height: 16),
                    Text(
                      'This booking is already $status.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
