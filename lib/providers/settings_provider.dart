import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsProvider with ChangeNotifier {
  static const _baseUrlKey = 'baseURL';
  static const _authTokenKey = 'authToken';

  String _baseURL = 'https://api.kasai.tech/api'; // default fallback
  String? _authToken;

  SettingsProvider() {
    _loadSettings();
  }

  String get baseURL => _baseURL;
  String? get authToken => _authToken;

  /// Sanitizes the URL ensuring it starts with 'https://' and ends with '/api'
  String _sanitizeUrl(String url) {
    String sanitized = url.trim();
    if (!sanitized.startsWith('https://')) {
      sanitized = 'https://' + sanitized;
    }
    if (!sanitized.endsWith('/api')) {
      sanitized = sanitized + '/api';
    }
    return sanitized;
  }

  /// Load both baseURL and authToken from secure storage.
  Future<void> _loadSettings() async {
    const secureStorage = FlutterSecureStorage();
    final storedBaseUrl = await secureStorage.read(key: _baseUrlKey);
    final storedToken = await secureStorage.read(key: _authTokenKey);

    // Use fallback if no baseURL is found; otherwise, sanitize the stored URL.
    _baseURL = (storedBaseUrl != null && storedBaseUrl.isNotEmpty)
        ? _sanitizeUrl(storedBaseUrl)
        : 'https://api.kasai.tech/api';
    _authToken = storedToken;
    notifyListeners();
  }

  /// Updates the baseURL. If it changes, clears the token to force re-authentication.
  Future<void> updateBaseURL(String newURL) async {
    if (newURL.isEmpty) {
      debugPrint('[SettingsProvider] Invalid empty baseURL. Aborting update.');
      return;
    }

    final sanitizedUrl = _sanitizeUrl(newURL);

    if (_baseURL != sanitizedUrl) {
      // Clear token to require reauthentication.
      await clearAuthToken();
    }
    _baseURL = sanitizedUrl;

    const secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: _baseUrlKey, value: sanitizedUrl);

    debugPrint('[SettingsProvider] baseURL updated to $_baseURL');
    notifyListeners();
  }

  /// Sets a new auth token and persists it. (Call this after a successful login)
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    const secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: _authTokenKey, value: token);
    debugPrint('[SettingsProvider] Auth token set');
    notifyListeners();
  }

  /// Clears the auth token (e.g., on logout or when the baseURL changes)
  Future<void> clearAuthToken() async {
    _authToken = null;
    const secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: _authTokenKey);
    debugPrint('[SettingsProvider] Auth token cleared');
    notifyListeners();
  }
}
