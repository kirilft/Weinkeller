import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/api_service.dart';
import 'package:weinkeller/services/auth_service.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  // Controllers for the input fields.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Loading state to show a progress indicator during API calls.
  bool _isLoading = false;

  /// Shows an error dialog with the provided [title] and [message].
  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  /// Handles user registration:
  /// - Validates input fields.
  /// - Calls the register API endpoint.
  /// - Automatically logs in the user on successful registration.
  Future<void> _handleCreateUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Input validation with appropriate error messages.
    if (name.isEmpty) {
      _showErrorDialog("Validation Error", "Name cannot be empty. :3");
      return;
    }
    if (email.isEmpty) {
      _showErrorDialog("Validation Error", "Email cannot be empty. :3");
      return;
    }
    if (password.isEmpty) {
      _showErrorDialog("Validation Error", "Password cannot be empty. :3");
      return;
    }
    if (password != confirmPassword) {
      _showErrorDialog("Validation Error", "Passwords do not match. :3");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Retrieve the ApiService and AuthService using Provider.
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Call the new registerUser method in ApiService.
      await apiService.registerUser(
        username: name,
        email: email,
        password: password,
      );

      // After successful registration, automatically log in to fetch a token.
      final loginSuccess = await authService.login(email, password);
      if (loginSuccess) {
        // Navigate to home screen after successful registration and login.
        Navigator.pushReplacementNamed(context, '/');
      } else {
        _showErrorDialog("Login Error",
            "Account created but failed to log in automatically. :3");
      }
    } catch (e) {
      _showErrorDialog("Registration Error", e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontFamily: 'SFProDisplay',
            fontSize: 28,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w400,
            height: 34 / 28,
            letterSpacing: -0.38,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: IconButton(
            icon: const Icon(
              FontAwesomeIcons.arrowLeft,
              size: 32,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: IconButton(
              icon: Icon(
                FontAwesomeIcons.gear,
                size: 32,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.2),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Passwort'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              decoration:
                  const InputDecoration(labelText: 'Passwort bestätigen'),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerRight,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleCreateUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      child: const Text('Erstellen'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
