import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import './verification_screen.dart';
// Import helper for Firebase Authentication operations
import '../../utils/firebase_auth_helper.dart';
// Import helper for Firebase Firestore database operations
import '../../utils/firebase_firestore_helper.dart';
import './signup_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});
  
  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}
  
class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
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
    // Expect exactly 9 digits.
    final cleanDigits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanDigits.length != 9) {
      return 'Please enter a valid 9-digit mobile number';
    }
    return null;
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

    setState(() {
      _isLoading = true;
    });

    // Firebase Firestore: Check if a customer exists by phone number
    try {
      bool exists = await _firestoreHelper.doesCustomerExistByPhone(phone: fullPhone);
      if (!exists) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No customer found with this phone number. Please sign up."),
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

      // Firebase Authentication: Start phone number verification process
      await _authHelper.verifyPhoneNumber(
        phoneNumber: fullPhone,
        // Firebase Authentication: Handle successful SMS code sending
        onCodeSent: (String verificationId, int? forceResendingToken) {
          setState(() {
            _isLoading = false;
            _phoneAttempts = 0;
          });
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomerVerificationScreen(
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

  /// Builds a social button with the provided icon.
  Widget _buildSocialButton(IconData icon, {Color? color}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(
        icon,
        size: 24,
        color: color,
      ),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Image.asset(
                      'assets/Assets-main/Assets-main/logo 2.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Sign in',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Phone Number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Display static "+94" text.
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade400,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            decoration: const InputDecoration(
                              hintText: '7XXXXXXXX',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Center(
                    child: Text(
                      'Or sign in with',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
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
                      // You can add more social buttons here.
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Create a New Account? ',
                        style: TextStyle(color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomerSignUpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: Color(0xFF0D47A1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
