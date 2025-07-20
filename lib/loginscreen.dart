import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'pages/home.dart'; // Import the home page
import 'services/user_service.dart';
import 'forgot_password_screen.dart';
import 'dart:convert';
import 'services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Base URL for the Express backend (use 10.0.2.2 for Android emulator)
const String baseUrl = 'http://192.168.100.128:3000/api';
    // Base URL for the Express backend when running on a website or local browser
const String websiteBaseUrl = 'http://localhost:3000/api';

// LoginScreen: Allows the user to log in to their account
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();
  final _sessionService = SessionService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? sessionToken;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if backend is available
      bool isBackendAvailable = await _userService.isBackendAvailable();
      if (!isBackendAvailable) {
        _showErrorDialog('Connection Error', 'Cannot connect to server. Please make sure the backend is running.');
        return;
      }

      final result = await _userService.loginUser(
        emailOrUsername: _emailOrUsernameController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success']) {
        // Clear form after successful login
        _emailOrUsernameController.clear();
        _passwordController.clear();
        
        // The user data returned from the API
        final user = result['user'];
        print('User object after login: $user'); // Debug print
        final userId = user['user_id'] ?? user['id'];
        if (userId == null) {
          _showErrorDialog('Login Failed', 'User ID not found in response.');
          return;
        }
        final sessionResult = await _sessionService.createSession(userId);
        if (sessionResult['success']) {
          sessionToken = sessionResult['session_token'];
          user['session_token'] = sessionToken;

          // Save session token to shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_token', sessionToken!);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => SafeBiteHomePage(user: user)),
          );
        } else {
          _showErrorDialog('Login Failed', sessionResult['error'] ?? 'Invalid session creation');
        }
      } else {
        _showErrorDialog('Login Failed', result['error'] ?? 'Invalid credentials');
      }
    } catch (e) {
      _showErrorDialog('Error', 'An unexpected error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo
                const SizedBox(height: 40),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    children: [
                      TextSpan(
                        text: 'Safe',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'Bite',
                        style: TextStyle(color: Color(0xFF7FA6C9)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                const Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                  // Email or Username field
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      'Email or Username',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailOrUsernameController,
                  style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email or username';
                      }
                      return null;
                    },
                  decoration: InputDecoration(
                      hintText: 'Enter Email or Username',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.transparent,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF7FA6C9)),
                    ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                  ),
                ),
                const SizedBox(height: 18),
                // Password field
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  decoration: InputDecoration(
                    hintText: 'Enter Password',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.transparent,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF7FA6C9)),
                    ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                  ),
                ),
                const SizedBox(height: 28),
                  // Sign in Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Sign in',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  // Forgot Password?
                  Container(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                    onPressed: () {
                        // Navigate to ForgotPasswordScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.white70,
                          decoration: TextDecoration.underline,
                        ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 