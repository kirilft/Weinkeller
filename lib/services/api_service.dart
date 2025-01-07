// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Custom exceptions defined directly in this file
class WrongPasswordException implements Exception {
  final String message;
  WrongPasswordException(this.message);

  @override
  String toString() => 'WrongPasswordException: $message';
}

class NoResponseException implements Exception {
  final String message;
  NoResponseException(this.message);

  @override
  String toString() => 'NoResponseException: $message';
}

/// The main API service class
class ApiService {
  final String baseUrl;

  /// By default, connects to localhost:8080
  /// For Android emulator, you might need 'http://10.0.2.2:8080' instead.
  ApiService({this.baseUrl = 'http://10.20.30.19:8080'});

  /// Example: Perform a login request and return a token if successful
  /// Throws:
  /// - [WrongPasswordException] if server returns 401
  /// - [NoResponseException] if there's a network/socket issue
  /// - [Exception] for other error statuses
  Future<String> loginUser(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      // Distinguish by status code
      if (response.statusCode == 200) {
        // Parse the token from response
        final data = jsonDecode(response.body);
        final token = data['token'];
        if (token == null || token.isEmpty) {
          throw Exception('Login failed: No token returned.');
        }
        return token;
      } else if (response.statusCode == 401) {
        // Typically 401 indicates invalid credentials
        throw WrongPasswordException('Incorrect email or password.');
      } else {
        // Any other non-200 status code
        throw Exception(
          'Login failed with status code ${response.statusCode}\n'
          'Response body: ${response.body}',
        );
      }
    } catch (e) {
      // If we detect a socket/network issue, rethrow as NoResponseException
      if (e.toString().contains('SocketException')) {
        throw NoResponseException(
            'Unable to contact the server. Check your network.');
      }
      rethrow; // Otherwise rethrow any other exceptions
    }
  }

  /// Example function to save QR data to the server
  Future<void> saveQrData({
    required String token,
    required String qrData,
    required String userInput,
  }) async {
    final url = Uri.parse('$baseUrl/api/qr/save');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'qrData': qrData,
          'userInput': userInput,
        }),
      );

      if (response.statusCode == 200) {
        // Successfully saved
        return;
      } else {
        throw Exception(
          'Failed to save QR data. '
          'Status code: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      // If there's a socket/network error, optionally convert it similarly:
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to reach the server.');
      }
      rethrow;
    }
  }
}
