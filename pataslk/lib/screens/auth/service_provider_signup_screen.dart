// Firebase Firestore package for database operations
import 'package:cloud_firestore/cloud_firestore.dart';
// Firebase Authentication package for user authentication
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'service_provider_login_screen.dart';
// Helper utility for Firebase Authentication operations
import '../../utils/firebase_auth_helper.dart';
// Helper utility for Firebase Firestore database operations
import '../../utils/firebase_firestore_helper.dart';
import './service_provider_verification_screen.dart';

class ServiceProviderSignupScreen extends StatefulWidget {
  const ServiceProviderSignupScreen({Key? key}) : super(key: key);

  @override
  State<ServiceProviderSignupScreen> createState() =>
      _ServiceProviderSignupScreenState();
}

class _ServiceProviderSignupScreenState extends State<ServiceProviderSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedTitle = 'Mr.';
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final FirebaseAuthHelper _authHelper = FirebaseAuthHelper();
  final FirestoreHelper _firestoreHelper = FirestoreHelper();
  bool _isProcessing = false;
  
  // Job role dropdown field.
  final List<String> _jobRoles = [
    'AC Repair',
    'Beauty',
    'Appliance',
    'Painting',
    'Cleaning',
    'Plumbing',
    'Electronics',
    'Shifting',
    "Men's Salon"
  ];
  String _selectedJobRole = 'AC Repair';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  bool isValidPhone(String phone) {
    // Accept either 9 digits (without leading zero) or 10 digits (with leading zero)
    final cleanDigits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanDigits.length == 9) {
      // Standard format without leading zero (e.g., 7XXXXXXXX)
      return true;
    }
    if (cleanDigits.length == 10 && cleanDigits.startsWith('0')) {
      // With leading zero (e.g., 07XXXXXXXX) - common user input format
      return true;
    }
    return false;
  }
  
  /// Helper to format phone number in E.164 format.
  String formatPhoneNumber(String raw) {
    return FirebaseAuthHelper.formatPhoneNumber(raw);
  }
  
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (!isValidPhone(_phoneController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid Sri Lankan mobile number (9 digits without leading zero)"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Firebase Firestore: Check if user with this email already exists
      bool exists = await _firestoreHelper.doesUserExist(
        collection: 'serviceProviders',
        email: _emailController.text.trim(),
      );
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User already exists. Please sign in."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      setState(() {
        _isProcessing = true;
      });
  
      // Get formatted phone number using the helper
      String fullPhone = formatPhoneNumber(_phoneController.text);
      debugPrint("Formatted phone: $fullPhone");
  
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sending verification code... Please wait"),
          duration: Duration(seconds: 2),
        ),
      );
      
      try {
        // Create local variables to capture the data we'll need
        final String firstName = _firstNameController.text.trim();
        final String lastName = _lastNameController.text.trim();
        final String email = _emailController.text.trim();
        final String jobRole = _selectedJobRole;
        
        // Firebase Authentication: Start phone number verification process
        await _authHelper.verifyPhoneNumber(
          phoneNumber: fullPhone,
          onCodeSent: (String verificationId, int? forceResendingToken) {
            debugPrint("✓ Code sent successfully to $fullPhone");
            debugPrint("✓ Verification ID: $verificationId");
            
            if (mounted) {
              // First set loading to false
              setState(() {
                _isProcessing = false;
              });
              
              // Schedule navigation on the next frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ServiceProviderVerificationScreen(
                        verificationId: verificationId,
                        resendToken: forceResendingToken,
                        isSignUpFlow: true,
                        firstName: firstName,
                        lastName: lastName,
                        email: email,
                        phone: fullPhone,
                        jobRole: jobRole,
                      ),
                    ),
                  );
                }
              });
            }
          },
          onError: (String error) {
            debugPrint("✗ Error during verification: $error");
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      } catch (e) {
        debugPrint("✗ Exception during verification: $e");
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Authentication error: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ServiceProviderLoginScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/Assets-main/Assets-main/logo 2.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              // First Name Field with title dropdown.
              const Text(
                'First Name',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<String>(
                        value: _selectedTitle,
                        underline: const SizedBox(),
                        items: ['Mr.', 'Mrs.', 'Ms.', 'Dr.']
                            .map((title) => DropdownMenuItem(
                                  value: title,
                                  child: Text(title),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTitle = value;
                            });
                          }
                        },
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey.shade400,
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          if (value.length < 2) {
                            return 'First name must be at least 2 characters';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'First Name',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Last Name Field.
              const Text(
                'Last Name',
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
                child: TextFormField(
                  controller: _lastNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    if (value.length < 2) {
                      return 'Last name must be at least 2 characters';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Last Name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Phone Number Field.
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
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        decoration: const InputDecoration(
                          hintText: '7XXXXXXXX',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length != 9) {
                            return 'Mobile number must be 9 digits';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Email Field.
              const Text(
                'Email',
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
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!isValidEmail(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Job Role Field
              const Text(
                'Job Role',
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedJobRole,
                    items: _jobRoles
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedJobRole = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const ServiceProviderLoginScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an Account? ',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign in',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
