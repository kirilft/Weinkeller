import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weinkeller/config/app_colors.dart';
import 'package:weinkeller/config/theme.dart';
import 'package:weinkeller/services/auth_service.dart';
import 'package:weinkeller/services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _baseUrlController;
  bool _isLoading = true;
  int _cacheSize = 0; // Cache size in bytes

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController();
    _loadSettings();
    _updateCacheSize(); // Update the cache size on init
  }

  /// Sanitizes the URL ensuring it starts with 'https://' and ends with '/api'
  String _sanitizeUrl(String url) {
    String sanitized = url.trim();
    if (!sanitized.startsWith('https://')) {
      sanitized = 'https://$sanitized';
    }
    if (!sanitized.endsWith('/api')) {
      sanitized = '$sanitized/api';
    }
    return sanitized;
  }

  /// Loads the saved base URL from secure storage.
  Future<void> _loadSettings() async {
    const secureStorage = FlutterSecureStorage();
    final storedBaseUrl = await secureStorage.read(key: 'baseURL');
    _baseUrlController.text =
        (storedBaseUrl != null && storedBaseUrl.isNotEmpty)
            ? _sanitizeUrl(storedBaseUrl)
            : 'https://api.kasai.tech/api';

    setState(() {
      _isLoading = false;
    });
  }

  /// Validate the URL before saving.
  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  /// Saves new baseURL and clears the token if changed.
  Future<void> _saveSettings() async {
    String newBaseUrl = _baseUrlController.text.trim();
    if (newBaseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Base URL cannot be empty')),
      );
      return;
    }

    // Sanitize the URL to ensure it starts with 'https://' and ends with '/api'
    newBaseUrl = _sanitizeUrl(newBaseUrl);

    if (!_isValidUrl(newBaseUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL format')),
      );
      return;
    }

    final secureStorage = const FlutterSecureStorage();
    final oldBaseUrl = await secureStorage.read(key: 'baseURL') ?? '';

    if (oldBaseUrl != newBaseUrl) {
      debugPrint('SETTINGS: BaseURL changed from $oldBaseUrl to $newBaseUrl');
      final authService = context.read<AuthService>();
      await authService.clearAuthToken();

      final apiService = context.read<ApiService>();
      apiService.baseUrl = newBaseUrl;

      await secureStorage.write(key: 'baseURL', value: newBaseUrl);
      _baseUrlController.text = newBaseUrl;
    } else {
      debugPrint(
          'SETTINGS: BaseURL is unchanged ($oldBaseUrl). Token remains valid.');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
    }
  }

  /// Updates the cache size by computing the size of ApiService.wineNameCache.
  void _updateCacheSize() {
    final bytes = utf8.encode(jsonEncode(ApiService.wineNameCache)).length;
    setState(() {
      _cacheSize = bytes;
    });
  }

  /// Clears the cache and updates the displayed cache size.
  void _clearCache() {
    final apiService = context.read<ApiService>();
    apiService.deleteCache();
    _updateCacheSize();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared')),
    );
  }

  /// Formats bytes into a human-readable string.
  String _formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (log(bytes) / log(1024)).floor();
    double value = bytes / pow(1024, i);
    return "${value.toStringAsFixed(decimals)} ${suffixes[i]}";
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
    final currentTheme = themeProvider.themeMode;

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
            // Save Button aligned to the right with fixed width.
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.gray1,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _saveSettings,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).colorScheme.onPrimary,
                      fontFamily: 'SF Pro',
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.43,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // --- Theme Settings ---
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
            const SizedBox(height: 16),
            const Text(
              'Select your preferred theme mode. Light mode is recommended for daytime use, while dark mode reduces eye strain in low-light environments.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Clear Cache Button aligned to the right with fixed width.
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.gray2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        color: AppColors.gray1,
                        width: 3.0,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _clearCache,
                  child: Text(
                    'Clear Cache (${_formatBytes(_cacheSize)})',
                    style: const TextStyle(
                      color: AppColors.gray1,
                      fontFamily: 'SF Pro',
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.43,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
