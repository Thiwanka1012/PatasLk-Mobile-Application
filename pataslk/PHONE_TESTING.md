# Phone Authentication Testing Guide

## Setup Test Phone Numbers in Firebase

1. Go to Firebase Console > Authentication > Sign-in methods > Phone
2. Enable Phone Authentication if not already enabled
3. Under "Phone numbers for testing" add:
   ```
   +94768713717:123456
   ```
   This will associate the test number with verification code 123456

## Important App Settings

In `main.dart`, we've added:
```dart
FirebaseAuth.instance.setSettings(
  appVerificationDisabledForTesting: true,
);
```

This setting:
- Bypasses reCAPTCHA verification for testing
- Works with test phone numbers added to Firebase
- Must be REMOVED before production release!

## Testing Real Phone Numbers

To test with real phone numbers:

1. Make sure the SHA-1 certificate is correctly added to Firebase:
   ```
   SHA-1: AB:07:C0:5D:82:BD:A2:3D:3E:67:3E:54:49:D2:B9:A3:E1:E1:34:F1
   ```

2. Check Firebase App Check Console:
   - Go to Firebase Console > App Check
   - Add the debug token printed in your console logs to the allowlist
   - This debug token starts with: `da75c52e-c18c-4cfc-a547-0412d44e988f`

3. Test different authentication scenarios:
   - Testing with a phone number already registered
   - Testing with a new phone number
   - Testing with invalid verification codes

## Troubleshooting

If you see these errors:

1. `App attestation failed` - Check App Check settings and add debug token to allowlist

2. `Recaptcha verification failed - EXPIRED` - Try using test phone numbers during development

3. `captcha-check-failed` - Make sure the SHA-1 fingerprint is correct in Firebase, and consider using Debug provider for App Check

## Production Deployment Checklist

Before deploying to production:

1. Remove `appVerificationDisabledForTesting` setting
2. Remove test phone numbers from Firebase
3. Switch to `safetyNet` provider for App Check
4. Add release keystore SHA-1 and SHA-256 to Firebase
