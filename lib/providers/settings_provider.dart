import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsProvider with ChangeNotifier {
  static const _baseUrlKey = 'baseURL';
  static const _authTokenKey = 'authToken';

  String _baseURL = 'http://localhost:80/api'; // default fallback
  String? _authToken;

  SettingsProvider() {
    _loadSettings();
  }

  String get baseURL => _baseURL;
  String? get authToken => _authToken;

  /// Load both baseURL and authToken from secure storage.
  Future<void> _loadSettings() async {
    const secureStorage = FlutterSecureStorage();
    final storedBaseUrl = await secureStorage.read(key: _baseUrlKey);
    final storedToken = await secureStorage.read(key: _authTokenKey);

    // Use fallback if no baseURL is found
    _baseURL = storedBaseUrl ?? 'https://api.kasai.tech/api';
    _authToken = storedToken;
    notifyListeners();
  }

  /// Updates the baseURL. If the baseURL changes, clear the token to force re-auth.
  Future<void> updateBaseURL(String newURL) async {
    // Basic validation to avoid empty URL
    if (newURL.isEmpty) {
      debugPrint('[SettingsProvider] Invalid empty baseURL. Aborting update.');
      return;
    }
    if (_baseURL != newURL) {
      // Clear token to require reauthentication
      await clearAuthToken();
    }
    _baseURL = newURL;

    const secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: _baseUrlKey, value: newURL);

    debugPrint('[SettingsProvider] baseURL updated to $_baseURL');
    notifyListeners();
  }

  /// Sets a new auth token and persists it. (Call this after successful login)
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    const secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: _authTokenKey, value: token);
    debugPrint('[SettingsProvider] Auth token set');
    notifyListeners();
  }

  /// Clears the auth token (e.g., on logout or baseURL change)
  Future<void> clearAuthToken() async {
    _authToken = null;
    const secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: _authTokenKey);
    debugPrint('[SettingsProvider] Auth token cleared');
    notifyListeners();
  }
}
