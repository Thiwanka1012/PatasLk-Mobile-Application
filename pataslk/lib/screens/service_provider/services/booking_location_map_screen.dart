import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingLocationMapScreen extends StatefulWidget {
  final LatLng location;
  final String address;
  final String bookingId;
  final String customerName;

  const BookingLocationMapScreen({
    super.key,
    required this.location, 
    required this.address,
    required this.bookingId,
    this.customerName = "Customer",
  });

  /// Factory constructor to create from Firestore data
  factory BookingLocationMapScreen.fromFirestoreData({
    required Map<String, dynamic> bookingData,
    Key? key,
  }) {
    // Extract location data safely
    LatLng location;
    
    try {
      // First check if location is in nested format
      if (bookingData['location'] != null) {
        final locationData = bookingData['location'];
        
        // Case 1: location is a map with latitude/longitude
        if (locationData is Map) {
          final lat = locationData['latitude'];
          final lng = locationData['longitude'];
          if (lat != null && lng != null) {
            location = LatLng(
              lat is num ? lat.toDouble() : 0.0, 
              lng is num ? lng.toDouble() : 0.0
            );
          } else {
            location = LatLng(7.8731, 80.7718); // Default
          }
        } 
        // Case 2: location is directly a LatLng object (shouldn't happen but just in case)
        else if (locationData is LatLng) {
          location = locationData;
        }
        else {
          location = LatLng(7.8731, 80.7718); // Default
        }
      } 
      // Case 3: Check for direct latitude/longitude on booking
      else if (bookingData['latitude'] != null && bookingData['longitude'] != null) {
        final lat = bookingData['latitude'];
        final lng = bookingData['longitude'];
        location = LatLng(
          lat is num ? lat.toDouble() : 0.0, 
          lng is num ? lng.toDouble() : 0.0
        );
      } 
      else {
        // Default to central Sri Lanka if no valid location
        location = LatLng(7.8731, 80.7718);
      }
    } catch (e) {
      print('Error extracting location: $e');
      location = LatLng(7.8731, 80.7718); // Default on error
    }
    
    // Extract address safely
    final String address = bookingData['address'] as String? ?? 
                         (bookingData['location'] is Map ? 
                           bookingData['location']['address'] as String? : null) ?? 
                         'Address not available';
    
    // Extract booking ID and customer name
    final String bookingId = bookingData['bookingId'] as String? ?? 
                           bookingData['referenceCode'] as String? ?? 
                           'Unknown';
    final String customerName = bookingData['customerName'] as String? ?? 'Customer';
    
    return BookingLocationMapScreen(
      key: key,
      location: location,
      address: address,
      bookingId: bookingId,
      customerName: customerName,
    );
  }

  @override
  State<BookingLocationMapScreen> createState() => _BookingLocationMapScreenState();
}

class _BookingLocationMapScreenState extends State<BookingLocationMapScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  double _currentZoom = 15.0;

  // Helper function to open map directions
  Future<void> _openMapDirections() async {
    final String googleMapsUrl = 
        'https://www.google.com/maps/dir/?api=1&destination=${widget.location.latitude},${widget.location.longitude}';
    
    final Uri uri = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text(
          'Booking Location', 
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_mapReady) {
                _mapController.move(widget.location, 16.0);
              }
            },
            tooltip: 'Center on location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // The map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.location,
              initialZoom: 15.0,
              minZoom: 4.0,
              maxZoom: 18.0,
              onMapReady: () {
                setState(() => _mapReady = true);
              },
              // Use callback without type for position to avoid MapPosition dependency
              onPositionChanged: (position, hasGesture) {
                if (position.zoom != null) {
                  setState(() {
                    _currentZoom = position.zoom!;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.location,
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                // Using withOpacity with a different approach
                                color: Colors.black87,
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.home_work, color: Colors.red, size: 26),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.red,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Zoom controls
          Positioned(
            right: 16,
            bottom: 180,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        // Using different approach without withOpacity
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _currentZoom + 1,
                          );
                        },
                      ),
                      Container(
                        height: 1,
                        width: 20,
                        color: Colors.grey[300],
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _currentZoom - 1,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Location information panel at the bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    // Using non-deprecated approach
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person_pin_circle, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking #${widget.bookingId.length >= 6 ? widget.bookingId.substring(0, 6) : widget.bookingId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customer: ${widget.customerName}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Address:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.address,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coordinates: ${widget.location.latitude.toStringAsFixed(6)}, ${widget.location.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openMapDirections,
                          icon: const Icon(Icons.directions),
                          label: const Text('Get Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
