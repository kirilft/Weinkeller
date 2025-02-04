import 'dart:convert';
import 'dart:io'; // For file I/O
import 'package:path_provider/path_provider.dart'; // For accessing local file paths
import 'package:http/http.dart' as http;
import 'package:weinkeller/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // for ChangeNotifier, debugPrint, etc.

/// Custom exceptions in case the server responds with specific errors.
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
/// Handles user authentication, fermentation entries, QR data, local history,
/// and wine name lookups. Wrapped with [ChangeNotifier] to allow dynamic baseUrl changes.
class ApiService extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  // We store the base URL in a variable so it can be updated at runtime if needed.
  String _baseUrl;
  String get baseUrl => _baseUrl;
  set baseUrl(String newUrl) {
    if (newUrl.isEmpty) {
      debugPrint(
          '[ApiService] WARNING: Provided baseUrl is empty, using fallback');
      _baseUrl = 'http://localhost:80/api'; // Or some fallback
    } else {
      _baseUrl = newUrl;
    }
    debugPrint('[ApiService] baseUrl updated to $_baseUrl');
    notifyListeners();
  }

  /// Constructor requires an initial base URL.
  ApiService({required String baseUrl}) : _baseUrl = baseUrl;

  // ==========================================================================
  // Public Wrapper Methods (Original API Interface)
  // ==========================================================================

  /// Logs in a user and returns a token if successful.
  ///
  /// Throws:
  /// - [WrongPasswordException] if status 401
  /// - [NoResponseException] on network/socket issues
  /// - [Exception] for other server errors
  Future<String> loginUser(String email, String password) async {
    return await _loginUserNew(email, password);
  }

  /// Adds a new fermentation entry to the server and saves it locally if it fails.
  ///
  /// Throws:
  /// - [NoResponseException] on network/socket issues
  /// - [Exception] for other server errors
  Future<void> addFermentationEntry({
    required String token,
    required DateTime date,
    required double density,
    required int wineId,
  }) async {
    await _addFermentationEntryNew(
      token: token,
      date: date,
      density: density,
      wineId: wineId,
    );
  }

  /// Retrieves all wines with their ids and names.
  ///
  /// Returns a list of maps, where each map contains the `id` and `name` keys.
  ///
  /// Throws:
  /// - [NoResponseException] on network/socket issues
  /// - [Exception] for other server errors
  Future<List<Map<String, dynamic>>> getAllWineNames() async {
    final url = Uri.parse('$baseUrl/Wines/Names');
    debugPrint('[ApiService] getAllWineNames() - Starting request');
    debugPrint('[ApiService]  -> URL: $url');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      debugPrint('[ApiService]  <- Response code: ${response.statusCode}');
      debugPrint('[ApiService]  <- Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Ensure the result is a list of maps with id and name.
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to retrieve wine names (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        debugPrint('[ApiService] getAllWineNames() - NoResponseException: $e');
        throw NoResponseException(
            'Unable to connect to $url. Check your network.');
      }
      debugPrint('[ApiService] getAllWineNames() - Exception: $e');
      rethrow;
    }
  }

  /// Retrieves the name of a wine using its [id].
  ///
  /// Returns the wine name as a [String].
  ///
  /// Throws:
  /// - [NoResponseException] on network/socket issues
  /// - [Exception] for other server errors
  Future<String> getWineNameById(int id) async {
    final url = Uri.parse('$baseUrl/Wines/$id/Name');
    debugPrint('[ApiService] getWineNameById() - Starting request');
    debugPrint('[ApiService]  -> URL: $url');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      debugPrint('[ApiService]  <- Response code: ${response.statusCode}');
      debugPrint('[ApiService]  <- Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Assuming the response body contains a JSON encoded string,
        // if not, simply return response.body.
        final data = jsonDecode(response.body);
        if (data is String) {
          return data;
        } else {
          // If the endpoint returns a plain string, fallback to this:
          return response.body;
        }
      } else {
        throw Exception(
            'Failed to retrieve wine name (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        debugPrint('[ApiService] getWineNameById() - NoResponseException: $e');
        throw NoResponseException(
            'Unable to connect to $url. Check your network.');
      }
      debugPrint('[ApiService] getWineNameById() - Exception: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // New Internal Implementations (Adapted to New Endpoints/DTOs)
  // ==========================================================================

  Future<String> _loginUserNew(String email, String password) async {
    final url = Uri.parse('$baseUrl/Users/Login');
    debugPrint('[ApiService] _loginUserNew() - Starting request');
    debugPrint('[ApiService]  -> URL: $url');
    debugPrint(
        '[ApiService]  -> Sending JSON: {"email": "$email", "password": "******"}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      debugPrint('[ApiService]  <- Response code: ${response.statusCode}');
      debugPrint('[ApiService]  <- Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        if (token == null || token.toString().isEmpty) {
          debugPrint('[ApiService] _loginUserNew() - No token in response!');
          throw Exception('Login failed: No token returned by the server.');
        }
        debugPrint('[ApiService] _loginUserNew() - Success, got token');
        return token.toString();
      } else if (response.statusCode == 401) {
        debugPrint(
            '[ApiService] _loginUserNew() - WrongPasswordException thrown');
        throw WrongPasswordException('Incorrect email or password.');
      } else {
        debugPrint(
            '[ApiService] _loginUserNew() - Unexpected status: ${response.statusCode}');
        throw Exception(
          'Login failed (status ${response.statusCode}):\n${response.body}',
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        debugPrint('[ApiService] _loginUserNew() - NoResponseException: $e');
        throw NoResponseException(
            'Unable to connect to $url. Check your network.');
      }
      debugPrint('[ApiService] _loginUserNew() - Exception: $e');
      rethrow;
    }
  }

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

    debugPrint('[ApiService] _addFermentationEntryNew() - Starting request');
    debugPrint('[ApiService]  -> URL: $url');
    debugPrint('[ApiService]  -> Request body: $body');
    debugPrint('[ApiService]  -> Token: Bearer $token');

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

      debugPrint('[ApiService]  <- Response code: ${response.statusCode}');
      debugPrint('[ApiService]  <- Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[ApiService] _addFermentationEntryNew() - Success');
        await _saveToLocalHistory(body);
      } else {
        debugPrint(
            '[ApiService] _addFermentationEntryNew() - Failed, saving locally');
        await _databaseService.insertPendingEntry(body);
      }
    } catch (e) {
      if (e is SocketException || e is NoResponseException) {
        debugPrint(
            '[ApiService] _addFermentationEntryNew() - Network error, saving locally');
        await _databaseService.insertPendingEntry(body);
      } else {
        debugPrint(
            '[ApiService] _addFermentationEntryNew() - Unexpected error: $e');
        rethrow;
      }
    }
  }

  // ==========================================================================
  // Remaining Methods (Unchanged)
  // ==========================================================================

  /// Synchronizes pending entries with the server.
  Future<void> syncPendingEntries(String token) async {
    debugPrint('[ApiService] syncPendingEntries() - Starting synchronization');
    final pendingEntries = await _databaseService.getPendingEntries();
    for (final entry in pendingEntries) {
      try {
        await addFermentationEntry(
          token: token,
          date: DateTime.parse(entry['date']),
          density: entry['density'],
          wineId: entry['wineId'],
        );
        await _databaseService.clearPendingEntry(entry['id']);
      } catch (e) {
        debugPrint(
            '[ApiService] syncPendingEntries() - Error syncing entry: $e');
      }
    }
    debugPrint('[ApiService] syncPendingEntries() - Completed synchronization');
  }

  /// Saves a fermentation entry to a local file for history tracking.
  Future<void> _saveToLocalHistory(Map<String, dynamic> entry) async {
    final file = await _getLocalFile();
    List<Map<String, dynamic>> entries = await loadLocalHistory();

    // Add the new entry
    entries.add(entry);

    // Write the updated list to the file
    await file.writeAsString(jsonEncode(entries));
    debugPrint('[ApiService] _saveToLocalHistory() - Entry saved locally');
  }

  /// Loads all fermentation entries from the local file for the history page.
  Future<List<Map<String, dynamic>>> loadLocalHistory() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return List<Map<String, dynamic>>.from(jsonDecode(content));
      }
      return [];
    } catch (e) {
      debugPrint('[ApiService] loadLocalHistory() - Error: $e');
      return [];
    }
  }

  /// Gets the local file for saving fermentation entries.
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/fermentation_history.json');
  }
}
