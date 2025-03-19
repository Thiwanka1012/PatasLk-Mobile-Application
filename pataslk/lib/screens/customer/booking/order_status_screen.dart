import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services_screen.dart';

class OrderStatusScreen extends StatelessWidget {
  // Firebase Firestore: The document ID from the 'bookings' collection
  final String bookingId;
  final String address;
  final String serviceType;
  final String jobRole;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String description;
  // Firebase Storage: URL of the image stored in Firebase Storage
  final String? uploadedImageUrl; // Add parameter for image URL

  const OrderStatusScreen({
    Key? key,
    required this.bookingId,
    required this.address,
    required this.serviceType,
    required this.jobRole,
    required this.selectedDate,
    required this.selectedTime,
    required this.description,
    this.uploadedImageUrl, // Add the uploadedImageUrl parameter
  }) : super(key: key);

  String _extractDistrict(String address) {
    final List<String> parts = address.split(',');
    for (String part in parts) {
      part = part.trim();
      if (part.contains('District')) {
        return part;
      }
    }
    return 'District not specified';
  }

  @override
  Widget build(BuildContext context) {
    final String district = _extractDistrict(address);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Order Status'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Section - displays the status from Firebase Firestore
              Row(
                children: [
                  const Text(
                    'Order Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Pending', // This status would normally come from Firestore data
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your order is still pending. The service provider has not yet started the job.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              // Display booking details from Firestore document
              _buildInfoSection('Address:', address),
              _buildInfoSection('District:', district),
              _buildInfoSection('Service Type:', serviceType.isNotEmpty ? serviceType : 'Not specified'),
              _buildInfoSection('Job Role:', jobRole),
              _buildInfoSection('Order Date:', '${DateFormat('MMM d, yyyy').format(selectedDate)} at ${selectedTime.format(context)}'),
              _buildInfoSection('Details:', description.isNotEmpty ? description : 'No description provided'),
              _buildInfoSection('Attachments:', ''),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Service charge:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        Text(
                          'Rs 1000.00',
                          style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            // Show bill details if needed.
                          },
                          child: Row(
                            children: const [
                              Text('Bill Details', style: TextStyle(color: Colors.blue)),
                              Icon(Icons.keyboard_arrow_up, color: Colors.blue),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // "Check Order Progress" Button navigates to the ServicesScreen.
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ServicesScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Check Bookings',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            content.isNotEmpty ? content : 'No description provided',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
