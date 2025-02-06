import 'dart:convert';
import 'dart:io'; // For file I/O
import 'package:path_provider/path_provider.dart'; // For accessing local file paths
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
      _baseUrl = 'http://localhost:80/api';
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

  /// Logs in a user and returns a token if successful.
  /// Throws [WrongPasswordException], [NoResponseException], or general [Exception].
  Future<String> loginUser(String email, String password) async {
    debugPrint('[ApiService] loginUser() called with email: $email');
    return await _loginUserNew(email, password);
  }

  /// Registers a new user.
  /// Returns the parsed user data on success.
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

      if (response.statusCode == 200) {
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

  /// Changes the user password.
  /// TODO: Implement the actual API call logic.
  Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/Users/Password');
    final body = {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };

    debugPrint('[ApiService] changePassword() - URL: $url');
    debugPrint('[ApiService] changePassword() - Request body: $body');
    debugPrint('[ApiService] changePassword() - Token: Bearer $token');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      debugPrint(
          '[ApiService] changePassword() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] changePassword() - Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to change password (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] changePassword() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException(
            'Unable to connect to $url. Check your network.');
      }
      rethrow;
    }
  }

  /// Deletes the user's account.
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
      if (response.statusCode == 200) {
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

  // ==========================================================================
  // ========== ADDITIVES ==========
  // ==========================================================================

  /// Retrieves an additive by [id].
  Future<Map<String, dynamic>> getAdditive(int id) async {
    final url = Uri.parse('$baseUrl/Additives/$id');
    debugPrint('[ApiService] getAdditive() - URL: $url');
    try {
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      debugPrint(
          '[ApiService] getAdditive() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getAdditive() - Response body: ${response.body}');
      if (response.statusCode == 200) {
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

  /// Updates an additive with [id] using [additive] data.
  Future<void> updateAdditive(int id, Map<String, dynamic> additive) async {
    final url = Uri.parse('$baseUrl/Additives/$id');
    debugPrint('[ApiService] updateAdditive() - URL: $url');
    debugPrint('[ApiService] updateAdditive() - Request body: $additive');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
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

  /// Deletes an additive with the given [id].
  Future<void> deleteAdditive(int id) async {
    final url = Uri.parse('$baseUrl/Additives/$id');
    debugPrint('[ApiService] deleteAdditive() - URL: $url');
    try {
      final response =
          await http.delete(url, headers: {'Content-Type': 'application/json'});
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

  /// Creates a new additive.
  Future<Map<String, dynamic>> createAdditive(
      Map<String, dynamic> additive) async {
    final url = Uri.parse('$baseUrl/Additives');
    debugPrint('[ApiService] createAdditive() - URL: $url');
    debugPrint('[ApiService] createAdditive() - Request body: $additive');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(additive),
      );
      debugPrint(
          '[ApiService] createAdditive() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] createAdditive() - Response body: ${response.body}');
      if (response.statusCode == 200) {
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

  /// Adds a fermentation entry.
  Future<void> addFermentationEntry({
    required String token,
    required DateTime date,
    required double density,
    required int wineId,
  }) async {
    debugPrint('[ApiService] addFermentationEntry() called');
    await _addFermentationEntryNew(
        token: token, date: date, density: density, wineId: wineId);
  }

  /// Retrieves a fermentation entry by [id].
  Future<Map<String, dynamic>> getFermentationEntry(int id) async {
    final url = Uri.parse('$baseUrl/FermentationEntries/$id');
    debugPrint('[ApiService] getFermentationEntry() - URL: $url');
    try {
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      debugPrint(
          '[ApiService] getFermentationEntry() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getFermentationEntry() - Response body: ${response.body}');
      if (response.statusCode == 200) {
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

  /// Updates a fermentation entry with [id] using [entry] data.
  Future<void> updateFermentationEntry(
      int id, Map<String, dynamic> entry) async {
    final url = Uri.parse('$baseUrl/FermentationEntries/$id');
    debugPrint('[ApiService] updateFermentationEntry() - URL: $url');
    debugPrint('[ApiService] updateFermentationEntry() - Request body: $entry');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
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

  /// Deletes a fermentation entry with [id].
  Future<void> deleteFermentationEntry(int id) async {
    final url = Uri.parse('$baseUrl/FermentationEntries/$id');
    debugPrint('[ApiService] deleteFermentationEntry() - URL: $url');
    try {
      final response =
          await http.delete(url, headers: {'Content-Type': 'application/json'});
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

  /// Internal method to add a fermentation entry.
  Future<void> _addFermentationEntryNew({
    required String token,
    required DateTime date,
    required double density,
    required int wineId,
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
        await _databaseService.insertPendingEntry(body);
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

  /// Retrieves all wine names.
  Future<List<Map<String, dynamic>>> getAllWineNames() async {
    final url = Uri.parse('$baseUrl/Wines/Names');
    debugPrint('[ApiService] getAllWineNames() - URL: $url');
    try {
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      debugPrint(
          '[ApiService] getAllWineNames() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getAllWineNames() - Response body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to retrieve wine names (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] getAllWineNames() - Error: $e');
      if (e.toString().contains('SocketException')) {
        throw NoResponseException('Unable to connect to $url.');
      }
      rethrow;
    }
  }

  /// Retrieves a wine by [id].
  Future<Map<String, dynamic>> getWineById(int id,
      {required String token}) async {
    final url = Uri.parse('$baseUrl/Wines/$id');
    debugPrint('[ApiService] getWineById() - URL: $url');

    // Use Accept header (matching your curl) and include the Authorization header.
    final headers = <String, String>{
      'accept': 'text/plain', // using text/plain as in your curl command
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      debugPrint(
          '[ApiService] getWineById() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getWineById() - Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
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

  /// Creates a new wine.
  Future<Map<String, dynamic>> createWine(Map<String, dynamic> wine) async {
    final url = Uri.parse('$baseUrl/Wines');
    debugPrint('[ApiService] createWine() - URL: $url');
    debugPrint('[ApiService] createWine() - Request body: $wine');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(wine),
      );
      debugPrint(
          '[ApiService] createWine() - Response code: ${response.statusCode}');
      debugPrint('[ApiService] createWine() - Response body: ${response.body}');
      if (response.statusCode == 200) {
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

  /// Updates an existing wine with [id] using [wine] data.
  Future<void> updateWine(int id, Map<String, dynamic> wine) async {
    final url = Uri.parse('$baseUrl/Wines/$id');
    debugPrint('[ApiService] updateWine() - URL: $url');
    debugPrint('[ApiService] updateWine() - Request body: $wine');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
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

  /// Deletes a wine with the given [id].
  Future<void> deleteWine(int id) async {
    final url = Uri.parse('$baseUrl/Wines/$id');
    debugPrint('[ApiService] deleteWine() - URL: $url');
    try {
      final response =
          await http.delete(url, headers: {'Content-Type': 'application/json'});
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

  /// Retrieves additives for a given wine [wineId].
  Future<List<Map<String, dynamic>>> getWineAdditives(int wineId) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/Additives');
    debugPrint('[ApiService] getWineAdditives() - URL: $url');
    try {
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      debugPrint(
          '[ApiService] getWineAdditives() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getWineAdditives() - Response body: ${response.body}');
      if (response.statusCode == 200) {
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

  /// Retrieves fermentation entries for a given wine [wineId].
  Future<List<Map<String, dynamic>>> getWineFermentationEntries(
      int wineId) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/FermentationEntries');
    debugPrint('[ApiService] getWineFermentationEntries() - URL: $url');
    try {
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      debugPrint(
          '[ApiService] getWineFermentationEntries() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getWineFermentationEntries() - Response body: ${response.body}');
      if (response.statusCode == 200) {
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

  /// Retrieves the MostTreatment data for a given wine [wineId].
  Future<Map<String, dynamic>> getMostTreatment(int wineId) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/MostTreatment');
    debugPrint('[ApiService] getMostTreatment() - URL: $url');
    try {
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      debugPrint(
          '[ApiService] getMostTreatment() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] getMostTreatment() - Response body: ${response.body}');
      if (response.statusCode == 200) {
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

  /// Updates the MostTreatment data for a given wine [wineId] using [treatmentData].
  Future<void> updateMostTreatment(
      int wineId, Map<String, dynamic> treatmentData) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/MostTreatment');
    debugPrint('[ApiService] updateMostTreatment() - URL: $url');
    debugPrint(
        '[ApiService] updateMostTreatment() - Request body: $treatmentData');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
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

  /// Creates a new MostTreatment entry for a given wine [wineId] using [treatmentData].
  Future<Map<String, dynamic>> createMostTreatment(
      int wineId, Map<String, dynamic> treatmentData) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/MostTreatment');
    debugPrint('[ApiService] createMostTreatment() - URL: $url');
    debugPrint(
        '[ApiService] createMostTreatment() - Request body: $treatmentData');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(treatmentData),
      );
      debugPrint(
          '[ApiService] createMostTreatment() - Response code: ${response.statusCode}');
      debugPrint(
          '[ApiService] createMostTreatment() - Response body: ${response.body}');
      if (response.statusCode == 200) {
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

  /// Deletes the MostTreatment data for a given wine [wineId].
  Future<void> deleteMostTreatment(int wineId) async {
    final url = Uri.parse('$baseUrl/Wines/$wineId/MostTreatment');
    debugPrint('[ApiService] deleteMostTreatment() - URL: $url');
    try {
      final response =
          await http.delete(url, headers: {'Content-Type': 'application/json'});
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
}
