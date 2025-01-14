// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weinkeller/services/api_service.dart';

/// A service that manages user authentication (login/logout) and stores tokens.
class AuthService extends ChangeNotifier {
  // Reference to your API service (which calls the backend endpoints).
  final ApiService _apiService;

  // We'll use secure storage for persisting tokens.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keep a local copy of the token in memory.
  String? _token;
  String? get token => _token;

  // A quick getter to see if the user is logged in (has a token).
  bool get isLoggedIn => _token != null;

  /// Constructor requires an instance of ApiService.
  ///
  /// Example usage in main.dart or elsewhere:
  ///   final apiService = ApiService();
  ///   final authService = AuthService(apiService: apiService);
  AuthService({required ApiService apiService}) : _apiService = apiService {
    // Optionally load a saved token when this service is first created.
    _loadSavedToken();
  }

  /// Step 2a: Load any existing token from secure storage (if exists).
  Future<void> _loadSavedToken() async {
    final savedToken = await _secureStorage.read(key: 'auth_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      notifyListeners(); // Let listeners know we have a token now
    }
  }

  /// Step 2b: Login the user by calling the API service, then store the token.
  /// On success, we save the token in secure storage for future sessions.
  Future<void> login(String email, String password) async {
    // This calls the API to do an actual login request.
    // api_service.loginUser(...) should return a token or throw an exception.
    final fetchedToken = await _apiService.loginUser(email, password);

    // If we got here, login succeeded and we have a token.
    _token = fetchedToken;

    // Save it for future use.
    await _secureStorage.write(key: 'auth_token', value: fetchedToken);

    // Notify the UI (e.g., to show a success message).
    notifyListeners();
  }

  /// Step 2c: Optional logout. Clears the token from memory and secure storage.
  Future<void> logout() async {
    _token = null;
    await _secureStorage.delete(key: 'auth_token');
    notifyListeners();
  }
}
