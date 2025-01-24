import 'package:flutter/material.dart';
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

  /// Submits the QR code and additional data (density) to the server.
  Future<void> _submitData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);

    final token = authService.token; // Retrieve the stored auth token
    final qrCode = widget.qrCode;
    final densityInput = _densityController.text.trim();

    if (token == null || token.isEmpty) {
      _showErrorDialog(
        'Authentication Error',
        'You must be logged in to submit data.',
        showLoginButton: true, // pass this flag
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

    // Convert QR code to wineId (assuming it's numeric, adjust as needed)
    int wineId;
    try {
      wineId = int.parse(qrCode);
    } catch (_) {
      _showErrorDialog('QR Code Error', 'Invalid QR Code for wine ID.');
      return;
    }

    final DateTime date = DateTime.now(); // Use current date

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
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: [
            // Conditionally display a "Login" button.
            if (showLoginButton)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
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
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scanned QR Code:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.qrCode,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
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
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitData,
                    child: const Text('Submit'),
                  ),
          ],
        ),
      ),
    );
  }
}
