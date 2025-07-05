import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class AnalyticsService {
  // Base URL for the analytics endpoints
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  // Base URL for the Express backend when running on a website or local browser
  static const String websiteBaseUrl = 'http://localhost:3000/api';

  // Helper method to make GET requests
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.get(Uri.parse('$apiUrl/$endpoint')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data;
        } else {
          throw Exception('Backend returned success:false');
        }
      } else {
        throw Exception('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Re-throw the exception to be caught by the FutureBuilder
      throw Exception('Failed to connect to the analytics service: ${e.toString()}');
    }
  }

  // Fetch summary data for the AI Analyzer box
  Future<Map<String, dynamic>> getSummaryData() async {
    return _get('summary');
  }

  // Fetch data for the sensor activity chart
  Future<Map<String, dynamic>> getSensorActivityData() async {
    return _get('sensor-activity');
  }

  // Fetch data for the food risk chart
  Future<Map<String, dynamic>> getFoodRiskData() async {
    return _get('food-risk');
  }

  // Fetch the most recent food detections
  Future<Map<String, dynamic>> getRecentDetections() async {
    return _get('recent-detections');
  }
} 