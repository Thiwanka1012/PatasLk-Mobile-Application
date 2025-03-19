import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      debugPrint('Could not launch \$url');
    }
  }

  Widget _buildContactItem(IconData icon, String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0D47A1),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return IconButton(
      icon: FaIcon(
        icon,
        color: const Color(0xFF0D47A1),
        size: 24,
      ),
      onPressed: () => _launchUrl(url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            children: [
              const Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'If you have any question\nwe are happy to help',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Phone
              _buildContactItem(
                Icons.phone,
                '+94 761234895',
                onTap: () => _launchUrl('tel:+94761234895'),
              ),
              const SizedBox(height: 24),

              // Email
              _buildContactItem(
                Icons.email_outlined,
                'contact@patasik.services',
                onTap: () => _launchUrl('mailto:contact@patasik.services'),
              ),
              const SizedBox(height: 48),

              // Social Media Section
              const Text(
                'Get Connected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(
                    FontAwesomeIcons.linkedin,
                    'https://linkedin.com/company/patasik',
                  ),
                  _buildSocialIcon(
                    FontAwesomeIcons.facebook,
                    'https://facebook.com/patasik',
                  ),
                  _buildSocialIcon(
                    FontAwesomeIcons.twitter,
                    'https://twitter.com/patasik',
                  ),
                  _buildSocialIcon(
                    FontAwesomeIcons.instagram,
                    'https://instagram.com/patasik',
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
