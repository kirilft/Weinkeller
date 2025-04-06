import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weinkeller/config/app_colors.dart';
import 'package:weinkeller/config/theme.dart';
import 'package:weinkeller/services/auth_service.dart';
import 'package:weinkeller/services/database_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _baseUrlController;
  bool _isLoading = true;
  int _cacheSize = 0; // Number of pending operations

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController();
    _loadSettings();
    _updateCacheSize();
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
    // Use 'baseUrl' as the key consistently.
    final storedBaseUrl = await secureStorage.read(key: 'baseUrl');
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

  /// Saves the new base URL using AuthService's updateBaseURL method.
  Future<void> _saveSettings() async {
    String newBaseUrl = _baseUrlController.text.trim();
    if (newBaseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Die Basis-URL darf nicht leer sein')),
      );
      return;
    }

    // Sanitize the URL to ensure it starts with 'https://' and ends with '/api'
    newBaseUrl = _sanitizeUrl(newBaseUrl);

    if (!_isValidUrl(newBaseUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ungültiges URL-Format')),
      );
      return;
    }

    final authService = context.read<AuthService>();
    await authService.updateBaseURL(newBaseUrl);
    _baseUrlController.text = newBaseUrl;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Einstellungen gespeichert!')),
      );
    }
  }

  /// Updates the cache size by getting the count of pending operations from DatabaseService.
  Future<void> _updateCacheSize() async {
    final dbService = context.read<DatabaseService>();
    final count = await dbService.getPendingOperationsCount();
    setState(() {
      _cacheSize = count;
    });
  }

  /// Formats the cache size for display.
  String _formatCacheSize(int count) {
    return "$count ausstehende Operation${count == 1 ? '' : 'en'}";
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
        title: const Text('Einstellungen'),
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
              'API-Einstellungen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Basis-URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // Save Button aligned to the right.
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
                    'Speichern',
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
              'Erscheinungsbild',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            RadioListTile<ThemeMode>(
              title: const Text('Systemstandard'),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Hell'),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dunkel'),
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
              'Wählen Sie Ihren bevorzugten Anzeigemodus. Der helle Modus wird für den Tagesgebrauch empfohlen, während der dunkle Modus die Augen in schwach beleuchteten Umgebungen schont.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Local Cache Size Display
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Lokaler Cache: ${_formatCacheSize(_cacheSize)}',
                style: const TextStyle(
                  color: AppColors.gray1,
                  fontFamily: 'SF Pro',
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.43,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
