import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/auth_service.dart';
import 'package:weinkeller/services/api_service.dart'; // Still needed for exceptions
// Import SyncService to trigger the update
import 'package:weinkeller/services/sync_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart'; // For HapticFeedback

// --- Constants and ShadowedButton remain the same ---

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

// --- Exceptions remain the same ---
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

// --- LoginPage Widget ---

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // State to handle loading indicator

  /// Checks if the `baseUrl` is empty and navigates to the settings page.
  Future<void> _checkBaseUrl() async {
    // Use mounted check for safety in async gaps
    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    if (apiService.baseUrl.isEmpty) {
      // Ensure context is still valid before navigating
      if (mounted) {
        // Use addPostFrameCallback to avoid building during build phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Double check mounted after callback
            Navigator.pushReplacementNamed(context, '/settings');
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkBaseUrl();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return; // Check if widget is still active
    showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(message)),
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

  /// Handles the login process, including triggering an initial sync on success.
  Future<void> _handleLogin() async {
    if (_isLoading) return; // Prevent multiple login attempts

    setState(() {
      _isLoading = true;
    }); // Show loading indicator

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Use mounted check before accessing context after async gap
    if (!mounted) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final authService = Provider.of<AuthService>(context, listen: false);
    // Get SyncService instance
    final syncService = Provider.of<SyncService>(context, listen: false);

    try {
      final success = await authService.login(email, password);

      if (success && authService.isLoggedIn && mounted) {
        HapticFeedback.lightImpact(); // Provide feedback

        // ** Trigger immediate sync after successful login **
        final token = authService.authToken;
        if (token != null && token.isNotEmpty) {
          debugPrint(
              "[LoginPage] Login successful. Triggering immediate sync...");
          try {
            // Perform the sync but don't block navigation if it fails
            await syncService.updatePendingOperationsAndFetch(token);
            debugPrint("[LoginPage] Immediate sync after login completed.");
          } catch (syncError) {
            // Log sync error but proceed with navigation
            debugPrint(
                "[LoginPage] Error during immediate sync after login: $syncError");
            // Optionally show a non-blocking notification about sync failure
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(content: Text('Hintergrund-Sync fehlgeschlagen: $syncError')),
            // );
          }
        }

        // Navigate to home screen after login and sync attempt
        if (mounted) {
          // Check mounted again before navigating
          Navigator.pushReplacementNamed(context, '/');
        }
      } else if (mounted) {
        // Handle login failure (e.g., wrong password returned false)
        _showErrorDialog(
            'Login fehlgeschlagen', 'E-Mail oder Passwort ist falsch.');
      }
    } on WrongPasswordException catch (e) {
      if (mounted) _showErrorDialog('Login fehlgeschlagen', e.message);
    } on NoResponseException catch (e) {
      if (mounted) _showErrorDialog('Server Fehler', e.message);
    } catch (e) {
      // Catch any other unexpected errors during login
      if (mounted) {
        _showErrorDialog('Fehler',
            'Ein unerwarteter Fehler ist aufgetreten: ${e.toString()}');
      }
    } finally {
      // Ensure loading indicator is hidden regardless of outcome
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      centerTitle: true,
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
          onPressed: () => Navigator.maybePop(context), // Use maybePop
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
            SizedBox(height: screenHeight * 0.15), // Adjusted spacing
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _emailController,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                    enabled: !_isLoading, // Disable when loading
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Passwort'),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) =>
                        _handleLogin(), // Allow login via keyboard action
                    enabled: !_isLoading, // Disable when loading
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30), // Increased spacing
            Align(
              alignment: Alignment.centerRight,
              child: _isLoading
                  ? const CircularProgressIndicator() // Show loader when loading
                  : ShadowedButton(
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
