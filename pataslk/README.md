# Pataslk App

## Firebase Authentication Setup

### SHA Certificate Setup (Required for Phone Auth)

To fix the "missing-client-identifier" error and enable phone authentication, you need to add SHA certificate fingerprints to your Firebase project:

#### For Debug SHA-1 and SHA-256:

1. Run the following command in your project directory:

   ```bash
   # For Windows
   cd android
   ./gradlew signingReport
   
   # For macOS/Linux
   cd android
   ./gradlew signingReport
   ```

2. Look for the "SHA1" and "SHA-256" values under the "Task :app:signingReport" section:

   - SHA1: `AB:07:C0:5D:82:BD:A2:3D:3E:67:3E:54:49:D2:B9:A3:E1:E1:34:F1`
   - SHA-256: `F8:93:D1:10:EC:0C:4E:A8:C0:B5:BC:A6:08:45:64:D8:FE:3B:2D:FF:1B:F4:DF:D7:F7:DF:31:E0:4E:D2:7E:9F`

3. Add these values to your Firebase project:
   - Go to Firebase Console → Project settings → Your apps
   - Add the SHA-1 and SHA-256 fingerprints exactly as shown above

### Add Test Phone Numbers (Essential for Development)

To bypass reCAPTCHA verification during development:

1. Go to Firebase Console → Authentication → Sign-in methods → Phone
2. Expand "Phone numbers for testing"
3. Add your test phone numbers with verification codes:
   - Phone number: `+94768713717`
   - Verification code: `123456`

This allows you to test phone authentication without actually sending SMS messages.

### Troubleshooting

#### reCAPTCHA Redirect Issue
If Firebase is redirecting to a web browser for reCAPTCHA verification:

1. Make sure your SHA certificate fingerprints are correctly added in Firebase
2. Add test phone numbers in Firebase console as described above
3. Check that the package name in Firebase matches your app's package name
4. Wait a few hours after adding fingerprints (sometimes changes take time to propagate)

#### For Production Release

1. Create a new keystore file using Android Studio or the keytool command
2. Extract SHA-1 and SHA-256 from the release keystore
3. Add these to Firebase Console
4. Remove debug test phone numbers before production release

### Troubleshooting Common Issues

1. **"Verification failed: missing-client-identifier"**: This means Firebase can't verify your app. Check SHA certificates in Firebase console.

2. **App Check Errors**: If you see "Error getting App Check token", check that App Check is properly configured in Firebase console.

3. **SMS Retriever Issues**: Ensure Google Play services are up to date on the test device.

### Development Testing Tips

- For development, you can enable debug verification:
  - Go to Firebase Console → Authentication → Phone → Phone numbers for testing
  - Add your test phone number
  - This will bypass actual SMS verification for listed numbers during development
