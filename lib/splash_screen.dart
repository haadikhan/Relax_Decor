import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart'; // Make sure to import your login screen
import 'dashboard.dart'; // Make sure to import your home screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Wait a bit to show splash screen
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      // Check if Firebase is already initialized
      try {
        Firebase.app();
      } catch (e) {
        // Firebase not initialized, initialize it
        await Firebase.initializeApp();
      }

      if (!mounted) return;

      // Check authentication status
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      // Navigate based on auth status using direct widgets
      if (user != null) {
        // User is logged in, go to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // User not logged in, go to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      if (!mounted) return;

      // On error, go to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            // App Name
            Text(
              'Mob World',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Inventory Management',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 50),

            // Loading Indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Loading...',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
