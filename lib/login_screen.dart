import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:inventory_system/dashboard.dart';
import 'package:inventory_system/signup_screen.dart';
// Corrected import for the main screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Changed to Email Controller
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false; // State to manage loading indicator

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      // 1. Attempt to sign in with email and password using Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Successful login: Navigate to HomeScreen
      debugPrint(
        'Login successful for user: ${FirebaseAuth.instance.currentUser!.email}',
      );
      // Use pushReplacement so the user can't go back to the login screen using the back button
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // 3. Handle Firebase-specific errors
      String message;
      debugPrint('Firebase Auth Error Code: ${e.code}');

      switch (e.code) {
        case 'user-not-found':
          message =
              'No user found for that email. Please check your email or register.';
          break;
        case 'wrong-password':
        case 'invalid-credential': // Used for general failed sign-in in newer SDKs
          message = 'Invalid password or credentials. Please try again.';
          break;
        case 'invalid-email':
          message = 'The email address format is invalid.';
          break;
        case 'too-many-requests':
          message = 'Too many failed login attempts. Try again later.';
          break;
        default:
          message =
              'An unknown authentication error occurred. Please try again.';
          break;
      }

      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      // 4. Handle general errors (e.g., network issues)
      debugPrint('General Login Error: $e');
      setState(() {
        _errorMessage =
            'Login failed due to a general error. Check network connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // App Logo/Icon
                Icon(Icons.spa, size: 80.0, color: Colors.teal.shade600),
                const SizedBox(height: 16.0),
                Text(
                  'Mob World Login',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                const SizedBox(height: 40.0),

                // Email Field (formerly Username)
                TextFormField(
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress, // Set keyboard type for email
                  decoration: InputDecoration(
                    labelText: 'Email', // Changed label
                    hintText: 'Enter your email address', // Changed hint
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.email,
                      color: Colors.teal,
                    ), // Changed icon
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    // Basic email validation
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    // Validation for password length
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30.0),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _login, // Disable button while loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 5,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 20.0),

                // Registration Link
                TextButton(
                  onPressed: () {
                    // Navigate to the Signup screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Don't have an account? Register here.", // Updated text
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
