// lib/services/auth_service.dart

import 'package:flutter/material.dart';
import 'package:weinkeller/services/api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService;

  AuthService({required ApiService apiService}) : _apiService = apiService;

  String? _token;
  bool get isLoggedIn => _token != null;
  String? get token => _token;

  Future<void> login(String email, String password) async {
    try {
      final fetchedToken = await _apiService.loginUser(email, password);
      _token = fetchedToken;
      notifyListeners();
    } catch (e) {
      rethrow; // Rethrow so the UI can handle the specific exception
    }
  }

  Future<void> logout() async {
    _token = null;
    notifyListeners();
  }
}
