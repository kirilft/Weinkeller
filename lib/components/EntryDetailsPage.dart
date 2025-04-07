import 'dart:io'; // For SocketException
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/api_service.dart'; // Still needed for getWineBarrel
import 'package:weinkeller/services/auth_service.dart';
import 'package:weinkeller/services/api_manager.dart'; // Import ApiManager

/// A simple model class to represent each additive, ensuring uniqueness by id.
class AdditiveModel {
  final String id;
  final String type;

  AdditiveModel({required this.id, required this.type});

  // Override equals and hashCode for DropdownButtonFormField value comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdditiveModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
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

  // Store the originally fetched name to compare on offline continue
  String? _originalFetchedName;

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

  /// Fetches the entry (wine barrel) name using the WineBarrels API endpoint.
  Future<void> _fetchEntryName() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _entryName = 'Unbekannt (Auth Fehler)';
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
      final result =
          await apiService.getWineBarrel(widget.entryId, token: token);
      final String entryName = result['name'] ?? 'Unbekannt';
      _originalFetchedName = entryName; // Store the fetched name
      if (!mounted) return;
      setState(() {
        _entryName = entryName;
      });
    } on SocketException catch (e) {
      debugPrint('[EntryDetailsPage] _fetchEntryName() - Offline Error: $e');
      final continueOffline = await _showOfflineDialog();
      if (continueOffline) {
        if (!mounted) return;
        setState(() {
          // Keep potentially previously fetched name or default
          _entryName = _originalFetchedName ?? 'Unbekannt (Offline)';
        });
      } else {
        // If user cancels offline, maybe pop back?
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[EntryDetailsPage] _fetchEntryName() - Error: $e');
      if (!mounted) return;
      if (e.toString().contains('401') || e.toString().contains('403')) {
        // Check for 403 Forbidden too
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Zugriff auf diesen Eintrag verweigert')),
          );
        });
      } else {
        setState(() {
          _entryName = 'Unbekannt (Fehler)';
        });
        _showErrorDialog('Fehler beim Laden des Namens', e.toString());
      }
    }
  }

  /// Fetches the list of additive types from the API using ApiManager.
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

      if (!mounted) return; // Check mount status *after* await
      setState(() {
        _availableAdditives = additiveTypes.map((e) {
          final id = e['id']?.toString() ?? '';
          final type = e['type']?.toString() ?? 'Unknown Type';
          return AdditiveModel(
            id: id,
            type: type,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('[EntryDetailsPage] _fetchAdditiveTypes() - Error: $e');
      if (!mounted) return; // Check mount status *after* await
      setState(() {
        _availableAdditives = [];
      });
      _showErrorDialog(
          "Fehler beim Laden der Zusatzmittel",
          "Konnte die Liste der Zusatzmittel nicht laden. "
              "Möglicherweise sind Sie offline und es sind keine lokalen Daten verfügbar.\n\nError: $e");
    }
  }

  /// Shows a dialog asking if the user wants to continue offline.
  Future<bool> _showOfflineDialog() async {
    // Check mount status before showing dialog
    if (!mounted) return false;
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
        false; // Return false if dialog is dismissed
  }

  /// Submits the entry data and/or additives USING APIMANAGER.
  Future<void> _submitData() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final authService = Provider.of<AuthService>(context, listen: false);
    final apiManager = Provider.of<ApiManager>(context, listen: false);
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

    // --- Density Parsing ---
    double? density;
    if (densityInput.isNotEmpty) {
      try {
        density = double.parse(densityInput.replaceAll(',', '.'));
      } catch (_) {
        _showErrorDialog('Validierungsfehler',
            'Die Dichte muss eine gültige Zahl sein (z.B. 0.98 oder 0,98).');
        return;
      }
    }

    // --- Entry ID Validation ---
    final String entryId = widget.entryId;
    if (entryId.isEmpty) {
      _showErrorDialog(
          'Eintrags-ID Fehler', 'Ungültige Eintrags-ID angegeben.');
      return;
    }

    // --- Additive Payload Creation ---
    List<Map<String, dynamic>> additivePayloads = [];
    for (var entry in _additiveEntries) {
      final selected = entry.selectedAdditive;
      // Only process rows where an additive type is actually selected AND amount is entered
      if (selected != null && selected.id.isNotEmpty) {
        // Check if amount is entered only if an additive is selected
        if (entry.amount.trim().isEmpty) {
          _showErrorDialog('Validierungsfehler',
              'Bitte geben Sie die Menge für ${selected.type} ein.');
          return;
        }
        double additiveAmount;
        try {
          additiveAmount = double.parse(entry.amount.replaceAll(',', '.'));
          if (additiveAmount <= 0) {
            _showErrorDialog('Validierungsfehler',
                'Die Menge für ${selected.type} muss positiv sein.');
            return;
          }
        } catch (_) {
          _showErrorDialog('Validierungsfehler',
              'Die Menge für ${selected.type} muss eine gültige Zahl sein.');
          return;
        }
        additivePayloads.add({
          'winebarrelid': widget.entryId,
          'type': selected.id,
          'amount': additiveAmount,
          'unit': 'GrammsPerLitre',
          'addedAt': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
              .format(DateTime.now().toUtc()),
        });
      }
    }

    // --- Validation: At least one input required ---
    // Check if density is null AND no valid additive payloads were created
    if (density == null && additivePayloads.isEmpty) {
      // Refine the check: ensure that if additives rows exist, at least one has a selected type AND amount
      bool hasValidAdditiveInput = _additiveEntries.any((entry) =>
          entry.selectedAdditive != null &&
          entry.selectedAdditive!.id.isNotEmpty &&
          entry.amount.trim().isNotEmpty);

      if (!hasValidAdditiveInput && density == null) {
        _showErrorDialog('Validierungsfehler',
            'Bitte geben Sie einen Dichtewert ein oder wählen Sie ein Zusatzmittel aus UND geben Sie dessen Menge an.');
        return;
      }
    }

    // --- Submission Logic ---
    final DateTime date = DateTime.now();
    if (!mounted) return;
    setState(() => _isSubmitting = true);

    bool densitySuccess = false;
    bool additivesSuccess = true;

    try {
      // Send density if provided
      if (density != null) {
        await apiManager.addFermentationEntry(token, date, density, entryId);
        densitySuccess = true;
      } else {
        densitySuccess = true; // No density to submit
      }

      // Send additives if provided
      if (additivePayloads.isNotEmpty) {
        bool currentAdditiveSuccess = true;
        for (var payload in additivePayloads) {
          try {
            await apiManager.createAdditive(payload, token);
          } catch (additiveError) {
            currentAdditiveSuccess = false;
            debugPrint(
                '[EntryDetailsPage] Error submitting additive ${payload['type']}: $additiveError');
            // Show specific error immediately
            _showErrorDialog('Fehler beim Senden des Zusatzmittels',
                'Zusatzmittel vom Typ ID ${payload['type']} konnte nicht gesendet werden: $additiveError'); // Show ID if name lookup failed
            // Decide whether to stop or continue submitting other additives
            // break; // Uncomment to stop on first additive error
          }
        }
        additivesSuccess = currentAdditiveSuccess;
      }

      // Show success message only if ALL parts were successful
      if (densitySuccess && additivesSuccess) {
        HapticFeedback.heavyImpact();
        _showSuccessSnackbar('Eintrag erfolgreich hinzugefügt!');
      } else {
        debugPrint(
            '[EntryDetailsPage] Partial submission failure. Density success: $densitySuccess, Additives success: $additivesSuccess');
        // No global success message if anything failed. Specific errors shown above.
      }
    } catch (e) {
      debugPrint('[EntryDetailsPage] _submitData() - General Error: $e');
      // Handle specific exceptions first
      if (e is NoResponseException) {
        _showErrorDialog('Übermittlungsfehler',
            'Keine Verbindung zum Server. Ihre Eingabe wurde lokal gespeichert und wird später synchronisiert.');
        // Consider navigating back even on offline save
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Zugriff auf diesen Eintrag verweigert')),
          );
        });
      } else {
        // Generic error for other cases
        _showErrorDialog('Übermittlungsfehler', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Displays an error dialog.
  void _showErrorDialog(String title, String message,
      {bool showLoginButton = false}) {
    if (!mounted) return;
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
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
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

  /// Displays a success snackbar and navigates quickly to the main page.
  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 1500),
    ));
    // Reduced delay for faster navigation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  /// Builds a single additive row with a dropdown and amount field.
  Widget _buildAdditiveRow(int index) {
    if (index < 0 || index >= _additiveEntries.length) {
      return const SizedBox.shrink();
    }
    final additiveEntry = _additiveEntries[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<AdditiveModel>(
            value: additiveEntry.selectedAdditive,
            items: _availableAdditives.map((model) {
              return DropdownMenuItem<AdditiveModel>(
                value: model,
                child: Text(model.type),
              );
            }).toList(),
            onChanged: (AdditiveModel? value) {
              if (!mounted) return;
              setState(() {
                _additiveEntries[index].selectedAdditive = value;
                // Add new row only if last row gets a value
                if (value != null &&
                    value.id.isNotEmpty &&
                    index == _additiveEntries.length - 1) {
                  _additiveEntries.add(_AdditiveEntry());
                }
                // Optional: Clear amount when additive changes?
                // _additiveEntries[index].amount = '';
              });
            },
            decoration: const InputDecoration(
              labelText: 'Zusatzmittel wählen',
              border: OutlineInputBorder(),
            ),
          ),
          if (additiveEntry.selectedAdditive != null &&
              additiveEntry.selectedAdditive!.id.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: '${additiveEntry.selectedAdditive!.type} Menge',
                  hintText: 'Menge eingeben',
                  border: const OutlineInputBorder(),
                  suffixText: 'g/L',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]+')),
                ],
                onChanged: (value) {
                  if (!mounted) return;
                  // No need for setState here if not using TextEditingController
                  additiveEntry.amount = value;
                },
              ),
            ),
        ],
      ),
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
          tooltip: 'Zurück',
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
                Text(
                  _entryName.isEmpty ? 'Laden...' : _entryName,
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
                    labelText: 'Dichte',
                    hintText: 'Geben Sie den Dichtewert ein (z.B. 0.98)',
                    border: OutlineInputBorder(),
                    // *** Icon Re-added ***
                    prefixIcon: Icon(Icons.science_outlined),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]+')),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Zusatzmittel (optional)',
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
                        // *** Changed back to ElevatedButton.icon ***
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send), // Icon added
                          label: const Text('Absenden'), // Label text
                          onPressed: _submitData,
                          // Re-added styling from the version with the icon
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            textStyle: theme.textTheme.labelLarge,
                          ),
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
