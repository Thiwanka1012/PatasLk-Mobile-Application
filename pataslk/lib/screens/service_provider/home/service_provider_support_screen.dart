import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceProviderSupportScreen extends StatelessWidget {
  const ServiceProviderSupportScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: () => _launchUrl(url),
        icon: FaIcon(
          icon,
          color: const Color(0xFF0D47A1),
          size: 20,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you have any question\nwe are happy to help',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.phone,
                  color: const Color(0xFF0D47A1),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _launchUrl('tel:+94761234895'),
                child: const Text(
                  '+94 761234895',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.email,
                  color: const Color(0xFF0D47A1),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _launchUrl('mailto:contact@patasik.services'),
                child: const Text(
                  'contact@patasik.services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Get Connected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(
                    FontAwesomeIcons.linkedin,
                    'https://www.linkedin.com/company/patasik',
                  ),
                  _buildSocialIcon(
                    FontAwesomeIcons.facebook,
                    'https://www.facebook.com/patasik',
                  ),
                  _buildSocialIcon(
                    FontAwesomeIcons.twitter,
                    'https://twitter.com/patasik',
                  ),
                  _buildSocialIcon(
                    FontAwesomeIcons.instagram,
                    'https://www.instagram.com/patasik',
                  ),
                  _buildSocialIcon(
                    FontAwesomeIcons.whatsapp,
                    'https://wa.me/94761234895',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
