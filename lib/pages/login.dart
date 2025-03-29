import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/config/app_colors.dart';
import 'package:weinkeller/services/auth_service.dart';
import 'package:weinkeller/services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const List<Shadow> kTextShadow = [
  Shadow(
    offset: Offset(0, 4),
    blurRadius: 4,
    color: Color.fromARGB(25, 0, 0, 0),
  ),
];

final List<BoxShadow> kBoxShadow = [
  BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 4,
    color: Colors.black.withAlpha(25),
  ),
];

class ShadowedButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final BorderSide? borderSide;

  const ShadowedButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: kBoxShadow,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
          shape: RoundedRectangleBorder(
            side: borderSide ?? BorderSide.none,
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontFamily: 'SF Pro',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 20 / 15,
            letterSpacing: -0.23,
          ),
        ),
      ),
    );
  }
}

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
    _checkBaseUrl();
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
            ),
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
      } else {
        _showErrorDialog('Login Error', 'Das eingegebene Passwort ist falsch.');
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

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        'Anmelden',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontFamily: 'SF Pro',
          fontSize: 28,
          fontWeight: FontWeight.w400,
          height: 34 / 28,
          letterSpacing: -0.38,
          shadows: kTextShadow,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 32),
        child: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: 32,
            color: theme.colorScheme.onSurface,
            shadows: kTextShadow,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 32),
          child: IconButton(
            icon: FaIcon(
              FontAwesomeIcons.gear,
              size: 32,
              color: theme.colorScheme.onSurface,
              shadows: kTextShadow,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.2),
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
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ShadowedButton(
                label: 'Anmelden',
                backgroundColor: theme.colorScheme.primary,
                textColor: theme.colorScheme.onPrimary,
                onPressed: _handleLogin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
