import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ...existing code...
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late CameraController _cameraController;
  bool _cameraInitialized = false;
  String? _errorMessage;

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
    _initializeCamera();
    _pickRandomGreeting();
  }

  void _pickRandomGreeting() {
    final randomIndex = Random().nextInt(_greetings.length);
    _randomGreeting = _greetings[randomIndex];
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras found.');
      }
      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController.initialize();
      setState(() {
        _cameraInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Unable to access the camera. Check permissions and retry.';
      });
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    if (_cameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
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
            decoration: const InputDecoration(labelText: 'Enter Code'),
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
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Home Screen',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
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
              color: isDarkMode ? Colors.grey[900] : const Color(0xFF00BFA5)),
          if (_cameraInitialized)
            CameraPreview(_cameraController)
          else if (_errorMessage != null)
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
            Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
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
                        icon: Icon(
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

// ...existing code...
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Screen')),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Center(child: Text('History Screen')),
    );
  }
}

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Changelog')),
      body: const Center(child: Text('Changelog Screen')),
    );
  }
}

class QRResultScreen extends StatelessWidget {
  const QRResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String enteredCode =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'No Code';
    return Scaffold(
      appBar: AppBar(title: const Text('QR Result')),
      body: Center(child: Text('Entered Code: $enteredCode')),
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: const Center(child: Text('Account Screen')),
    );
  }
}
