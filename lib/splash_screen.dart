import 'dart:async';
import 'package:flutter/material.dart';

import 'package:inventory_system/login_screen.dart';

// --- The Splash Screen Widget ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup the animation controller for the fade effect
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // Fade duration
      vsync: this,
    );

    // 2. Define the opacity curve
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 3. Start the timer for the splash screen duration
    // The splash screen will show for 3 seconds (3000ms) before transitioning.
    Timer(const Duration(milliseconds: 3000), () async {
      // Start the fade-out animation
      await _controller.forward();

      // Navigate to the home screen, replacing the splash screen in the stack
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The FadeTransition uses the animation controller to fade the content out.
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Scaffold(
        backgroundColor: Colors.teal.shade50, // Light, calm background
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Placeholder for your app logo (e.g., a Leaf or Home icon)
              Icon(
                Icons.spa, // Relaxing icon for 'Relax Decor'
                size: 100.0,
                color: Colors.teal.shade700,
              ),
              const SizedBox(height: 24.0),
              // App Title
              Text(
                'Relax Decor',
                style: TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.teal.shade800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16.0),
              // Loading indicator
              const SizedBox(
                width: 150,
                child: LinearProgressIndicator(
                  color: Colors.teal,
                  backgroundColor: Colors.tealAccent,
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Creating your serene space...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
