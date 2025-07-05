import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class SessionService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/session';
  // Base URL for the Express backend when running on a website or local browser
  static const String websiteBaseUrl = 'http://localhost:3000/api/session';

  // Create a new session (login)
  Future<Map<String, dynamic>> createSession(int userId) async {
    final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
    final response = await http.post(
      Uri.parse('$apiUrl/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    return jsonDecode(response.body);
  }

  // Validate a session token
  Future<Map<String, dynamic>> validateSession(String sessionToken) async {
    final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
    final response = await http.get(
      Uri.parse('$apiUrl/validate?session_token=$sessionToken'),
      headers: {'Content-Type': 'application/json'},
    );
    return jsonDecode(response.body);
  }

  // Delete a session (logout)
  Future<Map<String, dynamic>> deleteSession(String sessionToken) async {
    final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
    final response = await http.delete(
      Uri.parse('$apiUrl/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'session_token': sessionToken}),
    );
    return jsonDecode(response.body);
  }
} 