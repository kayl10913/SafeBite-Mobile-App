import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserService {
  // Base URL for the Express backend (use 10.0.2.2 for Android emulator)
  static const String baseUrl = 'http://192.168.100.128:3000/api';
  // Base URL for the Express backend when running on a website or local browser
  static const String websiteBaseUrl = 'http://localhost:3000/api';
  
  // Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password strength
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Validate password confirmation
  bool doPasswordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  // Validate name (first name, last name, full name)
  bool isValidName(String name) {
    return name.trim().length >= 2 && RegExp(r'^[a-zA-Z\s]+$').hasMatch(name.trim());
  }

  // Validate username
  bool isValidUsername(String username) {
    return username.trim().length >= 3 && RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username.trim());
  }

  // Validate phone number
  bool isValidPhoneNumber(String contact_number) {
    // Allow various phone number formats
    return RegExp(r'^[\+]?[0-9\s\-\(\)]{10,15}$').hasMatch(contact_number.trim());
  }

  // Register a new user via API
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String username,
    required String contact_number,
    required bool acceptTerms,
    required bool acceptPrivacy,
  }) async {
    try {
      // Client-side validation
      if (!isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
        };
      }

      if (!isValidPassword(password)) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters long',
        };
      }

      if (!doPasswordsMatch(password, confirmPassword)) {
        return {
          'success': false,
          'message': 'Passwords do not match',
        };
      }

      if (!isValidName(firstName)) {
        return {
          'success': false,
          'message': 'First name must be at least 2 characters and contain only letters',
        };
      }

      if (!isValidName(lastName)) {
        return {
          'success': false,
          'message': 'Last name must be at least 2 characters and contain only letters',
        };
      }

      if (!isValidUsername(username)) {
        return {
          'success': false,
          'message': 'Username must be at least 3 characters and contain only letters, numbers, and underscores',
        };
      }

      if (!isValidPhoneNumber(contact_number)) {
        return {
          'success': false,
          'message': 'Please enter a valid phone number',
        };
      }

      if (!acceptTerms) {
        return {
          'success': false,
          'message': 'You must accept the Terms and Conditions',
        };
      }

      if (!acceptPrivacy) {
        return {
          'success': false,
          'message': 'You must accept the Data Privacy Policy',
        };
      }

      // Make API call to register user
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/newuser'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password, // Note: In production, this should be hashed
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'username': username.trim(),
          'contact_number': contact_number.trim(),
          'acceptTerms': acceptTerms,
          'acceptPrivacy': acceptPrivacy,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        return {
          'success': true,
          'message': data['message'],
          'userId': data['userId'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: Please check your connection',
      };
    }
  }

  // Login user via API
  Future<Map<String, dynamic>> loginUser({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      // Client-side validation
      if (emailOrUsername.isEmpty) {
        return {
          'success': false,
          'message': 'Please enter your email or username',
        };
      }

      if (password.isEmpty) {
        return {
          'success': false,
          'message': 'Please enter your password',
        };
      }

      // Make API call to login user
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': emailOrUsername, // Backend will check both email and username
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: Please check your connection',
      };
    }
  }

  // Get all users (for testing)
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.get(
        Uri.parse('$apiUrl/users'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'users': data['users'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to get users',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: Please check your connection',
      };
    }
  }

  // Check if backend is available
  Future<bool> isBackendAvailable() async {
    try {
      // We ping the /users endpoint as a simple way to check for a server response.
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.get(Uri.parse('$apiUrl/users')).timeout(const Duration(seconds: 3));
      // A 200 OK response means the server is up.
      return response.statusCode == 200;
    } catch (e) {
      // Any exception (like a timeout) means the backend is not available.
      return false;
    }
  }

  // Update a user's profile data
  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.put(
        Uri.parse('$apiUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update user'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: Please check your connection',
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to reset password'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: Please try again'};
    }
  }
} 