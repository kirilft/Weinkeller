import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  final ApiService apiService;

  AuthService({required this.apiService});

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _authToken;
  String? get authToken => _authToken;

  /// Initializes the AuthService by checking secure storage for a saved baseURL and token.
  Future<void> initialize(BuildContext context) async {
    const secureStorage = FlutterSecureStorage();

    // Check for baseURL first.
    final savedBaseUrl = await secureStorage.read(key: 'baseUrl') ?? '';
    if (savedBaseUrl.isEmpty) {
      debugPrint('AUTH_SERVICE: No baseURL found. Redirecting to /settings.');
      Navigator.pushReplacementNamed(context, '/settings');
      return;
    } else {
      apiService.baseUrl = savedBaseUrl;
    }

    // Check for the auth token.
    final savedToken = await secureStorage.read(key: 'authToken') ?? '';
    if (savedToken.isEmpty) {
      debugPrint('AUTH_SERVICE: No auth token found. Redirecting to root (/).');
      Navigator.pushReplacementNamed(context, '/');
    } else {
      _authToken = savedToken;
      _isLoggedIn = true;
      debugPrint('AUTH_SERVICE: Initialization complete. Token loaded.');
      notifyListeners();
    }
  }

  /// Save the token to secure storage.
  Future<void> _saveToken(String token) async {
    const secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: 'authToken', value: token);
    _authToken = token;
    _isLoggedIn = true;
    debugPrint('AUTH_SERVICE: Token saved -> $_authToken');
    notifyListeners();
  }

  /// Clears the auth token (e.g., during logout or if the baseURL changes).
  Future<void> clearAuthToken() async {
    debugPrint('AUTH_SERVICE: Clearing auth token...');
    const secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: 'authToken');
    _authToken = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  /// Updates the base URL.
  /// It writes the new URL to secure storage, updates the API service,
  /// clears any existing authentication, and re-reads the new URL.
  Future<void> updateBaseURL(String newUrl) async {
    const secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: 'baseUrl', value: newUrl);
    apiService.baseUrl = newUrl;
    // Clear the current auth token since the base URL has changed.
    await clearAuthToken();
    final updatedUrl = await secureStorage.read(key: 'baseUrl');
    debugPrint(
        'AUTH_SERVICE: Base URL updated to $updatedUrl and auth token cleared.');
    notifyListeners();
  }

  /// User login method.
  Future<bool> login(String username, String password) async {
    debugPrint('AUTH_SERVICE: Attempting to login user: $username');
    try {
      final token = await apiService.loginUser(username, password);
      await _saveToken(token);
      return true;
    } catch (e) {
      debugPrint('AUTH_SERVICE: Login error: $e');
      return false;
    }
  }

  /// User logout method.
  Future<void> logout() async {
    debugPrint('AUTH_SERVICE: Logging out...');
    await clearAuthToken();
  }
}
