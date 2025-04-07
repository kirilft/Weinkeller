import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/database_service.dart';
import 'package:weinkeller/config/app_colors.dart';
import 'package:weinkeller/components/pending_changes.dart';
import 'package:weinkeller/services/auth_service.dart';
// Only ApiManager should be needed here now for fetching cached data
import 'package:weinkeller/services/api_manager.dart';
// ApiService import might not be needed directly anymore in this file
// import 'package:weinkeller/services/api_service.dart';

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
    _randomGreeting = _greetings[randomIndex];
  }

  @override
  void dispose() {
    _qrController?.dispose(); // Keep QR controller disposal
    super.dispose();
  }

  /// Shows the bottom sheet displaying pending changes (offline operations).
  void _showPendingChanges() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 414),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(54)),
          ),
          child: const PendingChanges(),
        );
      },
    );
  }

  /// Fetches barrels and wine types using ApiManager (leveraging caching)
  /// and combines them for the dialog.
  /// Returns a list of maps: [{'barrel': barrelData, 'currentWineType': wineTypeData}].
  Future<List<Map<String, dynamic>>> _fetchWines() async {
    // Access ApiManager and AuthService using Provider
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;

    if (token == null || token.isEmpty) {
      debugPrint('[HomeScreen] No auth token found for fetching wines.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nicht angemeldet.')),
        );
      }
      return []; // Return empty list if not authenticated
    }

    try {
      // 1. Fetch Barrels (tries API, falls back to cache)
      debugPrint(
          '[HomeScreen] Calling apiManager.getAllWineBarrelsWithCaching...');
      final barrels = await apiManager.getAllWineBarrelsWithCaching(token);
      debugPrint('[HomeScreen] Fetched ${barrels.length} barrels.');

      // 2. Fetch All Wine Types (tries API, falls back to cache)
      debugPrint(
          '[HomeScreen] Calling apiManager.getAllWineTypesWithCaching...');
      final allWineTypes = await apiManager.getAllWineTypesWithCaching(token);
      debugPrint('[HomeScreen] Fetched ${allWineTypes.length} wine types.');

      // 3. Create a lookup map for Wine Types by ID
      final wineTypeMap = <String, Map<String, dynamic>>{
        for (var wt in allWineTypes)
          if (wt['id'] != null) wt['id'].toString(): wt,
      };
      debugPrint('[HomeScreen] Created WineType lookup map.');

      // 4. Combine Barrel data with its corresponding Wine Type data
      List<Map<String, dynamic>> combinedData = [];
      for (final barrel in barrels) {
        final currentWineTypeId = barrel['currentWineTypeId']?.toString();
        Map<String, dynamic>? currentWineType; // Initialize as null

        if (currentWineTypeId != null) {
          // Look up the wine type in the map
          currentWineType = wineTypeMap[currentWineTypeId];
          if (currentWineType == null) {
            debugPrint(
                '[HomeScreen] Warning: WineType with ID $currentWineTypeId not found in fetched/cached types for barrel ${barrel['id']}.');
          }
        } else {
          // Barrel might be empty or data missing
          // debugPrint('[HomeScreen] Barrel ${barrel['id']} has no currentWineTypeId.');
        }

        combinedData.add({
          'barrel': barrel, // The full barrel data
          'currentWineType':
              currentWineType, // The corresponding wine type data (or null)
        });
      }

      debugPrint('[HomeScreen] Finished combining barrel and wine type data.');
      return combinedData;
    } catch (e) {
      // Log error if fetching barrels or wine types fails significantly
      debugPrint('[HomeScreen] Error during _fetchWines data retrieval: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Fehler beim Laden der Daten: ${e.toString().split(':').last}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return []; // Return empty list on error
    }
  }

  /// Opens a bottom sheet displaying a list of wine barrels for manual selection.
  /// Displays the wine type of the barrel below the current one, using pre-fetched data.
  void _showManualSelectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Use FutureBuilder to handle the asynchronous fetching of combined data
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchWines(), // Calls the updated method
          builder: (context, snapshot) {
            // Loading indicator
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(54)),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            // Error display
            if (snapshot.hasError) {
              return Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(54)),
                ),
                child: Center(
                  child: Text(
                    'Fehler beim Laden der Weine',
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

            // Data available: snapshot.data is List<{'barrel': {...}, 'currentWineType': {...}}>]
            final combinedData = snapshot.data ?? [];

            // Build the dialog content
            return Container(
              constraints: const BoxConstraints(maxHeight: 414),
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(54)),
              ),
              child: combinedData.isEmpty
                  ? Center(
                      child: Text("Keine Fässer gefunden.",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount: combinedData.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        // --- Data Extraction ---
                        final currentItem = combinedData[index];
                        final currentBarrel =
                            currentItem['barrel'] as Map<String, dynamic>? ??
                                {};
                        // final currentWineType = currentItem['currentWineType'] as Map<String, dynamic>?; // Wine type of *this* barrel

                        final currentBarrelName =
                            currentBarrel['name'] ?? 'Unbekannter Wein';
                        final currentBarrelId = currentBarrel['id']?.toString();

                        // --- Determine Subtitle (Wine in Barrel Below) ---
                        String subtitleText = '';
                        if (index + 1 < combinedData.length) {
                          final nextItem = combinedData[index + 1];
                          // Get the pre-fetched wine type data for the *next* barrel
                          final nextWineTypeData = nextItem['currentWineType']
                              as Map<String, dynamic>?;
                          final nextWineTypeName =
                              nextWineTypeData?['name'] as String?;

                          if (nextWineTypeName != null &&
                              nextWineTypeName.isNotEmpty) {
                            subtitleText = nextWineTypeName;
                          } else if (nextWineTypeData != null) {
                            // If next barrel has a wine type ID but we couldn't find the name in cache
                            subtitleText = '(Unbekannter Weintyp)';
                          } else {
                            // If next barrel has no currentWineTypeId or fetch failed earlier
                            subtitleText = '(Fass leer / Kein Weintyp)';
                          }
                        } else {
                          subtitleText = 'Letztes Fass in der Liste';
                        }

                        // --- Build ListTile ---
                        return ListTile(
                          title: Text(currentBarrelName,
                              style: TextStyle(
                                  fontFamily: 'SF Pro',
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text(
                            subtitleText,
                            style: TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          onTap: () {
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

    // ** Using the UI structure from the user's provided original design **
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
