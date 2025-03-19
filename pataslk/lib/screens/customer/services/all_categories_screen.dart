import 'package:flutter/material.dart';
import 'service_category_screen.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  Widget _buildCategoryButton({
    required String title,
    required String imageAsset,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                imageAsset,
                width: 45,
                height: 45,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'title': 'AC Repair',
        'image': 'assets/Assets-main/Assets-main/Ac Repair.png',
        'color': const Color(0xFFFFE5D9),
      },
      {
        'title': 'Beauty',
        'image': 'assets/Assets-main/Assets-main/Beauty.png',
        'color': const Color(0xFFE5E1FF),
      },
      {
        'title': 'Appliance',
        'image': 'assets/Assets-main/Assets-main/Appliance.png',
        'color': const Color(0xFFD9F2FF),
      },
      {
        'title': 'Painting',
        'image': 'assets/Assets-main/Assets-main/Painting.png',
        'color': const Color(0xFFD9FFE5),
      },
      {
        'title': 'Cleaning',
        'image': 'assets/Assets-main/Assets-main/Cleaning.png',
        'color': const Color(0xFFFFF3D9),
      },
      {
        'title': 'Plumbing',
        'image': 'assets/Assets-main/Assets-main/Plumbing.png',
        'color': const Color(0xFFE5FFD9),
      },
      {
        'title': 'Electronics',
        'image': 'assets/Assets-main/Assets-main/Electronics.png',
        'color': const Color(0xFFFFD9D9),
      },
      {
        'title': 'Shifting',
        'image': 'assets/Assets-main/Assets-main/Shifting.png',
        'color': const Color(0xFFFFD9F2),
      },
      {
        'title': 'Men\'s Salon',
        'image': 'assets/Assets-main/Assets-main/Men\'s Salon.png',
        'color': const Color(0xFFD9E5FF),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search Category',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    'All Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 24,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryButton(
                    title: category['title'] as String,
                    imageAsset: category['image'] as String,
                    backgroundColor: category['color'] as Color,
                    onTap: () {
                      if (category['title'] == 'Shifting' ||
                          category['title'] == 'Men\'s Salon') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'This service will be available in future updates'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceCategoryScreen(
                              serviceName: category['title'] as String,
                            ),
                          ),
                        );
                      }
                    },
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
