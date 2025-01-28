import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const _baseUrlKey = 'baseURL';
  static const _authTokenKey = 'authToken';

  String? _baseURL;
  String? _authToken;

  SettingsProvider() {
    _loadSettings();
  }

  String? get baseURL => _baseURL;
  String? get authToken => _authToken;

  /// Load both baseURL and authToken from local storage.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _baseURL = prefs.getString(_baseUrlKey);
    _authToken = prefs.getString(_authTokenKey);
    notifyListeners();
  }

  /// Updates the baseURL. If the baseURL changes, clear the token to force re-auth.
  Future<void> updateBaseURL(String newURL) async {
    if (_baseURL != newURL) {
      // BaseURL changed => reset the token to require reauthentication
      _authToken = null; 
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);  // remove old token from storage
    }

    _baseURL = newURL;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, newURL);

    notifyListeners();
  }

  /// Sets a new auth token and persists it. (Call this after successful login)
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
    notifyListeners();
  }

  /// Clears the auth token (e.g., on logout)
  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    notifyListeners();
  }
}