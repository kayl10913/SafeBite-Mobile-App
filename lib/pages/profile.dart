// pages/profile.dart

import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'home.dart';
import 'notification.dart';
import 'analysis.dart';
import '../services/session_service.dart';
import '../loginscreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Base URL for the Express backend (use 10.0.2.2 for Android emulator)
const String baseUrl = 'http://10.0.2.2:3000/api';
// Base URL for the Express backend when running on a website or local browser
const String websiteBaseUrl = 'http://localhost:3000/api';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfilePage({super.key, required this.user});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _sessionService = SessionService();
  bool _isLoading = false;

  // Using TextEditingControllers for better control and to set initial values
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _sessionToken; // Store the session token if available

  @override
  void initState() {
    super.initState();
    // Populate controllers with the logged-in user's data
    _firstNameController.text = widget.user['first_name'] ?? '';
    _lastNameController.text = widget.user['last_name'] ?? '';
    _usernameController.text = widget.user['username'] ?? '';
    _emailController.text = widget.user['email'] ?? '';
    _contactNumberController.text = widget.user['contact_number']?.toString() ?? '';
    // Optionally, get the session token from user or app state
    _sessionToken = widget.user['session_token'];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do not proceed
    }

    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> updatedData = {
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'username': _usernameController.text,
      'email': _emailController.text,
      'contact_number': _contactNumberController.text,
    };
    
    // Only include the password if it has been changed
    if (_passwordController.text.isNotEmpty) {
      updatedData['password'] = _passwordController.text;
    }

    final userId = widget.user['user_id'] ?? widget.user['id'];
    if (userId == null) {
      _showErrorDialog('Login Failed', 'User ID not found in response.');
      return;
    }
    final result = await _userService.updateUser(userId.toString(), updatedData);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout() async {
    if (_sessionToken == null) {
      // If no session token, just go to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }
    setState(() { _isLoading = true; });

    // Call the backend to delete the session
    final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
    final response = await http.delete(
      Uri.parse('$apiUrl/session/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'session_token': _sessionToken}),
    );

    setState(() { _isLoading = false; });

    // Remove session token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');

    // Regardless of result, navigate to login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: const Color(0xFF8BA3BF),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0B1739),
        elevation: 0,
        automaticallyImplyLeading: false, // Removes back button
      ),
      body: Form(
          key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            children: [
            // User Avatar section
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.9),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: const Color(0xFF0B1739).withOpacity(0.7),
              ),
              ),
            ),
            const SizedBox(height: 24),

            // Personal Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Color(0xFFF2F4F7),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1739))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_firstNameController, 'First Name', Icons.person_outline)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_lastNameController, 'Last Name', Icons.person_outline)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_usernameController, 'Username', Icons.alternate_email),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildTextField(_contactNumberController, 'Contact Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Security Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Color(0xFFF2F4F7),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Update Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1739))),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _passwordController,
                      label: 'New Password (optional)',
                      isObscured: _obscurePassword,
                      toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirm New Password',
                      isObscured: _obscureConfirmPassword,
                      toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                  }
                  return null;
                },
              ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B1739),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 5,
                ),
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 20),
            // Logout Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 5,
              ),
              onPressed: _isLoading ? null : _logout,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0B1739),
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => SafeBiteHomePage(user: widget.user)),
            );
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => NotificationPage(user: widget.user)),
            );
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => AnalysisPage(user: widget.user)),
            );
          }
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label == 'Email' && !value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback toggleObscure,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: _inputDecoration(label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off, color: Color(0xFF0B1739).withOpacity(0.7)),
          onPressed: toggleObscure,
        ),
      ),
      validator: validator ?? (value) {
        if (label == 'New Password (optional)' && (value == null || value.isEmpty)) {
          return null; // Optional field can be empty
        }
        if (value == null || value.isEmpty) {
          return 'Please enter the password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF0B1739)),
      prefixIcon: Icon(icon, color: Color(0xFF0B1739).withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0B1739), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

Future<String?> getSessionToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('session_token');
}