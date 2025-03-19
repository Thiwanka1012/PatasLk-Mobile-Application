import 'dart:async';
// Firebase Firestore package for database operations
import 'package:cloud_firestore/cloud_firestore.dart';
// Firebase Authentication package for user authentication
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Helper utility for Firebase Authentication operations
import '../../utils/firebase_auth_helper.dart';
// Helper utility for Firebase Firestore database operations
import '../../utils/firebase_firestore_helper.dart';
import '../customer/home/home_screen.dart';

class CustomerVerificationScreen extends StatefulWidget {
  final String verificationId;
  final bool isSignUpFlow;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final int? resendToken; // Added field for resend token

  const CustomerVerificationScreen({
    super.key,
    required this.verificationId,
    required this.isSignUpFlow,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.resendToken,
  });

  @override
  State<CustomerVerificationScreen> createState() => _CustomerVerificationScreenState();
}

class _CustomerVerificationScreenState extends State<CustomerVerificationScreen> {
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
    // Store the verification ID
    _currentVerificationId = widget.verificationId;
    
    // Initialize _localResendToken from widget
    _localResendToken = widget.resendToken;
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

  Future<void> _completeCustomerSignUp() async {
    // Get current Firebase user after successful authentication
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        widget.firstName != null &&
        widget.lastName != null &&
        widget.email != null &&
        widget.phone != null) {
      try {
        final userData = {
          'firstName': widget.firstName,
          'lastName': widget.lastName,
          'email': widget.email,
          'phone': widget.phone,
          'userType': 'customer',
          'createdAt': FieldValue.serverTimestamp(), // Firestore server timestamp
          'lastLogin': FieldValue.serverTimestamp(),
        };
        
        // Log the data being saved
        debugPrint("Saving user data to Firestore: $userData");
        
        // Firebase Firestore: Save user data to 'customers' collection
        await _firestoreHelper.saveUserData(
          collection: 'customers',
          uid: user.uid,
          data: userData,
        );
        
        debugPrint("User profile created successfully, navigating to home screen");
        _navigateToHomeScreen();
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
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // This removes all previous routes
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
            collection: 'customers',
            uid: user.uid,
            data: {
              'lastLogin': FieldValue.serverTimestamp(),
            },
          );
          debugPrint("Updated lastLogin for existing user");
        }
        
        if (widget.isSignUpFlow && isNewUser) {
          debugPrint("New user sign up - creating profile");
          await _completeCustomerSignUp();
        } else {
          debugPrint("Existing user login - navigating to home screen now");
          _navigateToHomeScreen();
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
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.length == 1 && index == 5) {
      _verifyCode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Phone"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
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
                child: _isVerifying
                    ? const CircularProgressIndicator()
                    : const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
