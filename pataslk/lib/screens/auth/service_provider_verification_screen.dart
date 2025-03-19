import 'dart:async';
// Firebase Firestore package for database operations
import 'package:cloud_firestore/cloud_firestore.dart';
// Firebase Authentication package for user authentication
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Helper utility for Firebase Authentication operations
import '../../utils/firebase_auth_helper.dart';
// Helper utility for Firestore database operations
import '../../utils/firebase_firestore_helper.dart';
import '../service_provider/home/service_provider_home_screen.dart';

class ServiceProviderVerificationScreen extends StatefulWidget {
  final String verificationId;
  final bool isSignUpFlow;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? jobRole;
  final int? resendToken; // Added field for resend token

  const ServiceProviderVerificationScreen({
    super.key,
    required this.verificationId,
    required this.isSignUpFlow,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.jobRole,
    this.resendToken,
  });

  @override
  State<ServiceProviderVerificationScreen> createState() =>
      _ServiceProviderVerificationScreenState();
}

class _ServiceProviderVerificationScreenState extends State<ServiceProviderVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (index) => FocusNode());
  // Firebase Authentication helper instance
  final FirebaseAuthHelper _authHelper = FirebaseAuthHelper();
  // Firebase Firestore helper instance
  final FirestoreHelper _firestoreHelper = FirestoreHelper();
  bool _isVerifying = false;
  String? _errorMessage;
  bool _canResend = false;
  int _remainingSeconds = 60;
  Timer? _resendTimer;
  int? _localResendToken; // Firebase token for resending verification code
  String _currentVerificationId = "";
  
  @override
  void initState() {
    super.initState();
    // Log that we've entered the verification screen
    debugPrint("📱 Entered verification screen with ID: ${widget.verificationId}");
    debugPrint("📱 Phone: ${widget.phone}, Sign-up flow: ${widget.isSignUpFlow}");
    
    // Store the verification ID
    _currentVerificationId = widget.verificationId;
    
    // Initialize _localResendToken from widget.
    _localResendToken = widget.resendToken;
    
    // Request focus on the first input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty && mounted) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      }
    });
    
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _remainingSeconds = 60;
    });
    
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) controller.dispose();
    for (var node in _focusNodes) node.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _completeSignUp() async {
    // Get current Firebase user after successful authentication
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        widget.firstName != null &&
        widget.lastName != null &&
        widget.email != null &&
        widget.phone != null &&
        widget.jobRole != null) {
      try {
        final userData = {
          'firstName': widget.firstName,
          'lastName': widget.lastName,
          'email': widget.email,
          'phone': widget.phone,
          'jobRole': widget.jobRole,
          'userType': 'serviceProvider',
          'createdAt': FieldValue.serverTimestamp(), // Firestore server timestamp
          'lastLogin': FieldValue.serverTimestamp(),
        };
        
        // Log the data being saved
        debugPrint("Saving user data to Firestore: $userData");
        
        // Firebase Firestore: Save user data to 'serviceProviders' collection
        await _firestoreHelper.saveUserData(
          collection: 'serviceProviders',
          uid: user.uid,
          data: userData,
        );
        
        debugPrint("User profile created successfully, navigating to home screen");
        
        if (mounted) {
          // Clear the entire navigation stack and go to home screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ServiceProviderHomeScreen()),
            (route) => false, // Remove all previous routes
          );
        }
      } catch (e) {
        debugPrint("Error creating user profile: $e");
        setState(() {
          _errorMessage = "Failed to create profile: ${e.toString()}";
          _isVerifying = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = "User not signed in or missing details";
        _isVerifying = false;
      });
    }
  }

  // Extracted navigation to a separate method for consistency
  void _navigateToHomeScreen() {
    // Add a small delay to prevent potential navigation conflicts
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        // Use pushAndRemoveUntil to clear the navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ServiceProviderHomeScreen()),
          (route) => false,
        );
      }
    });
  }

  void _resendCode() async {
    if (!_canResend) return;
    
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    
    if (widget.phone == null) {
      setState(() {
        _errorMessage = "Phone number not available for resend";
        _isVerifying = false;
      });
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Requesting a new verification code..."),
        duration: Duration(seconds: 3),
      ),
    );
    
    try {
      // Clear old input fields
      for (var controller in _controllers) {
        controller.clear();
      }
      
      // Firebase Authentication: Resend phone verification code
      await _authHelper.verifyPhoneNumber(
        phoneNumber: widget.phone!,
        resendToken: _localResendToken, // Firebase token to optimize resend process
        // Firebase Authentication: Handle successful SMS code sending
        onCodeSent: (String verificationId, int? forceResendingToken) {
          setState(() {
            _isVerifying = false;
            _localResendToken = forceResendingToken; // update local Firebase token
            _currentVerificationId = verificationId; // update verification ID for new code
          });
          
          if (_focusNodes.isNotEmpty) {
            _focusNodes[0].requestFocus();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code resent successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _startResendTimer();
        },
        // Firebase Authentication: Handle verification errors
        onError: (String error) {
          setState(() {
            _errorMessage = error;
            _isVerifying = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Error requesting code: ${e.toString()}';
      });
    }
  }

  void _verifyCode() async {
    String smsCode = _controllers.map((c) => c.text).join();
    if (smsCode.length != 6) {
      setState(() {
        _errorMessage = "Please enter all 6 digits of your verification code";
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      debugPrint("Attempting to verify code with verification ID: $_currentVerificationId");
      
      // Firebase Authentication: Verify the SMS code and sign in the user
      var result = await _authHelper.signInWithOTP(
        verificationId: _currentVerificationId,
        smsCode: smsCode,
      );

      if (result != null) {
        bool isNewUser = result["isNewUser"] as bool;
        User? user = result["user"] as User?;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification successful! Redirecting...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
        
        // Also update lastLogin for existing users
        if (!isNewUser && user != null) {
          await _firestoreHelper.saveUserData(
            collection: 'serviceProviders',
            uid: user.uid,
            data: {
              'lastLogin': FieldValue.serverTimestamp(),
            },
          );
          debugPrint("Updated lastLogin for existing user");
        }
        
        if (widget.isSignUpFlow && isNewUser) {
          debugPrint("New user sign up - creating profile");
          await _completeSignUp();
        } else {
          debugPrint("Existing user login - navigating to home screen now");
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const ServiceProviderHomeScreen()),
              (route) => false, // Remove all previous routes
            );
          }
        }
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Verification failed. Please check your code and try again.';
        });
      }
    } catch (e) {
      debugPrint("Verification error: $e");
      setState(() {
        _isVerifying = false;
        _errorMessage = e.toString();
      });
      
      // Clear fields so user can try again
      for (var controller in _controllers) {
        controller.clear();
      }
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    }
  }

  void _onTextChanged(String value, int index) {
    if (value.length == 1) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field, try verification
        _verifyCode();
      }
    } else if (value.isEmpty && index > 0) {
      // Handle backspace - move to previous field
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Phone"),
        backgroundColor: Colors.blue,
      ),
      // Fix the overflow by using SingleChildScrollView
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification Code',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              widget.phone != null 
                  ? 'Enter the 6-digit code sent to ${widget.phone}'
                  : 'Enter the 6-digit code sent to your mobile number.',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 45,
                  height: 55,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      counterText: "",
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _onTextChanged(value, index),
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_canResend ? "Didn't receive a code? " : "Resend code in ${_remainingSeconds}s"),
                if (_canResend)
                  TextButton(
                    onPressed: _canResend && !_isVerifying ? _resendCode : null,
                    child: Text(
                      'Resend',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _canResend && !_isVerifying ? Theme.of(context).primaryColor : Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verify',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            // Display phone number and edit option
            const SizedBox(height: 30),
            if (widget.phone != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      'Verifying: ${widget.phone}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Change Phone Number'),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
