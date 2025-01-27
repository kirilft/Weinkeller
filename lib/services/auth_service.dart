// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weinkeller/services/api_service.dart';

/// A service that manages user authentication (login/logout) and stores tokens.
class AuthService extends ChangeNotifier {
  // Reference to the API service (which calls the backend endpoints).
  final ApiService _apiService;

  // Secure storage for persisting tokens across sessions.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Token stored in memory for quick access.
  String? _token;
  String? get token => _token;

  // A quick getter to check if the user is logged in (has a valid token).
  bool get isLoggedIn => _token != null;

  /// Constructor requires an instance of ApiService.
  ///
  /// Example:
  ///   final authService = AuthService(apiService: apiService);
  AuthService({required ApiService apiService}) : _apiService = apiService {
    // Optionally load a saved token when this service is first created.
    _loadSavedToken();
  }

  /// Loads the token from secure storage (if it exists) during initialization.
  Future<void> _loadSavedToken() async {
    try {
      final savedToken = await _secureStorage.read(key: 'auth_token');
      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        notifyListeners(); // Notify listeners that the token is loaded.
      }
    } catch (e) {
      debugPrint('[AuthService] Error loading saved token: $e');
    }
  }

  /// Logs in the user by calling the API service, then stores the token.
  ///
  /// On success:
  /// - Saves the token in memory and secure storage.
  /// - Notifies listeners to update the app state.
  Future<void> login(String email, String password) async {
    try {
      // Call the API to authenticate and retrieve a token.
      final fetchedToken = await _apiService.loginUser(email, password);

      // If successful, save the token.
      _token = fetchedToken;
      await _secureStorage.write(key: 'auth_token', value: fetchedToken);

      // Notify listeners to reflect the updated login state.
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] Login failed: $e');
      rethrow; // Re-throw the exception to handle it in the UI.
    }
  }

  /// Logs out the user by clearing the token from memory and secure storage.
  ///
  /// Notifies listeners to reflect the logout state.
  Future<void> logout() async {
    try {
      _token = null;
      await _secureStorage.delete(key: 'auth_token');
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] Logout failed: $e');
    }
  }
}
