import 'dart:convert';
// For SocketException
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // for ChangeNotifier, debugPrint, etc.

// Custom exceptions for server errors.
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
/// This version only handles API requests related to Users, Additives,
/// Fermentation Entries, WineTypes, and now AdditiveTypes.
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

  /// **NEW**: Retrieve all AdditiveTypes from the /api/AdditiveTypes endpoint.
  Future<List<Map<String, dynamic>>> getAllAdditiveTypes(
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/AdditiveTypes');
    debugPrint('[ApiService] getAllAdditiveTypes() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getAllAdditiveTypes() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getAllAdditiveTypes() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        // Convert each JSON object into a Map<String, dynamic>.
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to retrieve additive types (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getAllAdditiveTypes() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  // ==========================================================================
  // ========== FERMENTATION ENTRIES ==========
  // ==========================================================================

  /// **Adds a fermentation entry**. We rename the parameter from `winebarrelid` to `wineId`
  /// in the final payload to match the server's expectation.
  Future<void> addFermentationEntry({
    required String token,
    required DateTime date,
    required double density,
    required String winebarrelid, // Keep this parameter unchanged
  }) async {
    debugPrint('[ApiService] addFermentationEntry() called');
    final url = Uri.parse('$_baseUrl/FermentationEntries');
    final body = {
      'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
          .format(date.toUtc()), // Use UTC
      'density': density,
      'wineId': winebarrelid, // the server expects 'wineId'
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
        // Try to parse error response for more details
        String errorDetails = response.body;
        try {
          final decodedBody = jsonDecode(response.body);
          if (decodedBody is Map && decodedBody.containsKey('title')) {
            errorDetails = decodedBody['title'];
            if (decodedBody.containsKey('errors')) {
              errorDetails += ': ${jsonEncode(decodedBody['errors'])}';
            }
          }
        } catch (_) {
          // Ignore decoding errors, use raw body
        }
        throw Exception(
            'Failed to add fermentation entry (status ${response.statusCode}): $errorDetails');
      }
    } catch (e) {
      debugPrint('[ApiService] addFermentationEntry() - Error: $e');
      if (e is NoResponseException) {
        rethrow; // Re-throw specific exception if already caught
      } else if (e.toString().contains('SocketException')) {
        throw NoResponseException(
            'Unable to add fermentation entry. Please check your network connection.');
      } else {
        rethrow; // Re-throw other exceptions
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

  // ==========================================================================
  // ========== WINE TYPES ==========
  // ==========================================================================

  Future<List<Map<String, dynamic>>> getAllWineTypes(
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineTypes');
    debugPrint('[ApiService] getAllWineTypes() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getAllWineTypes() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getAllWineTypes() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to retrieve wine types (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getAllWineTypes() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createWineType(Map<String, dynamic> wineType,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineTypes');
    debugPrint('[ApiService] createWineType() - URL: $url');
    debugPrint('[ApiService] createWineType() - Request body: $wineType');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response =
          await http.post(url, headers: headers, body: jsonEncode(wineType));
      debugPrint(
          '[ApiService] createWineType() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] createWineType() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to create wine type (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] createWineType() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWineType(String id,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineTypes/$id');
    debugPrint('[ApiService] getWineType() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getWineType() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getWineType() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to retrieve wine type (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getWineType() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<void> updateWineType(String id, Map<String, dynamic> wineType,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineTypes/$id');
    debugPrint('[ApiService] updateWineType() - URL: $url');
    debugPrint('[ApiService] updateWineType() - Request body: $wineType');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response =
          await http.put(url, headers: headers, body: jsonEncode(wineType));
      debugPrint(
          '[ApiService] updateWineType() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] updateWineType() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to update wine type: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] updateWineType() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<void> deleteWineType(String id, {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineTypes/$id');
    debugPrint('[ApiService] deleteWineType() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.delete(url, headers: headers);
      debugPrint(
          '[ApiService] deleteWineType() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] deleteWineType() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete wine type: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] deleteWineType() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  // ==========================================================================
  // ========== NEW API ENDPOINTS ==========
  // ========== ADDITIVE TYPES ==========

  /// Create a new Additive (mapped to the /api/Additives endpoint).
  /// **FIXED:** This method now directly uses the 'additive' map parameter,
  /// assuming ApiManager has already prepared the correct keys.
  Future<Map<String, dynamic>> createAdditive(Map<String, dynamic> additive,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/Additives');
    debugPrint('[ApiService] createAdditive() - URL: $url');

    // *** FIX START ***
    // Remove the redundant key adjustment. Assume 'additive' map has correct keys.
    // final adjustedAdditive = {
    //   'wineId': additive['winebarrelid'], // Problematic line removed
    //   'additiveTypeId': additive['type'], // Problematic line removed
    //   'amount': additive['amount'],
    //   'unit': additive['unit'],
    //   'addedAt': additive['addedAt'],
    // };
    // Use the 'additive' map directly as it should already be adjusted by ApiManager
    debugPrint(
        '[ApiService] createAdditive() - Request body (as received): $additive');
    // *** FIX END ***

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        // *** FIX: Send the original 'additive' map directly ***
        body: jsonEncode(additive),
      );
      debugPrint(
          '[ApiService] createAdditive() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] createAdditive() - Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Try to parse error response for more details
        String errorDetails = response.body;
        try {
          final decodedBody = jsonDecode(response.body);
          if (decodedBody is Map && decodedBody.containsKey('title')) {
            errorDetails = decodedBody['title'];
            if (decodedBody.containsKey('errors')) {
              errorDetails += ': ${jsonEncode(decodedBody['errors'])}';
            }
          }
        } catch (_) {
          // Ignore decoding errors, use raw body
        }
        throw Exception(
            'Failed to create additive (status ${response.statusCode}): $errorDetails');
      }
    } catch (e) {
      debugPrint('[ApiService] createAdditive() - Error: $e');
      if (e is NoResponseException) {
        rethrow; // Re-throw specific exception if already caught
      } else if (e.toString().contains('SocketException')) {
        throw NoResponseException(
            'Unable to create additive. Please check your network connection.');
      } else {
        rethrow; // Re-throw other exceptions
      }
    }
  }

  /// Retrieve an AdditiveType by its ID.
  Future<Map<String, dynamic>> getAdditiveType(String id,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/AdditiveTypes/$id');
    debugPrint('[ApiService] getAdditiveType() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getAdditiveType() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getAdditiveType() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to retrieve additive type (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getAdditiveType() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Update an existing AdditiveType.
  Future<void> updateAdditiveType(String id, Map<String, dynamic> additiveType,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/AdditiveTypes/$id');
    debugPrint('[ApiService] updateAdditiveType() - URL: $url');
    debugPrint(
        '[ApiService] updateAdditiveType() - Request body: $additiveType');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response =
          await http.put(url, headers: headers, body: jsonEncode(additiveType));
      debugPrint(
          '[ApiService] updateAdditiveType() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] updateAdditiveType() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to update additive type: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] updateAdditiveType() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Delete an AdditiveType.
  Future<void> deleteAdditiveType(String id, {required String token}) async {
    final url = Uri.parse('$_baseUrl/AdditiveTypes/$id');
    debugPrint('[ApiService] deleteAdditiveType() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.delete(url, headers: headers);
      debugPrint(
          '[ApiService] deleteAdditiveType() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] deleteAdditiveType() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete additive type: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] deleteAdditiveType() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  // ========== WINE BARRELS ==========

  /// Retrieve all WineBarrels.
  Future<List<Map<String, dynamic>>> getAllWineBarrels(
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels');
    debugPrint('[ApiService] getAllWineBarrels() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getAllWineBarrels() - Response code: ${response.statusCode}');
      // Limit log output for potentially large responses
      debugPrint(
          '[ApiService] getAllWineBarrels() - Response body length: ${response.bodyBytes.length}');
      // debugPrint('[ApiService] getAllWineBarrels() - Response body: ${response.body}'); // Optionally log full body if needed

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to retrieve wine barrels (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getAllWineBarrels() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Create a new WineBarrel.
  Future<Map<String, dynamic>> createWineBarrel(Map<String, dynamic> wineBarrel,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels');
    debugPrint('[ApiService] createWineBarrel() - URL: $url');
    debugPrint('[ApiService] createWineBarrel() - Request body: $wineBarrel');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response =
          await http.post(url, headers: headers, body: jsonEncode(wineBarrel));
      debugPrint(
          '[ApiService] createWineBarrel() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] createWineBarrel() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to create wine barrel (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] createWineBarrel() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Retrieve a WineBarrel by its ID.
  Future<Map<String, dynamic>> getWineBarrel(String id,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id');
    debugPrint('[ApiService] getWineBarrel() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getWineBarrel() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getWineBarrel() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('Wine barrel with ID $id not found.');
      } else {
        throw Exception(
            'Failed to retrieve wine barrel (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getWineBarrel() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Update an existing WineBarrel.
  Future<void> updateWineBarrel(String id, Map<String, dynamic> wineBarrel,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id');
    debugPrint('[ApiService] updateWineBarrel() - URL: $url');
    debugPrint('[ApiService] updateWineBarrel() - Request body: $wineBarrel');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response =
          await http.put(url, headers: headers, body: jsonEncode(wineBarrel));
      debugPrint(
          '[ApiService] updateWineBarrel() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] updateWineBarrel() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to update wine barrel: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] updateWineBarrel() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Delete a WineBarrel.
  Future<void> deleteWineBarrel(String id, {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id');
    debugPrint('[ApiService] deleteWineBarrel() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.delete(url, headers: headers);
      debugPrint(
          '[ApiService] deleteWineBarrel() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] deleteWineBarrel() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete wine barrel: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] deleteWineBarrel() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Retrieve the WineBarrelHistory for a given WineBarrel.
  Future<List<Map<String, dynamic>>> getWineBarrelHistory(String id,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id/WineBarrelHistory');
    debugPrint('[ApiService] getWineBarrelHistory() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getWineBarrelHistory() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getWineBarrelHistory() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to retrieve wine barrel history (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getWineBarrelHistory() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Insert wine into a barrel.
  Future<void> insertWine(String id, String wineTypeId, DateTime startDate,
      {required String token}) async {
    final formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        .format(startDate.toUtc()); // Use UTC
    final url = Uri.parse(
        '$_baseUrl/WineBarrels/$id/InsertWine/$wineTypeId/$formattedDate');
    debugPrint('[ApiService] insertWine() - URL: $url');
    final headers = {
      'Content-Type':
          'application/json', // Content-Type might not be needed for POST with URL params
      'Authorization': 'Bearer $token',
    };
    try {
      // Body is often empty for this kind of POST request where data is in the URL path
      final response = await http.post(url, headers: headers);
      debugPrint(
          '[ApiService] insertWine() - Response code: ${response.statusCode}');
      debugPrint('[ApiService] insertWine() - Response body: ${response.body}');
      if (response.statusCode != 200 && response.statusCode != 204) {
        // Allow 204 No Content
        throw Exception(
            'Failed to insert wine (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] insertWine() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Remove the current wine from a barrel.
  Future<void> removeCurrentWine(String id, DateTime endDate,
      {required String token}) async {
    final formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        .format(endDate.toUtc()); // Use UTC
    final url =
        Uri.parse('$_baseUrl/WineBarrels/$id/RemoveCurrentWine/$formattedDate');
    debugPrint('[ApiService] removeCurrentWine() - URL: $url');
    final headers = {
      'Content-Type': 'application/json', // Content-Type might not be needed
      'Authorization': 'Bearer $token',
    };
    try {
      // Body is often empty for this kind of POST request
      final response = await http.post(url, headers: headers);
      debugPrint(
          '[ApiService] removeCurrentWine() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] removeCurrentWine() - Response body: ${response.body}');
      if (response.statusCode != 200 && response.statusCode != 204) {
        // Allow 204 No Content
        throw Exception(
            'Failed to remove current wine (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] removeCurrentWine() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Retrieve the WineType for a given barrel.
  Future<Map<String, dynamic>> getWineTypeForBarrel(String id,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id/WineType');
    debugPrint('[ApiService] getWineTypeForBarrel() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getWineTypeForBarrel() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getWineTypeForBarrel() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to retrieve wine type for barrel (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getWineTypeForBarrel() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Retrieve the current WineHistory for a given barrel.
  Future<Map<String, dynamic>> getCurrentWineHistory(String id,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id/CurrentWineHistory');
    debugPrint('[ApiService] getCurrentWineHistory() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getCurrentWineHistory() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getCurrentWineHistory() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to retrieve current wine history (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getCurrentWineHistory() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Retrieve the additives for a given wine barrel.
  Future<List<Map<String, dynamic>>> getBarrelAdditives(String id,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id/Additives');
    debugPrint('[ApiService] getBarrelAdditives() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getBarrelAdditives() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getBarrelAdditives() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to retrieve additives for wine barrel (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getBarrelAdditives() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Retrieve the fermentation entries for a given wine barrel.
  Future<List<Map<String, dynamic>>> getBarrelFermentationEntries(String id,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id/FermentationEntries');
    debugPrint('[ApiService] getBarrelFermentationEntries() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getBarrelFermentationEntries() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getBarrelFermentationEntries() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to retrieve fermentation entries for wine barrel (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getBarrelFermentationEntries() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  // ========== MOST TREATMENT (WineBarrels) ==========

  /// Retrieve the MostTreatment for a given wine barrel.
  Future<Map<String, dynamic>> getMostTreatment(String id,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id/MostTreatment');
    debugPrint('[ApiService] getMostTreatment() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getMostTreatment() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getMostTreatment() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to retrieve most treatment (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getMostTreatment() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Update the MostTreatment for a given wine barrel.
  Future<void> updateMostTreatment(
      String id, Map<String, dynamic> mostTreatment,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id/MostTreatment');
    debugPrint('[ApiService] updateMostTreatment() - URL: $url');
    debugPrint(
        '[ApiService] updateMostTreatment() - Request body: $mostTreatment');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.put(url,
          headers: headers, body: jsonEncode(mostTreatment));
      debugPrint(
          '[ApiService] updateMostTreatment() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] updateMostTreatment() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to update most treatment: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] updateMostTreatment() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Create a MostTreatment for a given wine barrel.
  Future<Map<String, dynamic>> createMostTreatment(
      String id, Map<String, dynamic> mostTreatment,
      {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id/MostTreatment');
    debugPrint('[ApiService] createMostTreatment() - URL: $url');
    debugPrint(
        '[ApiService] createMostTreatment() - Request body: $mostTreatment');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.post(url,
          headers: headers, body: jsonEncode(mostTreatment));
      debugPrint(
          '[ApiService] createMostTreatment() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] createMostTreatment() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to create most treatment (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] createMostTreatment() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Delete the MostTreatment for a given wine barrel.
  Future<void> deleteMostTreatment(String id, {required String token}) async {
    final url = Uri.parse('$_baseUrl/WineBarrels/$id/MostTreatment');
    debugPrint('[ApiService] deleteMostTreatment() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.delete(url, headers: headers);
      debugPrint(
          '[ApiService] deleteMostTreatment() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] deleteMostTreatment() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete most treatment: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] deleteMostTreatment() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }
}
