# Testing Phone Authentication

## Setup Test Environment

1. Add your SHA certificates to Firebase Console:
   - SHA1: `AB:07:C0:5D:82:BD:A2:3D:3E:67:3E:54:49:D2:B9:A3:E1:E1:34:F1`
   - SHA256: `F8:93:D1:10:EC:0C:4E:A8:C0:B5:BC:A6:08:45:64:D8:FE:3B:2D:FF:1B:F4:DF:D7:F7:DF:31:E0:4E:D2:7E:9F`

2. Add test phone numbers in Firebase Console:
   - Go to Authentication → Sign-in methods → Phone
   - Add `+94768713717` with verification code `123456`

## Testing Signup Flow

### Testing Steps
1. Clear app data or uninstall the app
2. Launch the app in debug mode
3. Go to the Signup screen
4. Enter your test phone number
5. Proceed with verification using code `123456` 

### Troubleshooting
- Make sure your Firebase Project's debug SHA key is correctly added
- Restart the app after making configuration changes
- Try building a clean version: `flutter clean && flutter pub get && flutter run`

## Debugging Tools

### Firebase App Check Debug Output
Look for the debug token in the console logs:
```
Firebase App Check Debug Token: YOUR_TOKEN_HERE
```

### Firebase Authentication Debug Mode
In the `main.dart` file, you can enable additional debug logs:
```dart
FirebaseAuth.instance.setSettings(
  appVerificationDisabledForTesting: true, // Only for development!
);
```

## Summary of Changes

1. **Fixed the reCAPTCHA Redirect Issue**:
   - Updated Firebase Auth Helper to prevent browser redirection
   - Added missing configuration for App Check

2. **Added Test Phone Number Functionality**:
   - Added a debug option to easily enter test phone numbers
   - Added instructions for adding test phone numbers in Firebase Console

3. **Improved Error Handling**:
   - Better debugging output for Auth-related issues
   - Added comprehensive testing instructions

These changes should eliminate the web browser reCAPTCHA verification and allow the app to properly handle phone authentication entirely within the app.
