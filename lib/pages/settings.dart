// lib/pages/settings.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/theme_provider.dart'; // Corrected import path

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

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

  /// Loads the saved base URL from SharedPreferences; defaults to an empty string if none found.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final storedBaseUrl = prefs.getString('baseUrl') ?? '';

    setState(() {
      _baseUrlController.text = storedBaseUrl;
      _isLoading = false;
    });
  }

  /// Saves the current text in _baseUrlController to SharedPreferences.
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', _baseUrlController.text);

    // Provide user feedback on successful save
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
      // Show a loading indicator while fetching current settings
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Access the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    ThemeMode currentTheme = themeProvider.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to previous screen
          },
        ),
      ),
      body: SingleChildScrollView(
        // Allows scrolling if content overflows
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing Base URL Settings
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
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            // New Theme Settings
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
