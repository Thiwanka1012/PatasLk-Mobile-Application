import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Helper class for Firebase Authentication operations
class FirebaseAuthHelper {
  // Firebase Auth: Initialize auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Validates and formats a phone number to E.164 format
  static String formatPhoneNumber(String raw) {
    // First remove all spaces, dashes, and parentheses
    String trimmed = raw.trim().replaceAll(RegExp(r'\s+|-|\(|\)'), '');
    
    // Handle case where user added country code variations
    if (trimmed.startsWith('94')) {
      trimmed = trimmed.substring(2);
    } else if (trimmed.startsWith('+94')) {
      trimmed = trimmed.substring(3);
    } else if (trimmed.startsWith('0')) {
      // Remove leading zero if present (common in local format)
      trimmed = trimmed.substring(1);
    }
    
    // Ensure the number is properly formatted with country code
    if (trimmed.length == 9) { // Valid Sri Lankan numbers without country code
      return '+94$trimmed';
    } else {
      // In case of any other format, still try to add country code
      debugPrint("Warning: Unusual phone number format: $trimmed");
      return '+94$trimmed';
    }
  }

  /// Initiates phone number verification process with enhanced error handling
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? forceResendingToken) onCodeSent,
    required Function(String error) onError,
    int? resendToken,
  }) async {
    try {
      final formattedPhone = formatPhoneNumber(phoneNumber);
      debugPrint("🔔 Attempting to verify phone: $formattedPhone");
      
      // Firebase Auth: Start phone verification process with improved settings
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint("🔔 Auto verification completed (not using for UX consistency)");
          // Not auto-signing in for more consistent UX across platforms
        },
        
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("🔔 Verification failed: ${e.code} - ${e.message}");
          onError(_getReadableError(e));
        },
        
        codeSent: (String verificationId, int? forceResendingToken) {
          debugPrint("🔔 SMS code sent to $formattedPhone");
          debugPrint("🔔 Verification ID: $verificationId");
          
          // Ensure we call the callback
          onCodeSent(verificationId, forceResendingToken);
        },
        
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("🔔 SMS auto-retrieval timed out for ID: $verificationId");
        },
      );
    } catch (e) {
      debugPrint("🔔 Error in verifyPhoneNumber: $e");
      onError("An unexpected error occurred. Please try again.");
    }
  }

  /// Signs in user with verification code (OTP) with improved error handling
  Future<Map<String, dynamic>?> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      if (verificationId.isEmpty || smsCode.length != 6) {
        debugPrint("Error: Invalid verificationId or smsCode");
        return null;
      }
      
      debugPrint("Attempting to sign in with verification code");
      
      // Create credential from verification ID and SMS code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      // Sign in with credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      debugPrint("Sign in successful. User: ${userCredential.user?.uid}, isNewUser: $isNewUser");
      return {
        "user": userCredential.user, 
        "isNewUser": isNewUser
      };
    } catch (e) {
      debugPrint("Error in signInWithOTP: $e");
      if (e is FirebaseAuthException) {
        throw _getReadableError(e);
      }
      throw "Failed to verify code. Please try again.";
    }
  }
  
  /// Converts Firebase Auth error codes to user-friendly messages
  String _getReadableError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'The phone number format is incorrect. Please check and try again.';
        case 'quota-exceeded':
          return 'SMS quota exceeded. Please try again later.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again after some time.';
        case 'session-expired':
          return 'The verification code has expired. Please request a new one.';
        case 'invalid-verification-code':
          return 'The verification code is incorrect. Please check and try again.';
        case 'invalid-verification-id':
          return 'The verification session has expired. Please request a new code.';
        case 'network-request-failed':
          return 'Network error. Please check your connection and try again.';
        case 'app-not-authorized':
          return 'This device is not authorized. Please use a different device.';
        default:
          return error.message ?? "Verification failed. Please try again later.";
      }
    }
    return error.toString();
  }
  
  /// Check if a user is currently authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }
  
  /// Get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  /// Listen to authentication state changes
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Signs out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
