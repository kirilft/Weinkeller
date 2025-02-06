import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:weinkeller/services/database_service.dart';
import 'package:flutter/services.dart';
import 'package:weinkeller/config/app_colors.dart';
import 'package:weinkeller/config/custom_colors.dart';
import 'package:weinkeller/components/pending_changes.dart';

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
  String? _errorMessage;
  int _pendingChangesCount = 0;

  final List<String> _greetings = [
    'Hello',
    'Hallo',
    'Bonjour',
    'Ciao',
    'Konnichiwa',
    'Namaste',
  ];
  late String _randomGreeting;

  @override
  void initState() {
    super.initState();
    _pickRandomGreeting();
    _loadPendingChangesCount();
  }

  void _pickRandomGreeting() {
    final randomIndex = Random().nextInt(_greetings.length);
    _randomGreeting = _greetings[randomIndex];
  }

  Future<void> _loadPendingChangesCount() async {
    try {
      final entries = await DatabaseService().getPendingEntries();
      setState(() {
        _pendingChangesCount = entries.length;
      });
    } catch (e) {
      print('[HomeScreen] Error loading pending changes count: $e');
    }
  }

  void _showManualCodeDialog() {
    String enteredCode = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manual Entry',
              style: TextStyle(fontFamily: 'SF Pro')),
          content: TextField(
            onChanged: (value) => enteredCode = value,
            decoration: const InputDecoration(
              labelText: 'Enter WineID',
              labelStyle: TextStyle(fontFamily: 'SF Pro'),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text('Cancel', style: TextStyle(fontFamily: 'SF Pro')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/qrResult',
                    arguments: enteredCode);
              },
              style: ElevatedButton.styleFrom(elevation: 0),
              child: const Text('OK', style: TextStyle(fontFamily: 'SF Pro')),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _qrController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 64), // Left spacer
            Text(
              'Home',
              style: TextStyle(
                color: Theme.of(context).white,
                fontFeatures: [
                  FontFeature.disable('liga'),
                  FontFeature.disable('clig')
                ],
                fontFamily: 'SF Pro',
                fontSize: 28,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w400,
                height: 34 / 28,
                letterSpacing: 0.38,
              ),
            ),
            _pendingChangesCount > 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors
                              .transparent, // So our container decoration shows properly.
                          isScrollControlled: true,
                          builder: (context) {
                            final screenHeight =
                                MediaQuery.of(context).size.height;
                            return Container(
                              constraints: BoxConstraints(
                                maxHeight: screenHeight *
                                    0.5, // Limit to 50% of screen height.
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              child: const PendingChanges(),
                            );
                          },
                        );
                      },
                      child: Stack(
                        children: [
                          Icon(
                            FontAwesomeIcons.arrowsRotate,
                            size: 32,
                            color: theme.colorScheme.error,
                          ),
                          Positioned(
                            right: 0,
                            child: CircleAvatar(
                              radius: 8,
                              backgroundColor: theme.colorScheme.onError,
                              child: Text(
                                '$_pendingChangesCount',
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
                : const SizedBox(width: 64),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            SizedBox(
              height: 100,
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  // Use a custom color: redDark in light mode, or a dark grey in dark mode
                  color: isDarkMode ? Colors.grey[800] : AppColors.redDark,
                ),
                child: Center(
                  child: Text(
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
            ListTile(
              leading: Icon(Icons.settings, color: theme.colorScheme.onSurface),
              title: const Text('Settings',
                  style: TextStyle(fontFamily: 'SF Pro')),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            ListTile(
              leading: Icon(Icons.history, color: theme.colorScheme.onSurface),
              title:
                  const Text('History', style: TextStyle(fontFamily: 'SF Pro')),
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
            ListTile(
              leading: Icon(Icons.info, color: theme.colorScheme.onSurface),
              title: const Text('Changelog',
                  style: TextStyle(fontFamily: 'SF Pro')),
              onTap: () => Navigator.pushNamed(context, '/changelog'),
            ),
            ListTile(
              leading: const Icon(Icons.wine_bar),
              title: const Text('All Wines'),
              onTap: () {
                Navigator.of(context).pushNamed('/all_wines');
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background/weinkeller.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay for dark mode
          if (isDarkMode)
            Container(
              color: Color.alphaBlend(
                Colors.black.withAlpha(80),
                Colors.transparent,
              ),
            ),
          // Error message overlay
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showManualCodeDialog,
                        style: ElevatedButton.styleFrom(
                          elevation: 0, // Removes button shadow
                          backgroundColor: const Color(
                              0xFFEFEFF0), // Custom light gray background
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'SF Pro',
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w400,
                            height: 1.333,
                            letterSpacing: -0.23,
                          ),
                        ),
                        child: Text(
                          'Manuell Code eingeben',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
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
            // QRView if no error
            QRView(
              key: _qrKey,
              onQRViewCreated: (QRViewController controller) {
                _qrController = controller;
                controller.scannedDataStream.listen((scanData) {
                  if (scanData.code != null && _scannedCode != scanData.code) {
                    setState(() {
                      _scannedCode = scanData.code;
                    });
                    Navigator.pushNamed(context, '/qrResult',
                        arguments: scanData.code);
                  }
                });
              },
              onPermissionSet: (ctrl, isGranted) {
                if (!isGranted) {
                  setState(() {
                    _errorMessage = 'Camera permission denied.';
                  });
                }
              },
            ),
          // Bottom navigation bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 100,
              child: ClipRect(
                child: Container(
                  color: isDarkMode
                      ? const Color(0xCC000000)
                      : const Color(0xCC000000),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu,
                            size: 30, color: Colors.white),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        tooltip: 'Open Menu',
                      ),
                      ElevatedButton(
                        onPressed: _showManualCodeDialog,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(18),
                          backgroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Icon(
                          FontAwesomeIcons.qrcode,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person,
                            size: 30, color: Colors.white),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/account'),
                        tooltip: 'Open Account',
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
