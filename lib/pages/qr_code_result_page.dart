// lib/pages/qr_code_result_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/api_service.dart';
import 'package:weinkeller/services/auth_service.dart';

class QrCodeResultPage extends StatelessWidget {
  final String qrData;

  const QrCodeResultPage({super.key, required this.qrData});

  @override
  Widget build(BuildContext context) {
    final TextEditingController userInputController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('QR Code Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'QR Code: $qrData',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: userInputController,
              decoration: const InputDecoration(
                labelText: 'Additional Info',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final userInput = userInputController.text;

                // 1) Check if user is logged in (depending on your logic)
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                if (!authService.isLoggedIn) {
                  Navigator.pushNamed(context, '/login');
                  return;
                }

                // 2) Retrieve the token from AuthService
                final token = authService.token;
                if (token == null) {
                  Navigator.pushNamed(context, '/login');
                  return;
                }

                // 3) Retrieve the ApiService from Provider
                final apiService =
                    Provider.of<ApiService>(context, listen: false);

                // 4) Attempt to save the data
                try {
                  await apiService.saveQrData(
                    token: token,
                    qrData: qrData,
                    userInput: userInput,
                  );

                  // If successful, pop back with user input or show success
                  Navigator.pop(context, userInput);
                } catch (e) {
                  // If there's an error, show a snackbar or handle gracefully
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
