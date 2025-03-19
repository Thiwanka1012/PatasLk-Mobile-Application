import 'package:flutter/material.dart';
import './service_details_screen.dart';

class ServiceCategoryScreen extends StatelessWidget {
  final String serviceName;

  const ServiceCategoryScreen({
    super.key,
    required this.serviceName,
  });

  Widget _buildServiceOption({
    required String title,
    required String description,
    required String imageAsset, // Changed from imageUrl to imageAsset
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Image.asset(
                  // Changed from Image.network to Image.asset
                  imageAsset,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pick the Service\nYou Need',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 32),
              _buildServiceOption(
                title: 'One-Day Service',
                description:
                    'Quick, reliable help for single-day tasks or emergencies.',
                imageAsset: 'assets/Assets-main/Assets-main/one day png.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsScreen(
                        serviceName: serviceName,
                        serviceType: 'One-Day Service',
                      ),
                    ),
                  );
                },
              ),
              _buildServiceOption(
                title: 'Part-Time',
                description:
                    'Flexible support for shorter commitments or recurring needs.',
                imageAsset:
                    'assets/Assets-main/Assets-main/part time basis.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsScreen(
                        serviceName: serviceName,
                        serviceType: 'Part-Time',
                      ),
                    ),
                  );
                },
              ),
              _buildServiceOption(
                title: 'Contract Basis',
                description:
                    'Long-term solutions tailored to your specific project or goals.',
                imageAsset: 'assets/Assets-main/Assets-main/contract basis.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsScreen(
                        serviceName: serviceName,
                        serviceType: 'Contract Basis',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
