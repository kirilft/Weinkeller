import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/database_service.dart';
import 'package:weinkeller/config/app_colors.dart';
import 'package:weinkeller/components/pending_changes.dart';
import 'package:weinkeller/services/auth_service.dart';
// Import both ApiManager and ApiService as they are needed by the v3 _fetchWines/_showManualSelectDialog
import 'package:weinkeller/services/api_manager.dart';
import 'package:weinkeller/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? _qrController;
  String? _scannedCode;
  String? _errorMessage; // Keep error message state

  // Greetings list from the original design provided by user
  final List<String> _greetings = [
    'Hallo',
    'Hallo',
    'Bonjour',
    'Ciao',
    'Konnichiwa',
    'Namaste',
  ];
  late String _randomGreeting; // Keep random greeting state

  @override
  void initState() {
    super.initState();
    _pickRandomGreeting(); // Keep random greeting logic
  }

  // Keep random greeting logic
  void _pickRandomGreeting() {
    final randomIndex = Random().nextInt(_greetings.length);
    // Use setState only if needed, here it's just initialization
    _randomGreeting = _greetings[randomIndex];
  }

  @override
  void dispose() {
    _qrController?.dispose(); // Keep QR controller disposal
    super.dispose();
  }

  /// Shows the bottom sheet displaying pending changes (offline operations).
  /// Use the style from the original design provided by user.
  void _showPendingChanges() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // Style from original design
        return Container(
          constraints: const BoxConstraints(maxHeight: 414),
          decoration: const BoxDecoration(
            color: Colors.white, // Original design used white
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(54)), // Original radius
          ),
          child: const PendingChanges(),
        );
      },
    );
  }

  /// Fetches the list of wine barrels AND their current wine types using ApiManager/ApiService.
  /// Returns a list of maps, where each map contains 'barrel' data and 'wineType' data.
  /// Handles potential errors during fetching.
  /// ** KEEPING THIS METHOD FROM v3 AS IT'S REQUIRED BY THE v3 DIALOG **
  Future<List<Map<String, dynamic>>> _fetchWines() async {
    // Access ApiManager, ApiService and AuthService using Provider
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    // We need ApiService directly to fetch the wine type for each barrel
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken; // Get the current auth token

    if (token != null && token.isNotEmpty) {
      List<Map<String, dynamic>> barrels = [];
      try {
        // 1. Get the list of barrels (potentially from cache)
        debugPrint(
            '[HomeScreen] Calling apiManager.getAllWineBarrelsWithCaching...');
        barrels = await apiManager.getAllWineBarrelsWithCaching(token);
        debugPrint('[HomeScreen] Fetched ${barrels.length} barrels.');

        // 2. Pre-fetch the current wine type for each barrel
        List<Map<String, dynamic>> combinedData = [];
        for (final barrel in barrels) {
          final barrelId = barrel['id']?.toString();
          Map<String, dynamic>? wineType; // Initialize as null

          if (barrelId != null) {
            try {
              // Fetch the wine type using ApiService directly
              wineType =
                  await apiService.getWineTypeForBarrel(barrelId, token: token);
              debugPrint(
                  '[HomeScreen] Fetched wine type for barrel $barrelId: ${wineType?['name']}');
            } catch (e) {
              // Log error fetching wine type for a specific barrel, but continue
              debugPrint(
                  '[HomeScreen] Error fetching wine type for barrel $barrelId: $e');
              // wineType remains null, which is handled later
            }
          } else {
            debugPrint(
                '[HomeScreen] Warning: Barrel found without an ID in the list.');
          }

          // Add the barrel and its fetched wine type (or null) to the combined list
          combinedData.add({
            'barrel': barrel,
            'wineType': wineType,
          });
        }
        debugPrint(
            '[HomeScreen] Finished pre-fetching wine types. Returning combined data.');
        return combinedData; // Return the list containing both barrel and wine type info
      } catch (e) {
        // Log error if fetching the initial barrel list fails
        debugPrint(
            '[HomeScreen] Error fetching initial barrel list via ApiManager: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Fehler beim Laden der Fässer: ${e.toString().split(':').last}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return []; // Return empty list on error
      }
    } else {
      // Handle case where there's no authentication token
      debugPrint('[HomeScreen] No auth token found for fetching wines.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nicht angemeldet.')),
        );
      }
      return []; // Return empty list if not authenticated
    }
  }

  /// Opens a bottom sheet displaying a list of wine barrels for manual selection.
  /// Displays the wine type of the barrel below the current one.
  /// ** KEEPING THIS METHOD FROM v3 AS REQUESTED **
  void _showManualSelectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to take variable height
      backgroundColor: Colors.transparent, // Sheet background is transparent
      builder: (context) {
        // Use FutureBuilder to handle the asynchronous fetching of combined barrel/wine data
        return FutureBuilder<List<Map<String, dynamic>>>(
          future:
              _fetchWines(), // Call the method to fetch combined data (uses caching for barrels)
          builder: (context, snapshot) {
            // Show loading indicator while waiting for data
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Consistent styling for loader background
              return Container(
                height: 200, // Give it some height
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface, // Use theme surface color
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(54)), // Match original radius
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            // Show error message if fetching failed
            if (snapshot.hasError) {
              // Consistent styling for error background
              return Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface, // Use theme surface color
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(54)), // Match original radius
                ),
                child: Center(
                  child: Text(
                    // Use original error text style
                    'Fehler beim Laden der Weine', // Simpler error message like original
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontFamily: 'SF Pro',
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }
            // If data is available, display the list
            final combinedWinesData = snapshot.data ?? [];

            // Build the container for the list
            return Container(
              constraints: const BoxConstraints(
                  maxHeight: 414), // Max height from original
              padding: const EdgeInsets.only(
                  top: 16), // Padding at the top from original
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.surface, // Background color
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(54)), // Rounded corners from original
              ),
              // Use ListView.separated for list items with dividers
              child: combinedWinesData.isEmpty
                  ? Center(
                      child: Text("Keine Fässer gefunden.",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16), // Padding for the list from original
                      itemCount: combinedWinesData
                          .length, // Number of items in the list
                      separatorBuilder: (_, __) => const SizedBox(
                          height: 8), // Space between items from original
                      itemBuilder: (context, index) {
                        // --- Data Extraction (from v3 logic) ---
                        final currentItem = combinedWinesData[index];
                        final currentBarrel =
                            currentItem['barrel'] as Map<String, dynamic>? ??
                                {};
                        final currentBarrelName = currentBarrel['name'] ??
                            'Unbekannter Wein'; // Use original default text
                        final currentBarrelId = currentBarrel['id']?.toString();

                        // --- Determine Subtitle (Wine in Barrel Below - from v3 logic) ---
                        String subtitleText = ''; // Default empty subtitle
                        if (index + 1 < combinedWinesData.length) {
                          final nextItem = combinedWinesData[index + 1];
                          final nextWineType =
                              nextItem['wineType'] as Map<String, dynamic>?;
                          final nextWineTypeName =
                              nextWineType?['name'] as String?;

                          if (nextWineTypeName != null &&
                              nextWineTypeName.isNotEmpty) {
                            subtitleText = 'Darunter: $nextWineTypeName';
                          } else if (nextWineType != null) {
                            subtitleText = 'Darunter: (Unbekannter Weintyp)';
                          } else {
                            subtitleText = 'Darunter: (Kein Wein / Fehler)';
                          }
                        } else {
                          subtitleText = 'Letztes Fass in der Liste';
                        }

                        // --- Build ListTile (Combine original style with v3 subtitle) ---
                        return ListTile(
                          title: Text(currentBarrelName,
                              // Style from original design
                              style: TextStyle(
                                  fontFamily: 'SF Pro',
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                          // Display the determined subtitle (from v3 logic)
                          subtitle: Text(
                            subtitleText,
                            style: TextStyle(
                              // Style subtitle similarly to v3
                              fontFamily: 'SF Pro',
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          onTap: () {
                            // Original onTap logic
                            Navigator.pop(context);
                            if (currentBarrelId != null) {
                              Navigator.pushNamed(context, '/entryDetails',
                                  arguments: currentBarrelId);
                            } else {
                              debugPrint(
                                  "[HomeScreen] Error: Tapped barrel has no ID.");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Fehler: Fass ohne ID ausgewählt.')),
                              );
                            }
                          },
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    // ** USING THE UI STRUCTURE FROM THE USER'S PROVIDED ORIGINAL DESIGN **
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      // AppBar from original design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 64), // Linker Abstand from original
            Text(
              // Title text from original
              'Startseite',
              style: TextStyle(
                color: Colors.white,
                fontFeatures: const [
                  FontFeature.disable('liga'),
                  FontFeature.disable('clig'),
                ],
                fontFamily: 'SF Pro',
                fontSize: 28,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w400,
                height: 34 / 28,
                letterSpacing: 0.38,
              ),
            ),
            // Pending changes badge from original design
            StreamBuilder<int>(
              stream: dbService.pendingOperationsStream,
              initialData: 0,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return count > 0
                    ? Padding(
                        padding: const EdgeInsets.only(
                            right: 32), // Original padding
                        child: GestureDetector(
                          onTap: _showPendingChanges,
                          child: Stack(
                            // Original badge stack
                            children: [
                              Icon(
                                // Original icon
                                FontAwesomeIcons.arrowsRotate,
                                size: 32, // Original size
                                color:
                                    theme.colorScheme.error, // Original color
                              ),
                              Positioned(
                                // Original positioning
                                right: 0,
                                child: CircleAvatar(
                                  // Original badge style
                                  radius: 8,
                                  backgroundColor: theme.colorScheme.onError,
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.error,
                                      fontFamily: 'SF Pro',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(width: 64); // Original placeholder
              },
            ),
          ],
        ),
      ),
      // Drawer from original design
      drawer: Drawer(
        child: ListView(
          // Remove padding: zero from original design might cause issues, let's keep default
          // padding: EdgeInsets.zero,
          children: [
            SizedBox(
              // Original drawer header size
              height: 100,
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  // Original decoration
                  color: isDarkMode ? Colors.grey[800] : AppColors.red,
                ),
                child: Center(
                  child: Text(
                    // Original greeting text style
                    _randomGreeting,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'SF Pro',
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
            ),
            // Original drawer items
            ListTile(
                leading:
                    Icon(Icons.settings, color: theme.colorScheme.onSurface),
                title: const Text('Einstellungen',
                    style: TextStyle(fontFamily: 'SF Pro')),
                onTap: () {
                  Navigator.pop(context); // Close drawer first
                  Navigator.pushNamed(context, '/settings');
                }),
            ListTile(
                leading: FaIcon(FontAwesomeIcons.cloud,
                    color: theme.colorScheme.onSurface),
                title: const Text('Web-Oberfläche',
                    style: TextStyle(fontFamily: 'SF Pro')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/webui');
                }),
            ListTile(
                leading:
                    Icon(Icons.history, color: theme.colorScheme.onSurface),
                title: const Text('Verlauf',
                    style: TextStyle(fontFamily: 'SF Pro')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/history');
                }),
            // No divider or logout in original design
          ],
        ),
      ),
      // Body structure from original design
      body: Stack(
        children: [
          // Background image from original
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background/weinkeller.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark overlay from original
          if (isDarkMode)
            Container(
              color: Color.alphaBlend(
                Colors.black.withAlpha(80), // Original opacity
                Colors.transparent,
              ),
            ),
          // Error message display from original design
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Original padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // Original error text style
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 16,
                        color: Colors.red, // Original color
                      ),
                    ),
                    const SizedBox(height: 16), // Original spacing
                    SizedBox(
                      // Original button structure
                      width: double.infinity,
                      child: ElevatedButton(
                        // Original button style
                        onPressed: _showManualSelectDialog,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor:
                              const Color(0xFFEFEFF0), // Original color
                          padding: const EdgeInsets.symmetric(
                              vertical: 16), // Original padding
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30), // Original radius
                          ),
                          textStyle: const TextStyle(
                            // Original text style
                            fontSize: 15,
                            fontFamily: 'SF Pro',
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w400,
                            height: 1.333,
                            letterSpacing: -0.23,
                          ),
                        ),
                        child: Text(
                          // Original button text style
                          'Manuell auswählen',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontFamily: 'SF Pro',
                            fontSize: 15,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w400,
                            height: 1.333,
                            letterSpacing: -0.23,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // QRView setup from original design (no specific size/overlay)
            Center(
              // Ensure QRView is centered if no error
              child: SizedBox(
                // Use SizedBox to constrain QRView size if needed
                width: MediaQuery.of(context).size.width *
                    0.7, // Example size, adjust as needed
                height: MediaQuery.of(context).size.width * 0.7,
                child: QRView(
                  key: _qrKey,
                  onQRViewCreated: (QRViewController controller) {
                    _qrController = controller;
                    controller.scannedDataStream.listen((scanData) {
                      if (scanData.code != null &&
                          _scannedCode != scanData.code) {
                        setState(() {
                          _scannedCode = scanData.code;
                        });
                        // Use pushNamed to navigate
                        Navigator.pushNamed(context, '/entryDetails',
                            arguments: scanData.code);
                      }
                    });
                  },
                  onPermissionSet: (ctrl, isGranted) {
                    if (!isGranted) {
                      setState(() {
                        // Use original error message text
                        _errorMessage = 'Kamerazugriff verweigert.';
                      });
                    } else {
                      // If permission granted later, clear error message
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                      _qrController?.resumeCamera();
                    }
                  },
                  // No specific overlay defined in original design, use default or add one if desired
                  // overlay: QrScannerOverlayShape(...)
                ),
              ),
            ),
          // Bottom navigation bar from original design
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              // Original SizedBox wrapper
              height: 100,
              child: ClipRect(
                // Original ClipRect
                child: Container(
                  // Original Container style
                  color: const Color(0xCC000000), // Original color
                  child: Row(
                    // Original Row layout
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        // Original Menu button
                        icon: const Icon(Icons.menu,
                            size: 30, color: Colors.white),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        tooltip: 'Menü öffnen',
                      ),
                      ElevatedButton(
                        // Original Center button
                        onPressed: _showManualSelectDialog,
                        style: ElevatedButton.styleFrom(
                          // Original style
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(18),
                          backgroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Icon(
                          // Original icon (qrcode)
                          FontAwesomeIcons.qrcode,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        // Original Account button
                        icon: const Icon(Icons.person, // Original icon (filled)
                            size: 30,
                            color: Colors.white),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/account'),
                        tooltip: 'Konto öffnen',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
