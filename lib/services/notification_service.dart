import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  // Base URL for the Express backend (use 10.0.2.2 for Android emulator)
  static const String baseUrl = 'http://192.168.100.128:3000/api';
  // Base URL for the Express backend when running on a website or local browser
  static const String websiteBaseUrl = 'http://localhost:3000/api';

  // Get all alerts from the backend
  Future<Map<String, dynamic>> getAlerts() async {
    try {
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.get(
        Uri.parse('$apiUrl/alerts'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'alerts': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to retrieve alerts',
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
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.get(Uri.parse('$apiUrl/alerts')).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getAlertsForUser(dynamic userId) async {
    try {
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.get(
        Uri.parse('$apiUrl/alerts?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: Please check your connection',
      };
    }
  }
} 