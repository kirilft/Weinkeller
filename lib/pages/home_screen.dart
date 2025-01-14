import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:weinkeller/services/database_service.dart';

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
    final entries = await DatabaseService().getPendingEntries();
    setState(() {
      _pendingChangesCount = entries.length;
    });
  }

  void _showManualCodeDialog() {
    String enteredCode = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manual Entry'),
          content: TextField(
            onChanged: (value) => enteredCode = value,
            decoration: const InputDecoration(labelText: 'Enter WineID'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(
                  this.context,
                  '/qrResult',
                  arguments: enteredCode,
                );
              },
              child: const Text('OK'),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Spacer to balance the right-side icon
            const SizedBox(width: 24), // Adjust width to match the icon size

            // Centered title
            Text(
              'Home Screen',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),

            // Right-side pending changes icon (if needed)
            if (_pendingChangesCount > 0)
              Stack(
                children: [
                  const Icon(
                    Icons.sync_problem,
                    color: Colors.red,
                  ),
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.white,
                      child: Text(
                        '$_pendingChangesCount',
                        style: const TextStyle(fontSize: 10, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              )
            else
              // Placeholder to keep the title centered when no icon is shown
              const SizedBox(width: 24),
          ],
        ),
        automaticallyImplyLeading: false,
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
                  color:
                      isDarkMode ? Colors.grey[800] : const Color(0xFFFF453A),
                ),
                child: Center(
                  child: Text(
                    _randomGreeting,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              title: const Text('Settings'),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            ListTile(
              leading: Icon(
                Icons.history,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              title: const Text('History'),
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
            ListTile(
              leading: Icon(
                Icons.info,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              title: const Text('Changelog'),
              onTap: () => Navigator.pushNamed(context, '/changelog'),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: isDarkMode ? Colors.grey[900] : const Color(0xFF00BFA5),
          ),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.redAccent
                            : const Color(0xFFFF453A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showManualCodeDialog,
                      child: const Text('Enter Code Manually'),
                    ),
                  ],
                ),
              ),
            )
          else
            QRView(
              key: _qrKey,
              onQRViewCreated: (QRViewController controller) {
                _qrController = controller;
                controller.scannedDataStream.listen((scanData) {
                  if (scanData.code != null && _scannedCode != scanData.code) {
                    setState(() {
                      _scannedCode = scanData.code;
                    });
                    Navigator.pushNamed(
                      context,
                      '/qrResult',
                      arguments: scanData.code,
                    );
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 100,
              child: ClipRect(
                child: Container(
                  color: isDarkMode ? Colors.black87 : Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          size: 30,
                          color: Colors.white,
                        ),
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
                        ),
                        child: const Icon(
                          FontAwesomeIcons.qrcode,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        ),
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
