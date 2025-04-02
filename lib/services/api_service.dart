import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // for ChangeNotifier, debugPrint, etc.

/// Custom exceptions for server errors.
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

/// The main API service class.
///
/// This version only handles API requests related to Users, Additives, and
/// Fermentation Entries. All code related to Wines (barrels), MostTreatment,
/// offline local caching, and background synchronization has been removed.
class ApiService extends ChangeNotifier {
  // Base URL which can be updated dynamically.
  String _baseUrl;
  String get baseUrl => _baseUrl;
  set baseUrl(String newUrl) {
    if (newUrl.isEmpty) {
      debugPrint(
          '[ApiService] WARNING: Provided baseUrl is empty, using fallback');
      _baseUrl = '';
    } else {
      _baseUrl = newUrl;
    }
    debugPrint('[ApiService] baseUrl updated to $_baseUrl');
    notifyListeners();
  }

  /// Constructor requires an initial base URL.
  ApiService({required String baseUrl}) : _baseUrl = baseUrl;

  // ==========================================================================
  // ========== USERS ==========
  // ==========================================================================

  Future<String> loginUser(String email, String password) async {
    debugPrint('[ApiService] loginUser() called with email: $email');
    final url = Uri.parse('$_baseUrl/Users/Login');
    debugPrint('[ApiService] loginUser() - URL: $url');
    debugPrint(
        '[ApiService] loginUser() - Sending credentials for email: $email');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      debugPrint(
          '[ApiService] loginUser() - Response code: ${response.statusCode}');
      debugPrint('[ApiService] loginUser() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        if (token == null || token.toString().isEmpty) {
          throw Exception('Login failed: No token returned.');
        }
        return token.toString();
      } else if (response.statusCode == 401) {
        throw WrongPasswordException('Incorrect email or password.');
      } else {
        throw Exception(
            'Login failed (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] loginUser() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException(
            'Unable to connect to $url. Check your network.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/Users/Register');
    final body = {
      'username': username,
      'email': email,
      'password': password,
    };

    debugPrint('[ApiService] registerUser() - URL: $url');
    debugPrint('[ApiService] registerUser() - Request body: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      debugPrint(
          '[ApiService] registerUser() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] registerUser() - Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to register user (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] registerUser() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException(
            'Unable to connect to $url. Check your network.');
      }
      rethrow;
    }
  }

  Future<void> deleteAccount({required String token}) async {
    final url = Uri.parse('$_baseUrl/Users');
    debugPrint('[ApiService] deleteAccount() - URL: $url');
    debugPrint('[ApiService] deleteAccount() - Token: Bearer $token');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint(
          '[ApiService] deleteAccount() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] deleteAccount() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete account (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] deleteAccount() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException(
            'Unable to connect to $url. Check your network.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser({required String token}) async {
    final url = Uri.parse('$_baseUrl/Users');
    debugPrint('[ApiService] getCurrentUser() - URL: $url');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getCurrentUser() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getCurrentUser() - Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to retrieve current user (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getCurrentUser() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException(
            'Unable to connect to $url. Check your network.');
      }
      rethrow;
    }
  }

  // ==========================================================================
  // ========== ADDITIVES ==========
  // ==========================================================================

  Future<Map<String, dynamic>> getAdditive(int id,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/Additives/$id');
    debugPrint('[ApiService] getAdditive() - URL: $url');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getAdditive() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getAdditive() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to retrieve additive (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getAdditive() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<void> updateAdditive(int id, Map<String, dynamic> additive,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/Additives/$id');
    debugPrint('[ApiService] updateAdditive() - URL: $url');
    debugPrint('[ApiService] updateAdditive() - Request body: $additive');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(additive),
      );
      debugPrint(
          '[ApiService] updateAdditive() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] updateAdditive() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to update additive: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] updateAdditive() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<void> deleteAdditive(int id, {required String token}) async {
    final url = Uri.parse('$_baseUrl/Additives/$id');
    debugPrint('[ApiService] deleteAdditive() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.delete(url, headers: headers);
      debugPrint(
          '[ApiService] deleteAdditive() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] deleteAdditive() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete additive: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] deleteAdditive() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createAdditive(Map<String, dynamic> additive,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/Additives');
    debugPrint('[ApiService] createAdditive() - URL: $url');
    debugPrint('[ApiService] createAdditive() - Request body: $additive');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(additive),
      );
      debugPrint(
          '[ApiService] createAdditive() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] createAdditive() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to create additive (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] createAdditive() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  // ==========================================================================
  // ========== FERMENTATION ENTRIES ==========
  // ==========================================================================

  Future<void> addFermentationEntry({
    required String token,
    required DateTime date,
    required double density,
    required String wineId,
  }) async {
    debugPrint('[ApiService] addFermentationEntry() called');
    final url = Uri.parse('$_baseUrl/FermentationEntries');
    final body = {
      'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(date),
      'density': density,
      'wineId': wineId,
    };

    debugPrint('[ApiService] addFermentationEntry() - URL: $url');
    debugPrint('[ApiService] addFermentationEntry() - Body: $body');
    debugPrint('[ApiService] addFermentationEntry() - Token: Bearer $token');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      debugPrint(
          '[ApiService] addFermentationEntry() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] addFermentationEntry() - Response body: ${response.body}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add fermentation entry: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] addFermentationEntry() - Error: $e');
      if (e.toString().contains('SocketException') ||
          e is NoResponseException) {
        throw NoResponseException(
            'Unable to add fermentation entry. Please check your network connection.');
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> getFermentationEntry(int id,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/FermentationEntries/$id');
    debugPrint('[ApiService] getFermentationEntry() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getFermentationEntry() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getFermentationEntry() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to retrieve fermentation entry: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getFermentationEntry() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<void> updateFermentationEntry(int id, Map<String, dynamic> entry,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/FermentationEntries/$id');
    debugPrint('[ApiService] updateFermentationEntry() - URL: $url');
    debugPrint('[ApiService] updateFermentationEntry() - Request body: $entry');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(entry),
      );
      debugPrint(
          '[ApiService] updateFermentationEntry() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] updateFermentationEntry() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update fermentation entry: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] updateFermentationEntry() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<void> deleteFermentationEntry(int id, {required String token}) async {
    final url = Uri.parse('$_baseUrl/FermentationEntries/$id');
    debugPrint('[ApiService] deleteFermentationEntry() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.delete(url, headers: headers);
      debugPrint(
          '[ApiService] deleteFermentationEntry() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] deleteFermentationEntry() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete fermentation entry: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] deleteFermentationEntry() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }
}
