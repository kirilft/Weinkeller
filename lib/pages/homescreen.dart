import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isDebugMenuVisible = false; // Boolean to toggle the debug menu

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Initialize the camera
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first; // Use the first available camera
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false, // Disable audio for the preview
      );
      await _cameraController.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  // Dispose the camera controller
  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  // Toggles the debug menu
  void _toggleDebugMenu() {
    setState(() {
      _isDebugMenuVisible = !_isDebugMenuVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        actions: [
          // Debug menu toggle button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _toggleDebugMenu,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview as the background
          if (_isCameraInitialized)
            CameraPreview(_cameraController)
          else
            const Center(child: CircularProgressIndicator()),

          // Debug menu overlay
          if (_isDebugMenuVisible)
            Positioned(
              top: 70, // Position below the AppBar
              right: 10, // Position near the right edge
              child: Material(
                elevation: 4.0, // Add shadow for a floating effect
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text('Login Page'),
                        onTap: () {
                          Navigator.pushNamed(context, '/login');
                          _toggleDebugMenu();
                        },
                      ),
                      ListTile(
                        title: const Text('Password Reset'),
                        onTap: () {
                          Navigator.pushNamed(context, '/password_reset');
                          _toggleDebugMenu();
                        },
                      ),
                      ListTile(
                        title: const Text('Account Page'),
                        onTap: () {
                          Navigator.pushNamed(context, '/account');
                          _toggleDebugMenu();
                        },
                      ),
                      ListTile(
                        title: const Text('Settings Page'),
                        onTap: () {
                          Navigator.pushNamed(context, '/settings');
                          _toggleDebugMenu();
                        },
                      ),
                      ListTile(
                        title: const Text('Menu Page'),
                        onTap: () {
                          Navigator.pushNamed(context, '/menu');
                          _toggleDebugMenu();
                        },
                      ),
                      ListTile(
                        title: const Text('History Page'),
                        onTap: () {
                          Navigator.pushNamed(context, '/history');
                          _toggleDebugMenu();
                        },
                      ),
                      ListTile(
                        title: const Text('Changelog Page'),
                        onTap: () {
                          Navigator.pushNamed(context, '/changelog');
                          _toggleDebugMenu();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Frosted box at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.white.withOpacity(0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Menu button (burger icon)
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            Navigator.pushNamed(context, '/menu');
                          },
                          tooltip: 'Open Menu',
                        ),

                        // Take a picture button
                        ElevatedButton(
                          onPressed: () {
                            // Placeholder for picture-taking functionality
                          },
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(24),
                          ),
                          child: const Icon(Icons.camera_alt),
                        ),

                        // Account button (person icon)
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
