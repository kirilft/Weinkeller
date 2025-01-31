import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/auth_service.dart';
import 'package:weinkeller/services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NoResponseException implements Exception {
  final String message;
  NoResponseException(this.message);

  @override
  String toString() => 'NoResponseException: $message';
}

class WrongPasswordException implements Exception {
  final String message;
  WrongPasswordException(this.message);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// Checks if the `baseUrl` is empty and navigates to the settings page.
  Future<void> _checkBaseUrl() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    if (apiService.baseUrl.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/settings');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkBaseUrl(); // Redirect to settings if baseUrl is empty.
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final success = await authService.login(email, password);
      if (success && authService.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (e is WrongPasswordException) {
        _showErrorDialog('Login Error', e.message);
      } else if (e is NoResponseException) {
        _showErrorDialog('Server Error', e.message);
      } else {
        _showErrorDialog('Error', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: IconButton(
              icon: const Icon(
                FontAwesomeIcons.gear,
                size: 32,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.2),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-Mail'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/password_reset');
                },
                icon: const Icon(Icons.link, size: 16),
                label: const Text('Forgot Password'),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                child: const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
