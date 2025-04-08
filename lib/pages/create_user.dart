import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/api_service.dart'; // Keep for exceptions and registerUser call
import 'package:weinkeller/services/auth_service.dart';
// Import SyncService to trigger the update
import 'package:weinkeller/services/sync_service.dart';
// Import HapticFeedback if needed (optional)
// import 'package:flutter/services.dart';

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
          // Ensure font family matches if needed, original had SFProDisplay
          style: TextStyle(
            color: textColor,
            fontFamily:
                'SF Pro', // Using SF Pro like other places for consistency
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

// --- CreateUserPage Widget ---

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false; // State for loading indicator

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return; // Check mounted status
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          // Removed shadows to match login page dialog style
          // style: const TextStyle(shadows: kTextShadow),
        ),
        content: Text(
          message,
          // Removed shadows
          // style: const TextStyle(shadows: kTextShadow),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  /// Handles user creation, auto-login, and triggers initial sync.
  Future<void> _handleCreateUser() async {
    if (_isLoading) return; // Prevent multiple submissions

    // --- Input Validation ---
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      _showErrorDialog(
          "Validierungsfehler", "Name darf nicht leer sein."); // Removed ':3'
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      // Basic email format check
      _showErrorDialog(
          "Validierungsfehler", "Bitte eine gültige E-Mail eingeben.");
      return;
    }
    if (password.isEmpty) {
      _showErrorDialog("Validierungsfehler", "Passwort darf nicht leer sein.");
      return;
    }
    if (password.length < 6) {
      // Example: Minimum password length
      _showErrorDialog("Validierungsfehler",
          "Passwort muss mindestens 6 Zeichen lang sein.");
      return;
    }
    if (password != confirmPassword) {
      _showErrorDialog(
          "Validierungsfehler", "Passwörter stimmen nicht überein.");
      return;
    }
    // --- End Validation ---

    setState(() {
      _isLoading = true;
    }); // Show loading indicator

    // Use mounted check before accessing context after async gaps
    if (!mounted) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    // Get SyncService instance
    final syncService = Provider.of<SyncService>(context, listen: false);

    try {
      // 1. Register User
      debugPrint("[CreateUserPage] Attempting registration...");
      await apiService.registerUser(
        username: name,
        email: email,
        password: password,
      );
      debugPrint("[CreateUserPage] Registration API call successful.");

      // 2. Attempt Auto-Login
      debugPrint("[CreateUserPage] Attempting auto-login...");
      final loginSuccess = await authService.login(email, password);

      // 3. Handle Login Success (Sync and Navigate)
      if (loginSuccess && authService.isLoggedIn && mounted) {
        debugPrint("[CreateUserPage] Auto-login successful.");
        // ** Trigger immediate sync after successful registration & login **
        final token = authService.authToken;
        if (token != null && token.isNotEmpty) {
          debugPrint("[CreateUserPage] Triggering immediate sync...");
          try {
            // Perform the sync but don't block navigation if it fails
            await syncService.updatePendingOperationsAndFetch(token);
            debugPrint(
                "[CreateUserPage] Immediate sync after registration completed.");
          } catch (syncError) {
            // Log sync error but proceed with navigation
            debugPrint(
                "[CreateUserPage] Error during immediate sync after registration: $syncError");
          }
        }

        // Navigate to home screen after registration, login, and sync attempt
        if (mounted) {
          // Check mounted again before navigating
          Navigator.pushNamedAndRemoveUntil(
              context, '/', (route) => false); // Go home, clear stack
        }
      } else if (mounted) {
        // Handle auto-login failure after successful registration
        debugPrint("[CreateUserPage] Auto-login failed after registration.");
        _showErrorDialog("Anmeldung fehlgeschlagen",
            "Konto wurde erstellt, aber die automatische Anmeldung ist fehlgeschlagen. Bitte melden Sie sich manuell an.");
        // Optionally navigate to login page: Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint("[CreateUserPage] Error during registration/login: $e");
      if (mounted) {
        // Show specific error messages if possible
        String errorMessage = e.toString();
        if (e is NoResponseException) {
          errorMessage = "Keine Verbindung zum Server.";
        } else if (e.toString().contains('409') ||
            e.toString().toLowerCase().contains('conflict')) {
          // Example check for conflict
          errorMessage = "Benutzername oder E-Mail existiert bereits.";
        }
        _showErrorDialog("Registrierungsfehler", errorMessage);
      }
    } finally {
      // Ensure loading indicator is hidden
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- AppBar remains the same ---
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      centerTitle: true,
      title: Text(
        'Konto erstellen', // Changed title
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontFamily: 'SF Pro', // Consistent font
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
      // Removed settings gear from create user page for simplicity
      // actions: [
      //   Padding(
      //     padding: const EdgeInsets.only(right: 24),
      //     child: IconButton(
      //       icon: FaIcon(
      //         FontAwesomeIcons.gear,
      //         size: 32,
      //         color: theme.colorScheme.onSurface,
      //         shadows: kTextShadow,
      //       ),
      //       onPressed: () {
      //         Navigator.pushNamed(context, '/settings');
      //       },
      //     ),
      //   ),
      // ],
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
            SizedBox(height: screenHeight * 0.1), // Adjusted spacing
            // Added AutofillGroup for better form handling
            AutofillGroup(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Name'),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'E-Mail'),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Passwort'),
                    obscureText: true,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _confirmPasswordController,
                    textInputAction: TextInputAction.done,
                    decoration:
                        const InputDecoration(labelText: 'Passwort bestätigen'),
                    obscureText: true,
                    enabled: !_isLoading,
                    onSubmitted: (_) =>
                        _handleCreateUser(), // Allow submit via keyboard
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30), // Increased spacing
            Align(
              alignment: Alignment.centerRight,
              child: _isLoading
                  ? const CircularProgressIndicator() // Show loader
                  : ShadowedButton(
                      label: 'Erstellen',
                      backgroundColor: theme.colorScheme.primary,
                      textColor: theme.colorScheme.onPrimary,
                      onPressed: _handleCreateUser,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
