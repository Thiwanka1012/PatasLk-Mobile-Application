// Firebase Firestore package for database operations
import 'package:cloud_firestore/cloud_firestore.dart';
// Firebase Authentication package for user authentication
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../service_provider/home/service_provider_home_screen.dart';
import 'service_provider_signup_screen.dart';
import 'service_provider_verification_screen.dart';
// Helper utility for Firebase Authentication operations
import '../../utils/firebase_auth_helper.dart';
// Helper utility for Firestore database operations
import '../../utils/firebase_firestore_helper.dart';

class ServiceProviderLoginScreen extends StatefulWidget {
  const ServiceProviderLoginScreen({Key? key}) : super(key: key);

  @override
  State<ServiceProviderLoginScreen> createState() =>
      _ServiceProviderLoginScreenState();
}

class _ServiceProviderLoginScreenState extends State<ServiceProviderLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  // Firebase Authentication helper instance
  final FirebaseAuthHelper _authHelper = FirebaseAuthHelper();
  // Firebase Firestore helper instance
  final FirestoreHelper _firestoreHelper = FirestoreHelper();
  bool _isLoading = false;
  int _phoneAttempts = 0;

  /// Formats the raw phone number to E.164 format for Firebase Authentication.
  String _formatPhoneNumber(String raw) => FirebaseAuthHelper.formatPhoneNumber(raw);

  /// Validates the phone number.
  String? _validatePhone(String value) {
    if (value.isEmpty) {
      return 'Please enter your phone number';
    }
    
    final cleanDigits = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Accept either 9 digits (without leading zero) or 10 digits (with leading zero)
    if (cleanDigits.length == 9) {
      return null; // Valid
    }
    if (cleanDigits.length == 10 && cleanDigits.startsWith('0')) {
      return null; // Valid with leading zero
    }
    
    return 'Enter a valid Sri Lankan mobile number';
  }

  /// Login using phone number with Firebase Authentication.
  void _loginWithPhone() async {
    final validation = _validatePhone(_phoneController.text);
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation), backgroundColor: Colors.red),
      );
      return;
    }
    
    String fullPhone = _formatPhoneNumber(_phoneController.text);
    debugPrint("Attempting login with formatted phone: $fullPhone");

    setState(() {
      _isLoading = true;
    });

    // Check if this service provider exists
    try {
      bool exists = await _firestoreHelper.doesServiceProviderExistByPhone(phone: fullPhone);
      if (!exists) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No service provider found with this number. Please sign up."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sending verification code..."),
          duration: Duration(seconds: 2),
        ),
      );

      // Firebase Authentication: Start phone verification process
      await _authHelper.verifyPhoneNumber(
        phoneNumber: fullPhone, // Use formatted phone number
        // Firebase Authentication: Handle successful SMS code sending
        onCodeSent: (String verificationId, int? forceResendingToken) {
          setState(() {
            _isLoading = false;
            _phoneAttempts = 0;
          });
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ServiceProviderVerificationScreen(
                verificationId: verificationId,
                isSignUpFlow: false,
                phone: fullPhone,
                resendToken: forceResendingToken,
              ),
            ),
          );
        },
        // Firebase Authentication: Handle verification errors
        onError: (String error) {
          _phoneAttempts++;
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Authentication error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSocialButton(IconData icon, {Color? color}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/Assets-main/Assets-main/logo 2.png',
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'Sign in',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/Assets-main/Assets-main/circle 1.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '+94',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.grey.shade300,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Phone Number',
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loginWithPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        'Or sign in with',
                        style: TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(
                          FontAwesomeIcons.google,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Create a New Account? ',
                            style: TextStyle(color: Colors.black87)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ServiceProviderSignupScreen()),
                            );
                          },
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.bold),
                          ),
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
