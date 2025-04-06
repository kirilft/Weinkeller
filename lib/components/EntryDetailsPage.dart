import 'dart:io'; // For SocketException
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/api_service.dart';
import 'package:weinkeller/services/auth_service.dart';
import 'package:weinkeller/services/api_manager.dart'; // Import ApiManager

/// A simple model class to represent each additive, ensuring uniqueness by id.
class AdditiveModel {
  final String id;
  final String type;

  AdditiveModel({required this.id, required this.type});
}

/// A simple data class to hold additive information for each row.
class _AdditiveEntry {
  AdditiveModel? selectedAdditive;
  String amount = '';

  _AdditiveEntry();
}

class EntryDetailsPage extends StatefulWidget {
  static const routeName = '/entryDetails';

  final String entryId;

  const EntryDetailsPage({super.key, required this.entryId});

  @override
  State<EntryDetailsPage> createState() => _EntryDetailsPageState();
}

class _EntryDetailsPageState extends State<EntryDetailsPage> {
  final TextEditingController _densityController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  String _entryName = '';

  // List to hold additive entries; starts with one empty entry.
  final List<_AdditiveEntry> _additiveEntries = [_AdditiveEntry()];

  // List of additive data (with unique IDs) retrieved from AdditiveTypes.
  List<AdditiveModel> _availableAdditives = [];

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact(); // Haptic feedback on page open
    _fetchEntryName();
    _fetchAdditiveTypes(); // Load actual additive names from the API.
  }

  @override
  void dispose() {
    _densityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Fetches the entry (wine type) name using the WineTypes API endpoint.
  Future<void> _fetchEntryName() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _entryName = 'Unbekannt';
      });
      return;
    }
    if (widget.entryId.isEmpty) {
      _showErrorDialog(
          'Eintrags-ID Fehler', 'Ungültige Eintrags-ID angegeben.');
      return;
    }
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // Use the WineTypes endpoint to get the wine type name
      final result = await apiService.getWineType(widget.entryId, token: token);
      final String entryName = result['name'] ?? 'Unbekannt';
      setState(() {
        _entryName = entryName;
      });
    } on SocketException catch (e) {
      debugPrint('[EntryDetailsPage] _fetchEntryName() - Offline Error: $e');
      final continueOffline = await _showOfflineDialog();
      if (continueOffline) {
        setState(() {
          _entryName = 'Unbekannt';
        });
      }
    } catch (e) {
      debugPrint('[EntryDetailsPage] _fetchEntryName() - Error: $e');
      if (e.toString().contains('401')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Zugriff auf diesen Eintrag verweigert')),
          );
        });
      } else {
        setState(() {
          _entryName = 'Unbekannt';
        });
      }
    }
  }

  /// Fetches the list of additive types from the API and populates _availableAdditives as a list of AdditiveModel.
  Future<void> _fetchAdditiveTypes() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      final apiManager = Provider.of<ApiManager>(context, listen: false);
      final List<Map<String, dynamic>> additiveTypes =
          await apiManager.getAllAdditiveTypes(token);
      setState(() {
        _availableAdditives = additiveTypes.map((e) {
          return AdditiveModel(
            id: e['id'] as String,
            type: e['type'] as String,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('[EntryDetailsPage] _fetchAdditiveTypes() - Error: $e');
      // Fallback to empty list if it fails.
      setState(() {
        _availableAdditives = [];
      });
    }
  }

  /// Shows a dialog asking if the user wants to continue offline.
  Future<bool> _showOfflineDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Offline'),
            content: const Text(
                'Es scheint, dass Sie offline sind. Möchten Sie trotzdem fortfahren?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Fortfahren'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Submits the entry data and/or additives.
  Future<void> _submitData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = authService.authToken;
    final densityInput = _densityController.text.trim();

    if (token == null || token.isEmpty) {
      _showErrorDialog(
        'Authentifizierungsfehler',
        'Sie müssen angemeldet sein, um Daten zu übermitteln.',
        showLoginButton: true,
      );
      return;
    }

    double? density;
    if (densityInput.isNotEmpty) {
      try {
        density = double.parse(densityInput);
      } catch (_) {
        _showErrorDialog('Validierungsfehler',
            'Die Dichte muss eine gültige Zahl sein (z.B. 0,98).');
        return;
      }
    }

    final String entryId = widget.entryId;
    if (entryId.isEmpty) {
      _showErrorDialog(
          'Eintrags-ID Fehler', 'Ungültige Eintrags-ID angegeben.');
      return;
    }

    List<Map<String, dynamic>> additivePayloads = [];
    for (var entry in _additiveEntries) {
      final selected = entry.selectedAdditive;
      if (selected != null && selected.type.isNotEmpty) {
        if (entry.amount.trim().isEmpty) {
          _showErrorDialog('Validierungsfehler',
              'Bitte geben Sie die Menge für ${selected.type} ein.');
          return;
        }
        double additiveAmount;
        try {
          additiveAmount = double.parse(entry.amount);
        } catch (_) {
          _showErrorDialog('Validierungsfehler',
              'Die Menge für ${selected.type} muss eine gültige Zahl sein.');
          return;
        }
        additivePayloads.add({
          'type': selected.type, // Or 'id': selected.id, if your API needs it
          'date':
              DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(DateTime.now()),
          'amountGrammsPerLitre': additiveAmount,
          'entryId': entryId,
        });
      }
    }

    if (density == null && additivePayloads.isEmpty) {
      _showErrorDialog('Validierungsfehler',
          'Bitte geben Sie einen Dichtewert ein oder fügen Sie mindestens ein Zusatzmittel hinzu.');
      return;
    }

    final DateTime date = DateTime.now();
    setState(() => _isSubmitting = true);

    try {
      // Send density if provided
      if (density != null) {
        await apiService.addFermentationEntry(
          token: token,
          date: date,
          density: density,
          wineId: entryId, // Reusing the same field name for consistency.
        );
      }
      // Send all additive entries
      for (var payload in additivePayloads) {
        await apiService.createAdditive(payload, token: token);
      }
      HapticFeedback.heavyImpact();
      _showSuccessSnackbar('Eintrag erfolgreich hinzugefügt!');
    } catch (e) {
      debugPrint('[EntryDetailsPage] _submitData() - Error: $e');
      if (e.toString().contains('401')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Zugriff auf diesen Eintrag verweigert')),
          );
        });
      } else {
        _showErrorDialog('Übermittlungsfehler', e.toString());
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  /// Displays an error dialog.
  void _showErrorDialog(String title, String message,
      {bool showLoginButton = false}) {
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
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/login');
                },
                child: const Text('Anmelden'),
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

  /// Displays a success snackbar and navigates to the main page.
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

  /// Builds a single additive row with a dropdown and amount field.
  Widget _buildAdditiveRow(int index) {
    final additiveEntry = _additiveEntries[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AdditiveModel>(
          value: additiveEntry.selectedAdditive,
          hint: const Text('Wählen Sie ein Zusatzmittel'),
          items: _availableAdditives.map((model) {
            return DropdownMenuItem<AdditiveModel>(
              value: model,
              child: Text(model.type),
            );
          }).toList(),
          onChanged: (AdditiveModel? value) {
            setState(() {
              _additiveEntries[index].selectedAdditive = value;
              // If user just selected a new additive in the last row, add another empty row
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
                labelText: '${additiveEntry.selectedAdditive!.type} Menge',
                hintText:
                    'Geben Sie die Menge für ${additiveEntry.selectedAdditive!.type} ein',
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Eintragsdetails',
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
                const SizedBox(height: 56),
                Text(
                  _entryName.isEmpty ? 'Laden...' : _entryName,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
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
                    labelText: 'Dichte',
                    hintText: 'Geben Sie den Dichtewert ein (z.B. 0,98)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Text(
                  'Zusatzmittel (optional)',
                  style: theme.textTheme.titleMedium,
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
                          child: const Text('Absenden'),
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
