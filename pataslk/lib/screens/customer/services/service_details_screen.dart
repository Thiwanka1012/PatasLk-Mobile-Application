import 'package:flutter/material.dart';
import 'add_photos_screen.dart';
import '../booking/booking_details_screen.dart';
// CachedNetworkImage used to display images from Firebase Storage
import 'package:cached_network_image/cached_network_image.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceName;
  final String serviceType;

  const ServiceDetailsScreen({
    Key? key,
    required this.serviceName,
    required this.serviceType,
  }) : super(key: key);

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  // URL from Firebase Storage after image upload
  String? _uploadedImageUrl;

  // Map each service to an image path
  String get _headerImage {
    switch (widget.serviceName) {
      case 'AC Repair':
        return 'assets/Assets-main/Assets-main/ac repair.jpg';
      case 'Beauty':
        return 'assets/Assets-main/Assets-main/beauty.jpg';
      case 'Appliance':
        return 'assets/Assets-main/Assets-main/applience service.jpg';
      case 'Painting':
        return 'assets/Assets-main/Assets-main/painting service.jpg';
      case 'Cleaning':
        return 'assets/Assets-main/Assets-main/cleaning service.jpg';
      case 'Plumbing':
        return 'assets/Assets-main/Assets-main/plumbing service.jpg';
      case 'Electronics':
        return 'assets/Assets-main/Assets-main/electrical service.jpg';
      default:
        return '';
    }
  }

  // Combined title for the service
  String get _serviceTitle {
    return '${widget.serviceName} ${widget.serviceType}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top header image with overlay
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_headerImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                  foregroundDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Text(
                    _serviceTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Add photos" button - navigates to screen that handles Firebase Storage upload
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddPhotosScreen(serviceName: widget.serviceName),
                        ),
                      );
                      
                      if (result != null) {
                        setState(() {
                          // Store Firebase Storage URL of uploaded image
                          _uploadedImageUrl = result;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Photo uploaded successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE5D9),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Add photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Show uploaded image from Firebase Storage if there is one
                  if (_uploadedImageUrl != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _uploadedImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(Icons.error, color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),

                  // Description label
                  Row(
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
                        'Description',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description editor
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.format_bold),
                                onPressed: () {},
                                color: Colors.grey[700],
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_italic),
                                onPressed: () {},
                                color: Colors.grey[700],
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_underline),
                                onPressed: () {},
                                color: Colors.grey[700],
                              ),
                              IconButton(
                                icon: const Icon(Icons.insert_emoticon),
                                onPressed: () {},
                                color: Colors.grey[700],
                              ),
                              IconButton(
                                icon: const Icon(Icons.link),
                                onPressed: () {},
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            hintText: 'Enter description...',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Service charge (static)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Service charge:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'Rs 1000.00',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.keyboard_arrow_up, color: Colors.orange[400]),
                          Text(
                            'Bill Details',
                            style: TextStyle(
                              color: Colors.orange[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // "Next" button to go to booking details
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetailsScreen(
                              serviceName: widget.serviceName,
                              amount: 1000.00, // Replace if you have dynamic pricing
                              serviceType: widget.serviceType,
                              description: _descriptionController.text,
                              uploadedImageUrl: _uploadedImageUrl,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Next',
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
          ],
        ),
      ),
    );
  }
}
