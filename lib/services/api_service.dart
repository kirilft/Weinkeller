import 'dart:convert';
import 'dart:io'; // For file I/O and SocketException
import 'package:path_provider/path_provider.dart'; // For local file paths
import 'package:http/http.dart' as http;
import 'package:weinkeller/services/database_service.dart';
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
/// This class integrates all endpoints as defined in the OpenAPI spec.
/// It handles Additives, FermentationEntries, Users (login, register, changePassword, deleteAccount),
/// and Wines (and associated MostTreatment).
class ApiService extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

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

  // Updated static cache for wine names using String keys.
  static Map<String, String> wineNameCache = {};

  // ==========================================================================
  // ========== USERS ==========
  // ==========================================================================

  Future<String> loginUser(String email, String password) async {
    debugPrint('[ApiService] loginUser() called with email: $email');
    return await _loginUserNew(email, password);
  }

  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/Users/Register');
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
    final url = Uri.parse('$baseUrl/Users');
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

  // ==========================================================================
  // ========== LOGIN INTERNAL ==========
  // ==========================================================================

  Future<String> _loginUserNew(String email, String password) async {
    final url = Uri.parse('$baseUrl/Users/Login');
    debugPrint('[ApiService] _loginUserNew() - URL: $url');
    debugPrint(
        '[ApiService] _loginUserNew() - Sending credentials for email: $email');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      debugPrint(
          '[ApiService] _loginUserNew() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] _loginUserNew() - Response body: ${response.body}');
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
      debugPrint('[ApiService] _loginUserNew() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException(
            'Unable to connect to $url. Check your network.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser({required String token}) async {
    final url = Uri.parse('$baseUrl/Users');
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
    final url = Uri.parse('$baseUrl/Additives/$id');
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
    final url = Uri.parse('$baseUrl/Additives/$id');
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
    final url = Uri.parse('$baseUrl/Additives/$id');
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
    final url = Uri.parse('$baseUrl/Additives');
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

  // Updated parameter type for wineId: now a String
  Future<void> addFermentationEntry({
    required String token,
    required DateTime date,
    required double density,
    required String wineId,
  }) async {
    debugPrint('[ApiService] addFermentationEntry() called');
    await _addFermentationEntryNew(
        token: token, date: date, density: density, wineId: wineId);
  }

  Future<Map<String, dynamic>> getFermentationEntry(int id,
      {required String token}) async {
    final url = Uri.parse('$baseUrl/FermentationEntries/$id');
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
    final url = Uri.parse('$baseUrl/FermentationEntries/$id');
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
    final url = Uri.parse('$baseUrl/FermentationEntries/$id');
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

  // Updated parameter type for wineId: now a String
  Future<void> _addFermentationEntryNew({
    required String token,
    required DateTime date,
    required double density,
    required String wineId,
  }) async {
    final url = Uri.parse('$baseUrl/FermentationEntries');
    final body = {
      'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(date),
      'density': density,
      'wineId': wineId,
    };

    debugPrint('[ApiService] _addFermentationEntryNew() - URL: $url');
    debugPrint('[ApiService] _addFermentationEntryNew() - Body: $body');
    debugPrint(
        '[ApiService] _addFermentationEntryNew() - Token: Bearer $token');

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
          '[ApiService] _addFermentationEntryNew() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] _addFermentationEntryNew() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _saveToLocalHistory(body);
      } else {
        debugPrint(
            '[ApiService] _addFermentationEntryNew() - 4xx/5xx => storing in local DB');
        await _databaseService.insertPendingEntry(body);
        debugPrint(
            '[ApiService] _addFermentationEntryNew() - Inserted into pending_entries: $body');
      }
    } catch (e) {
      debugPrint('[ApiService] _addFermentationEntryNew() - Error: $e');
      if (e is SocketException || e is NoResponseException) {
        await _databaseService.insertPendingEntry(body);
      } else {
        rethrow;
      }
    }
  }

  // ==========================================================================
  // ========== WINES ==========
  // ==========================================================================

  // Updated: Using String as wineId in cache & for wine types
  Future<List<Map<String, dynamic>>> getAllWineTypes(
      {required String token}) async {
    final url = Uri.parse('$baseUrl/WineTypes');
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
        // Update the local cache using String keys
        for (var item in data) {
          String wineId = item['id'];
          String wineName = item['name'] ?? 'Unknown Wine';
          wineNameCache[wineId] = wineName;
        }
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

  // Updated parameter type: id is now a String
  Future<Map<String, dynamic>> getWineById(String id,
      {required String token}) async {
    final url = Uri.parse('$baseUrl/Wines/$id');
    debugPrint('[ApiService] getWineById() - URL: $url');
    final headers = {
      'Accept': 'text/plain',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getWineById() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getWineById() - Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> wine =
            jsonDecode(response.body) as Map<String, dynamic>;
        // Update the local cache using String keys
        String wineId = wine['id'];
        String wineName = wine['name'] ?? 'Unknown Wine';
        wineNameCache[wineId] = wineName;
        return wine;
      } else {
        throw Exception(
            'Failed to retrieve wine (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getWineById() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createWine(Map<String, dynamic> wine,
      {required String token}) async {
    final url = Uri.parse('$baseUrl/Wines');
    debugPrint('[ApiService] createWine() - URL: $url');
    debugPrint('[ApiService] createWine() - Request body: $wine');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(wine),
      );
      debugPrint(
          '[ApiService] createWine() - Response code: ${response.statusCode}');
      debugPrint('[ApiService] createWine() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create wine: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] createWine() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  // Updated: id is now a String
  Future<void> updateWine(String id, Map<String, dynamic> wine,
      {required String token}) async {
    final url = Uri.parse('$baseUrl/Wines/$id');
    debugPrint('[ApiService] updateWine() - URL: $url');
    debugPrint('[ApiService] updateWine() - Request body: $wine');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(wine),
      );
      debugPrint(
          '[ApiService] updateWine() - Response code: ${response.statusCode}');
      debugPrint('[ApiService] updateWine() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to update wine: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] updateWine() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  // Updated: id is now a String
  Future<void> deleteWine(String id, {required String token}) async {
    final url = Uri.parse('$baseUrl/Wines/$id');
    debugPrint('[ApiService] deleteWine() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.delete(url, headers: headers);
      debugPrint(
          '[ApiService] deleteWine() - Response code: ${response.statusCode}');
      debugPrint('[ApiService] deleteWine() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete wine: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] deleteWine() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getWineAdditives(String wineId,
      {required String token}) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/Additives');
    debugPrint('[ApiService] getWineAdditives() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getWineAdditives() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getWineAdditives() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to retrieve additives for wine $wineId: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getWineAdditives() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getWineFermentationEntries(String wineId,
      {required String token}) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/FermentationEntries');
    debugPrint('[ApiService] getWineFermentationEntries() - URL: $url');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getWineFermentationEntries() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getWineFermentationEntries() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to retrieve fermentation entries for wine $wineId: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getWineFermentationEntries() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMostTreatment(String wineId,
      {required String token}) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/MostTreatment');
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
            'Failed to retrieve MostTreatment for wine $wineId: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getMostTreatment() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<void> updateMostTreatment(
      String wineId, Map<String, dynamic> treatmentData,
      {required String token}) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/MostTreatment');
    debugPrint('[ApiService] updateMostTreatment() - URL: $url');
    debugPrint(
        '[ApiService] updateMostTreatment() - Request body: $treatmentData');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(treatmentData),
      );
      debugPrint(
          '[ApiService] updateMostTreatment() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] updateMostTreatment() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update MostTreatment for wine $wineId: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] updateMostTreatment() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMostTreatment(
      String wineId, Map<String, dynamic> treatmentData,
      {required String token}) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/MostTreatment');
    debugPrint('[ApiService] createMostTreatment() - URL: $url');
    debugPrint(
        '[ApiService] createMostTreatment() - Request body: $treatmentData');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(treatmentData),
      );
      debugPrint(
          '[ApiService] createMostTreatment() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] createMostTreatment() - Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to create MostTreatment for wine $wineId: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] createMostTreatment() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  Future<void> deleteMostTreatment(String wineId,
      {required String token}) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/MostTreatment');
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
        throw Exception(
            'Failed to delete MostTreatment for wine $wineId: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] deleteMostTreatment() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  // ==========================================================================
  // ========== LOCAL HISTORY ==========
  // ==========================================================================

  Future<void> _saveToLocalHistory(Map<String, dynamic> entry) async {
    final file = await _getLocalFile();
    List<Map<String, dynamic>> entries = await loadLocalHistory();
    entries.add(entry);
    await file.writeAsString(jsonEncode(entries));
    debugPrint('[ApiService] _saveToLocalHistory() - Entry saved locally');
  }

  Future<List<Map<String, dynamic>>> loadLocalHistory() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        debugPrint('[ApiService] loadLocalHistory() - File content: $content');
        return List<Map<String, dynamic>>.from(jsonDecode(content));
      }
      return [];
    } catch (e) {
      debugPrint('[ApiService] loadLocalHistory() - Error: $e');
      return [];
    }
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/fermentation_history.json';
    debugPrint('[ApiService] _getLocalFile() - Path: $path');
    return File(path);
  }

  int getCacheSize() {
    return wineNameCache.length;
  }

  void deleteCache() {
    wineNameCache.clear();
    notifyListeners();
  }

  /// Forces an update of the wine cache by calling getAllWineTypes.
  /// If nothing changes in the cache, it logs that the cache did not change.
  Future<void> updateCache({required String token}) async {
    // Make a copy of the current cache.
    final Map<String, String> oldCache =
        Map<String, String>.from(wineNameCache);

    // Update the cache by calling getAllWineTypes.
    await getAllWineTypes(token: token);

    // Compare the old and new caches.
    if (mapEquals(oldCache, wineNameCache)) {
      debugPrint('[ApiService] updateCache() - Cache did not change.');
    } else {
      debugPrint('[ApiService] updateCache() - Cache updated successfully.');
    }
  }

  // ==========================================================================
  // ========== BACKGROUND SYNC ==========
  // ==========================================================================

  /// Attempts to synchronize pending fermentation entries stored locally.
  Future<void> syncPendingFermentationEntries({required String token}) async {
    final pendingEntries = await _databaseService.getPendingEntries();
    for (final entry in pendingEntries) {
      try {
        final url = Uri.parse('$baseUrl/FermentationEntries');
        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'date': entry['date'],
                'density': entry['density'],
                'wineId': entry['wineId'],
              }),
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200 || response.statusCode == 201) {
          await _databaseService.deletePendingEntry(entry['id']);
          debugPrint(
              '[ApiService] Sync: Entry ${entry['id']} synced successfully.');
        } else {
          debugPrint(
              '[ApiService] Sync: Failed to sync entry ${entry['id']}: ${response.body}');
        }
      } catch (e) {
        debugPrint('[ApiService] Sync: Error syncing entry ${entry['id']}: $e');
        // Break the loop if a network issue is detected to avoid rapid retries.
        break;
      }
    }
  }
}
