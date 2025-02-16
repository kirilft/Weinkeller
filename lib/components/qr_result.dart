import 'dart:ui'; // For FontFeature
import 'dart:io'; // For SocketException
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/api_service.dart';
import 'package:weinkeller/services/auth_service.dart';

/// A simple data class to hold additive information.
class _AdditiveEntry {
  String? selectedAdditive;
  String amount = '';

  _AdditiveEntry();
}

class QRResultPage extends StatefulWidget {
  static const routeName = '/qrResult';

  final String qrCode;

  const QRResultPage({super.key, required this.qrCode});

  @override
  State<QRResultPage> createState() => _QRResultPageState();
}

class _QRResultPageState extends State<QRResultPage> {
  final TextEditingController _densityController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  String _wineName = '';

  // List to hold additive entries; starts with one empty entry.
  List<_AdditiveEntry> _additiveEntries = [_AdditiveEntry()];

  // Sample list of available additives.
  final List<String> _availableAdditives = [
    'Sulfur',
    'Yeast Nutrient',
    'Acid',
    'Pectic Enzyme'
  ];

  @override
  void initState() {
    super.initState();
    // Update the local cache for fresh data on page open.
    _updateWineCache();
    _fetchWineName();
  }

  @override
  void dispose() {
    _densityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Updates the local cache of wine names by calling getAllWineNames.
  Future<void> _updateWineCache() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;
    if (token == null || token.isEmpty) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      await apiService.getAllWineNames(token: token);
    } catch (e) {
      debugPrint('Error updating wine cache: $e');
      // Optionally handle the error.
    }
  }

  /// Fetches the wine name using local cache first, then the API.
  Future<void> _fetchWineName() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _wineName = 'Unknown Wine';
      });
      return;
    }
    final wineId = int.tryParse(widget.qrCode);
    if (wineId == null) {
      _showErrorDialog('QR Code Error', 'Invalid QR Code for wine ID.');
      return;
    }
    // Check if the wine name is already cached.
    final cachedName = ApiService.wineNameCache[wineId];
    if (cachedName != null) {
      setState(() {
        _wineName = cachedName;
      });
      return;
    }
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.getWineById(wineId, token: token);
      final String wineName = result['name'] ?? 'Unknown Wine';
      // Update the cache.
      ApiService.wineNameCache[wineId] = wineName;
      setState(() {
        _wineName = wineName;
      });
    } on SocketException catch (e) {
      debugPrint('[QRResultPage] _fetchWineName() - Offline Error: $e');
      final continueOffline = await _showOfflineDialog();
      if (continueOffline) {
        setState(() {
          _wineName = cachedName ?? 'Unknown Wine';
        });
      }
    } catch (e) {
      debugPrint('[QRResultPage] _fetchWineName() - Error: $e');
      if (e.toString().contains('401')) {
        // Navigate back to home and show the access denied message.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You do not have access to this wine')),
          );
        });
      } else {
        setState(() {
          _wineName = 'Unknown Wine';
        });
      }
    }
  }

  /// Shows a dialog asking if the user wants to continue offline.
  Future<bool> _showOfflineDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Offline'),
            content: const Text(
                'You seem to be offline. Do you still want to continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Submits the fermentation entry and/or additives.
  ///
  /// If a density is provided, a fermentation entry is created. Additionally,
  /// for every additive selected with an entered amount, a separate API call is made
  /// using [apiService.createAdditive]. At least one of these must be provided.
  Future<void> _submitData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = authService.authToken;
    final densityInput = _densityController.text.trim();

    if (token == null || token.isEmpty) {
      _showErrorDialog(
        'Authentication Error',
        'You must be logged in to submit data.',
        showLoginButton: true,
      );
      return;
    }

    // Parse density if provided.
    double? density;
    if (densityInput.isNotEmpty) {
      try {
        density = double.parse(densityInput);
      } catch (_) {
        _showErrorDialog(
            'Validation Error', 'Density must be a valid number (e.g., 0.98).');
        return;
      }
    }

    // Convert QR code to wineId.
    int wineId;
    try {
      wineId = int.parse(widget.qrCode);
    } catch (_) {
      _showErrorDialog('QR Code Error', 'Invalid QR Code for wine ID.');
      return;
    }

    // Gather additive entries from the form.
    List<Map<String, dynamic>> additivePayloads = [];
    for (var entry in _additiveEntries) {
      if (entry.selectedAdditive != null &&
          entry.selectedAdditive!.isNotEmpty) {
        if (entry.amount.trim().isEmpty) {
          _showErrorDialog('Validation Error',
              'Please enter the amount for ${entry.selectedAdditive}.');
          return;
        }
        double additiveAmount;
        try {
          additiveAmount = double.parse(entry.amount);
        } catch (_) {
          _showErrorDialog('Validation Error',
              'Amount for ${entry.selectedAdditive} must be a valid number.');
          return;
        }
        additivePayloads.add({
          'type': entry.selectedAdditive,
          'date':
              DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(DateTime.now()),
          // For simplicity, we use the "amountGrammsPerLitre" field.
          'amountGrammsPerLitre': additiveAmount,
          'wineId': wineId,
        });
      }
    }

    // At least one of density or additives must be provided.
    if (density == null && additivePayloads.isEmpty) {
      _showErrorDialog('Validation Error',
          'Please enter a density value or add at least one additive.');
      return;
    }

    final DateTime date = DateTime.now();
    setState(() => _isSubmitting = true);

    try {
      // If density is provided, submit the fermentation entry.
      if (density != null) {
        await apiService.addFermentationEntry(
          token: token,
          date: date,
          density: density,
          wineId: wineId,
        );
      }
      // For every additive provided, create an additive entry.
      for (var payload in additivePayloads) {
        await apiService.createAdditive(payload, token: token);
      }
      _showSuccessSnackbar('Entry added successfully!');
    } catch (e) {
      debugPrint('[QRResultPage] _submitData() - Error: $e');
      if (e.toString().contains('401')) {
        // Navigate back to home and show the access denied message.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You do not have access to this wine')),
          );
        });
      } else {
        _showErrorDialog('Submission Error', e.toString());
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  /// Displays an error dialog.
  void _showErrorDialog(
    String title,
    String message, {
    bool showLoginButton = false,
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            if (showLoginButton)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog.
                  Navigator.of(context)
                      .pushNamed('/login'); // Navigate to login.
                },
                child: const Text('Login'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Displays a success snackbar and navigates quickly to the main page.
  void _showSuccessSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 2000),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    Future.delayed(const Duration(milliseconds: 200), () {
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  /// Builds a single additive row with a dropdown and, if selected, an amount field.
  Widget _buildAdditiveRow(int index) {
    final additiveEntry = _additiveEntries[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: additiveEntry.selectedAdditive,
          hint: const Text('Select an additive'),
          items: _availableAdditives.map((additive) {
            return DropdownMenuItem<String>(
              value: additive,
              child: Text(additive),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _additiveEntries[index].selectedAdditive = value;
              // If an additive is selected in the last row, append a new empty row.
              if (value != null && index == _additiveEntries.length - 1) {
                _additiveEntries.add(_AdditiveEntry());
              }
            });
          },
        ),
        if (additiveEntry.selectedAdditive != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: '${additiveEntry.selectedAdditive} Amount',
                hintText: 'Enter amount for ${additiveEntry.selectedAdditive}',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _additiveEntries[index].amount = value;
                });
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set the system overlay style so that iOS status bar icons are dark.
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Wein',
          style: TextStyle(fontFamily: 'SF Pro'),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scanned WineID: ${widget.qrCode}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  _wineName.isEmpty ? 'Loading...' : _wineName,
                  style: const TextStyle(
                    color: Color(0xFF000000),
                    fontFamily: 'SF Pro',
                    fontSize: 20,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                    letterSpacing: -0.45,
                    fontFeatures: [
                      FontFeature.disable('liga'),
                      FontFeature.disable('clig'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _densityController,
                  decoration: const InputDecoration(
                    labelText: 'Density',
                    hintText: 'Enter the density value (e.g., 0.98)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Text(
                  'Additives (optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Column(
                  children: List.generate(
                    _additiveEntries.length,
                    (index) => _buildAdditiveRow(index),
                  ),
                ),
                const SizedBox(height: 24),
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _submitData,
                          child: const Text('Submit'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
