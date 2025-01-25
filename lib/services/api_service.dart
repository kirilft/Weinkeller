import 'dart:convert';
import 'dart:io'; // For file I/O
import 'package:path_provider/path_provider.dart'; // For accessing local file paths
import 'package:http/http.dart' as http;
import 'package:weinkeller/services/database_service.dart';
import 'package:intl/intl.dart';

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
/// Handles user authentication, fermentation entries, QR data, and local history.
class ApiService {
  final String baseUrl;
  final DatabaseService _databaseService = DatabaseService();

  /// Constructor to initialize the base URL.
  ApiService({required this.baseUrl});

  /// Logs in a user and returns a token if successful.
  ///
  /// Throws:
  /// - [WrongPasswordException] if status 401
  /// - [NoResponseException] on network/socket issues
  /// - [Exception] for other server errors
  Future<String> loginUser(String email, String password) async {
    final url = Uri.parse('$baseUrl/Users/Login');
    print('[ApiService] loginUser() - Starting request');
    print('[ApiService]  -> URL: $url');
    print(
        '[ApiService]  -> Sending JSON: {"email": "$email", "password": "******"}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('[ApiService]  <- Response code: ${response.statusCode}');
      print('[ApiService]  <- Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        if (token == null || token.isEmpty) {
          print('[ApiService] loginUser() - No token in response!');
          throw Exception('Login failed: No token returned by the server.');
        }
        print('[ApiService] loginUser() - Success, got token');
        return token;
      } else if (response.statusCode == 401) {
        print('[ApiService] loginUser() - WrongPasswordException thrown');
        throw WrongPasswordException('Incorrect email or password.');
      } else {
        print(
            '[ApiService] loginUser() - Unexpected status: ${response.statusCode}');
        throw Exception(
          'Login failed (status ${response.statusCode}):\n${response.body}',
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        print('[ApiService] loginUser() - NoResponseException: $e');
        throw NoResponseException(
            'Unable to connect to $url. Check your network.');
      }
      print('[ApiService] loginUser() - Exception: $e');
      rethrow;
    }
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
    final url = Uri.parse('$baseUrl/FermentationEntries');
    final DateFormat formatter = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS");
    final body = {
      'date':
          formatter.format(date), // Format with three decimals in milliseconds
      'density': density,
      'wineId': wineId,
    };

    print('[ApiService] addFermentationEntry() - Starting request');
    print('[ApiService]  -> URL: $url');
    print('[ApiService]  -> Request body: $body');
    print('[ApiService]  -> Token: $token');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('[ApiService]  <- Response code: ${response.statusCode}');
      print('[ApiService]  <- Response body: ${response.body}');

      if (response.statusCode == 201) {
        print('[ApiService] addFermentationEntry() - Success');
      } else {
        print('[ApiService] Failed, saving locally');
        await _databaseService.insertPendingEntry(body);
      }
    } catch (e) {
      print('[ApiService] Error connecting to server, saving locally');
      await _databaseService.insertPendingEntry(body);
    }
  }

  /// Synchronizes pending entries with the server.
  Future<void> syncPendingEntries(String token) async {
    print('[ApiService] syncPendingEntries() - Starting synchronization');
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
        print('[ApiService] syncPendingEntries() - Error syncing entry: $e');
      }
    }
    print('[ApiService] syncPendingEntries() - Completed synchronization');
  }

  /// Saves a fermentation entry to a local file for history tracking.
  Future<void> _saveToLocalHistory(Map<String, dynamic> entry) async {
    final file = await _getLocalFile();
    List<Map<String, dynamic>> entries = await loadLocalHistory();

    // Add the new entry to the existing list
    entries.add(entry);

    // Write the updated list back to the file
    await file.writeAsString(jsonEncode(entries));
    print('[ApiService] _saveToLocalHistory() - Entry saved locally');
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
      print('[ApiService] loadLocalHistory() - Error: $e');
      return [];
    }
  }

  /// Gets the local file for saving fermentation entries.
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/fermentation_history.json');
  }
}
