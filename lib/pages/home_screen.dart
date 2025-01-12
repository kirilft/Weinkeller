import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:weinkeller/components/app_drawer.dart';
import 'package:weinkeller/components/bottom_nav_bar.dart';

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
  final List<String> _greetings = [
    'Hello',
    'Hallo',
    'Bonjour',
    'Ciao',
    'Konnichiwa',
    'Namaste'
  ];
  late String _randomGreeting;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _randomGreeting = _greetings[Random().nextInt(_greetings.length)];
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras found.');
      _cameraController = CameraController(cameras.first, ResolutionPreset.high,
          enableAudio: false);
      await _cameraController.initialize();
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      setState(() => _cameraErrorMessage = 'Unable to access the camera.');
    }
  }

  @override
  void dispose() {
    if (_isCameraInitialized) _cameraController.dispose();
    super.dispose();
  }

  void _showManualCodeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String enteredCode = '';
        return AlertDialog(
          title: const Text('Manual Entry'),
          content: TextField(
            onChanged: (value) => enteredCode = value,
            decoration: const InputDecoration(labelText: 'Enter Code'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/qrResult',
                    arguments: enteredCode);
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
        title: Text('Home Screen',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        automaticallyImplyLeading: false,
      ),
      drawer: AppDrawer(randomGreeting: _randomGreeting),
      body: Stack(
        children: [
          Container(
              color: isDarkMode ? Colors.grey[900] : const Color(0xFF00BFA5)),
          if (_isCameraInitialized)
            CameraPreview(_cameraController)
          else if (_cameraErrorMessage != null)
            Center(
                child: Text(_cameraErrorMessage!, textAlign: TextAlign.center)),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(
              scaffoldKey: _scaffoldKey,
              showManualCodeDialog: _showManualCodeDialog,
            ),
          ),
        ],
      ),
    );
  }
}
