import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/api_service.dart';
import 'package:weinkeller/services/auth_service.dart';

class QRResultPage extends StatefulWidget {
  static const routeName = '/qrResult';

  final String qrCode;

  const QRResultPage({super.key, required this.qrCode});

  @override
  State<QRResultPage> createState() => _QRResultPageState();
}

class _QRResultPageState extends State<QRResultPage> {
  final TextEditingController _densityController = TextEditingController();
  bool _isSubmitting = false;
  String _wineName = ''; // This will store the fetched wine name

  @override
  void initState() {
    super.initState();
    _fetchWineName();
  }

  Future<void> _fetchWineName() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      // Parse the QR code as wineId
      final wineId = int.parse(widget.qrCode);
      // Retrieve the token; if null, we cannot fetch the wine name
      final token = authService.authToken;
      if (token == null || token.isEmpty) {
        setState(() {
          _wineName = 'Unknown Wine';
        });
        return;
      }
      final result = await apiService.getWineById(wineId, token: token);
      setState(() {
        _wineName = result['name'] ?? 'Unknown Wine';
      });
    } catch (e) {
      setState(() {
        _wineName = 'Unknown Wine';
      });
      debugPrint('[QRResultPage] _fetchWineName() - Error: $e');
    }
  }

  /// Submits the QR code and additional data (density) to the server.
  Future<void> _submitData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);

    final token = authService.authToken; // Retrieve the stored auth token
    final qrCode = widget.qrCode;
    final densityInput = _densityController.text.trim();

    if (token == null || token.isEmpty) {
      _showErrorDialog(
        'Authentication Error',
        'You must be logged in to submit data.',
        showLoginButton: true,
      );
      return;
    }

    if (densityInput.isEmpty) {
      _showErrorDialog('Validation Error', 'Please enter the density value.');
      return;
    }

    double density;
    try {
      density = double.parse(densityInput);
    } catch (_) {
      _showErrorDialog(
          'Validation Error', 'Density must be a valid number (e.g., 0.98).');
      return;
    }

    // Convert QR code to wineId (assuming it's numeric).
    int wineId;
    try {
      wineId = int.parse(qrCode);
    } catch (_) {
      _showErrorDialog('QR Code Error', 'Invalid QR Code for wine ID.');
      return;
    }

    final DateTime date = DateTime.now();

    setState(() => _isSubmitting = true);

    try {
      await apiService.addFermentationEntry(
        token: token,
        date: date,
        density: density,
        wineId: wineId,
      );
      _showSuccessDialog('Fermentation entry added successfully!');
    } catch (e) {
      _showErrorDialog('Submission Error', e.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  /// Displays an error dialog.
  void _showErrorDialog(
    String title,
    String message, {
    bool showLoginButton = false,
  }) {
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
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pushNamed('/login'); // Go to login page
                },
                child: const Text('Login'),
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

  /// Displays a success dialog.
  void _showSuccessDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set the system overlay style so that iOS status bar icons are dark.
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Wein',
          style: TextStyle(fontFamily: 'SF Pro'),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Scanned QR Code:" with the code appended.
              Text(
                'Scanned QR Code: ${widget.qrCode}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              // Headline: use the fetched wine name (if available), aligned left.
              Text(
                _wineName.isEmpty ? 'Loading...' : _wineName,
                style: const TextStyle(
                  color: Color(0xFF000000), // var(--luminance-black, #000)
                  fontFamily: 'SF Pro',
                  fontSize: 20,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w400,
                  height: 1.25, // 25/20
                  letterSpacing: -0.45,
                  fontFeatures: [
                    FontFeature.disable('liga'),
                    FontFeature.disable('clig'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Density input field.
              TextField(
                controller: _densityController,
                decoration: const InputDecoration(
                  labelText: 'Density',
                  hintText: 'Enter the density value (e.g., 0.98)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              // Submit button aligned to the right.
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _submitData,
                        child: const Text('Submit'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
