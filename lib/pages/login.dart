// lib/pages/login.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/auth_service.dart';
// Since we defined custom exceptions in api_service.dart, import that as well:
import 'package:weinkeller/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  /// Displays a popup dialog with a given title and message
  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button
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

  /// Attempts the login, handling errors with specific popups
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    // Get AuthService from Provider
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.login(email, password);

      // If no exception was thrown, login was successful
      if (authService.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/account');
      }
    } on WrongPasswordException catch (e) {
      // Show a popup for wrong credentials
      _showErrorDialog('Login Error', e.message);
    } on NoResponseException catch (e) {
      // Show a popup for no server response or network error
      _showErrorDialog('Server Error', e.message);
    } catch (e) {
      // Any other exception
      _showErrorDialog('Error', e.toString());
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
          onPressed: () => Navigator.pop(context), // Go back
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spacing to push the form down
            SizedBox(height: screenHeight * 0.2),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _passController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
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
