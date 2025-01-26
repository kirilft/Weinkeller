// lib/pages/settings.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/api_service.dart';
import 'package:weinkeller/services/theme_provider.dart';

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

  /// Loads the saved base URL from SharedPreferences; defaults to an empty string if none found.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final storedBaseUrl = prefs.getString('baseUrl') ?? '';

    setState(() {
      _baseUrlController.text = storedBaseUrl;
      _isLoading = false;
    });
  }

  /// Saves the current text in _baseUrlController to SharedPreferences and updates ApiService.
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final newBaseUrl = _baseUrlController.text.trim();
    await prefs.setString('baseUrl', newBaseUrl);

    // Update ApiService with the new base URL
    final apiService = Provider.of<ApiService>(context, listen: false);
    apiService.baseUrl = newBaseUrl;

    // Provide user feedback on successful save
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved and updated!')),
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
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (value) => themeProvider.setThemeMode(value!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (value) => themeProvider.setThemeMode(value!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              onChanged: (value) => themeProvider.setThemeMode(value!),
            ),
          ],
        ),
      ),
    );
  }
}
