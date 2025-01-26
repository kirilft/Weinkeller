import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weinkeller/services/api_service.dart';

/// Manages authentication tokens and the current API location (base URL).
/// Notifies listeners whenever values change, allowing the UI to react in real time.
class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ApiService _apiService;

  // In-memory token and base URL
  String? _token;
  String? get token => _token;

  String _apiLocation = '';
  String get apiLocation => _apiLocation;

  // Quick check if user is logged in
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  AuthService(this._apiService) {
    _initialize();
  }

  /// Load saved token & base URL from secure storage on startup.
  Future<void> _initialize() async {
    try {
      // 1. Load auth token
      final savedToken = await _secureStorage.read(key: 'auth_token');
      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        _apiService.authToken = savedToken;
      }

      // 2. Load stored base URL
      final savedApiLocation = await _secureStorage.read(key: 'api_location');
      if (savedApiLocation != null && savedApiLocation.isNotEmpty) {
        _apiLocation = savedApiLocation;
        _apiService.baseUrl = savedApiLocation;
      } else {
        // Fallback default if none stored
        _apiLocation = 'https://example.com/api';
        _apiService.baseUrl = _apiLocation;
      }
    } catch (e) {
      debugPrint('[AuthService] _initialize error: $e');
    }
    notifyListeners();
  }

  /// Update the API location (base URL) at runtime without restarting the app.
  Future<void> updateApiLocation(String newLocation) async {
    _apiLocation = newLocation;
    _apiService.baseUrl = newLocation;
    // Persist in secure storage
    await _secureStorage.write(key: 'api_location', value: newLocation);
    notifyListeners();
  }

  /// Attempt a login using the ApiService (example).
  /// On success, store token and persist it securely.
  Future<void> login(String email, String password) async {
    try {
      final fetchedToken = await _apiService.loginUser(email, password);
      _token = fetchedToken;
      _apiService.authToken = fetchedToken;

      // Save token to secure storage
      await _secureStorage.write(key: 'auth_token', value: fetchedToken);
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] login error: $e');
      rethrow; // Let the caller handle errors
    }
  }

  /// Logs out by clearing the token (in memory + secure storage).
  Future<void> logout() async {
    _token = null;
    _apiService.authToken = null;
    await _secureStorage.delete(key: 'auth_token');
    notifyListeners();
  }
}
