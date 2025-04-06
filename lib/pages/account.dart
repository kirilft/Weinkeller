import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/api_service.dart';
import 'package:weinkeller/services/auth_service.dart';
// Add this import for FontFeature:

/// AppBar TextStyle matching your Figma “Title1/Regular” specs.
final TextStyle appBarTextStyle = TextStyle(
  color: const Color(0xFF000000), // #000
  fontFeatures: const <FontFeature>[
    FontFeature.disable('liga'),
    FontFeature.disable('clig'),
  ],
  fontFamily: "SF Pro",
  fontSize: 28,
  fontWeight: FontWeight.w400,
  // 34px line-height / 28px font-size ≈ 1.2143
  height: 34 / 28,
  letterSpacing: 0.38,
);

/// TextStyle for other textual elements (optional).
final TextStyle topTextStyle = TextStyle(
  color: const Color.fromRGBO(60, 60, 67, 0.30),
  fontFeatures: const <FontFeature>[
    FontFeature.disable('liga'),
    FontFeature.disable('clig'),
  ],
  fontFamily: "SF Pro",
  fontSize: 17,
  fontWeight: FontWeight.w400,
  height: 22 / 17, // 22px line-height / 17px font-size
  letterSpacing: -0.43,
);

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // Controllers for account info (name and email).
  // Initially set to empty; these will be updated after fetching from the API.
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  bool _isEditingName = false;
  bool _isEditingEmail = false;

  @override
  void initState() {
    super.initState();

    // Initialize text controllers with empty strings.
    _nameController = TextEditingController();
    _emailController = TextEditingController();

    // Load current user information (username, email) from the API.
    _loadUserData();
  }

  /// Call the getCurrentUser() method from ApiService to get the
  /// currently logged-in user's details. Then set them in the text fields.
  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final userData = await apiService.getCurrentUser(
        token: authService.authToken!,
      );
      // userData should contain keys like "username" and "email".
      setState(() {
        _nameController.text = userData["username"] ?? "";
        _emailController.text = userData["email"] ?? "";
      });
    } catch (e) {
      // Show a simple error dialog or handle otherwise as desired.
      _showErrorDialog("Fehler", "Laden der Benutzerdaten fehlgeschlagen: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Simulate updating account info (name or email).
  /// In production, this would be a PUT or PATCH request to your API.
  Future<void> _updateAccountInfo(String field) async {
    await Future.delayed(const Duration(seconds: 1));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$field erfolgreich aktualisiert")));
  }

  /// Handle logout action with confirmation.
  Future<void> _handleLogout() async {
    final confirmed = await _showConfirmationDialog(
      "Abmelden",
      "Sind Sie sicher, dass Sie sich abmelden möchten?",
    );
    if (confirmed) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  /// Handle delete account action with confirmation.
  Future<void> _handleDeleteAccount() async {
    final confirmed = await _showConfirmationDialog(
      "Konto löschen",
      "Sind Sie sicher, dass Sie Ihr Konto löschen möchten? Diese Aktion ist unwiderruflich.",
    );
    if (confirmed) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      try {
        await apiService.deleteAccount(token: authService.authToken!);
        await authService.logout();
        Navigator.pushReplacementNamed(context, '/');
      } catch (e) {
        _showErrorDialog("Fehler beim Löschen des Kontos", e.toString());
      }
    }
  }

  /// Displays a confirmation dialog and returns true if confirmed.
  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text("Bestätigen", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows an error dialog with the provided title and message.
  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Builds an editable field for the given [label] and [controller].
  /// When the edit icon is tapped, toggles editing mode.
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditToggle,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: !isEditing,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(isEditing ? Icons.check : FontAwesomeIcons.solidEdit),
          onPressed: onEditToggle,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Konto",
          style: appBarTextStyle, // Apply the new style here
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          // Horizontal padding of 40 for design accuracy
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // === Account Information Section ===
              _buildEditableField(
                label: "Name",
                controller: _nameController,
                isEditing: _isEditingName,
                onEditToggle: () {
                  setState(() {
                    _isEditingName = !_isEditingName;
                    if (!_isEditingName) _updateAccountInfo("Name");
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildEditableField(
                label: "E-Mail",
                controller: _emailController,
                isEditing: _isEditingEmail,
                onEditToggle: () {
                  setState(() {
                    _isEditingEmail = !_isEditingEmail;
                    if (!_isEditingEmail) _updateAccountInfo("E-Mail");
                  });
                },
              ),
              const SizedBox(height: 32),
              // === Divider Spacer ===
              Container(
                height: 4,
                width: double.infinity,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 32),
              // === Logout and Delete Account Links ===
              TextButton(
                onPressed: _handleDeleteAccount,
                child: const Text(
                  "Konto löschen",
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: _handleLogout,
                child: const Text(
                  "Abmelden",
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
