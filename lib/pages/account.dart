import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/api_service.dart';
import 'package:weinkeller/services/auth_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // Controllers for account info (name and email)
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditingName = false;
  bool _isEditingEmail = false;

  // Controllers for password change fields
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // In a complete implementation, these values would come from your user model.
    _nameController = TextEditingController(text: "John Doe");
    _emailController = TextEditingController(text: "john.doe@example.com");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  /// Simulate updating account info (name or email).
  Future<void> _updateAccountInfo(String field) async {
    // TODO: Replace with real API integration.
    await Future.delayed(const Duration(seconds: 1));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("$field updated successfully")));
  }

  /// Handle password change action.
  Future<void> _handleChangePassword() async {
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmNewPasswordController.text;

    // Client-side validation.
    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showErrorDialog(
          "Validation Error", "Please fill all password fields. :3");
      return;
    }
    if (newPass != confirmPass) {
      _showErrorDialog("Validation Error", "New passwords do not match. :3");
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      // TODO: Implement actual API integration for password change.
      await apiService.changePassword(
        token: authService.authToken!,
        oldPassword: oldPass,
        newPassword: newPass,
      );
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully")));
      // Clear password fields upon success.
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    } catch (e) {
      _showErrorDialog("Password Change Error", e.toString());
    }
  }

  /// Handle logout action with confirmation.
  Future<void> _handleLogout() async {
    final confirmed = await _showConfirmationDialog(
      "Logout",
      "Are you sure you want to logout?",
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
      "Delete Account",
      "Are you sure you want to delete your account? This action is irreversible.",
    );
    if (confirmed) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      try {
        await apiService.deleteAccount(token: authService.authToken!);
        await authService.logout();
        Navigator.pushReplacementNamed(context, '/');
      } catch (e) {
        _showErrorDialog("Delete Account Error", e.toString());
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
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.red)),
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
          "Account",
          style: TextStyle(fontFamily: 'SFProDisplay', fontSize: 28),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                label: "Email",
                controller: _emailController,
                isEditing: _isEditingEmail,
                onEditToggle: () {
                  setState(() {
                    _isEditingEmail = !_isEditingEmail;
                    if (!_isEditingEmail) _updateAccountInfo("Email");
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
              // === Password Change Section ===
              Text(
                "Change Password",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _oldPasswordController,
                decoration: const InputDecoration(labelText: "Altes Passwort"),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: "Neues Passwort"),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmNewPasswordController,
                decoration: const InputDecoration(
                    labelText: "Neues Passwort bestätigen"),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleChangePassword,
                child: const Text("Change Password"),
              ),
              const SizedBox(height: 32),
              // === Logout and Delete Account Links ===
              TextButton(
                onPressed: _handleLogout,
                child: const Text(
                  "Logout",
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: _handleDeleteAccount,
                child: const Text(
                  "Delete Account",
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
