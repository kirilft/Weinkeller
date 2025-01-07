import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraErrorMessage;

  // List of greetings in different languages
  final List<String> _greetings = [
    'Hello',
    'Hallo',
    'Bonjour',
    'Ciao',
    'Konnichiwa',
    'Namaste',
  ];

  // We'll store the random greeting here
  late String _randomGreeting;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _pickRandomGreeting();
  }

  void _pickRandomGreeting() {
    // Pick a random index from 0 to _greetings.length - 1
    final randomIndex = Random().nextInt(_greetings.length);
    _randomGreeting = _greetings[randomIndex];
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        // No cameras found -> set an error message
        throw Exception('No cameras found on the device.');
      }

      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController.initialize();

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      setState(() {
        _cameraErrorMessage =
            'Unable to access the camera. Please check your permissions and try again.';
      });
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  /// Opens a dialog that lets the user type in a code, then navigates to /qrResult.
  void _showManualCodeDialog() {
    String enteredCode = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manual Entry'),
          content: TextField(
            onChanged: (value) => enteredCode = value,
            decoration: const InputDecoration(
              labelText: 'Enter Code',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Dismiss dialog
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Close the dialog first
                Navigator.of(context).pop();
                // Then navigate to the result page with the typed-in code
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
    return Scaffold(
      key: _scaffoldKey,
      // AppBar without a menu icon
      appBar: AppBar(
        title: const Text('Home Screen'),
        automaticallyImplyLeading: false, // Removes the default drawer icon
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            // Wrap the DrawerHeader in a SizedBox to reduce its height
            SizedBox(
              height: 100, // Adjust the height as needed
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF453A),
                ),
                child: Center(
                  child: Text(
                    _randomGreeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Changelog'),
              onTap: () {
                Navigator.pushNamed(context, '/changelog');
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Camera preview as the background if initialized
          if (_isCameraInitialized)
            CameraPreview(_cameraController)

          // If there's an error (e.g. no camera), show a message and a "Manual Entry" button
          else if (_cameraErrorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _cameraErrorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFF453A),
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

          // Otherwise, show loading indicator
          else
            const Center(child: CircularProgressIndicator()),

          // Frosted box at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 100,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.white.withOpacity(0.2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Menu button (opens the drawer)
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          tooltip: 'Open Menu',
                        ),

                        // Take a picture button
                        ElevatedButton(
                          onPressed: _showManualCodeDialog,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(24),
                          ),
                          child: const Icon(Icons.camera_alt),
                        ),

                        // Account button
                        IconButton(
                          icon: const Icon(Icons.person),
                          onPressed: () {
                            Navigator.pushNamed(context, '/account');
                          },
                          tooltip: 'Open Account',
                        ),
                      ],
                    ),
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
