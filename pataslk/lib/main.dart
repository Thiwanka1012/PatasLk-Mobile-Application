import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart'; // Add this import
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'screens/auth/user_type_screen.dart';
import 'screens/service_provider/home/service_provider_home_screen.dart';
import 'screens/customer/home/home_screen.dart';
import 'utils/firebase_auth_helper.dart';
import 'utils/firebase_firestore_helper.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    // Firebase Core: Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Firebase App Check: Activate security features to prevent unauthorized API usage
    await FirebaseAppCheck.instance.activate(
      // Use platform-specific verification providers
      androidProvider: AndroidProvider.playIntegrity, // Android Play Integrity API
      appleProvider: AppleProvider.deviceCheck, // Apple DeviceCheck API
    );
    debugPrint('Firebase App Check activated with production providers');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patas.lk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      home: const SafeStartupScreen(),
    );
  }
}

// This simple loading screen prevents navigation conflicts during startup
class SafeStartupScreen extends StatefulWidget {
  const SafeStartupScreen({super.key});

  @override
  State<SafeStartupScreen> createState() => _SafeStartupScreenState();
}

class _SafeStartupScreenState extends State<SafeStartupScreen> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to avoid navigation during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _safeNavigate();
    });
  }
  
  Future<void> _safeNavigate() async {
    if (!mounted) return;
    
    // Navigate to authentication check screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Simple loading screen with no navigation logic in build method
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final FirebaseAuthHelper _authHelper = FirebaseAuthHelper();
  final FirestoreHelper _firestoreHelper = FirestoreHelper();
  bool _isChecking = true;
  
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to avoid navigation during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }
  
  Future<void> _checkAuthentication() async {
    if (!mounted) return;
    
    try {
      if (_authHelper.isAuthenticated()) {
        final user = _authHelper.getCurrentUser();
        if (user != null) {
          // Check if this user is a service provider
          try {
            final serviceProviderDoc = await _firestoreHelper.getUserDocument(
              collection: 'serviceProviders', 
              uid: user.uid
            );
            
            if (serviceProviderDoc != null && serviceProviderDoc.exists && mounted) {
              // Navigate to service provider home with a small delay
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ServiceProviderHomeScreen()),
              );
              return;
            }
            
            // Then check if user is a customer
            final customerDoc = await _firestoreHelper.getUserDocument(
              collection: 'customers', 
              uid: user.uid
            );
            
            if (customerDoc != null && customerDoc.exists && mounted) {
              // Navigate to customer home
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              return;
            }
          } catch (e) {
            debugPrint("Error checking user type: $e");
          }
        }
      }
      
      // If not authenticated or user type not found, go to splash screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    } catch (e) {
      debugPrint("Auth check error: $e");
      // On error, default to splash screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigating = false;
  
  @override
  void initState() {
    super.initState();
    // Navigate to the user type screen after 3 seconds, but prevent multiple navigations
    Future.delayed(const Duration(seconds: 3), () {
      _safeNavigateToUserType();
    });
  }
  
  void _safeNavigateToUserType() {
    if (mounted && !_navigating) {
      setState(() {
        _navigating = true;
      });
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UserTypeScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Center(
        child: Image.asset(
          'assets/logo 1 (1).png', // Ensure this asset path is correct.
          width: 130,
          height: 130,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
