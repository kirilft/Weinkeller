import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // NEW
import 'api_service.dart';

class AuthService with ChangeNotifier {
  final ApiService apiService;

  AuthService({required this.apiService}) {
    _loadToken();
  }

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _authToken;
  String? get authToken => _authToken;

  /// Attempt to load any saved token from secure storage
  Future<void> _loadToken() async {
    const secureStorage = FlutterSecureStorage();
    _authToken = await secureStorage.read(key: 'authToken');
    if (_authToken != null && _authToken!.isNotEmpty) {
      _isLoggedIn = true;
      debugPrint(
          'AUTH_SERVICE: Found existing token on startup => user is logged in');
    } else {
      debugPrint(
          'AUTH_SERVICE: No token found on startup => user is logged out');
    }
    notifyListeners();
  }

  /// Save the token to Secure Storage
  Future<void> _saveToken(String token) async {
    const secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: 'authToken', value: token);
    _authToken = token;
    _isLoggedIn = true;
    debugPrint('AUTH_SERVICE: Token saved -> $_authToken');
    notifyListeners();
  }

  /// Clear the token (e.g., logout or baseURL changed)
  Future<void> clearAuthToken() async {
    debugPrint('AUTH_SERVICE: Clearing auth token...');
    const secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: 'authToken');
    _authToken = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  /// Example: user login
  Future<bool> login(String username, String password) async {
    debugPrint('AUTH_SERVICE: Attempting to login user: $username');
    try {
      // Use ApiService to authenticate with the server
      final token = await apiService.loginUser(username, password);

      // Store the token on success
      await _saveToken(token);
      return true;
    } catch (e) {
      debugPrint('AUTH_SERVICE: Login error: $e');
      return false;
    }
  }

  /// Example: user logout
  Future<void> logout() async {
    debugPrint('AUTH_SERVICE: Logging out...');
    await clearAuthToken();
  }
}
