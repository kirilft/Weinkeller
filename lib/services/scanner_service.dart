import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class ScannerService {
  late CameraController _cameraController;
  bool _cameraInitialized = false;
  String? _errorMessage;

  CameraController get cameraController => _cameraController;
  bool get cameraInitialized => _cameraInitialized;
  String? get errorMessage => _errorMessage;

  Future<void> initializeCamera() async {
    _cameraInitialized = false;
    _errorMessage = null;

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
      _cameraInitialized = true;
    } catch (e) {
      _errorMessage = 'Unable to open camera: $e';
    }
  }

  Future<void> scanQrCode(BuildContext context) async {
    const scannedCode = 'FakeQRCode123'; // Placeholder
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('QR Code Scanned'),
        content: Text('Scanned Code: $scannedCode'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void showManualCodeDialog(BuildContext context) {
    String enteredCode = '';
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Manual Entry'),
          content: TextField(
            onChanged: (value) => enteredCode = value,
            decoration: const InputDecoration(labelText: 'Enter Code'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                showDialog(
                  context: context,
                  builder: (bCtx) => AlertDialog(
                    title: const Text('Manual Code'),
                    content: Text('Entered Code: $enteredCode'),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(bCtx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
