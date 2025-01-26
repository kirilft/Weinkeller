import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:weinkeller/services/database_service.dart';
import 'package:weinkeller/exceptions/wrong_password_exception.dart';
import 'package:weinkeller/exceptions/no_response_exception.dart';
import 'package:intl/intl.dart';

class ApiService {
  String _baseUrl;
  String? _authToken;

  final DatabaseService _databaseService = DatabaseService();

  ApiService({required String baseUrl}) : _baseUrl = baseUrl;

  String get baseUrl => _baseUrl;

  set baseUrl(String newUrl) {
    _baseUrl = newUrl;
    print('[ApiService] Base URL updated: $newUrl');
  }

  String? get authToken => _authToken;

  set authToken(String? token) {
    _authToken = token;
    print(
        '[ApiService] Auth token updated: ${token != null ? "Set" : "Cleared"}');
  }

  Future<String> loginUser(String email, String password) async {
    final url = Uri.parse('$_baseUrl/Users/Login');
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
            'Login failed (status ${response.statusCode}): ${response.body}');
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

  Future<void> addFermentationEntry({
    required String token,
    required DateTime date,
    required double density,
    required int wineId,
  }) async {
    final url = Uri.parse('$_baseUrl/FermentationEntries');
    final body = {
      'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(date),
      'density': density,
      'wineId': wineId,
    };

    print('[ApiService] addFermentationEntry() - Starting request');
    print('[ApiService]  -> URL: $url');
    print('[ApiService]  -> Request body: $body');
    print('[ApiService]  -> Token: Bearer $token');

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[ApiService] addFermentationEntry() - Success');
        await _saveToLocalHistory(body);
      } else {
        print('[ApiService] addFermentationEntry() - Failed, saving locally');
        await _databaseService.insertPendingEntry(body);
      }
    } on SocketException {
      print(
          '[ApiService] addFermentationEntry() - Network error, saving locally');
      await _databaseService.insertPendingEntry(body);
    } catch (e) {
      print('[ApiService] addFermentationEntry() - Unexpected error: $e');
      rethrow;
    }
  }

  Future<void> syncPendingEntries(String token) async {
    print('[ApiService] syncPendingEntries() - Starting synchronization');
    final pendingEntries = await _databaseService.getPendingEntries();
    for (final entry in pendingEntries) {
      try {
        print(
            '[ApiService] syncPendingEntries() - Syncing entry ID: ${entry['id']}');
        await addFermentationEntry(
          token: token,
          date: DateTime.parse(entry['date']),
          density: entry['density'],
          wineId: entry['wineId'],
        );
        print(
            '[ApiService] syncPendingEntries() - Successfully synced entry ID: ${entry['id']}');
        await _databaseService.clearPendingEntry(entry['id']);
      } catch (e) {
        print(
            '[ApiService] syncPendingEntries() - Failed to sync entry ID: ${entry['id']}, Error: $e');
      }
    }
    print('[ApiService] syncPendingEntries() - Completed synchronization');
  }

  Future<void> _saveToLocalHistory(Map<String, dynamic> entry) async {
    final file = await _getLocalFile();
    final history = await loadLocalHistory();
    history.add(entry);
    await file.writeAsString(jsonEncode(history));
    print('[ApiService] _saveToLocalHistory() - Entry saved locally');
  }

  Future<List<Map<String, dynamic>>> loadLocalHistory() async {
    final file = await _getLocalFile();
    if (await file.exists()) {
      final content = await file.readAsString();
      print('[ApiService] loadLocalHistory() - Loaded history from file');
      return List<Map<String, dynamic>>.from(jsonDecode(content));
    }
    print(
        '[ApiService] loadLocalHistory() - No history file found, returning empty list');
    return [];
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/fermentation_history.json');
  }
}
