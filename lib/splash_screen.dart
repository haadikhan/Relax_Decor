import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventory_system/login_screen.dart';
import 'package:inventory_system/dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _colorAnimation;

  // Add a stream subscription for auth state changes
  StreamSubscription<User?>? _authSubscription;
  bool _authCheckCompleted = false;

  @override
  void initState() {
    super.initState();

    // 1. Setup the animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 2. Define multiple animations
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOutBack),
          ),
        );

    _colorAnimation = ColorTween(
      begin: Colors.teal.shade100,
      end: Colors.teal.shade50,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 3. Start the animations
    _controller.forward();

    // 4. Check authentication using stream (more reliable)
    _checkAuthenticationWithStream();
  }

  void _checkAuthenticationWithStream() {
    // Listen to auth state changes - this waits for Firebase to initialize
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        // This will be called when Firebase has determined the auth state
        if (!_authCheckCompleted) {
          _authCheckCompleted = true;
          _navigateBasedOnAuth(user);
        }
      },
      onError: (error) {
        // If there's an error, default to login screen
        if (!_authCheckCompleted) {
          _authCheckCompleted = true;
          _navigateToLogin();
        }
      },
    );

    // Add a timeout in case Firebase takes too long
    Timer(const Duration(seconds: 5), () {
      if (!_authCheckCompleted) {
        _authCheckCompleted = true;
        // If timeout occurs, check current user as fallback
        User? user = FirebaseAuth.instance.currentUser;
        _navigateBasedOnAuth(user);
      }
    });
  }

  void _navigateBasedOnAuth(User? user) async {
    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // Start fade out animation
      await _controller.reverse();

      if (user != null) {
        // User is logged in, go to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // User is not logged in, go to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  void _navigateToLogin() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      await _controller.reverse();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // Important: cancel the subscription
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _colorAnimation.value,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Animated Icon with multiple effects
                SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: RotationTransition(
                      turns: _rotationAnimation,
                      child: FadeTransition(
                        opacity: _opacityAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.teal.shade400,
                                    Colors.teal.shade700,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.shade300.withOpacity(
                                      0.5,
                                    ),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.spa,
                              size: 60.0,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.teal.shade800,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40.0),

                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Text(
                      'Mob World',
                      style: TextStyle(
                        fontSize: 42.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.teal.shade800,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.teal.shade200,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16.0),

                FadeTransition(
                  opacity: _opacityAnimation,
                  child: Text(
                    'Checking authentication...',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w300,
                      color: Colors.teal.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 50.0),

                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeInOut,
                          width: 200 * _controller.value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade400,
                                Colors.teal.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
