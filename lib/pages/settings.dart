// lib/pages/settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:weinkeller/config/theme.dart';
import 'package:weinkeller/services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _baseUrlController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController();
    _loadSettings();
  }

  /// Loads the saved base URL from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final storedBaseUrl = prefs.getString('baseUrl') ?? '';

    setState(() {
      _baseUrlController.text = storedBaseUrl;
      _isLoading = false;
    });
  }

  /// Compares the new baseURL with the old one.
  /// If changed, we clear the auth token via AuthService to prompt re-login next time.
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final oldBaseUrl = prefs.getString('baseUrl') ?? '';

    final newBaseUrl = _baseUrlController.text.trim();
    if (newBaseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Base URL cannot be empty')),
      );
      return;
    }

    // If baseURL changed, clear the existing token so user must reauthenticate
    if (oldBaseUrl != newBaseUrl) {
      debugPrint('SETTINGS: BaseURL changed from $oldBaseUrl to $newBaseUrl');
      final authService = context.read<AuthService>();
      await authService.clearAuthToken();
    } else {
      debugPrint(
          'SETTINGS: BaseURL is unchanged ($oldBaseUrl). Token remains valid.');
    }

    // Save the new baseURL
    await prefs.setString('baseUrl', newBaseUrl);

    // Notify user that settings are saved
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    ThemeMode currentTheme = themeProvider.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- API Settings ---
            const Text(
              'API Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Changes may require restarting the app or re-initializing '
              'the ApiService to take full effect.',
              style: TextStyle(color: Colors.grey),
            ),

            // --- Theme Settings ---
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Select your preferred theme mode. '
              'Light mode is recommended for daytime use, while dark mode reduces eye strain in low-light environments.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
